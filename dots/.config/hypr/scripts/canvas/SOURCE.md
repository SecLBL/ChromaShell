adapted from https://github.com/sarodscommits/IridumShell-IridiumDots-BETA (config/hypr/scripts), MIT, see LICENSE.iridium.

Driven from `config/canvas.lua` (toggle, focus, grab-to-pan).

- `floating_tile_toggle.py`, `hypr_ipc.py`: unchanged
- `auto_layout_mode.py`: never demotes floating -> tiled (tiling is the default here, floating comes from window rules); off via the shell config (`general.canvas.autoLayout`)
- `navigate_windows.py`: monitor centre respects transform/scale, browsers get focused too, parallax through the canvas plugin
- dropped:
  - `infinite_desktop_core.py`: read every keyboard/mouse through evdev (input group). Panning is `canvas.grab_*` in Lua now: Super+right drag, windows stick to the cursor
  - `zoom_canvas.py`: zoom by monitor scale, reconfigures the whole output on every step
  - `window_magnet.py`: fights Hyprland's own drag (jitter) and left a forced per-window animation prop behind; `general.snap` does the snapping
  - Iridium's edge push and glide

Multi-monitor: Hyprland draws a floating window on every monitor it overlaps. The canvas plugin (ChromaShell-Flake/plugins/canvas) cuts canvas windows off at their own monitor instead. (Moving the neighbour monitor away was tried first: every monitor move shows one misplaced frame while Hyprland is busy panning.)
