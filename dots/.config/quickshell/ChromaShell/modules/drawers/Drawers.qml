import QtQuick
import Quickshell

Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        ContentWindow {
            screen: scope.modelData
        }
    }
}
