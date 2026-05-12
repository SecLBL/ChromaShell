#!/usr/bin/env bash
# ChromaShell — setzt einen LV2-Parameter live via jalv stdin FIFO
#
# Usage:  audio-param.sh <plugin> <symbol> <value>
#
# Plugins:
#   mic-gate | mic-nr | mic-comp | chat-nr | chat-comp
#
# Symbole mic-gate (LSP Gate Stereo):
#   gt   = Threshold        (linear, 0.00988 ≈ -40 dBFS)
#   at   = Attack  (ms)
#   rt   = Release (ms)
#   hold = Hold    (ms)
#   gr   = Reduction ratio  (0.0631 ≈ -24 dB floor)
#
# Symbole mic-comp / chat-comp (LSP Compressor Stereo):
#   al   = Threshold        (linear, 0.0973 ≈ -20 dBFS)
#   at   = Attack  (ms)
#   rt   = Release (ms)
#   hold = Hold    (ms)
#   cr   = Compression ratio
#   kn   = Knee width
#   g_in = Input gain  (dB)
#   g_out= Output gain (dB)
#
# Symbole mic-nr / chat-nr (noise-repellent adaptive):
#   nres = Noise reduction amount (0.0 – 1.0)
#
# Quickshell-Aufruf:
#   Process { command: ["audio-param.sh", "mic-comp", "cr", "4.0"] }

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <plugin> <symbol> <value>" >&2
    exit 1
fi

PLUGIN="$1"
SYMBOL="$2"
VALUE="$3"
FIFO="/tmp/jalv-${PLUGIN}"

if [[ ! -p "$FIFO" ]]; then
    echo "Error: $FIFO nicht gefunden — start-jalv.sh gelaufen?" >&2
    exit 1
fi

echo "set ${SYMBOL} ${VALUE}" > "$FIFO"
