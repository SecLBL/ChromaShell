// ChromaShell — Theming Control Popup
//
// Funktionen (geplant):
//   - Theming-Backend wählen: Matugen | Pywal
//   - Wallpaper-Picker öffnen (WallpaperPicker.qml)
//   - Manuell Theme neu generieren
//
// Matugen-Flow:
//   matugen image <wallpaper> → matugen-reload.sh
//
// Pywal-Flow:
//   wal -i <wallpaper> → pywal-to-qs.sh → /tmp/qs_colors.json → matugen-reload.sh
//   (pywal-to-qs.sh konvertiert ~/.cache/wal/colors.json ins Quickshell-Format)
//
// Beide Flows schreiben am Ende nach /tmp/qs_colors.json
// → MatugenColors.qml picked es automatisch auf

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    // TODO
}
