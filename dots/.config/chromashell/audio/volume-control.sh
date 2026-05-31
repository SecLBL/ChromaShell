#!/usr/bin/env bash
# ChromaShell — Lautstärkekontrolle für virtuelle PipeWire-Nodes
#
# Usage:  volume-control.sh <bus> <action> [value]
#
# Busse:
#   mixbus       → MixBus.input         (Haupt-Mixing-Bus)
#   mixbus-chat  → MixBusChat.input     (Kommunikations-Bus)
#   cable        → VirtualCable.input   (Virtual Audio Cable)
#
# Actions:
#   set <0-100>   Lautstärke absolut setzen
#   up  [step]    Erhöhen (default: 5)
#   down [step]   Senken  (default: 5)
#   mute          Muten
#   unmute        Unmuten
#   toggle-mute   Mute umschalten
#   get           Aktuelle Lautstärke ausgeben (JSON: {"volume": 80, "muted": false})
#
# Quickshell-Aufruf:
#   Process { command: ["volume-control.sh", "mixbus", "set", "80"] }

set -euo pipefail

declare -A NODE_MAP=(
    ["mixbus"]="MixBus.input"
    ["mixbus-chat"]="MixBusChat.input"
    ["cable"]="VirtualCable.input"
)

BUS="${1:-}"
ACTION="${2:-}"
VALUE="${3:-5}"

if [[ -z "$BUS" || -z "$ACTION" ]]; then
    echo "Usage: $0 <mixbus|mixbus-chat|cable> <set|up|down|mute|unmute|toggle-mute|get> [value]" >&2
    exit 1
fi

NODE="${NODE_MAP[$BUS]:-}"
if [[ -z "$NODE" ]]; then
    echo "Error: Unbekannter Bus '$BUS'" >&2
    exit 1
fi

# Node-ID über PipeWire ermitteln
NODE_ID=$(wpctl status | grep -A1 "Sinks" | grep "$NODE" | awk '{print $1}' | tr -d '.')
# Fallback via pw-dump
if [[ -z "$NODE_ID" ]]; then
    NODE_ID=$(pw-dump | jq -r --arg n "$NODE" '[.[] | select(.info.props["node.name"] == $n)] | .[0].id // empty')
fi

if [[ -z "$NODE_ID" || "$NODE_ID" == "null" ]]; then
    echo "Error: Node '$NODE' nicht gefunden — PipeWire läuft?" >&2
    exit 1
fi

case "$ACTION" in
    set)         wpctl set-volume "$NODE_ID" "${VALUE}%" ;;
    up)          wpctl set-volume "$NODE_ID" "${VALUE}%+" ;;
    down)        wpctl set-volume "$NODE_ID" "${VALUE}%-" ;;
    mute)        wpctl set-mute   "$NODE_ID" 1 ;;
    unmute)      wpctl set-mute   "$NODE_ID" 0 ;;
    toggle-mute) wpctl set-mute   "$NODE_ID" toggle ;;
    get)
        VOL=$(wpctl get-volume "$NODE_ID")
        # Output: "Volume: 0.80" oder "Volume: 0.80 [MUTED]"
        NUM=$(echo "$VOL" | grep -oP '[0-9]+\.[0-9]+')
        MUTED=$(echo "$VOL" | grep -q "MUTED" && echo true || echo false)
        PERCENT=$(echo "$NUM * 100" | bc | cut -d. -f1)
        echo "{\"volume\": $PERCENT, \"muted\": $MUTED}"
        ;;
    *)
        echo "Error: Unbekannte Action '$ACTION'" >&2
        exit 1
        ;;
esac
