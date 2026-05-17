local ok, colors = pcall(require, "colors")
if not ok then
    colors = { active_border="rgba(0DB7D4FF)", inactive_border="rgba(31313600)" }
end

-- Fallback monitor rule (all unmatched outputs)
hl.monitor({ output="", mode="preferred", position="auto", scale=1 })

-- Gestures
hl.gesture({ fingers=3, direction="swipe",      action="move" })
hl.gesture({ fingers=3, direction="pinch",      action="float" })
hl.gesture({ fingers=4, direction="horizontal", action="workspace" })
hl.gesture({ fingers=4, direction="up",   action=hl.dsp.exec_cmd("hyprctl dispatch global quickshell:overviewWorkspacesToggle") })
hl.gesture({ fingers=4, direction="down", action=hl.dsp.exec_cmd("hyprctl dispatch global quickshell:overviewWorkspacesClose") })

hl.config({
    gestures = {
        workspace_swipe_distance           = 700,
        workspace_swipe_cancel_ratio       = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock     = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new         = true,
    },

    general = {
        gaps_in          = 4,
        gaps_out         = 5,
        gaps_workspaces  = 50,
        border_size      = 1,
        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing    = true,
        snap = {
            enabled      = true,
            window_gap   = 4,
            monitor_gap  = 5,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding         = 12,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        dim_inactive     = true,
        dim_strength     = 0.05,
        dim_special      = 0.2,

        blur = {
            enabled                  = true,
            xray                     = true,
            special                  = false,
            new_optimizations        = true,
            size                     = 6,
            passes                   = 2,
            brightness               = 1.5,
            noise                    = 0,
            contrast                 = 0.89,
            vibrancy                 = 0.3,
            vibrancy_darkness        = 0.3,
            popups                   = false,
            popups_ignorealpha       = 0.6,
            input_methods            = true,
            input_methods_ignorealpha = 0.8,
        },

        shadow = {
            enabled      = true,
            ignore_window = true,
            range        = 30,
            offset       = "0 2",
            render_power = 4,
            color        = "rgba(00000010)",
        },
    },

    dwindle = {
        preserve_split  = true,
        smart_split     = false,
        smart_resizing  = false,
    },

    input = {
        kb_layout            = "de",
        numlock_by_default   = true,
        repeat_delay         = 250,
        repeat_rate          = 35,
        follow_mouse         = 1,
        off_window_axis_events = 2,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.7,
        },
    },

    misc = {
        disable_hyprland_logo        = true,
        disable_splash_rendering     = true,
        vfr                          = true,
        vrr                          = 0,
        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,
        enable_swallow               = false,
        swallow_regex                = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        session_lock_xray            = true,
        initial_workspace_tracking   = false,
        focus_on_activate            = true,
    },

    binds = {
        scroll_event_delay             = 0,
        hide_special_on_workspace_change = true,
    },

    cursor = {
        zoom_factor     = 1,
        zoom_rigid      = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
    },
})
