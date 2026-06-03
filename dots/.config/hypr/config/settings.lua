-- Load colour scheme (written by caelestia-cli on every theme change)
local ok, sc = pcall(require, "scheme.current")
if not ok then
    -- Fallback: default scheme hex values (matches scheme/default.conf)
    sc = {
        primary          = "c2c1ff",
        surface          = "131317",
        surfaceContainer = "201f23",
        onPrimary        = "2a2a60",
        onSurfaceVariant = "c8c5d1",
        outlineVariant   = "47464f",
        secondary        = "c6c4e0",
    }
end

-- Pre-compute colour strings (mirrors upstream variables.conf pattern)
local active_border   = "rgba(" .. sc.primary          .. "e6)"
local inactive_border = "rgba(" .. sc.onSurfaceVariant .. "11)"
local bg_color        = "rgb("  .. sc.surfaceContainer .. ")"
local shadow_color    = "rgba(" .. sc.surface          .. "d4)"
local gb_text         = "rgb("  .. sc.onPrimary        .. ")"
local gb_active       = "rgba(" .. sc.primary          .. "d4)"
local gb_inactive     = "rgba(" .. sc.outlineVariant   .. "04)"
local gb_locked       = "rgba(" .. sc.secondary        .. "d4)"

local v = require("config.variables")

-- Fallback monitor rule (all unmatched outputs)
hl.monitor({ output="", mode="preferred", position="auto", scale=1 })

-- ── Animations ────────────────────────────────────────────────────────────────
hl.curve("emphasizedDecel",    { type="bezier", points={ {0.05, 0.7}, {0.1, 1}    } })
hl.curve("emphasizedAccel",    { type="bezier", points={ {0.3,  0},   {0.8, 0.15} } })
hl.curve("standard",           { type="bezier", points={ {0.2,  0},   {0,   1}    } })
hl.curve("specialWorkSwitch",  { type="bezier", points={ {0.05, 0.7}, {0.1, 1}    } })

hl.animation({ leaf="layersIn",          enabled=true, speed=5, bezier="emphasizedDecel", style="slide" })
hl.animation({ leaf="layersOut",         enabled=true, speed=4, bezier="emphasizedAccel", style="slide" })
hl.animation({ leaf="fadeLayers",        enabled=true, speed=5, bezier="standard" })
hl.animation({ leaf="windowsIn",         enabled=true, speed=5, bezier="emphasizedDecel" })
hl.animation({ leaf="windowsOut",        enabled=true, speed=3, bezier="emphasizedAccel" })
hl.animation({ leaf="windowsMove",       enabled=true, speed=6, bezier="standard" })
hl.animation({ leaf="workspaces",        enabled=true, speed=5, bezier="standard" })
hl.animation({ leaf="specialWorkspace",  enabled=true, speed=4, bezier="specialWorkSwitch", style="slidefadevert 15%" })
hl.animation({ leaf="fade",              enabled=true, speed=6, bezier="standard" })
hl.animation({ leaf="fadeDim",           enabled=true, speed=6, bezier="standard" })
hl.animation({ leaf="border",            enabled=true, speed=6, bezier="standard" })

-- ── Gestures ─────────────────────────────────────────────────────────────────
hl.gesture({ fingers=v.workspaceSwipeFingers, direction="horizontal", action="workspace" })
hl.gesture({ fingers=v.gestureFingers,        direction="up",         action="special",   workspace_name="special" })
-- 3-finger down (caelestia toggle specialws) and 4-finger down (suspend) require
-- arbitrary dispatcher calls which hl.gesture does not support in Hyprland 0.55.

hl.config({
    gestures = {
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },

-- ── General ───────────────────────────────────────────────────────────────────
    general = {
        gaps_in          = v.windowGapsIn,
        gaps_out         = v.windowGapsOut,
        gaps_workspaces  = v.workspaceGaps,
        border_size      = v.windowBorderSize,
        col = {
            active_border   = active_border,
            inactive_border = inactive_border,
        },
        resize_on_border  = true,
        no_focus_fallback = true,
        allow_tearing     = true,
        snap = {
            enabled      = true,
            window_gap   = 4,
            monitor_gap  = 5,
            respect_gaps = true,
        },
    },

-- ── Decoration ────────────────────────────────────────────────────────────────
    decoration = {
        rounding         = v.windowRounding,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        dim_inactive     = true,
        dim_strength     = 0.05,
        dim_special      = 0.2,

        blur = {
            enabled                   = v.blurEnabled,
            xray                      = v.blurXray,
            special                   = v.blurSpecialWs,
            new_optimizations         = true,
            size                      = v.blurSize,
            passes                    = v.blurPasses,
            brightness                = 1.5,
            noise                     = 0,
            contrast                  = 0.89,
            vibrancy                  = 0.3,
            vibrancy_darkness         = 0.3,
            popups                    = v.blurPopups,
            popups_ignorealpha        = 0.6,
            input_methods             = v.blurInputMethods,
            input_methods_ignorealpha = 0.8,
        },

        shadow = {
            enabled      = v.shadowEnabled,
            range        = v.shadowRange,
            offset       = "0 2",
            render_power = v.shadowRenderPower,
            color        = shadow_color,
        },
    },

-- ── Group / Groupbar ──────────────────────────────────────────────────────────
    group = {
        col = {
            border_active          = active_border,
            border_inactive        = inactive_border,
            border_locked_active   = active_border,
            border_locked_inactive = inactive_border,
        },
        groupbar = {
            font_family               = "JetBrains Mono NF",
            font_size                 = 15,
            gradients                 = true,
            gradient_round_only_edges = false,
            gradient_rounding         = 5,
            height                    = 25,
            indicator_height          = 0,
            gaps_in                   = 3,
            gaps_out                  = 3,
            text_color                = gb_text,
            col = {
                active        = gb_active,
                inactive      = gb_inactive,
                locked_active = gb_active,
                locked_inactive = gb_locked,
            },
        },
    },

-- ── Dwindle ───────────────────────────────────────────────────────────────────
    dwindle = {
        preserve_split  = true,
        smart_split     = false,
        smart_resizing  = true,
    },

-- ── Input ─────────────────────────────────────────────────────────────────────
    input = {
        kb_layout              = "us",
        numlock_by_default     = true,
        repeat_delay           = 250,
        repeat_rate            = 35,
        follow_mouse           = 1,
        focus_on_close         = 1,
        off_window_axis_events = 2,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = v.touchpadDisableTyping,
            clickfinger_behavior = true,
            scroll_factor        = v.touchpadScrollFactor,
        },
    },

-- ── Binds ─────────────────────────────────────────────────────────────────────
    binds = {
        scroll_event_delay               = 0,
        hide_special_on_workspace_change = true,
    },

-- ── Cursor ────────────────────────────────────────────────────────────────────
    cursor = {
        zoom_factor     = 1,
        zoom_rigid      = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
    },

-- ── Misc ──────────────────────────────────────────────────────────────────────
    misc = {
        disable_hyprland_logo        = true,
        disable_splash_rendering     = true,
        force_default_wallpaper      = 0,
        vrr                          = 1,
        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,
        middle_click_paste           = false,
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,
        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        session_lock_xray            = true,
        focus_on_activate            = true,
        enable_swallow               = false,
        initial_workspace_tracking   = false,
        background_color             = bg_color,
    },

-- ── Debug ─────────────────────────────────────────────────────────────────────
    debug = {
        vfr            = true,
        error_position = 1,
    },
})
