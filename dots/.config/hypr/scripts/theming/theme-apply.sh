#!/usr/bin/env bash
# ChromaShell — unified Theme-Apply Script
# Wird von WallpaperPicker.qml und ThemingPopup.qml aufgerufen
#
# Usage:
#   theme-apply.sh matugen <wallpaper-path>
#   theme-apply.sh pywal   <wallpaper-path>
#
# Beide Modi:
#   1. Wallpaper via swww setzen
#   2. Farben generieren (matugen oder wal)
#   3. Outputs in gemeinsame Pfade schreiben:
#        /tmp/qs_colors.json          → MatugenColors.qml (live)
#        ~/.cache/matugen/colors-gtk.css → GTK3/4 @import
#        /tmp/kitty-chromashell-colors.conf → Kitty include
#   4. matugen-reload.sh aufrufen (kitty, swayosd, GTK flush)

set -euo pipefail

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
RELOAD="${SCRIPTS_DIR}/../matugen-reload.sh"
PYWAL_TO_QS="${SCRIPTS_DIR}/pywal-to-qs.sh"

MODE="${1:-}"
WALLPAPER="${2:-}"

if [[ -z "$MODE" || -z "$WALLPAPER" ]]; then
    echo "Usage: $0 <matugen|pywal> <wallpaper-path>" >&2
    exit 1
fi

if [[ ! -f "$WALLPAPER" ]]; then
    echo "Error: Wallpaper nicht gefunden: $WALLPAPER" >&2
    exit 1
fi

# Wallpaper setzen
TRANSITION=$(shuf -n1 -e simple fade left right top bottom wipe grow center outer wave)
swww img "$WALLPAPER" \
    --transition-type "$TRANSITION" \
    --transition-pos 0.5,0.5 \
    --transition-fps 144 \
    --transition-duration 1 &

mkdir -p ~/.cache/matugen

case "$MODE" in
    matugen)
        matugen image "$WALLPAPER"
        ;;
    pywal)
        # -n = skip wallpaper (swww handles it), templates in ~/.config/wal/templates/ are applied automatically
        wal -i "$WALLPAPER" -n -q
        bash "$PYWAL_TO_QS"
        ;;
    *)
        echo "Error: Unbekannter Modus '$MODE' — matugen oder pywal" >&2
        exit 1
        ;;
esac

bash "$RELOAD"
