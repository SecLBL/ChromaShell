pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    required property ShellScreen screen

    spacing: 8

    Item { Layout.preferredHeight: 12; Layout.fillWidth: true }

    OsIcon { Layout.leftMargin: 10; Layout.rightMargin: 8 }

    Workspaces {
        screen: root.screen
        fullscreen: false
        Layout.leftMargin: 10
        Layout.rightMargin: 8
    }

    Item { Layout.fillHeight: true }

    Clock { Layout.leftMargin: 10; Layout.rightMargin: 8 }

    Item { Layout.preferredHeight: 12; Layout.fillWidth: true }
}
