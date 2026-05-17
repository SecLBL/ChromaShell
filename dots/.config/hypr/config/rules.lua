-- Disable blur for windows with empty class/title
hl.window_rule({ match={ class="^()$", title="^()$" }, no_blur=false })

-- Disable blur for all windows (baseline off; re-enabled per-window where wanted)
hl.window_rule({ match={ class=".*" }, no_blur=false })

-- Global opacity for all windows
hl.window_rule({ match={ class=".*" }, opacity="0.8 override 0.8 override" })

-- Full opacity + no blur for video playback in librewolf
hl.window_rule({
    match   = { class="^(librewolf)$", title=".*(YouTube|Twitch|Netflix|Prime Video|S.to|mp4).*" },
    opacity = "1.0 override",
    no_blur = true,
})

-- Full opacity + no blur for standalone video players
hl.window_rule({ match={ class="^(mpv)$" }, opacity="1.0 override", no_blur=true })
hl.window_rule({ match={ class="^(vlc)$" }, opacity="1.0 override", no_blur=true })

-- Scratchpad terminal (Super+Space dropdown)
hl.window_rule({
    match     = { class="^(kitty-scratchpad)$" },
    float     = true,
    size      = { "100%", "50%" },
    move      = { "0%", "0%" },
    workspace = "special:terminal silent",
    rounding  = 0,
})

-- Quickshell shell frame
hl.layer_rule({ match={ namespace="chromashell-frame" }, blur=true, ignore_alpha=0 })
