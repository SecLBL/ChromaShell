#!/usr/bin/env bash
# audio-route.sh <bus> <new-device-name> [old-device-name]
# Connects a physical PipeWire device to a ChromaShell bus via pw-link.
# bus: general | chat | mic
#   general — MixBus.output  → device playback ports
#   chat    — MixBusChat.output → device playback ports
#   mic     — device capture ports → mic_chain_in playback ports

set -euo pipefail

BUS="$1"
DEVICE="$2"
OLD="${3:-}"

disc() { pw-link -d "$1" "$2" 2>/dev/null || true; }
conn() { pw-link    "$1" "$2" 2>/dev/null || true; }

case "$BUS" in
    general)
        if [[ -n "$OLD" ]]; then
            disc "general_chain_out:capture_FL" "${OLD}:playback_FL"
            disc "general_chain_out:capture_FR" "${OLD}:playback_FR"
        fi
        conn "general_chain_out:capture_FL" "${DEVICE}:playback_FL"
        conn "general_chain_out:capture_FR" "${DEVICE}:playback_FR"
        ;;
    chat)
        if [[ -n "$OLD" ]]; then
            disc "chat_chain_out:capture_FL" "${OLD}:playback_FL"
            disc "chat_chain_out:capture_FR" "${OLD}:playback_FR"
        fi
        conn "chat_chain_out:capture_FL" "${DEVICE}:playback_FL"
        conn "chat_chain_out:capture_FR" "${DEVICE}:playback_FR"
        ;;
    mic)
        if [[ -n "$OLD" ]]; then
            disc "${OLD}:capture_FL" "mic_chain_in:playback_FL"
            disc "${OLD}:capture_FR" "mic_chain_in:playback_FR"
        fi
        conn "${DEVICE}:capture_FL" "mic_chain_in:playback_FL"
        conn "${DEVICE}:capture_FR" "mic_chain_in:playback_FR"
        ;;
    *)
        echo "audio-route.sh: unknown bus '${BUS}' (expected: general|chat|mic)" >&2
        exit 1
        ;;
esac

# Persist the selection so it survives reboots
ROUTING_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/audio/runtime/routing.json"
mkdir -p "$(dirname "$ROUTING_FILE")"
existing=$(cat "$ROUTING_FILE" 2>/dev/null || echo '{}')
printf '%s' "$existing" \
    | jq --arg bus "$BUS" --arg dev "$DEVICE" '.[$bus] = $dev' \
    > "${ROUTING_FILE}.tmp" \
    && mv "${ROUTING_FILE}.tmp" "$ROUTING_FILE"
