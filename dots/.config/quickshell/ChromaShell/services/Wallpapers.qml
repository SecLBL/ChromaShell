pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string current: ""
    property bool showPreview: false

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_picker/current_wallpaper"
        watchChanges: true
        onTextChanged: root.current = text.trim()
    }

    function setWallpaper(path) {
        const esc = String(path).replace(/(["\\$`])/g, '\\$1')
        Quickshell.execDetached(["bash", "-c",
            `awww img "${esc}" --transition-type fade --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1`])
        Quickshell.execDetached(["bash", "-c",
            `mkdir -p "$HOME/.cache/quickshell/wallpaper_picker" && echo "${esc}" > "$HOME/.cache/quickshell/wallpaper_picker/current_wallpaper"`])
    }
}
