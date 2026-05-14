pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property QtObject font: QtObject {
        readonly property QtObject size: QtObject {
            readonly property real extraLarge: 24
            readonly property real large: 18
            readonly property real larger: 16
            readonly property real normal: 14
            readonly property real small: 12
            readonly property real smaller: 11
        }
        readonly property QtObject family: QtObject {
            readonly property string sans: "Rubik"
            readonly property string mono: "JetBrains Mono"
            readonly property string material: "Material Symbols Rounded"
        }
    }
    readonly property QtObject padding: QtObject {
        readonly property int large: 12
        readonly property int normal: 8
        readonly property int small: 4
        readonly property int smaller: 2
    }
    readonly property QtObject spacing: QtObject {
        readonly property int large: 16
        readonly property int normal: 8
        readonly property int small: 4
    }
    readonly property QtObject rounding: QtObject {
        readonly property int full: 9999
        readonly property int large: 16
        readonly property int normal: 8
        readonly property int small: 4
    }
    readonly property QtObject sizes: QtObject {
        readonly property QtObject bar: QtObject {
            readonly property int innerWidth: 44
        }
    }
    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int normal: 300
            readonly property int small: 200
            readonly property int large: 400
        }
        readonly property var standard: Easing.OutCubic
        readonly property var standardAccel: Easing.InCubic
        readonly property var standardDecel: Easing.OutCubic
        readonly property var emphasized: Easing.InOutCubic
    }
}
