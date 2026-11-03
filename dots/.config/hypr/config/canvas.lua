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

-- M.float_size of the monitor, centred on the cursor, inside the monitor's free area
function M.float_geometry(mon)
    local w, h = mon.width, mon.height
    if mon.transform % 2 == 1 then w, h = h, w end
    local s = mon.scale or 1
    local r = mon.reserved or {}
    local left, top = mon.x + (r.left or 0), mon.y + (r.top or 0)
    local right = mon.x + math.floor(w / s + 0.5) - (r.right or 0)
    local bottom = mon.y + math.floor(h / s + 0.5) - (r.bottom or 0)
    local nw = math.floor((right - left) * M.float_size[1] + 0.5)
    local nh = math.floor((bottom - top) * M.float_size[2] + 0.5)
    local c = hl.get_cursor_pos()
    local x = math.min(math.max(math.floor(c.x - nw / 2 + 0.5), left), right - nw)
    local y = math.min(math.max(math.floor(c.y - nh / 2 + 0.5), top), bottom - nh)
    return x, y, nw, nh
end

-- kbToggleWindowFloating: a window that starts floating gets the floating size at the cursor
function M.float_toggle()
    local w = hl.get_active_window()
    if not w then return end
    local target, was_floating = "address:" .. w.address, w.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = target }))
    if was_floating then return end -- now tiled
    local mon = w.monitor or hl.get_active_monitor()
    if not mon then return end
    local x, y, nw, nh = M.float_geometry(mon)
    hl.dispatch(hl.dsp.window.resize({ window = target, x = nw, y = nh, relative = false }))
    hl.dispatch(hl.dsp.window.move({ window = target, x = x, y = y, relative = false }))
end

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
