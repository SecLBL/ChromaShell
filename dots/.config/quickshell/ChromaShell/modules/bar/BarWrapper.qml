import QtQuick
import Quickshell

Item {
    id: root

    required property ShellScreen screen

    readonly property int barInnerWidth: 44
    readonly property int sidePadding: 8
    readonly property int contentWidth: barInnerWidth + sidePadding * 2

    clip: true
    implicitWidth: contentWidth

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Bar {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.contentWidth
        screen: root.screen
    }
}
