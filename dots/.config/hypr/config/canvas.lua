-- ══════════════════════════════════════════
--  Canvas: per-workspace floating mode with panning
-- ══════════════════════════════════════════
-- Each workspace has a stored mode, tiling (default) or canvas, also for empty
-- workspaces, in $XDG_RUNTIME_DIR/canvas-modes.json ({"<ws id>": true} per canvas).
-- That file is the only copy: canvas.toggle() writes it, scripts/canvas/auto_layout_mode.py
-- follows manual float changes (all windows floating -> canvas, all tiled -> tiling),
-- the bar's mode indicator watches it. Survives config reloads, not a Hyprland restart.
-- Scripts adapted from Iridium, see scripts/canvas/SOURCE.md.
--
--   canvas.toggle()          tiling <-> canvas for the active workspace (Super+A, bar indicator):
--                            all its windows float / tile along
--   canvas.focus(dir)        canvas: next window that way, panned to the centre; tiling: normal focus
--   canvas.grab_start/stop() hold Super+right mouse: the windows stick to the cursor
--   canvas.hold(ws, on)      no move animation for a canvas being panned from outside (bar preview)
--
-- The canvas Hyprland plugin (ChromaShell-Flake/plugins/canvas) adds the grab cursor,
-- the wallpaper parallax event and cuts windows off at their monitor; without it the
-- canvas still works.

local M = {}

M.bar_height = 30 -- hyprbars title bar on floating windows

M.python  = "python3"
M.scripts = os.getenv("HOME") .. "/.config/hypr/scripts/canvas/"

local function py(script, args)
    hl.dispatch(hl.dsp.exec_cmd(M.python .. " " .. M.scripts .. script .. (args and (" " .. args) or "")))
end

local function plugin(fn, ...)
    if hl.plugin.canvas then hl.plugin.canvas[fn](...) end
end

local function floating(ws)
    local out = {}
    for _, w in ipairs(hl.get_workspace_windows(ws)) do
        if w.floating then out[#out + 1] = w end
    end
    return out
end

-- ── Mode per workspace ──
M.modes_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/canvas-modes.json"

-- tostring(ws id) -> true for canvas workspaces; read fresh, python writes it too
local function load_modes()
    local modes = {}
    local f = io.open(M.modes_file, "r")
    if not f then return modes end
    for id in f:read("a"):gmatch('"(%-?%d+)"%s*:%s*true') do modes[id] = true end
    f:close()
    return modes
end

-- in place, not via rename: the bar watches this file
local function save_modes(modes)
    local ids = {}
    for id in pairs(modes) do ids[#ids + 1] = string.format('"%s":true', id) end
    local f = io.open(M.modes_file, "w")
    if not f then return end
    f:write("{" .. table.concat(ids, ",") .. "}\n")
    f:close()
end

save_modes(load_modes()) -- exists from the start, so the bar can watch it

function M.is_canvas(ws)
    return load_modes()[tostring(ws)] == true
end

function M.toggle()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local modes = load_modes()
    local canvas = not modes[tostring(ws.id)]
    modes[tostring(ws.id)] = canvas or nil
    save_modes(modes)
    if #hl.get_workspace_windows(ws.id) > 0 then
        py("floating_tile_toggle.py", canvas and "float" or "tile")
    end
end

-- ── Floating size ──
-- Share of the monitor's free area a window gets when it starts floating; keep in
-- line with NEW_SIZE in scripts/canvas/auto_layout_mode.py (new canvas windows).
M.float_size = { 0.5, 0.6 }

-- height of the hyprbars title bar floating windows get, 0 without the plugin
function M.bar()
    return hl.plugin.hyprbars and M.bar_height or 0
end

-- monitor in logical px, and its free area (without bars)
local function monitor_area(mon)
    local w, h = mon.width, mon.height
    if mon.transform % 2 == 1 then w, h = h, w end
    local s = mon.scale or 1
    w, h = math.floor(w / s + 0.5), math.floor(h / s + 0.5)
    local r = mon.reserved or {}
    return w, h, mon.x + (r.left or 0), mon.y + (r.top or 0), mon.x + w - (r.right or 0), mon.y + h - (r.bottom or 0)
end

-- M.float_size of the monitor, centred on the cursor (or the monitor, when the cursor
-- is elsewhere), inside the monitor's free area
function M.float_geometry(mon)
    local w, h, left, top, right, bottom = monitor_area(mon)
    local nw = math.floor((right - left) * M.float_size[1] + 0.5)
    local nh = math.floor((bottom - top) * M.float_size[2] + 0.5)
    local c = hl.get_cursor_pos()
    if c.x < mon.x or c.x >= mon.x + w or c.y < mon.y or c.y >= mon.y + h then
        c = { x = (left + right) / 2, y = (top + bottom) / 2 }
    end
    local x = math.min(math.max(math.floor(c.x - nw / 2 + 0.5), left), right - nw)
    local y = math.min(math.max(math.floor(c.y - nh / 2 + 0.5), top), bottom - nh)
    -- the title bar sits above the window: the box holds both
    local bar = M.bar()
    return x, y + bar, nw, nh - bar
end

-- floating on: M.float_size at the cursor; off: tiled
local function set_floating(w, on)
    local target = "address:" .. w.address
    hl.dispatch(hl.dsp.window.float({ action = on and "enable" or "disable", window = target }))
    local mon = on and (w.monitor or hl.get_active_monitor())
    if not mon then return end
    local x, y, nw, nh = M.float_geometry(mon)
    hl.dispatch(hl.dsp.window.resize({ window = target, x = nw, y = nh, relative = false }))
    hl.dispatch(hl.dsp.window.move({ window = target, x = x, y = y, relative = false }))
end

-- kbToggleWindowFloating
function M.float_toggle()
    local w = hl.get_active_window()
    if w then set_floating(w, not w.floating) end
end

-- ── Maximize ──
-- A floating window covers its monitor's free area and stays floating (pans with the
-- canvas); again: back to where it was. Tiled windows float first.
local maximized = {} -- address -> { x, y, w, h } before maximizing

function M.max_toggle()
    local w = hl.get_active_window()
    if not w then return end
    local target = "address:" .. w.address
    local prev = maximized[w.address]
    maximized[w.address] = nil
    if prev and w.floating then
        hl.dispatch(hl.dsp.window.resize({ window = target, x = prev.w, y = prev.h, relative = false }))
        hl.dispatch(hl.dsp.window.move({ window = target, x = prev.x, y = prev.y, relative = false }))
        return
    end
    local mon = w.monitor or hl.get_active_monitor()
    if not mon then return end
    if w.floating then
        maximized[w.address] = { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
    else
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = target }))
        local x, y, nw, nh = M.float_geometry(mon) -- restore to the usual floating size
        maximized[w.address] = { x = x, y = y, w = nw, h = nh }
    end
    -- where a single tiled window would sit: gaps_out and border inside the free area,
    -- plus room for the title bar above the window
    local _, _, left, top, right, bottom = monitor_area(mon)
    local g = hl.get_config("general.gaps_out") or {}
    local b = hl.get_config("general.border_size") or 0
    local bar = M.bar()
    left, right = left + (g.left or 0) + b, right - (g.right or 0) - b
    top, bottom = top + (g.top or 0) + b + bar, bottom - (g.bottom or 0) - b
    hl.dispatch(hl.dsp.window.resize({ window = target, x = right - left, y = bottom - top, relative = false }))
    hl.dispatch(hl.dsp.window.move({ window = target, x = left, y = top, relative = false }))
end

-- ── Title bars (hyprbars, ChromaShell-Flake loads it) ──
-- Floating windows only: close, maximize, tiling/floating. Buttons run shell commands.
if hl.plugin.hyprbars then
    local sc = require("scheme.current")
    -- accent colour, like the active border (config/settings.lua)
    local bg, fg = "rgb(" .. sc.primary .. ")", "rgb(" .. sc.onPrimary .. ")"
    hl.config({ plugin = { hyprbars = {
        bar_height          = M.bar_height,
        bar_color           = bg, -- takes the window's opacity: blur it like the window behind
        bar_blur            = true,
        ["col.text"]        = fg,
        bar_text_font       = "FiraCode Nerd Font",
        bar_text_size       = 11,
        bar_padding         = 12,
        bar_button_padding  = 10,
        bar_buttons_alignment = "right",
        bar_part_of_window  = true,
        bar_precedence_over_border = false, -- the border runs around the window only, the bar sits on top
        icon_on_hover       = true, -- plain circles, icon only under the cursor
        on_double_click     = "hyprctl eval 'canvas.max_toggle()'",
    } } })
    local function button(icon, fn)
        -- circles in the contrast colour, the icon in the accent colour on hover
        hl.plugin.hyprbars.add_button({ bg_color = fg, fg_color = bg, size = 20, icon = icon, -- icons: "sans", 62% of size
                                        action = "hyprctl eval 'canvas." .. fn .. "()'" })
    end
    -- first one sits rightmost; Nerd Font icons: close, fullscreen, grid
    button("󰅖", "close")
    button("󰊓", "max_toggle")
    button("󰕰", "float_toggle")
    hl.window_rule({ match = { float = false }, ["hyprbars:no_bar"] = true })
    hl.window_rule({ match = { tag = "canvas_drag" }, ["hyprbars:no_bar"] = true })
end

function M.close()
    hl.dispatch(hl.dsp.window.close())
end

-- ── Windows moved to another workspace take on its mode ──
-- By keybind right away; by mouse drag only on release: switching the window mid-drag
-- drops it. Off with the auto layout switch (shell config general.canvas.autoLayout).
local function auto_layout_on()
    local f = io.open(os.getenv("HOME") .. "/.config/caelestia/shell.json", "r")
    if not f then return true end
    local off = f:read("a"):find('"autoLayout"%s*:%s*false') ~= nil
    f:close()
    return not off
end

function M.adapt(w, ws)
    ws = ws or (w and w.workspace)
    if not w or not ws or ws.id < 0 or not auto_layout_on() then return end -- < 0: scratchpads
    local canvas = M.is_canvas(ws.id)
    if canvas ~= w.floating then set_floating(w, canvas) end
end

local D = { active = false } -- Super+left drag, and the window it moved to another workspace

function M.drag_start()
    D.active, D.moved, D.tagged = true, nil, nil
    -- Hyprland floats a dragged tiled window for the drag: keep it without a bar
    local w = hl.get_active_window()
    if w and not w.floating then
        D.tagged = w.address
        hl.dispatch(hl.dsp.window.tag({ tag = "+canvas_drag", window = "address:" .. w.address }))
    end
end

function M.drag_stop()
    if not D.active then return end
    D.active = false
    if D.tagged then
        hl.dispatch(hl.dsp.window.tag({ tag = "-canvas_drag", window = "address:" .. D.tagged }))
    end
    if D.moved then M.adapt(hl.get_window("address:" .. D.moved)) end
end

hl.on("window.move_to_workspace", function(w, ws)
    if D.active then
        D.moved = w.address
    else
        M.adapt(w, ws)
    end
end)

function M.focus(dir)
    local ws = hl.get_active_workspace()
    if ws and M.is_canvas(ws.id) then
        py("navigate_windows.py", dir)
    else
        hl.dispatch(hl.dsp.focus({ direction = dir }))
    end
end

-- Per window, so the user's windowsMove animation stays untouched; "unset" (not
-- false) hands the window back to the global animation config.
function M.hold(ws, on)
    for _, w in ipairs(floating(ws)) do
        hl.dispatch(hl.dsp.window.set_prop({ prop = "no_anim", value = on and "true" or "unset", window = "address:" .. w.address }))
    end
end

-- ── Grab ──
local G = { active = false }

local function super_held()
    return hl.is_key_down("Super_L") or hl.is_key_down("Super_R")
end

function M.grab_stop()
    if not G.active then return end
    G.active = false
    G.timer:set_enabled(false)
    M.hold(G.ws, false)
    hl.config({ input = { follow_mouse = G.follow_mouse } })
    plugin("cursor")
end

local function tick()
    if not super_held() then return M.grab_stop() end -- Super let go before the button
    local c = hl.get_cursor_pos()
    local dx, dy = math.floor(c.x - G.last.x + 0.5), math.floor(c.y - G.last.y + 0.5)
    if dx == 0 and dy == 0 then return end
    G.last = { x = G.last.x + dx, y = G.last.y + dy }
    for _, w in ipairs(floating(G.ws)) do
        hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, x = dx, y = dy, relative = true }))
    end
    plugin("pan", G.ws, dx, dy)
end

function M.grab_start()
    if G.active then return end
    local ws = hl.get_active_workspace()
    if not ws then return end
    G.ws = ws.id
    local c = hl.get_cursor_pos()
    G.last = { x = c.x, y = c.y }
    -- windows slide under the cursor: focus (and dim_inactive) would flip constantly
    G.follow_mouse = hl.get_config("input.follow_mouse")
    hl.config({ input = { follow_mouse = 0 } })
    M.hold(G.ws, true)
    plugin("cursor", "grabbing")
    G.active = true
    G.timer = G.timer or hl.timer(tick, { timeout = 5, type = "repeat" }) -- ~200 Hz, follows high refresh rates
    G.timer:set_enabled(true)
end

-- for the shell (bar mode indicator, workspace preview): hyprctl eval "canvas.toggle()"
canvas = M

return M
