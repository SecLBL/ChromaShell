import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property string side  // "top" | "right" | "bottom"
    property  int    thickness: 6

    color: "transparent"
    WlrLayershell.namespace: "chromashell-edge"
    WlrLayershell.layer:     WlrLayer.Top

    anchors.top:    side !== "bottom"
    anchors.right:  true
    anchors.bottom: side !== "top"
    anchors.left:   side !== "right"

    implicitWidth:  side === "right" ? thickness : 0
    implicitHeight: side !== "right" ? thickness : 0

    exclusiveZone: thickness

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            MatugenColors.surface0.r,
            MatugenColors.surface0.g,
            MatugenColors.surface0.b,
            0.88
        )
    }
}
