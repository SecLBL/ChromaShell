pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData

        anchors.top: true
        anchors.bottom: true
        anchors.left: true

        exclusiveZone: barWrapper.implicitWidth
        color: "transparent"

        BarWrapper {
            id: barWrapper
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            screen: modelData
        }
    }
}
