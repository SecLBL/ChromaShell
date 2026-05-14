pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string osName: ""
    property string osPrettyName: ""
    property string osId: ""
    property string osLogo: ""
    property bool isDefaultLogo: true

    readonly property string user: Quickshell.env("USER")
    readonly property string shell: Quickshell.env("SHELL").split("/").pop()

    FileView {
        id: osRelease
        path: "/etc/os-release"
        watchChanges: false
        onTextChanged: {
            const lines = text().split("\n");
            const fd = key => lines.find(l => l.startsWith(`${key}=`))?.split("=")[1]?.replace(/"/g, "") ?? "";

            root.osName = fd("NAME");
            root.osPrettyName = fd("PRETTY_NAME");
            root.osId = fd("ID");

            const logo = Quickshell.iconPath(fd("LOGO"), true);
            if (logo) {
                root.osLogo = logo;
                root.isDefaultLogo = false;
            }
        }
    }
}
