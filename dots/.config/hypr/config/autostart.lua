hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.submap("global"))

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("ydotoold")

    -- Media
    hl.exec_cmd("mpris-proxy")

    -- Audio (jalv chain managed by chromashell-jalv.service — starts with wireplumber)
    hl.exec_cmd("sleep 2 && qpwgraph -a -m")

    -- Shell
    hl.exec_cmd("qs -c ChromaShell")
    hl.exec_cmd("caelestia resizer -d")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 18")
    hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"')
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 18")
end)
