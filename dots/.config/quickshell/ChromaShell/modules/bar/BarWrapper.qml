import QtQuick
import Quickshell
import qs.config

Item {
    id: root

    required property ShellScreen screen

    readonly property int contentWidth: Config.bar.contentWidth

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
