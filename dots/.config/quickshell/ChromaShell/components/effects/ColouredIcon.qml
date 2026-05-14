pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

IconImage {
    id: root

    required property color colour

    asynchronous: true

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: root.colour
        colorizationColor: root.colour
    }
}
