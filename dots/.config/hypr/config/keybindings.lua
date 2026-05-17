local v = require("config.variables")
local M = v.mainMod

-- Apps
hl.bind(M .. " + Return", hl.dsp.exec_cmd(v.terminal))
hl.bind(M .. " + T",      hl.dsp.exec_cmd(v.terminal))
hl.bind(M .. " + E",      hl.dsp.exec_cmd(v.fileManager))
hl.bind(M .. " + D",      hl.dsp.exec_cmd(v.launcher))
hl.bind(M .. " + Space",  hl.dsp.workspace.toggle_special("terminal"))

-- Windows
hl.bind(M .. " + Q",           hl.dsp.window.close())
hl.bind(M .. " SHIFT + F",     hl.dsp.window.float({ action="toggle" }))
hl.bind(M .. " + F",           hl.dsp.window.fullscreen(0))
hl.bind(M .. " + left",        hl.dsp.focus({ direction="left" }))
hl.bind(M .. " + right",       hl.dsp.focus({ direction="right" }))
hl.bind(M .. " + up",          hl.dsp.focus({ direction="up" }))
hl.bind(M .. " + down",        hl.dsp.focus({ direction="down" }))

hl.bind(M .. " + mouse:272",   hl.dsp.window.drag(),   { mouse=true })
hl.bind(M .. " + mouse:273",   hl.dsp.window.resize(), { mouse=true })

-- Workspaces
for i = 1, 8 do
    hl.bind(M .. " + " .. i,         hl.dsp.focus({ workspace=i }))
    hl.bind(M .. " SHIFT + " .. i,   hl.dsp.window.move({ workspace=i }))
end

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),        { locked=true, repeating=true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),        { locked=true, repeating=true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),  { locked=true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),   { locked=true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),                        { locked=true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),                          { locked=true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),                              { locked=true })

-- Quickshell
hl.bind(M .. " + W", hl.dsp.exec_cmd("qs -c ChromaShell ipc call wallpaper toggle"))

-- Screenshot
hl.bind("Print",         hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty -f -]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | satty -f -"))
