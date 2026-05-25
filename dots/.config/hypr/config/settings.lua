local ok, colors = pcall(require, "colors")
if not ok then
    colors = { active_border="rgba(0DB7D4FF)", inactive_border="rgba(31313600)" }
end

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
hl.gesture({ fingers=4, direction="horizontal", action="workspace" })
hl.gesture({ fingers=3, direction="up",         action="special",   workspace_name="special" })
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
        gaps_in          = 4,
        gaps_out         = 5,
        gaps_workspaces  = 50,
        border_size      = 1,
        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
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
        rounding         = 12,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        dim_inactive     = true,
        dim_strength     = 0.05,
        dim_special      = 0.2,

        blur = {
            enabled                   = true,
            xray                      = true,
            special                   = false,
            new_optimizations         = true,
            size                      = 6,
            passes                    = 2,
            brightness                = 1.5,
            noise                     = 0,
            contrast                  = 0.89,
            vibrancy                  = 0.3,
            vibrancy_darkness         = 0.3,
            popups                    = false,
            popups_ignorealpha        = 0.6,
            input_methods             = true,
            input_methods_ignorealpha = 0.8,
        },

        shadow = {
            enabled      = true,
            range        = 30,
            offset       = "0 2",
            render_power = 4,
            color        = "rgba(00000010)",
        },
    },

-- ── Group / Groupbar ──────────────────────────────────────────────────────────
    group = {
        col = {
            border_active          = colors.active_border,
            border_inactive        = colors.inactive_border,
            border_locked_active   = colors.active_border,
            border_locked_inactive = colors.inactive_border,
        },
        groupbar = {
            font_family              = "JetBrains Mono NF",
            font_size                = 15,
            gradients                = true,
            gradient_round_only_edges = false,
            gradient_rounding        = 5,
            height                   = 25,
            indicator_height         = 0,
            gaps_in                  = 3,
            gaps_out                 = 3,
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
        kb_layout              = "de",
        numlock_by_default     = true,
        repeat_delay           = 250,
        repeat_rate            = 35,
        follow_mouse           = 1,
        focus_on_close         = 1,
        off_window_axis_events = 2,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.7,
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
    },

-- ── Debug ─────────────────────────────────────────────────────────────────────
    debug = {
        vfr            = true,
        error_position = 1,
    },
})
