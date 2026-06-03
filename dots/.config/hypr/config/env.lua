-- Toolkit backends
hl.env("GDK_BACKEND",                        "wayland,x11")
hl.env("QT_QPA_PLATFORM",                    "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION","1")
hl.env("QT_QPA_PLATFORMTHEME",              "qtengine")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",        "1")
hl.env("SDL_VIDEODRIVER",                    "wayland,x11,windows")
hl.env("CLUTTER_BACKEND",                    "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT",       "auto")

-- XDG
hl.env("XDG_CURRENT_DESKTOP",               "Hyprland")
hl.env("XDG_SESSION_TYPE",                   "wayland")
hl.env("XDG_SESSION_DESKTOP",               "Hyprland")

-- Cursor
local _v = require("config.variables")
hl.env("XCURSOR_THEME", _v.cursorTheme)
hl.env("XCURSOR_SIZE",  tostring(_v.cursorSize))

-- Misc
hl.env("NIXOS_OZONE_WL",                     "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING",        "1")
