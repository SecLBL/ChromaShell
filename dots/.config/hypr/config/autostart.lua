local _v = require("config.variables")

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.submap("global"))

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("trash-empty 30")
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("ydotoold")

    -- Media
    hl.exec_cmd("mpris-proxy")

    -- Shell
    hl.exec_cmd("qs -c ChromaShell")
    hl.exec_cmd("caelestia resizer -d")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor " .. _v.cursorTheme .. " " .. _v.cursorSize)
    hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "' .. _v.cursorTheme .. '"')
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. _v.cursorSize)
end)
