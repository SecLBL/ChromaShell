-- ══════════════════════════════════════════
--  ChromaShell — Hyprland Entry Point
-- ══════════════════════════════════════════

-- Pre-load colour scheme into module cache. current.lua is written by
-- caelestia-cli on theme change; if it's missing or broken, fall back to
-- scheme/default.lua per key instead of aborting the whole config (no binds)
do
    local ok, sc = pcall(require, "scheme.current")
    if not ok or type(sc) ~= "table" then sc = {} end
    package.loaded["scheme.current"] = setmetatable(sc, { __index = require("scheme.default") })
end

-- variables
require("config.variables")         -- upstream
pcall(require, "custom.variables")  -- custom (writable, created once by flake, never overwritten)
pcall(require, "generated.editor")  -- flake-managed: sets v.editor from editor.app option
pcall(require, "generated.browser") -- flake-managed: sets v.browser from browser.app option

-- ChromaShell upstream
require("config.env")
require("config.settings")
require("config.rules")
require("config.keybindings")
require("config.autostart")

-- Per-machine (writable, created once by flake, never overwritten)
require("monitors")
require("workspaces")

-- User custom (writable, created once by flake, never overwritten)
pcall(require, "custom.env")
pcall(require, "custom.rules")
pcall(require, "custom.keybindings")
pcall(require, "custom.autostart")
pcall(require, "custom.settings")   -- hl.config() calls merge, so end is fine
