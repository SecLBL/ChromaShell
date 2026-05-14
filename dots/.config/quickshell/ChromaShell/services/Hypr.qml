pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property var toplevels: Hyprland.toplevels
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen)
    }

    function dispatch(cmd) {
        Hyprland.dispatch(cmd)
    }
}
