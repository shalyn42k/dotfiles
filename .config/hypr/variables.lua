local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "foot",
    browser                    = "zen-browser",
    editor                     = "codium",
    fileExplorer               = "thunar",
    kbManager                  = "hyprkcs",
    audioSettings              = "pavucontrol",

    -- Touchpad
    touchpadDisableTyping      = true,
    touchScrollFactor          = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 20,
    shadowRenderPower          = 3,
    shadowColour               = "rgba(" .. scheme.surface .. "d4)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 10,
    windowGapsOut              = 40,
    singleWindowGapsOut        = 20,

    -- Window styling
    windowOpacity              = 0.95,
    windowRounding             = 10,
    windowBorderSize           = 3,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

    -- Misc
    volumeStep                 = 10,
    cursorTheme                = "volantes_cursors",
    cursorSize                 = 24,
    sleepGestureCmd            = "systemctl suspend-then-hibernate",

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Workspaces
    kbMoveWinToWs              = "SUPER + SHIFT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",

    -- Window Group
    kbToggleGroup              = "ALT + Q",

    -- Window Action
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + space",
    kbCloseWindow              = "SUPER + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + Z",
    kbCommunicationWs          = "SUPER + X",
    kbTodoWs                   = "SUPER + C",
    kbMessangerWs              = "SUPER + V",

    -- Apps
    kbTerminal                 = "SUPER + TAB",
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + R",
    kbManagerApp               = "SUPER + T",
    kbFileExplorer             = "SUPER + E",

    -- Misc
    kbSession                  = "CTRL + ALT + Delete",
    kbClearNotifs              = "CTRL + ALT + C",
    kbLock                     = "SUPER + SHIFT + L",
    kbRestoreLock              = "SUPER + ALT + L",
}
