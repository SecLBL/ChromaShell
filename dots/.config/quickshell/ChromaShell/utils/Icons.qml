pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function getAppCategoryIcon(appClass, fallback) {
        return fallback ?? "terminal"
    }

    function getSpecialWsIcon(name) {
        return name.slice(8, 9) || "1"
    }
}
