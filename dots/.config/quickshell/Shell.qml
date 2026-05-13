//@ pragma UseQApplication
import QtQuick
import Quickshell
import "bar"

ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    // ── Shell frame ─────────────────────────────────
    LeftBar {}

    ShellEdge { side: "top" }
    ShellEdge { side: "right" }
    ShellEdge { side: "bottom" }

    // ── Popups (TODO) ──────────────────────────────
    // Floating {}
}
