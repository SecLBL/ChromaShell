#!/usr/bin/env bash
# audio-nr-bypass.sh <plugin: mic-nr|chat-nr> <enable: 1|0>
# Toggles an NR plugin in/out of the signal chain via pw-link routing.
# "Disable" bypasses the plugin by connecting its neighbours directly;
# "Enable" restores the normal routing through the plugin.

set -euo pipefail

PLUGIN="${1:-}"
ENABLE="${2:-}"

[[ -z "$PLUGIN" || -z "$ENABLE" ]] && { echo "Usage: $0 <mic-nr|chat-nr> <1|0>" >&2; exit 1; }

disc() { pw-link -d "$1" "$2" 2>/dev/null || true; }

case "$PLUGIN" in
    mic-nr)
        if [[ "$ENABLE" == "1" ]]; then
            disc "mic-gate:out_l" "mic-comp:in_l"
            disc "mic-gate:out_r" "mic-comp:in_r"
            pw-link "mic-gate:out_l"      "mic-nr:audio_in_1"
            pw-link "mic-gate:out_r"      "mic-nr:audio_in_2"
            pw-link "mic-nr:audio_out_1"  "mic-comp:in_l"
            pw-link "mic-nr:audio_out_2"  "mic-comp:in_r"
        else
            disc "mic-gate:out_l"     "mic-nr:audio_in_1"
            disc "mic-gate:out_r"     "mic-nr:audio_in_2"
            disc "mic-nr:audio_out_1" "mic-comp:in_l"
            disc "mic-nr:audio_out_2" "mic-comp:in_r"
            pw-link "mic-gate:out_l" "mic-comp:in_l"
            pw-link "mic-gate:out_r" "mic-comp:in_r"
        fi
        ;;
    chat-nr)
        if [[ "$ENABLE" == "1" ]]; then
            disc "chat_chain_internal_out:capture_FL" "chat-comp:in_l"
            disc "chat_chain_internal_out:capture_FR" "chat-comp:in_r"
            pw-link "chat_chain_internal_out:capture_FL" "chat-nr:audio_in_1"
            pw-link "chat_chain_internal_out:capture_FR" "chat-nr:audio_in_2"
            pw-link "chat-nr:audio_out_1"               "chat-comp:in_l"
            pw-link "chat-nr:audio_out_2"               "chat-comp:in_r"
        else
            disc "chat_chain_internal_out:capture_FL" "chat-nr:audio_in_1"
            disc "chat_chain_internal_out:capture_FR" "chat-nr:audio_in_2"
            disc "chat-nr:audio_out_1"                "chat-comp:in_l"
            disc "chat-nr:audio_out_2"                "chat-comp:in_r"
            pw-link "chat_chain_internal_out:capture_FL" "chat-comp:in_l"
            pw-link "chat_chain_internal_out:capture_FR" "chat-comp:in_r"
        fi
        ;;
    *)
        echo "Unknown plugin '$PLUGIN' (expected: mic-nr|chat-nr)" >&2
        exit 1
        ;;
esac
