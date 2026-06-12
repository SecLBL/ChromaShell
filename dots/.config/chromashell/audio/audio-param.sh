#!/usr/bin/env bash
# ChromaShell — sets a plugin parameter live AND persists it
#
# Usage:
#   audio-param.sh <plugin> <symbol> <value>      # set & save
#   audio-param.sh --get <plugin> <symbol>        # show current value
#   audio-param.sh --list <plugin>                # show all params of plugin
#   audio-param.sh --apply <plugin>               # re-apply saved params live
#   audio-param.sh --apply-all                    # re-apply everything live
#   audio-param.sh --reset <plugin>               # reset plugin to defaults
#   audio-param.sh --reset-all                    # reset whole config
#
# Plugins:  mic-gate | mic-nr | mic-comp | chat-nr | chat-comp | general-eq
#
# Backend: all plugins run inside native PipeWire filter-chain graphs
# (chains.conf, hosted by chromashell-audio.service). Live updates go through
# `pw-cli set-param <node> Props { params = [ "<filter>:<control>" <value> ] }`.
# Values are always persisted in audio.json first; the live update only takes
# effect while the chain node is running. Suspended chains (demand-suspend)
# are woken briefly with a burst of silence before applying; if that fails,
# start-audio.sh re-applies everything after the next service start anyway.
#
# Plugin -> chain node / filter name:
#   mic-gate    mic_chain_in      gate:   (LSP Gate Stereo, LV2 symbols)
#   mic-nr      mic_chain_in      nr:     (DeepFilterNet, LADSPA controls)
#   mic-comp    mic_chain_in      comp:   (LSP Compressor Stereo)
#   chat-nr     chat_chain_in     nr:
#   chat-comp   chat_chain_in     comp:
#   general-eq  general_chain_in  eq:     (fil4 Parametric EQ)
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
# ── mic-nr / chat-nr (DeepFilterNet — deep learning noise suppression) ──────
#
#   enabled          0/1   Virtual toggle: applies attenuation or 0 dB live
#   attenuation      dB    Max noise attenuation, 0 = transparent  (0–100)
#   postfilter_beta  —     Post filter strength                    (0–0.05)
#   min_db           dB    Min processing threshold                (-15–35)
#   max_erb_db       dB    Max ERB processing threshold            (-15–35)
#   max_df_db        dB    Max DF processing threshold             (-15–35)
#   min_buffer       fr    Min processing buffer (frames)          (0–10)
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
#
# ── general-eq (fil4 Parametric EQ Stereo — x42-plugins) ───────────────────
#
#   Master
#   enable   EQ bypass        0/1      0 = EQ bypassed (disabled)        (0–1, default 1)
#   gain     Master gain      dB       Global output gain                 (-18–+18, default 0)
#
#   HP filter (2nd-order Butterworth highpass)
#   HighPass HP enable        0/1      Enable highpass filter             (default 0)
#   HPfreq   HP frequency     Hz       Highpass cutoff                    (5–1250, log)
#   HPQ      HP resonance     —        0=no res, 0.7=flat, 1.4=resonant  (0–1.4)
#
#   Low shelf
#   LSsec    LS enable        0/1      Enable low-shelf filter            (default 1)
#   LSfreq   LS frequency     Hz       Shelf turnover frequency           (25–400, log)
#   LSq      LS bandwidth     oct      Shelf bandwidth                    (0.0625–4)
#   LSgain   LS gain          dB       Shelf boost/cut                    (-18–+18)
#
#   Peaking bands 1–4  (symbols: sec1–4, freq1–4, q1–4, gain1–4)
#   secN     Band N enable    0/1      Enable peaking band N              (default 1)
#   freqN    Band N frequency Hz       Center frequency                   (varies per band, log)
#   qN       Band N bandwidth oct      Bandwidth (higher = narrower)      (0.0625–4)
#   gainN    Band N gain      dB       Boost/cut at center frequency      (-18–+18)
#
#   High shelf
#   HSsec    HS enable        0/1      Enable high-shelf filter           (default 1)
#   HSfreq   HS frequency     Hz       Shelf turnover frequency           (1000–16000, log)
#   HSq      HS bandwidth     oct      Shelf bandwidth                    (0.0625–4)
#   HSgain   HS gain          dB       Shelf boost/cut                    (-18–+18)
#
#   LP filter (2nd-order Butterworth lowpass)
#   LowPass  LP enable        0/1      Enable lowpass filter              (default 0)
#   LPfreq   LP frequency     Hz       Lowpass cutoff                     (500–20000, log)
#   LPQ      LP resonance     —        0=no res, 0.7=flat, 1.4=resonant  (0–1.4)

set -euo pipefail

JQ="$(command -v jq)"
if [[ -z "$JQ" ]]; then
    echo "Error: jq not in PATH" >&2
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
        echo "Error: $CONFIG_FILE does not exist — run start-audio.sh first" >&2
        exit 1
    fi
}

# Atomic JSON update: write to tmp, then mv (prevents corruption on races)
update_config() {
    local tmp
    tmp="$(mktemp "${CONFIG_FILE}.XXXXXX")"
    if "$JQ" "$1" "$CONFIG_FILE" > "$tmp"; then
        mv "$tmp" "$CONFIG_FILE"
    else
        rm -f "$tmp"
        echo "Error: jq update failed" >&2
        exit 1
    fi
}

# ── Plugin -> filter-chain mapping ──────────────────────────────────────────

node_for_plugin() {
    case "$1" in
        mic-gate|mic-nr|mic-comp) echo "mic_chain_in" ;;
        chat-nr|chat-comp)        echo "chat_chain_in" ;;
        general-eq)               echo "general_chain_in" ;;
        *) return 1 ;;
    esac
}

prefix_for_plugin() {
    case "$1" in
        mic-gate)           echo "gate" ;;
        mic-nr|chat-nr)     echo "nr" ;;
        mic-comp|chat-comp) echo "comp" ;;
        general-eq)         echo "eq" ;;
        *) return 1 ;;
    esac
}

is_nr_plugin() {
    [[ "$1" == "mic-nr" || "$1" == "chat-nr" ]]
}

# DeepFilterNet: clean config symbols -> LADSPA control names.
# Prints nothing for the virtual "enabled" symbol (handled separately).
nr_control_name() {
    case "$1" in
        attenuation)     echo "Attenuation Limit (dB)" ;;
        postfilter_beta) echo "Post Filter Beta" ;;
        min_db)          echo "Min processing threshold (dB)" ;;
        max_erb_db)      echo "Max ERB processing threshold (dB)" ;;
        max_df_db)       echo "Max DF processing threshold (dB)" ;;
        min_buffer)      echo "Min Processing Buffer (frames)" ;;
        enabled)         ;;
        *) return 1 ;;
    esac
}

node_id_for() {
    pw-dump 2>/dev/null \
        | "$JQ" -r --arg n "$1" \
            'first(.[] | select(.type=="PipeWire:Interface:Node") | select(.info.props["node.name"]==$n) | .id) // empty'
}

node_state() {
    pw-dump 2>/dev/null \
        | "$JQ" -r --arg id "$1" \
            'first(.[] | select(.id == ($id | tonumber)) | .info.state) // empty'
}

# wake_node <node-name> <node-id>
# pw-cli set-param is a silent no-op on suspended nodes. With demand-suspend
# the chains sleep while unused, so pump a short burst of silence into the
# chain sink — the active stream link resumes the node long enough to apply
# the param, then the chain suspends again on its own.
wake_node() {
    local node="$1" id="$2" tries=0
    [[ "$(node_state "$id")" == "running" ]] && return 0
    head -c 96000 /dev/zero \
        | pw-cat -p --target "$node" --rate 48000 --channels 2 --format s16 - \
        2>/dev/null &
    while (( tries++ < 10 )); do
        [[ "$(node_state "$id")" == "running" ]] && return 0
        sleep 0.1
    done
    return 1
}

# live_set <plugin> <control-name> <value> [<control-name> <value> …]
# Best effort: persistence always wins; a missing node only warns.
live_set() {
    local plugin="$1"; shift
    local node prefix id pod=""
    node="$(node_for_plugin "$plugin")" || return 1
    prefix="$(prefix_for_plugin "$plugin")" || return 1
    id="$(node_id_for "$node")"
    if [[ -z "$id" ]]; then
        echo "Warning: chain node '$node' not found — value persisted only" >&2
        return 0
    fi
    if ! wake_node "$node" "$id"; then
        echo "Warning: chain node '$node' suspended and did not wake — value persisted only" >&2
        return 0
    fi
    while [[ $# -ge 2 ]]; do
        pod+=" \"${prefix}:$1\" $2"
        shift 2
    done
    [[ -z "$pod" ]] && return 0
    pw-cli set-param "$id" Props "{ params = [${pod} ] }" > /dev/null \
        || echo "Warning: pw-cli set-param failed on '$node' — value persisted only" >&2
}

# apply_plugin <plugin> — re-apply all saved params of one plugin live
apply_plugin() {
    local plugin="$1"
    local params
    params="$("$JQ" -c --arg p "$plugin" '.[$p].params // {}' "$CONFIG_FILE")"
    [[ "$params" == "{}" ]] && return 0

    local -a pairs=()
    local sym val
    if is_nr_plugin "$plugin"; then
        local enabled att name
        enabled="$(echo "$params" | "$JQ" -r '.enabled // 1')"
        att="$(echo "$params" | "$JQ" -r '.attenuation // 100')"
        if [[ "${enabled%.*}" == "0" ]]; then
            pairs+=("Attenuation Limit (dB)" "0.0")
        else
            pairs+=("Attenuation Limit (dB)" "$att")
        fi
        while IFS=$'\t' read -r sym val; do
            [[ "$sym" == "enabled" || "$sym" == "attenuation" ]] && continue
            name="$(nr_control_name "$sym" || true)"
            [[ -n "$name" ]] && pairs+=("$name" "$val")
        done < <(echo "$params" | "$JQ" -r 'to_entries[] | "\(.key)\t\(.value)"')
    else
        while IFS=$'\t' read -r sym val; do
            pairs+=("$sym" "$val")
        done < <(echo "$params" | "$JQ" -r 'to_entries[] | "\(.key)\t\(.value)"')
    fi

    [[ ${#pairs[@]} -eq 0 ]] && return 0
    live_set "$plugin" "${pairs[@]}"
    echo "Applied $plugin ($(( ${#pairs[@]} / 2 )) params)"
}

# ── Subcommands ─────────────────────────────────────────────────────────────

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

    --apply)
        require_config
        [[ $# -ne 2 ]] && { echo "Usage: $0 --apply <plugin>" >&2; exit 1; }
        node_for_plugin "$2" > /dev/null || { echo "Error: unknown plugin '$2'" >&2; exit 1; }
        apply_plugin "$2"
        ;;

    --apply-all)
        require_config
        while IFS= read -r plugin; do
            node_for_plugin "$plugin" > /dev/null 2>&1 || continue
            apply_plugin "$plugin"
        done < <("$JQ" -r 'keys_unsorted[]' "$CONFIG_FILE")
        ;;

    --reset)
        [[ $# -ne 2 ]] && { echo "Usage: $0 --reset <plugin>" >&2; exit 1; }
        [[ ! -f "$DEFAULT_CONFIG" ]] && { echo "Error: default config missing: $DEFAULT_CONFIG" >&2; exit 1; }
        require_config
        PLUGIN="$2"

        default_params="$("$JQ" --arg p "$PLUGIN" '.[$p].params' "$DEFAULT_CONFIG")"
        if [[ "$default_params" == "null" ]]; then
            echo "Error: plugin '$PLUGIN' not in default config" >&2
            exit 1
        fi
        update_config ".\"$PLUGIN\".params = $default_params"
        apply_plugin "$PLUGIN"
        echo "Plugin '$PLUGIN' reset to defaults (live + persistent)"
        ;;

    --reset-all)
        [[ ! -f "$DEFAULT_CONFIG" ]] && { echo "Error: default config missing: $DEFAULT_CONFIG" >&2; exit 1; }
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        while IFS= read -r plugin; do
            node_for_plugin "$plugin" > /dev/null 2>&1 || continue
            apply_plugin "$plugin"
        done < <("$JQ" -r 'keys_unsorted[]' "$CONFIG_FILE")
        echo "Whole config reset to defaults (live + persistent)"
        ;;

    --*)
        echo "Unknown option: $1" >&2
        usage
        ;;

    *)
        # Standard call: <plugin> <symbol> <value>
        [[ $# -ne 3 ]] && usage

        PLUGIN="$1"
        SYMBOL="$2"
        VALUE="$3"

        require_config
        node_for_plugin "$PLUGIN" > /dev/null || { echo "Error: unknown plugin '$PLUGIN'" >&2; exit 1; }

        if [[ "$("$JQ" -r --arg p "$PLUGIN" '.[$p] // "null"' "$CONFIG_FILE")" == "null" ]]; then
            echo "Error: plugin '$PLUGIN' not in config" >&2
            exit 1
        fi

        if ! [[ "$VALUE" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo "Error: value '$VALUE' is not numeric" >&2
            exit 1
        fi

        update_config ".\"$PLUGIN\".params.\"$SYMBOL\" = $VALUE"

        if is_nr_plugin "$PLUGIN"; then
            case "$SYMBOL" in
                enabled)
                    att="$("$JQ" -r --arg p "$PLUGIN" '.[$p].params.attenuation // 100' "$CONFIG_FILE")"
                    if [[ "${VALUE%.*}" == "0" ]]; then
                        live_set "$PLUGIN" "Attenuation Limit (dB)" "0.0"
                    else
                        live_set "$PLUGIN" "Attenuation Limit (dB)" "$att"
                    fi
                    ;;
                attenuation)
                    enabled="$("$JQ" -r --arg p "$PLUGIN" '.[$p].params.enabled // 1' "$CONFIG_FILE")"
                    if [[ "${enabled%.*}" != "0" ]]; then
                        live_set "$PLUGIN" "Attenuation Limit (dB)" "$VALUE"
                    fi
                    ;;
                *)
                    name="$(nr_control_name "$SYMBOL" || true)"
                    if [[ -n "$name" ]]; then
                        live_set "$PLUGIN" "$name" "$VALUE"
                    else
                        echo "Warning: unknown NR symbol '$SYMBOL' — persisted only" >&2
                    fi
                    ;;
            esac
        else
            live_set "$PLUGIN" "$SYMBOL" "$VALUE"
        fi

        echo "$PLUGIN.$SYMBOL = $VALUE  (live + persistent)"
        ;;
esac
