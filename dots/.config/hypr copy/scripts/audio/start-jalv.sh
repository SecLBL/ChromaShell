#!/usr/bin/env bash
# ChromaShell — startet alle jalv LV2-Plugin-Instanzen
# Jede Instanz bekommt ein FIFO unter /tmp/jalv-<name> für live Parametersteuerung
# Wird von autostart.conf via exec-once aufgerufen

JALV=$(which jalv)

start_plugin() {
    local name="$1"
    local uri="$2"
    shift 2
    local init_params=("$@")

    local fifo="/tmp/jalv-${name}"
    mkfifo "$fifo" 2>/dev/null || true

    # Hält write-end offen → jalv bekommt nie EOF
    # Initial-Parameter werden nach 3s gesetzt (jalv braucht Zeit zum Starten)
    (
        exec 3>"$fifo"
        if [[ ${#init_params[@]} -gt 0 ]]; then
            sleep 3
            for param in "${init_params[@]}"; do
                echo "$param" > "$fifo"
            done
        fi
        while true; do sleep 3600; done
    ) &

    JACK_CLIENT_NAME="$name" "$JALV" "$uri" < "$fifo" &
    echo "Started jalv $name (pid $!)"
}

# ── Mic Chain: gate → noise-repellent → compressor ─────────────────────────
start_plugin "mic-gate" "http://lsp-plug.in/plugins/lv2/gate_stereo" \
    "set gt 0.00988" \
    "set at 2.924" \
    "set rt 100" \
    "set hold 170.5" \
    "set gr 0.0631"

start_plugin "mic-nr" "https://github.com/lucianodato/noise-repellent#adaptive-stereo"

start_plugin "mic-comp" "http://lsp-plug.in/plugins/lv2/compressor_stereo" \
    "set al 0.0973" \
    "set at 10.08" \
    "set rt 131.57" \
    "set hold 14" \
    "set cr 3.536" \
    "set kn 0.552"

# ── Chat Chain: noise-repellent → compressor ────────────────────────────────
start_plugin "chat-nr" "https://github.com/lucianodato/noise-repellent#adaptive-stereo"

start_plugin "chat-comp" "http://lsp-plug.in/plugins/lv2/compressor_stereo" \
    "set al 0.0973" \
    "set at 10.08" \
    "set rt 131.57" \
    "set hold 14" \
    "set cr 3.536" \
    "set kn 0.552"
