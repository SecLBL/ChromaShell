#!/usr/bin/env bash
# ChromaShell — hosts the audio chains (chains.conf) in an own PipeWire
# client instance and wires them into the graph.
#
# Reads current plugin parameters from:
#   $XDG_CONFIG_HOME/chromashell/audio/runtime/audio.json   (single source of truth)
# If the config is missing it is created from audio.json.default.
#
# Runs as a Type=simple systemd service (chromashell-audio.service). The
# pipewire child carries the filter-chains; if it dies this script exits
# with code 1 and systemd restarts the whole thing.
#
# Log: /tmp/chromashell-audio.log

set -euo pipefail
exec >> /tmp/chromashell-audio.log 2>&1
echo "=== start-audio.sh $(date) ==="

JQ="$(command -v jq)"
PIPEWIRE="$(command -v pipewire)"

if [[ -z "$PIPEWIRE" ]]; then
    echo "Error: pipewire not in PATH" >&2
    exit 1
fi
if [[ -z "$JQ" ]]; then
    echo "Error: jq not in PATH" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/audio/runtime"
CONFIG_FILE="$CONFIG_DIR/audio.json"
DEFAULT_CONFIG="${CHROMASHELL_DEFAULT_CONFIG:-$SCRIPT_DIR/audio.json.default}"
CHAINS_CONF="$SCRIPT_DIR/chains.conf"

if [[ ! -f "$CHAINS_CONF" ]]; then
    echo "Error: $CHAINS_CONF not found" >&2
    exit 1
fi

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

# Fill in plugins/params added by newer defaults; saved values always win.
if [[ -f "$DEFAULT_CONFIG" ]]; then
    merged="$(mktemp "${CONFIG_FILE}.XXXXXX")"
    if "$JQ" -s '.[0] * .[1]' "$DEFAULT_CONFIG" "$CONFIG_FILE" > "$merged"; then
        mv "$merged" "$CONFIG_FILE"
    else
        rm -f "$merged"
        echo "Warning: could not merge new defaults into $CONFIG_FILE"
    fi
fi

# ── Start the chains instance ───────────────────────────────────────────────

"$PIPEWIRE" -c "$CHAINS_CONF" &
PW_PID=$!

cleanup() {
    echo "Stopping chains instance (pid $PW_PID)..."
    kill "$PW_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "Chains instance started (pid $PW_PID) — config: $CHAINS_CONF"

# ── Wiring ──────────────────────────────────────────────────────────────────

wait_node_out() {
    local node="$1" timeout="${2:-40}"
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
    wait_node_out "chat_chain_out"    || return 1
    wait_node_out "general_chain_out" || return 1
    wait_node_out "MixBusChat.output" || return 1
    wait_node_out "MixBus.output"     || return 1

    # Passive links: they carry audio but do not keep the chains awake, so an
    # unused chain suspends until a real client (player/recorder) activates it.
    pw-link -P "mic_chain_out:capture_FL"     "VirtualCable.input:playback_FL" || true
    pw-link -P "mic_chain_out:capture_FR"     "VirtualCable.input:playback_FR" || true
    pw-link -P "MixBusChat.output:capture_FL" "chat_chain_in:playback_FL"      || true
    pw-link -P "MixBusChat.output:capture_FR" "chat_chain_in:playback_FR"      || true
    pw-link -P "MixBus.output:capture_FL"     "general_chain_in:playback_FL"   || true
    pw-link -P "MixBus.output:capture_FR"     "general_chain_in:playback_FR"   || true

    echo "Static routes linked."
}

link_devices() {
    local routing="${CONFIG_DIR}/routing.json"
    [[ -f "$routing" ]] || return 0

    local general chat mic
    general=$("$JQ" -r '.general // ""' "$routing")
    chat=$("$JQ"    -r '.chat    // ""' "$routing")
    mic=$("$JQ"     -r '.mic     // ""' "$routing")

    local script="$SCRIPT_DIR/audio-route.sh"

    if [[ -n "$general" ]]; then
        bash "$script" general "$general" "" \
            || echo "Warning: could not restore general routing to '$general'"
    fi
    if [[ -n "$chat" ]]; then
        bash "$script" chat "$chat" "" \
            || echo "Warning: could not restore chat routing to '$chat'"
    fi
    if [[ -n "$mic" ]]; then
        pw-link -i 2>/dev/null | grep -q "^mic_chain_in:" \
            && bash "$script" mic "$mic" "" \
            || echo "Warning: could not restore mic routing to '$mic'"
    fi
    echo "Device routing restored from $routing"
}

apply_params() {
    # Nodes are linked and running at this point, so pw-cli set-param applies.
    bash "$SCRIPT_DIR/audio-param.sh" --apply-all \
        && echo "Plugin parameters applied from audio.json" \
        || echo "Warning: could not apply all plugin parameters"
}

( link_static && link_devices && apply_params ) &

# ── Monitor ─────────────────────────────────────────────────────────────────

echo "Monitoring chains instance..."
if wait "$PW_PID"; then
    echo "Chains instance exited cleanly — stopping service"
    exit 0
else
    echo "Chains instance died — triggering service restart"
    exit 1
fi
