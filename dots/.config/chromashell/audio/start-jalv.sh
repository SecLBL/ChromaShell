#!/usr/bin/env bash
# ChromaShell — startet alle jalv LV2-Plugin-Instanzen
#
# Liest Plugin-Definitionen und aktuelle Parameter aus:
#   $XDG_CONFIG_HOME/chromashell/audio/runtime/audio.json   (Single Source of Truth)
#
# Wenn die Config fehlt, wird sie aus audio.json.default angelegt.
# Jede Instanz bekommt ein FIFO unter /tmp/jalv-<name> für live Steuerung.
# Log: /tmp/start-jalv.log
#
# Läuft als Type=simple systemd-Service. Bleibt im Vordergrund und überwacht
# die jalv-Kindprozesse. Stirbt ein Plugin, exitiert das Script mit Code 1
# → systemd Restart=on-failure startet die gesamte Chain neu.

set -euo pipefail
exec >> /tmp/start-jalv.log 2>&1
echo "=== start-jalv.sh $(date) ==="

JALV="$(command -v jalv)"
PW_JACK="$(command -v pw-jack || true)"
JQ="$(command -v jq)"

if [[ -z "$JALV" ]]; then
    echo "Error: jalv not in PATH" >&2
    exit 1
fi
if [[ -z "$JQ" ]]; then
    echo "Error: jq not in PATH" >&2
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/audio/runtime"
CONFIG_FILE="$CONFIG_DIR/audio.json"
DEFAULT_CONFIG="${CHROMASHELL_DEFAULT_CONFIG:-$(dirname "$(readlink -f "$0")")/audio.json.default}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CONFIG_DIR"
    if [[ -f "$DEFAULT_CONFIG" ]]; then
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        echo "Initial audio.json created from defaults: $CONFIG_FILE"
    else
        echo "Error: neither $CONFIG_FILE nor $DEFAULT_CONFIG found" >&2
        exit 1
    fi
fi

if ! "$JQ" empty "$CONFIG_FILE" 2>/dev/null; then
    echo "Error: $CONFIG_FILE is not valid JSON" >&2
    exit 1
fi

# PID tracking — jalv processes and their FIFO keeper processes
declare -A JALV_PIDS=()
declare -A KEEPER_PIDS=()

cleanup() {
    echo "Cleaning up jalv processes..."
    for pid in "${JALV_PIDS[@]}"  "${KEEPER_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    rm -f /tmp/jalv-*
    echo "Cleanup done."
}
trap cleanup EXIT

start_plugin() {
    local name="$1"
    local uri="$2"
    local fifo="/tmp/jalv-${name}"

    local params
    params="$("$JQ" -r --arg n "$name" '.[$n].params | to_entries[] | "\(.key) \(.value)"' "$CONFIG_FILE")"

    # Plugins with no settable params (e.g. RNNoise) must run with -i to avoid
    # jalv's interactive stdin loop interfering with real-time audio processing.
    if [[ -z "$params" ]]; then
        ${PW_JACK:+"$PW_JACK"} "$JALV" -i -n "$name" "$uri" < /dev/null &
        JALV_PIDS["$name"]=$!
        echo "Started jalv $name (pid ${JALV_PIDS[$name]}) — URI: $uri [non-interactive]"
        return
    fi

    [[ -p "$fifo" ]] && rm -f "$fifo"
    mkfifo "$fifo"

    (
        exec 3>"$fifo"
        sleep 3
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            echo "set $line" >&3
        done <<< "$params"
        while true; do sleep 3600; done
    ) &
    KEEPER_PIDS["$name"]=$!

    ${PW_JACK:+"$PW_JACK"} "$JALV" -n "$name" "$uri" < "$fifo" &
    JALV_PIDS["$name"]=$!
    echo "Started jalv $name (pid ${JALV_PIDS[$name]}) — URI: $uri"
}

wait_node_out() {
    local node="$1" timeout="${2:-20}"
    local elapsed=0
    until pw-link -o 2>/dev/null | grep -q "^${node}:"; do
        sleep 0.5
        (( elapsed++ ))
        if [[ $elapsed -ge $timeout ]]; then
            echo "Warning: output node '${node}' did not appear within $(( timeout / 2 )) s"
            return 1
        fi
    done
    echo "Node ready (out): $node"
}

link_static() {
    wait_node_out "mic_chain_out"     || return 1
    wait_node_out "MixBusChat.output" || return 1
    wait_node_out "MixBus.output"     || return 1

    pw-link "mic_chain_out:capture_FL"     "VirtualCable.input:playback_FL" || true
    pw-link "mic_chain_out:capture_FR"     "VirtualCable.input:playback_FR" || true
    pw-link "MixBusChat.output:capture_FL" "chat_chain_in:playback_FL"      || true
    pw-link "MixBusChat.output:capture_FR" "chat_chain_in:playback_FR"      || true
    pw-link "MixBus.output:capture_FL"     "general_chain_in:playback_FL"   || true
    pw-link "MixBus.output:capture_FR"     "general_chain_in:playback_FR"   || true

    echo "Static routes linked."
}

link_chains() {
    local out_nodes=(
        mic-gate mic-nr mic-comp chat-nr chat-comp general-eq
        mic_chain_internal_out chat_chain_internal_out general_chain_internal_out
    )
    for node in "${out_nodes[@]}"; do
        wait_node_out "$node" 30 || return 1
    done

    pw-link "mic_chain_internal_out:capture_FL" "mic-gate:in_l"             || true
    pw-link "mic_chain_internal_out:capture_FR" "mic-gate:in_r"             || true
    pw-link "mic-gate:out_l"                    "mic-nr:audio_in_1"         || true
    pw-link "mic-gate:out_r"                    "mic-nr:audio_in_2"         || true
    pw-link "mic-nr:audio_out_1"                "mic-comp:in_l"             || true
    pw-link "mic-nr:audio_out_2"                "mic-comp:in_r"             || true
    pw-link "mic-comp:out_l"    "mic_chain_internal_in:playback_FL"         || true
    pw-link "mic-comp:out_r"    "mic_chain_internal_in:playback_FR"         || true

    pw-link "chat_chain_internal_out:capture_FL" "chat-nr:audio_in_1"       || true
    pw-link "chat_chain_internal_out:capture_FR" "chat-nr:audio_in_2"       || true
    pw-link "chat-nr:audio_out_1"                "chat-comp:in_l"           || true
    pw-link "chat-nr:audio_out_2"                "chat-comp:in_r"           || true
    pw-link "chat-comp:out_l"    "chat_chain_internal_in:playback_FL"       || true
    pw-link "chat-comp:out_r"    "chat_chain_internal_in:playback_FR"       || true

    pw-link "general_chain_internal_out:capture_FL" "general-eq:inL"        || true
    pw-link "general_chain_internal_out:capture_FR" "general-eq:inR"        || true
    pw-link "general-eq:outL" "general_chain_internal_in:playback_FL"       || true
    pw-link "general-eq:outR" "general_chain_internal_in:playback_FR"       || true

    echo "Audio chains linked."
}

link_devices() {
    local routing="${CONFIG_DIR}/routing.json"
    [[ -f "$routing" ]] || return 0

    local general chat mic
    general=$("$JQ" -r '.general // ""' "$routing")
    chat=$("$JQ"    -r '.chat    // ""' "$routing")
    mic=$("$JQ"     -r '.mic     // ""' "$routing")

    local script
    script="$(dirname "$(readlink -f "$0")")/audio-route.sh"

    if [[ -n "$general" ]]; then
        wait_node_out "general_chain_out" 10 \
            && bash "$script" general "$general" "" \
            || echo "Warning: could not restore general routing to '$general'"
    fi
    if [[ -n "$chat" ]]; then
        wait_node_out "chat_chain_out" 10 \
            && bash "$script" chat "$chat" "" \
            || echo "Warning: could not restore chat routing to '$chat'"
    fi
    if [[ -n "$mic" ]]; then
        pw-link -i 2>/dev/null | grep -q "^mic_chain_in:" \
            && bash "$script" mic "$mic" "" \
            || echo "Warning: could not restore mic routing to '$mic'"
    fi
    echo "Device routing restored from $routing"
}

# Start all plugins
while IFS=$'\t' read -r name uri; do
    start_plugin "$name" "$uri"
done < <("$JQ" -r 'keys_unsorted[] as $k | "\($k)\t\(.[$k].uri)"' "$CONFIG_FILE")

# Link setup in background — monitor loop runs in foreground
( link_static && link_chains && link_devices ) &

# Monitor: if any jalv process dies, exit so systemd restarts the service
echo "Monitoring ${#JALV_PIDS[@]} plugin processes..."
while true; do
    for name in "${!JALV_PIDS[@]}"; do
        if ! kill -0 "${JALV_PIDS[$name]}" 2>/dev/null; then
            echo "Plugin '$name' (pid ${JALV_PIDS[$name]}) died — triggering service restart"
            exit 1
        fi
    done
    sleep 5
done
