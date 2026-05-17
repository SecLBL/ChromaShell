pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData

        anchors.top: true
        anchors.bottom: true
        anchors.left: true

        width: Config.bar.contentWidth
        exclusiveZone: Config.bar.contentWidth
        color: "transparent"

        BarWrapper {
            id: barWrapper
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Config.bar.contentWidth
            screen: modelData
        }
    }
}
