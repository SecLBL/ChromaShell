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

    JACK_CLIENT_NAME="$name" "$JALV" "$uri" < "$fifo" &
    echo "Started jalv $name (pid $!) — URI: $uri"
}

# Alle Plugins aus der Config starten
while IFS=$'\t' read -r name uri; do
    start_plugin "$name" "$uri"
done < <("$JQ" -r 'keys_unsorted[] as $k | "\($k)\t\(.[$k].uri)"' "$CONFIG_FILE")
