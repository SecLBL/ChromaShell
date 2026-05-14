import QtQuick
import qs.config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    readonly property int iconSize: Math.round(Tokens.font.size.large * 1.2)

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: Tokens.sizes.bar.innerWidth

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3surfaceContainer
        radius: Tokens.rounding.full
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
    }

    Component {
        id: caelestiaLogo
        Logo {
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize
        }
    }

    Component {
        id: distroIcon
        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: root.iconSize
            colour: Colours.palette.m3tertiary
        }
    }
}
