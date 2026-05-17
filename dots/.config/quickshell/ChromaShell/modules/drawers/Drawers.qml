pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
        }

        ContentWindow {
            targetScreen: scope.modelData
        }
    }
}
