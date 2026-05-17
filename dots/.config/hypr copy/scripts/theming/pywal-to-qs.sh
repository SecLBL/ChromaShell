#!/usr/bin/env bash
# ChromaShell — konvertiert ~/.cache/wal/colors.json → /tmp/qs_colors.json
# Damit MatugenColors.qml pywal-Farben genau so einliest wie Matugen-Farben.
#
# Pywal color mapping:
#   color0  = dunkelster Hintergrund  → base, mantle, crust
#   color1  = Akzent 1 (meist rot)   → red, maroon
#   color2  = Akzent 2 (meist grün)  → green, teal
#   color3  = Akzent 3 (meist gelb)  → yellow, peach
#   color4  = Akzent 4 (meist blau)  → blue, sapphire
#   color5  = Akzent 5 (meist lila)  → mauve, pink
#   color6  = Akzent 6 (meist cyan)  → teal (überschreibt grün-teal)
#   color7  = heller Text            → text, subtext0, subtext1
#   color8  = dunkle Surface         → surface0, surface1, surface2
#   color15 = hellster Text          → overlay2

set -euo pipefail

WAL_COLORS="${HOME}/.cache/wal/colors.json"
OUTPUT="/tmp/qs_colors.json"

if [[ ! -f "$WAL_COLORS" ]]; then
    echo "Error: $WAL_COLORS nicht gefunden — wal -i <wallpaper> ausgeführt?" >&2
    exit 1
fi

python3 - <<EOF
import json, sys

with open("${WAL_COLORS}") as f:
    wal = json.load(f)

c = wal["colors"]
s = wal["special"]

out = {
    "base":     c["color0"],
    "mantle":   c["color0"],
    "crust":    c["color0"],
    "text":     c["color7"],
    "subtext0": c["color7"],
    "subtext1": c["color7"],
    "surface0": c["color8"],
    "surface1": c["color8"],
    "surface2": c["color8"],
    "overlay0": c["color15"],
    "overlay1": c["color15"],
    "overlay2": c["color15"],
    "blue":     c["color4"],
    "sapphire": c["color4"],
    "peach":    c["color3"],
    "green":    c["color2"],
    "red":      c["color1"],
    "mauve":    c["color5"],
    "pink":     c["color5"],
    "yellow":   c["color3"],
    "maroon":   c["color1"],
    "teal":     c["color6"],
}

with open("${OUTPUT}", "w") as f:
    json.dump(out, f, indent=2)

print(f"Written {len(out)} colors to ${OUTPUT}")
EOF
