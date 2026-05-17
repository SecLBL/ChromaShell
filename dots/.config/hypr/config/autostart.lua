hl.on("hyprland.start", function()
    -- Wallpaper
    hl.exec_cmd("awww-daemon")

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Media
    hl.exec_cmd("playerctld")

    -- Clipboard
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- OSD
    hl.exec_cmd("swayosd-server")

    -- Audio
    hl.exec_cmd("bash ~/.config/hypr/scripts/audio/start-jalv.sh")
    hl.exec_cmd("sleep 2 && qpwgraph -a -m")

    -- Shell
    hl.exec_cmd("quickshell -c ChromaShell")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 18")

    -- Scratchpad terminal (hidden on start, toggle via Super+Space)
    hl.exec_cmd("kitty --class kitty-scratchpad")
end)
