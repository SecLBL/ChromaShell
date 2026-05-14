import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
    id: root

    implicitWidth: 44
    implicitHeight: timeLayout.implicitHeight + 16

    color: Colours.palette.m3surfaceContainer
    radius: Tokens.rounding.full

    property date now: new Date()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        id: timeLayout
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String(root.now.getHours()).padStart(2, '0')
            color: Colours.palette.m3primary
            font.pixelSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 20
            implicitHeight: 1
            color: Colours.palette.m3primary
            opacity: 0.3
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String(root.now.getMinutes()).padStart(2, '0')
            color: Colours.palette.m3primary
            font.pixelSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
