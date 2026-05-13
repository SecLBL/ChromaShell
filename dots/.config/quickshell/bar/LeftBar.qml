import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    color: "transparent"
    WlrLayershell.namespace: "chromashell-bar"
    WlrLayershell.layer:     WlrLayer.Top

    anchors.left:   true
    anchors.top:    true
    anchors.bottom: true

    implicitWidth: 58
    exclusiveZone: implicitWidth

    Rectangle {
        anchors {
            fill:         parent
            topMargin:    6
            bottomMargin: 6
            leftMargin:   5
            rightMargin:  3
        }
        radius: 12
        color: Qt.rgba(
            MatugenColors.surface0.r,
            MatugenColors.surface0.g,
            MatugenColors.surface0.b,
            0.88
        )

        // Widgets go here
    }
}
