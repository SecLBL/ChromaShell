pragma ComponentBehavior: Bound

import "."
import "../../utils"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win

    property bool show: false
    visible: show

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "chromashell-wallpaper"
    color: "transparent"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { win.show = !win.show }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)

        MouseArea {
            anchors.fill: parent
            onClicked: win.show = false
        }
    }

    Scaler {
        id: scaler
        currentWidth: win.screen?.width ?? 1920
    }

    WallpaperPicker {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: win.screen?.width ?? 1920
        height: scaler.s(650)
    }
}
