pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var _data: ({})
    readonly property bool light: false

    function _c(key, fallback) {
        return root._data[key] || fallback;
    }

    function layer(color, elevation) {
        const opacity = [0, 0.05, 0.08, 0.11, 0.12, 0.14][Math.min(elevation, 5)];
        return Qt.rgba(
            Math.min(color.r + (1 - color.r) * opacity, 1),
            Math.min(color.g + (1 - color.g) * opacity, 1),
            Math.min(color.b + (1 - color.b) * opacity, 1),
            color.a
        );
    }

    readonly property QtObject palette: QtObject {
        readonly property color m3primary:                 root._c("blue",     "#89b4fa")
        readonly property color m3onPrimary:               root._c("base",     "#1e1e2e")
        readonly property color m3primaryContainer:        root._c("surface1", "#45475a")
        readonly property color m3onPrimaryContainer:      root._c("blue",     "#89b4fa")
        readonly property color m3secondary:               root._c("mauve",    "#cba4f7")
        readonly property color m3onSecondary:             root._c("base",     "#1e1e2e")
        readonly property color m3tertiary:                root._c("sky",      "#89dceb")
        readonly property color m3onTertiary:              root._c("base",     "#1e1e2e")
        readonly property color m3surface:                 root._c("base",     "#1e1e2e")
        readonly property color m3onSurface:               root._c("text",     "#cdd6f4")
        readonly property color m3surfaceVariant:          root._c("surface0", "#313244")
        readonly property color m3onSurfaceVariant:        root._c("subtext1", "#bac2de")
        readonly property color m3surfaceContainer:        root._c("surface0", "#313244")
        readonly property color m3surfaceContainerLow:     root._c("mantle",   "#181825")
        readonly property color m3surfaceContainerHigh:    root._c("surface1", "#45475a")
        readonly property color m3surfaceContainerHighest: root._c("surface2", "#585b70")
        readonly property color m3outline:                 root._c("overlay1", "#7f849c")
        readonly property color m3outlineVariant:          root._c("overlay0", "#6c7086")
        readonly property color m3error:                   root._c("red",      "#f38ba8")
        readonly property color m3onError:                 root._c("base",     "#1e1e2e")
        readonly property color m3scrim:                   root._c("crust",    "#11111b")
        readonly property color m3shadow:                  root._c("crust",    "#11111b")
    }

    FileView {
        id: colorFile
        path: "/tmp/qs_colors.json"
        watchChanges: true
        onTextChanged: {
            try {
                root._data = JSON.parse(colorFile.text);
            } catch(e) {}
        }
    }
}
