import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.services

Rectangle {
    id: root

    required property int wsId
    required property int activeWsId

    readonly property bool isActive: wsId === activeWsId

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: isActive ? 18 : 10
    implicitHeight: isActive ? 18 : 10
    radius: 9999
    color: isActive ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 200 } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch(`workspace ${root.wsId}`)
    }
}
