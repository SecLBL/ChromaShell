pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(root.screen)
    readonly property bool hasFullscreen:
        monitor?.activeWorkspace?.toplevels.values.some(
            t => t.lastIpcObject.fullscreen > 1) ?? false

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real borderThickness: Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding:  Config.border.rounding  * (1 - fsTransitionProg)
    readonly property real shadowOpacity:   0.7                     * (1 - fsTransitionProg)
    readonly property real sdfOffset: 2 * fsTransitionProg

    Behavior on fsTransitionProg {
        Anim { type: Anim.EmphasizedLarge }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "chromashell-border"
    color: "transparent"

    anchors.top: true; anchors.bottom: true
    anchors.left: true; anchors.right: true

    mask: Region {}

    Item {
        anchors.fill: parent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup
            color: Colours.palette.m3surface
            smoothing: Config.border.smoothing
            Behavior on color { CAnim {} }
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50
            group: blobGroup
            radius: root.borderRounding
            borderLeft:   root.borderThickness - anchors.margins - root.sdfOffset
            borderRight:  root.borderThickness - anchors.margins - root.sdfOffset
            borderTop:    root.borderThickness - anchors.margins - root.sdfOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfOffset
        }
    }
}
