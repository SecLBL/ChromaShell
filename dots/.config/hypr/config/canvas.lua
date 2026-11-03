-- ══════════════════════════════════════════
--  Canvas: per-workspace floating mode with panning
-- ══════════════════════════════════════════
-- A workspace is a canvas while most of its windows float (same rule as
-- scripts/canvas/auto_layout_mode.py, the bar's mode indicator and the wallpaper
-- parallax). Scripts adapted from Iridium, see scripts/canvas/SOURCE.md.
--
--   canvas.toggle()          tiling <-> canvas for the active workspace (Super+A, bar indicator)
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

function M.is_canvas(ws)
    local all = hl.get_workspace_windows(ws)
    local f = #floating(ws)
    return f > 0 and f * 2 > #all
end

function M.toggle()
    py("floating_tile_toggle.py")
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
