local _v = require("config.variables")

-- Long-running daemons get their own unit in background-graphical.slice
local function bg(cmd) hl.exec_cmd("app2unit -s b -- " .. cmd) end

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.submap("global"))

    -- Core components (gnome-keyring forks itself, a service unit would kill it)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    bg("polkit-gnome-authentication-agent-1")
    bg("hypridle")
    hl.exec_cmd("trash-empty 30")
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    bg("sh -c 'sleep 1 && exec gammastep'")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Clipboard
    bg("wl-paste --type text  --watch cliphist store")
    bg("wl-paste --type image --watch cliphist store")
    bg("ydotoold")

    -- Media
    bg("mpris-proxy")

    -- Shell
    hl.exec_cmd("app2unit -s s -- qs -c ChromaShell")
    bg("caelestia resizer -d")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor " .. _v.cursorTheme .. " " .. _v.cursorSize)
    hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "' .. _v.cursorTheme .. '"')
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. _v.cursorSize)
end)
