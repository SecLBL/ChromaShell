pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property QtObject border: QtObject {
        readonly property real thickness: 8
        readonly property real rounding: 20
        readonly property real smoothing: 32
    }

    readonly property QtObject bar: QtObject {
        readonly property int innerWidth: 44
        readonly property int sidePadding: 9
        readonly property int contentWidth: innerWidth + sidePadding * 2

        readonly property QtObject workspaces: QtObject {
            readonly property int shown: 5
            readonly property bool perMonitorWorkspaces: true
            readonly property bool occupiedBg: false
            readonly property bool activeIndicator: true
            readonly property bool activeTrail: true
            readonly property bool showWindows: true
            readonly property string capitalisation: "normal"
            readonly property string label: "•"
            readonly property string occupiedLabel: "•"
            readonly property string activeLabel: "•"
            readonly property int maxWindowIcons: 5
            readonly property bool showWindowsOnSpecialWorkspaces: false
        }
    }
}
