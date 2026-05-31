#!/usr/bin/env bash
# ChromaShell — setzt einen LV2-Parameter live UND persistiert ihn
#
# Usage:
#   audio-param.sh <plugin> <symbol> <value>      # set & save
#   audio-param.sh --get <plugin> <symbol>        # show current value
#   audio-param.sh --list <plugin>                # show all params of plugin
#   audio-param.sh --reset <plugin>               # reset plugin to defaults
#   audio-param.sh --reset-all                    # reset whole config
#
# Plugins:  mic-gate | mic-nr | mic-comp | chat-nr | chat-comp
#
# Quickshell-Aufruf:
#   Process { command: ["audio-param.sh", "mic-comp", "cr", "4.0"] }
#
# ── mic-gate (LSP Gate Stereo) ──────────────────────────────────────────────
#
#   Core
#   gt   Curve threshold     linear  Level above which gate opens   (0.001–1.0)
#   gz   Curve zone size     linear  Transition width below gt      (0.001–1.0)
#   gr   Reduction floor     linear  Attenuation when gate is shut  (0.000251–1.0)
#   mk   Makeup gain         linear  Output gain after gating       (0.001–1000)
#   at   Attack time         ms      Time to open                   (0–2000)
#   rt   Release time        ms      Time to close                  (0–5000)
#   hold Hold time           ms      Minimum time gate stays open   (0–1000)
#
#   Hysteresis (only active when gh=1)
#   gh   Hysteresis enable   0/1     Enable hysteresis mode
#   ht   Hyst. threshold     linear  Level at which gate closes     (0.001–1.0)
#   hz   Hyst. zone size     linear  Transition width for closing   (0.001–1.0)
#
#   Gain & Mix
#   g_in  Input gain         linear  Pre-gain before processing     (0–1000)
#   g_out Output gain        linear  Post-gain after processing     (0–1000)
#   cdr   Dry gain           linear  Direct (unprocessed) signal    (0–10)
#   cwt   Wet gain           linear  Processed signal level         (0–10)
#   cdw   Dry/Wet balance    %       100 = fully wet                (0–100)
#
#   Sidechain
#   scm  SC mode             0–3     0=Peak,1=RMS,2=LPF,3=MidSide
#   sla  SC lookahead        ms      Lookahead window               (0–20)
#   scr  SC reactivity       ms      RMS window size                (0–250)
#   scp  SC preamp           linear  Sidechain pre-amplification    (0–100)
#
#   Sidechain filters (for frequency-selective keying)
#   shpm HP filter mode      0–3     0=off,1=6dB,2=12dB,3=18dB/oct
#   shpf HP frequency        Hz      High-pass cutoff frequency     (10–20000)
#   slpm LP filter mode      0–3     0=off,1=6dB,2=12dB,3=18dB/oct
#   slpf LP frequency        Hz      Low-pass cutoff frequency      (10–20000)
#
# ── mic-nr / chat-nr (RNNoise — werman noise-suppression-for-voice) ─────────
#
#   Note: RNNoise uses the LV2 Patch/Atom protocol, not control ports.
#   Parameters cannot be set via this script.
#   Plugin defaults (VAD Threshold 0.6, Grace Period 20ms) are used automatically.
#
# ── mic-comp / chat-comp (LSP Compressor Stereo) ────────────────────────────
#
#   Core
#   cm   Compression mode   0–2     0=Downward,1=Upward,2=Both
#   al   Attack threshold   linear  Level above which compression starts  (0.001–1.0)
#   at   Attack time        ms      Time to reach full compression        (0–2000)
#   rrl  Release threshold  linear  Level below which comp releases       (0–1.0, 0=same as al)
#   rt   Release time       ms      Time to release compression           (0–5000)
#   hold Hold time          ms      Minimum compression hold time         (0–1000)
#   cr   Ratio              x:1     Compression ratio                     (1–100)
#   kn   Knee               linear  Soft-knee curve width                 (0.063–1.0)
#   mk   Makeup gain        linear  Output gain after compression         (0.001–1000)
#
#   Gain & Mix
#   g_in  Input gain        linear  Pre-gain before processing     (0–1000)
#   g_out Output gain       linear  Post-gain after processing     (0–1000)
#   cdr   Dry gain          linear  Direct (unprocessed) signal    (0–10)
#   cwt   Wet gain          linear  Processed signal level         (0–10)
#   cdw   Dry/Wet balance   %       100 = fully wet                (0–100)
#
#   Sidechain
#   scm  SC mode            0–3     0=Peak,1=RMS,2=LPF,3=MidSide
#   sla  SC lookahead       ms      Lookahead window               (0–20)
#   scr  SC reactivity      ms      RMS window size                (0–250)
#   scp  SC preamp          linear  Sidechain pre-amplification    (0–100)
#
#   All linear gain values: linear = 10^(dB/20)  e.g. -20dB → 0.1, +6dB → 2.0

set -euo pipefail

JQ="$(command -v jq)"
if [[ -z "$JQ" ]]; then
    echo "Error: jq nicht im PATH" >&2
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chromashell/audio/runtime"
CONFIG_FILE="$CONFIG_DIR/audio.json"
DEFAULT_CONFIG="${CHROMASHELL_DEFAULT_CONFIG:-$(dirname "$(readlink -f "$0")")/audio.json.default}"

usage() {
    awk '/^set -euo pipefail/{exit} NR>=3{sub(/^# ?/,""); print}' "$(readlink -f "$0")"
    exit "${1:-1}"
}

require_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: $CONFIG_FILE existiert nicht — start-jalv.sh erst laufen lassen" >&2
        exit 1
    fi
}

# Atomic JSON-Update: in tmp schreiben, dann mv (verhindert Korruption bei Race)
update_config() {
    local tmp
    tmp="$(mktemp "${CONFIG_FILE}.XXXXXX")"
    if "$JQ" "$1" "$CONFIG_FILE" > "$tmp"; then
        mv "$tmp" "$CONFIG_FILE"
    else
        rm -f "$tmp"
        echo "Error: jq-Update fehlgeschlagen" >&2
        exit 1
    fi
}

# ── Subcommands ────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    usage
fi

case "${1:-}" in
    -h|--help)
        usage 0
        ;;

    --get)
        require_config
        [[ $# -ne 3 ]] && { echo "Usage: $0 --get <plugin> <symbol>" >&2; exit 1; }
        "$JQ" -r --arg p "$2" --arg s "$3" '.[$p].params[$s] // "null"' "$CONFIG_FILE"
        ;;

    --list)
        require_config
        [[ $# -ne 2 ]] && { echo "Usage: $0 --list <plugin>" >&2; exit 1; }
        "$JQ" -r --arg p "$2" '.[$p].params | to_entries[] | "\(.key) = \(.value)"' "$CONFIG_FILE"
        ;;

    --reset)
        [[ $# -ne 2 ]] && { echo "Usage: $0 --reset <plugin>" >&2; exit 1; }
        [[ ! -f "$DEFAULT_CONFIG" ]] && { echo "Error: Default-Config fehlt: $DEFAULT_CONFIG" >&2; exit 1; }
        PLUGIN="$2"
        FIFO="/tmp/jalv-${PLUGIN}"

        default_params="$("$JQ" --arg p "$PLUGIN" '.[$p].params' "$DEFAULT_CONFIG")"
        if [[ "$default_params" == "null" ]]; then
            echo "Error: Plugin '$PLUGIN' nicht in Default-Config" >&2
            exit 1
        fi
        update_config ".\"$PLUGIN\".params = $default_params"

        if [[ -p "$FIFO" ]]; then
            "$JQ" -r --arg p "$PLUGIN" '.[$p].params | to_entries[] | "set \(.key) \(.value)"' "$CONFIG_FILE" \
                > "$FIFO"
            echo "Plugin '$PLUGIN' auf Defaults zurückgesetzt (Live + persistent)"
        else
            echo "Plugin '$PLUGIN' persistent zurückgesetzt — FIFO fehlt, Live-Update übersprungen"
        fi
        ;;

    --reset-all)
        [[ ! -f "$DEFAULT_CONFIG" ]] && { echo "Error: Default-Config fehlt: $DEFAULT_CONFIG" >&2; exit 1; }
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        echo "Komplette Config zurückgesetzt — Plugins für Reload neu starten"
        ;;

    --*)
        echo "Unbekannte Option: $1" >&2
        usage
        ;;

    *)
        # Standard-Aufruf: <plugin> <symbol> <value>
        [[ $# -ne 3 ]] && usage

        PLUGIN="$1"
        SYMBOL="$2"
        VALUE="$3"
        FIFO="/tmp/jalv-${PLUGIN}"

        require_config

        if [[ "$("$JQ" -r --arg p "$PLUGIN" '.[$p] // "null"' "$CONFIG_FILE")" == "null" ]]; then
            echo "Error: Plugin '$PLUGIN' nicht in Config" >&2
            exit 1
        fi

        if ! [[ "$VALUE" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo "Error: Wert '$VALUE' ist nicht numerisch" >&2
            exit 1
        fi

        update_config ".\"$PLUGIN\".params.\"$SYMBOL\" = $VALUE"

        if [[ -p "$FIFO" ]]; then
            echo "set ${SYMBOL} ${VALUE}" > "$FIFO"
            echo "$PLUGIN.$SYMBOL = $VALUE  (live + persistent)"
        else
            echo "$PLUGIN.$SYMBOL = $VALUE  (nur persistent — FIFO $FIFO fehlt)"
        fi
        ;;
esac
