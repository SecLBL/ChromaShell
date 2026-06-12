local v = require("config.variables")
local _op = string.format("%g", v.windowOpacity)

-- ── Opacity ───────────────────────────────────────────────────────────────────
hl.window_rule({ match={ class=".*" }, opacity=_op .. " override " .. _op .. " override" })

-- Full opacity for native-transparent or always-opaque apps
hl.window_rule({ match={ class="foot|org%.quickshell|imv|swappy" }, opacity="1.0 override", no_blur=true })

-- Full opacity + no blur for video playback
hl.window_rule({
    match   = { class="^(librewolf)$", title=".*(YouTube|Twitch|Netflix|Prime Video|S%.to|mp4).*" },
    opacity = "1.0 override",
    no_blur = true,
})
hl.window_rule({ match={ class="^(mpv)$" },  opacity="1.0 override", no_blur=true })
hl.window_rule({ match={ class="^(vlc)$" },  opacity="1.0 override", no_blur=true })

-- Full opacity for creative software
hl.window_rule({ match={ class="krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot" }, opacity="1.0 override", no_blur=true })

-- Full opacity for games
hl.window_rule({ match={ class="(steam_app_(default|[0-9]+))|gamescope" }, opacity="1.0 override", no_blur=true })

-- ── Floating ──────────────────────────────────────────────────────────────────
-- Center all floating windows (except xwayland popups)
hl.window_rule({ match={ float=true, xwayland=false }, center=true })

-- Simple float
hl.window_rule({ match={ class="yad|zenity|wev|feh|imv" },                   float=true })
hl.window_rule({ match={ class="org%.gnome%.FileRoller|file-roller" },        float=true })
hl.window_rule({ match={ class="blueman-manager" },                            float=true })
hl.window_rule({ match={ class="com%.github%.GradienceTeam%.Gradience" },    float=true })
hl.window_rule({ match={ class="system-config-printer" },                     float=true })
hl.window_rule({ match={ class="org%.quickshell" },                           float=true })
hl.window_rule({ match={ class="ueberzugpp_.*" },                             float=true, no_initial_focus=true })

-- Float + size + center
hl.window_rule({ match={ class="org%.pulseaudio%.pavucontrol|yad-icon-browser" }, float=true, size={ "60%", "70%" }, center=true })
hl.window_rule({ match={ class="org%.gnome%.Settings" },                           float=true, size={ "70%", "80%" }, center=true })
hl.window_rule({ match={ class="nwg-look" },                                       float=true, size={ "50%", "60%" }, center=true })

-- Dialogs
hl.window_rule({ match={ title="(Select|Open)( a)? (File|Folder)(s)?" },   float=true })
hl.window_rule({ match={ title="File (Operation|Upload)( Progress)?" },     float=true })
hl.window_rule({ match={ title=".* Properties" },                           float=true })
hl.window_rule({ match={ title="Export Image as PNG" },                     float=true })
hl.window_rule({ match={ title="Save As" },                                 float=true })
hl.window_rule({ match={ title="Library" },                                 float=true })

-- ── Steam ─────────────────────────────────────────────────────────────────────
hl.window_rule({ match={ class="steam" },                                    rounding=10 })
hl.window_rule({ match={ class="steam", title="Friends List" },              float=true })

-- ── Games ─────────────────────────────────────────────────────────────────────
hl.window_rule({ match={ class="(steam_app_(default|[0-9]+))|gamescope" }, immediate=true })
hl.window_rule({ match={ class="(steam_app_(default|[0-9]+))|gamescope" }, idle_inhibit="always" })

-- ── Picture-in-picture ────────────────────────────────────────────────────────
hl.window_rule({ match={ title="Picture(-| )in(-| )[Pp]icture" }, float=true })
hl.window_rule({ match={ title="Picture(-| )in(-| )[Pp]icture" }, pin=true })
hl.window_rule({ match={ title="Picture(-| )in(-| )[Pp]icture" }, keep_aspect_ratio=true })
hl.window_rule({ match={ title="Picture(-| )in(-| )[Pp]icture" }, move="100%-w-2% 100%-w-3%" })

-- ── XWayland popups ───────────────────────────────────────────────────────────
hl.window_rule({ match={ xwayland=true, title="win[0-9]+" }, no_dim=true })
hl.window_rule({ match={ xwayland=true, title="win[0-9]+" }, no_shadow=true })
hl.window_rule({ match={ xwayland=true, title="win[0-9]+" }, rounding=10 })

-- ── Special workspace assignments ────────────────────────────────────────────
hl.window_rule({ match={ class="btop" },                                                                      workspace="special:sysmon" })
hl.window_rule({ match={ class="feishin|Spotify|Supersonic|Cider|com%.github%.th_ch%.youtube_music|Plexamp" }, workspace="special:music" })
hl.window_rule({ match={ title="Spotify( Free)?" },                                                            workspace="special:music" })
hl.window_rule({ match={ class="discord|equibop|vesktop|whatsapp" },                                          workspace="special:communication" })
hl.window_rule({ match={ class="Todoist" },                                                                    workspace="special:todo" })

-- ── Layer rules ───────────────────────────────────────────────────────────────
hl.layer_rule({ match={ namespace="hyprpicker" },                      animation="fade" })
hl.layer_rule({ match={ namespace="selection" },                       animation="fade" })
hl.layer_rule({ match={ namespace="wayfreeze" },                       animation="fade" })
hl.layer_rule({ match={ namespace="logout_dialog" },                   animation="fade" })
hl.layer_rule({ match={ namespace="caelestia-(border-exclusion|area-picker)" }, no_anim=true })
hl.layer_rule({ match={ namespace="caelestia-(drawers|background)" },  animation="fade" })
hl.layer_rule({ match={ namespace="chromashell-frame" },               blur=true, ignore_alpha=0 })
hl.layer_rule({ match={ namespace="caelestia-cassette" },              blur=true, ignore_alpha=0.04 })
hl.layer_rule({ match={ namespace="caelestia-cassette" },              animation="fade" })
hl.layer_rule({ match={ namespace="launcher" },                        animation="popin 80%" })
hl.layer_rule({ match={ namespace="launcher" },                        blur=true })
