local M = "SUPER"

return {
    -- Apps
    mainMod     = M,
    -- terminal/fileManager: fallback only; live value comes from shell.json general.apps (reload-bake, see keybindings.lua).
    terminal    = "kitty",
    fileManager = "thunar",
    browser     = "librewolf",
    editor      = "codium",

    -- Touchpad
    touchpadDisableTyping = true,
    touchpadScrollFactor  = 0.7,

    -- Gestures
    workspaceSwipeFingers = 4,
    gestureFingers        = 3,
    gestureFingersMore    = 4,

    -- Blur
    blurEnabled      = true,
    blurSpecialWs    = false,
    blurPopups       = false,
    blurInputMethods = true,
    blurSize         = 6,
    blurPasses       = 2,
    blurXray         = true,

    -- Shadow
    shadowEnabled     = true,
    shadowRange       = 30,
    shadowRenderPower = 4,

    -- Gaps
    workspaceGaps       = 50,
    windowGapsIn        = 2,
    windowGapsOut       = 10,
    singleWindowGapsOut = 20,

    -- Window styling
    windowOpacity    = 0.8,
    windowRounding   = 12,
    windowBorderSize = 2,

    -- Misc
    volumeStep  = 10,
    cursorTheme = "Bibata-Modern-Classic",
    cursorSize  = 18,

    -- Keybinds — workspace navigation
    kbGoToWs           = M,
    kbGoToWsGroup      = "CTRL + " .. M,
    kbNextWs           = "CTRL + " .. M .. " + right",
    kbPrevWs           = "CTRL + " .. M .. " + left",
    kbToggleSpecialWs  = M .. " + S",
    kbMoveWinToWs      = M .. " + ALT",
    kbMoveWinToWsGroup = "CTRL + " .. M .. " + ALT",

    -- Keybinds — window groups
    kbWindowGroupCycleNext = "ALT + Tab",
    kbWindowGroupCyclePrev = "SHIFT + ALT + Tab",
    kbUngroup              = M .. " + U",
    kbToggleGroup          = M .. " + Comma",

    -- Keybinds — window actions
    kbMoveWindow               = M .. " + Z",
    kbResizeWindow             = M .. " + X",
    kbWindowPip                = M .. " + ALT + LESS",
    kbPinWindow                = M .. " + P",
    kbWindowFullscreen         = M .. " + F",
    kbWindowBorderedFullscreen = M .. " + ALT + F",
    kbToggleWindowFloating     = M .. " + ALT + Space",
    kbCloseWindow              = M .. " + Q",

    -- Keybinds — special workspace toggles
    kbSystemMonitor = "CTRL + SHIFT + Escape",
    kbMusic         = M .. " + M",
    kbCommunication = M .. " + D",
    kbTodo          = M .. " + R",

    -- Keybinds — apps
    kbTerminal     = M .. " + T",
    kbBrowser      = M .. " + W",
    kbEditor       = M .. " + C",
    kbFileExplorer = M .. " + E",

    -- Keybinds — shell / UI
    kbSession     = "CTRL + ALT + Delete",
    kbShowSidebar = M .. " + N",
    kbClearNotifs = "CTRL + ALT + C",
    kbShowPanels  = M .. " + K",
    kbLock        = M .. " + L",
    kbRestoreLock = M .. " + ALT + L",
}
