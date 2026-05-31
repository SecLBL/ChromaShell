#!/usr/bin/env bash
# ChromaShell — startet alle jalv LV2-Plugin-Instanzen
#
# Liest Plugin-Definitionen und aktuelle Parameter aus:
#   $XDG_CONFIG_HOME/chromashell/audio/runtime/audio.json   (Single Source of Truth)
#
# Wenn die Config fehlt, wird sie aus audio.json.default angelegt.
# Jede Instanz bekommt ein FIFO unter /tmp/jalv-<name> für live Steuerung.

set -euo pipefail

JALV="$(command -v jalv)"
PW_JACK="$(command -v pw-jack || true)"
JQ="$(command -v jq)"

if [[ -z "$JALV" ]]; then
    echo "Error: jalv nicht im PATH" >&2
    exit 1
fi
if [[ -z "$JQ" ]]; then
    echo "Error: jq nicht im PATH (brauchen wir zum JSON-Parsen)" >&2
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/audio/runtime"
CONFIG_FILE="$CONFIG_DIR/audio.json"
DEFAULT_CONFIG="${CHROMASHELL_DEFAULT_CONFIG:-$(dirname "$(readlink -f "$0")")/audio.json.default}"

# Erstinit: Config aus Defaults anlegen, falls noch keine da
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CONFIG_DIR"
    if [[ -f "$DEFAULT_CONFIG" ]]; then
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        echo "Initial audio.json aus Defaults angelegt: $CONFIG_FILE"
    else
        echo "Error: weder $CONFIG_FILE noch $DEFAULT_CONFIG vorhanden" >&2
        exit 1
    fi
fi

# Config validieren
if ! "$JQ" empty "$CONFIG_FILE" 2>/dev/null; then
    echo "Error: $CONFIG_FILE ist kein valides JSON" >&2
    exit 1
fi

start_plugin() {
    local name="$1"
    local uri="$2"
    local fifo="/tmp/jalv-${name}"

    # Stale FIFO aus alter Session entfernen
    [[ -p "$fifo" ]] && rm -f "$fifo"
    mkfifo "$fifo"

    local params
    params="$("$JQ" -r --arg n "$name" '.[$n].params | to_entries[] | "\(.key) \(.value)"' "$CONFIG_FILE")"

    (
        exec 3>"$fifo"
        if [[ -n "$params" ]]; then
            sleep 3
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                echo "set $line" >&3
            done <<< "$params"
        fi
        while true; do sleep 3600; done
    ) &

    ${PW_JACK:+"$PW_JACK"} "$JALV" -n "$name" "$uri" < "$fifo" &
    echo "Started jalv $name (pid $!) — URI: $uri"
}

link_static() {
    # Wait for the loopback and filter-chain source nodes (max 10 s)
    for node in mic_chain_out MixBusChat.output MixBus.output; do
        local elapsed=0
        until pw-link -o 2>/dev/null | grep -q "^${node}:"; do
            sleep 0.5
            elapsed=$((elapsed + 1))
            if [[ $elapsed -ge 20 ]]; then
                echo "Warning: node '${node}' did not appear within 10 s — skipping static links" >&2
                return 1
            fi
        done
    done

    # mic_chain_out → VirtualCable.input  (processed mic into virtual cable for Discord etc.)
    pw-link "mic_chain_out:capture_FL"     "VirtualCable.input:playback_FL"
    pw-link "mic_chain_out:capture_FR"     "VirtualCable.input:playback_FR"

    # MixBusChat.output → chat_chain_in  (comm audio through chat processing chain)
    pw-link "MixBusChat.output:capture_FL" "chat_chain_in:playback_FL"
    pw-link "MixBusChat.output:capture_FR" "chat_chain_in:playback_FR"

    # MixBus.output → general_chain_in  (main audio through general processing chain)
    pw-link "MixBus.output:capture_FL"     "general_chain_in:playback_FL"
    pw-link "MixBus.output:capture_FR"     "general_chain_in:playback_FR"

    echo "Static routes linked."
}

link_chains() {
    local nodes=(mic-gate mic-nr mic-comp chat-nr chat-comp general-eq)

    # Wait for all jalv nodes to appear in PipeWire (max 15 s)
    for node in "${nodes[@]}"; do
        local elapsed=0
        until pw-link -o 2>/dev/null | grep -q "^${node}:"; do
            sleep 0.5
            elapsed=$((elapsed + 1))
            if [[ $elapsed -ge 30 ]]; then
                echo "Warning: node '${node}' did not appear within 15 s — skipping link step" >&2
                return 1
            fi
        done
    done

    # Mic chain: mic_chain_internal_out → gate → nr → comp → mic_chain_internal_in
    pw-link "mic_chain_internal_out:capture_FL" "mic-gate:in_l"
    pw-link "mic_chain_internal_out:capture_FR" "mic-gate:in_r"
    pw-link "mic-gate:out_l"       "mic-nr:audio_in_1"
    pw-link "mic-gate:out_r"       "mic-nr:audio_in_2"
    pw-link "mic-nr:audio_out_1"   "mic-comp:in_l"
    pw-link "mic-nr:audio_out_2"   "mic-comp:in_r"
    pw-link "mic-comp:out_l"       "mic_chain_internal_in:playback_FL"
    pw-link "mic-comp:out_r"       "mic_chain_internal_in:playback_FR"

    # Chat chain: chat_chain_internal_out → nr → comp → chat_chain_internal_in
    pw-link "chat_chain_internal_out:capture_FL" "chat-nr:audio_in_1"
    pw-link "chat_chain_internal_out:capture_FR" "chat-nr:audio_in_2"
    pw-link "chat-nr:audio_out_1"  "chat-comp:in_l"
    pw-link "chat-nr:audio_out_2"  "chat-comp:in_r"
    pw-link "chat-comp:out_l"      "chat_chain_internal_in:playback_FL"
    pw-link "chat-comp:out_r"      "chat_chain_internal_in:playback_FR"

    # General chain: general_chain_internal_out → eq → general_chain_internal_in
    pw-link "general_chain_internal_out:capture_FL" "general-eq:in_l"
    pw-link "general_chain_internal_out:capture_FR" "general-eq:in_r"
    pw-link "general-eq:out_l" "general_chain_internal_in:playback_FL"
    pw-link "general-eq:out_r" "general_chain_internal_in:playback_FR"

    echo "Audio chains linked."
}

# Start all plugins from config
while IFS=$'\t' read -r name uri; do
    start_plugin "$name" "$uri"
done < <("$JQ" -r 'keys_unsorted[] as $k | "\($k)\t\(.[$k].uri)"' "$CONFIG_FILE")

link_static &
link_chains &
