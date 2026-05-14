pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services

Rectangle {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1

    implicitWidth: 44
    implicitHeight: wsLayout.implicitHeight + 8

    color: Colours.palette.m3surfaceContainer
    radius: 9999
    clip: true

    ColumnLayout {
        id: wsLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: 10

            Workspace {
                required property int index
                wsId: index + 1
                activeWsId: root.activeWsId
            }
        }
    }
}
