local v = require("config.variables")
local M = v.mainMod

local wsaction = "fish ~/.config/hypr/scripts/wsaction.fish"

hl.define_submap("global", "global", function()

    -- ── Launcher (Super tap) ──────────────────────────────────────────────────
    hl.bind(M .. " + Super_L",               hl.dsp.global("caelestia:launcher"),          { non_consuming=true })
    hl.bind(M,                               hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true, catch_all=true })
    hl.bind(M .. " + mouse:272",             hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true, mouse=true })
    hl.bind(M .. " + mouse:273",             hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true, mouse=true })
    hl.bind(M .. " + mouse:274",             hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true, mouse=true })
    hl.bind(M .. " + mouse_up",              hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true })
    hl.bind(M .. " + mouse_down",            hl.dsp.global("caelestia:launcherInterrupt"),  { non_consuming=true })

    -- ── Caelestia shell ───────────────────────────────────────────────────────
    hl.bind("CTRL + ALT + Delete",           hl.dsp.global("caelestia:session"))
    hl.bind(M .. " + N",                     hl.dsp.global("caelestia:sidebar"))
    hl.bind("CTRL + ALT + C",               hl.dsp.global("caelestia:clearNotifs"),         { locked=true })
    hl.bind(M .. " + K",                     hl.dsp.global("caelestia:showall"))
    hl.bind(M .. " + L",                     hl.dsp.global("caelestia:lock"))
    hl.bind(M .. " + ALT + L",              hl.dsp.exec_cmd("caelestia shell -d"),           { locked=true })
    hl.bind(M .. " + ALT + L",              hl.dsp.global("caelestia:lock"),                 { locked=true })

    -- Kill / restart caelestia shell
    hl.bind("CTRL + SUPER + SHIFT + R",     hl.dsp.exec_cmd("qs -c caelestia kill"),         { release=true })
    hl.bind("CTRL + SUPER + ALT + R",       hl.dsp.exec_cmd("qs -c caelestia kill; sleep .1; caelestia shell -d"), { release=true })

    -- ── Brightness ────────────────────────────────────────────────────────────
    hl.bind("XF86MonBrightnessUp",           hl.dsp.global("caelestia:brightnessUp"),        { locked=true, repeating=true })
    hl.bind("XF86MonBrightnessDown",         hl.dsp.global("caelestia:brightnessDown"),      { locked=true, repeating=true })

    -- ── Media ─────────────────────────────────────────────────────────────────
    hl.bind("CTRL + SUPER + Space",          hl.dsp.global("caelestia:mediaToggle"),          { locked=true })
    hl.bind("XF86AudioPlay",                 hl.dsp.global("caelestia:mediaToggle"),          { locked=true })
    hl.bind("XF86AudioPause",                hl.dsp.global("caelestia:mediaToggle"),          { locked=true })
    hl.bind("CTRL + SUPER + Equal",          hl.dsp.global("caelestia:mediaNext"),            { locked=true })
    hl.bind("XF86AudioNext",                 hl.dsp.global("caelestia:mediaNext"),            { locked=true })
    hl.bind("CTRL + SUPER + Minus",          hl.dsp.global("caelestia:mediaPrev"),            { locked=true })
    hl.bind("XF86AudioPrev",                 hl.dsp.global("caelestia:mediaPrev"),            { locked=true })
    hl.bind("XF86AudioStop",                 hl.dsp.global("caelestia:mediaStop"),            { locked=true })

    -- ── Workspaces — navigate ─────────────────────────────────────────────────
    for i = 1, 9 do
        hl.bind(M .. " + " .. i,              hl.dsp.exec_cmd(wsaction .. " workspace " .. i))
        hl.bind("CTRL + SUPER + " .. i,       hl.dsp.exec_cmd(wsaction .. " -g workspace " .. i))
    end
    hl.bind(M .. " + 0",                      hl.dsp.exec_cmd(wsaction .. " workspace 10"))
    hl.bind("CTRL + SUPER + 0",              hl.dsp.exec_cmd(wsaction .. " -g workspace 10"))

    -- Workspace +/-1
    hl.bind(M .. " + mouse_down",             hl.dsp.focus({ workspace="-1" }))
    hl.bind(M .. " + mouse_up",               hl.dsp.focus({ workspace="+1" }))
    hl.bind("CTRL + SUPER + right",           hl.dsp.focus({ workspace="+1" }),              { repeating=true })
    hl.bind("CTRL + SUPER + left",            hl.dsp.focus({ workspace="-1" }),              { repeating=true })
    hl.bind(M .. " + Page_Down",              hl.dsp.focus({ workspace="+1" }),              { repeating=true })
    hl.bind(M .. " + Page_Up",                hl.dsp.focus({ workspace="-1" }),              { repeating=true })

    -- Workspace group +/-10 (via mouse)
    hl.bind("CTRL + SUPER + mouse_down",      hl.dsp.focus({ workspace="-10" }))
    hl.bind("CTRL + SUPER + mouse_up",        hl.dsp.focus({ workspace="+10" }))

    -- Special workspace
    hl.bind(M .. " + S",                      hl.dsp.exec_cmd("caelestia toggle specialws"))

    -- ── Workspaces — move window ──────────────────────────────────────────────
    for i = 1, 9 do
        hl.bind(M .. " + ALT + " .. i,             hl.dsp.exec_cmd(wsaction .. " movetoworkspace " .. i))
        hl.bind("CTRL + SUPER + ALT + " .. i,      hl.dsp.exec_cmd(wsaction .. " -g movetoworkspace " .. i))
    end
    hl.bind(M .. " + ALT + 0",               hl.dsp.exec_cmd(wsaction .. " movetoworkspace 10"))
    hl.bind("CTRL + SUPER + ALT + 0",        hl.dsp.exec_cmd(wsaction .. " -g movetoworkspace 10"))

    -- Move window +/-1
    hl.bind(M .. " + ALT + Page_Up",          hl.dsp.window.move({ workspace="-1" }),         { repeating=true })
    hl.bind(M .. " + ALT + Page_Down",        hl.dsp.window.move({ workspace="+1" }),         { repeating=true })
    hl.bind(M .. " + ALT + mouse_down",       hl.dsp.window.move({ workspace="-1" }))
    hl.bind(M .. " + ALT + mouse_up",         hl.dsp.window.move({ workspace="+1" }))
    hl.bind("CTRL + SUPER + SHIFT + right",   hl.dsp.window.move({ workspace="+1" }),         { repeating=true })
    hl.bind("CTRL + SUPER + SHIFT + left",    hl.dsp.window.move({ workspace="-1" }),         { repeating=true })

    -- Move to/from special workspace
    hl.bind("CTRL + SUPER + SHIFT + up",      hl.dsp.window.move({ workspace="special:special" }))
    hl.bind("CTRL + SUPER + SHIFT + down",    hl.dsp.window.move({ workspace="e+0" }))
    hl.bind(M .. " + ALT + S",               hl.dsp.window.move({ workspace="special:special" }))

    -- ── Window groups ─────────────────────────────────────────────────────────
    hl.bind("ALT + Tab",                      hl.dsp.window.cycle_next(),                     { repeating=true })
    hl.bind("SHIFT + ALT + Tab",              hl.dsp.window.cycle_next("prev"),               { repeating=true })
    hl.bind("CTRL + ALT + Tab",              hl.dsp.group.next(),                             { repeating=true })
    hl.bind("CTRL + SHIFT + ALT + Tab",      hl.dsp.group.prev(),                             { repeating=true })
    hl.bind(M .. " + Comma",                  hl.dsp.group.toggle())
    hl.bind(M .. " + U",                      hl.dsp.group.move_window())
    hl.bind(M .. " + SHIFT + Comma",          hl.dsp.group.lock_active("toggle"))

    -- ── Window — focus ────────────────────────────────────────────────────────
    hl.bind(M .. " + left",                   hl.dsp.focus({ direction="left" }))
    hl.bind(M .. " + right",                  hl.dsp.focus({ direction="right" }))
    hl.bind(M .. " + up",                     hl.dsp.focus({ direction="up" }))
    hl.bind(M .. " + down",                   hl.dsp.focus({ direction="down" }))

    -- ── Window — move (keyboard) ──────────────────────────────────────────────
    hl.bind(M .. " + SHIFT + left",           hl.dsp.window.move({ direction="left" }))
    hl.bind(M .. " + SHIFT + right",          hl.dsp.window.move({ direction="right" }))
    hl.bind(M .. " + SHIFT + up",             hl.dsp.window.move({ direction="up" }))
    hl.bind(M .. " + SHIFT + down",           hl.dsp.window.move({ direction="down" }))

    -- ── Window — resize (keyboard) ────────────────────────────────────────────
    hl.bind(M .. " + Minus",                  hl.dsp.window.resize({ x=-100, y=0,    relative=true }),  { repeating=true })
    hl.bind(M .. " + Equal",                  hl.dsp.window.resize({ x=100,  y=0,    relative=true }),  { repeating=true })
    hl.bind(M .. " + SHIFT + Minus",          hl.dsp.window.resize({ x=0,    y=-100, relative=true }),  { repeating=true })
    hl.bind(M .. " + SHIFT + Equal",          hl.dsp.window.resize({ x=0,    y=100,  relative=true }),  { repeating=true })
    hl.bind(M .. " + ALT + left",             hl.dsp.window.resize({ x=-100, y=0,    relative=true }),  { repeating=true })
    hl.bind(M .. " + ALT + right",            hl.dsp.window.resize({ x=100,  y=0,    relative=true }),  { repeating=true })
    hl.bind(M .. " + ALT + up",               hl.dsp.window.resize({ x=0,    y=-100, relative=true }),  { repeating=true })
    hl.bind(M .. " + ALT + down",             hl.dsp.window.resize({ x=0,    y=100,  relative=true }),  { repeating=true })

    -- ── Window — mouse drag / resize ──────────────────────────────────────────
    hl.bind(M .. " + mouse:272",              hl.dsp.window.drag(),                           { mouse=true })
    hl.bind(M .. " + Z",                      hl.dsp.window.drag(),                           { mouse=true })
    hl.bind(M .. " + mouse:273",              hl.dsp.window.resize(),                         { mouse=true })
    hl.bind(M .. " + X",                      hl.dsp.window.resize(),                         { mouse=true })

    -- ── Window — actions ──────────────────────────────────────────────────────
    hl.bind("CTRL + SUPER + LESS",       hl.dsp.window.center(1))
    hl.bind("CTRL + SUPER + ALT + LESS", hl.dsp.window.resize({ x="55%", y="70%" }))
    hl.bind("CTRL + SUPER + ALT + LESS", hl.dsp.window.center(1))
    hl.bind(M .. " + ALT + LESS",        hl.dsp.exec_cmd("caelestia resizer pip"))
    hl.bind(M .. " + P",                      hl.dsp.window.pin())
    hl.bind(M .. " + F",                      hl.dsp.window.fullscreen(0))
    hl.bind(M .. " + ALT + F",               hl.dsp.window.fullscreen(1))
    hl.bind(M .. " + ALT + Space",            hl.dsp.window.float({ action="toggle" }))
    hl.bind(M .. " + Q",                      hl.dsp.window.close())

    -- ── Special workspace toggles ─────────────────────────────────────────────
    hl.bind("CTRL + SHIFT + Escape",          hl.dsp.exec_cmd("caelestia toggle sysmon"))
    hl.bind(M .. " + M",                      hl.dsp.exec_cmd("caelestia toggle music"))
    hl.bind(M .. " + D",                      hl.dsp.exec_cmd("caelestia toggle communication"))
    hl.bind(M .. " + R",                      hl.dsp.exec_cmd("caelestia toggle todo"))

    -- ── Apps ──────────────────────────────────────────────────────────────────
    hl.bind(M .. " + Return",                 hl.dsp.exec_cmd(v.terminal))
    hl.bind(M .. " + T",                      hl.dsp.exec_cmd(v.terminal))
    hl.bind(M .. " + W",                      hl.dsp.exec_cmd(v.browser))
    hl.bind(M .. " + C",                      hl.dsp.exec_cmd(v.editor))
    hl.bind(M .. " + E",                      hl.dsp.exec_cmd(v.fileManager))
    hl.bind("CTRL + ALT + Escape",            hl.dsp.exec_cmd("qps"))
    hl.bind("CTRL + ALT + V",                hl.dsp.exec_cmd("pavucontrol"))

    -- ── Screenshot ────────────────────────────────────────────────────────────
    hl.bind("Print",                           hl.dsp.global("caelestia:screenshot"),         { locked=true })
    hl.bind(M .. " + SHIFT + S",              hl.dsp.global("caelestia:screenshotFreeze"))
    hl.bind(M .. " + SHIFT + ALT + S",        hl.dsp.global("caelestia:screenshot"))
    hl.bind(M .. " + ALT + R",               hl.dsp.exec_cmd("caelestia record -s"))
    hl.bind("CTRL + ALT + R",                hl.dsp.exec_cmd("caelestia record"))
    hl.bind(M .. " + SHIFT + ALT + R",        hl.dsp.exec_cmd("caelestia record -r"))
    hl.bind(M .. " + SHIFT + C",              hl.dsp.exec_cmd("hyprpicker -a"))

    -- ── Volume ────────────────────────────────────────────────────────────────
    hl.bind("XF86AudioMicMute",               hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),                                      { locked=true })
    hl.bind("XF86AudioMute",                  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),                                        { locked=true })
    hl.bind(M .. " + SHIFT + M",              hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),                                        { locked=true })
    hl.bind("XF86AudioRaiseVolume",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"), { locked=true, repeating=true })
    hl.bind("XF86AudioLowerVolume",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),       { locked=true, repeating=true })

    -- ── Sleep ─────────────────────────────────────────────────────────────────
    hl.bind(M .. " + SHIFT + L",              hl.dsp.exec_cmd("systemctl suspend-then-hibernate"), { locked=true })

    -- ── Clipboard & Emoji ─────────────────────────────────────────────────────
    hl.bind(M .. " + V",                      hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
    hl.bind(M .. " + ALT + V",               hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"))
    hl.bind(M .. " + Period",                 hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"))
    hl.bind("CTRL + SHIFT + ALT + V",         hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]), { locked=true })

end)
