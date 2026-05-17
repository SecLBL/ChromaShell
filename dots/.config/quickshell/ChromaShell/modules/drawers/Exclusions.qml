pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Scope {
    id: root

    required property ShellScreen screen

    // Left is already reserved by BarRoot's own exclusiveZone
    ExclusionZone { anchors.top: true }
    ExclusionZone { anchors.right: true }
    ExclusionZone { anchors.bottom: true }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "chromashell-border-exclusion"
        WlrLayershell.layer: WlrLayer.Top
        exclusiveZone: Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
    }
}
