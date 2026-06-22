local vars = require("variables")
local fn   = require("hyprland.functions")
local home = os.getenv("HOME")
local wsaction = home .. "/.config/hypr/scripts/wsaction.fish"

-- Shell & Caelestia actions
hl.bind("SHIFT + TAB", hl.dsp.global("caelestia:launcher"))
hl.bind("SUPER + M", hl.dsp.exec_cmd([[fish -c "qs -c caelestia kill && qs -c caelestia -d"]])) -- Restart shell
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("systemctl poweroff"))                                -- Full off
hl.bind(vars.kbRestoreLock, hl.dsp.global("caelestia:lock"), { locked = true })                -- Lock screen

-- Window state & layout
hl.bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
hl.bind(vars.kbCloseWindow, hl.dsp.window.close())

-- Workspace navigation -1/+1
hl.bind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))

-- Numbered workspaces 1-10 (multi-monitor via wsaction.fish)
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(vars.kbGoToWs .. " + " .. key, hl.dsp.exec_cmd(wsaction .. " workspace " .. i))
    hl.bind(vars.kbMoveWinToWs .. " + " .. key, hl.dsp.exec_cmd(wsaction .. " movetoworkspace " .. i))
end

-- Special workspaces (scratchpads)
hl.bind(vars.kbSpecialWs, hl.dsp.exec_cmd("caelestia toggle specialws"))
hl.bind(vars.kbSystemMonitorWs, hl.dsp.exec_cmd("caelestia toggle sysmon"))
hl.bind(vars.kbMusicWs,
    hl.dsp.exec_cmd("pgrep -x feishin && hyprctl dispatch togglespecialworkspace music || feishin"))
hl.bind(vars.kbCommunicationWs,
    hl.dsp.exec_cmd("pgrep -x vesktop && hyprctl dispatch togglespecialworkspace communication || vesktop"))
hl.bind(vars.kbTodoWs,
    hl.dsp.exec_cmd(
        [[pgrep -x obsidian && hyprctl dispatch togglespecialworkspace todo || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
hl.bind(vars.kbMessangerWs,
    hl.dsp.exec_cmd("pgrep -x AyuGram && hyprctl dispatch togglespecialworkspace messanger || AyuGram"))

-- Application launchers (via app2unit)
hl.bind(vars.kbTerminal, hl.dsp.exec_cmd("app2unit -- " .. vars.terminal))
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd("app2unit -- " .. vars.browser))
hl.bind(vars.kbEditor, hl.dsp.exec_cmd("app2unit -- " .. vars.editor))
hl.bind(vars.kbManagerApp, hl.dsp.exec_cmd("app2unit -- " .. vars.kbManager))
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd("app2unit -- " .. vars.fileExplorer))

-- Utilities & tools
hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshotFreeze"))       -- Screenshot region (freeze)
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.global("caelestia:screenshot"))       -- Screenshot region
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("caelestia record -s"))              -- Record + sound
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("caelestia record"))                  -- Record
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("caelestia record -r"))      -- Record region
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))                  -- Colour picker

-- Clipboard & emoji
hl.bind("SUPER + grave", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"))
hl.bind("SUPER + Period", hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"))
hl.bind(
    "CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]),
    { locked = true }
)

-- Hardware keys (TUF laptop)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
    { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- Mouse bindings
hl.bind("SHIFT + mouse:274", hl.dsp.window.drag(), { mouse = true })
hl.bind("CTRL + mouse:274", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + mouse:273", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + SHIFT + mouse:273", hl.dsp.window.move({ workspace = "special:secret" }))
hl.bind("SUPER + SHIFT + mouse:274", hl.dsp.window.float())                            -- Toggle floating + pin + resize
hl.bind("SUPER + SHIFT + mouse:274", hl.dsp.window.pin())
hl.bind("SUPER + SHIFT + mouse:274", hl.dsp.window.resize(fn.resize_by_screen(50, 50)))

-- Resize active window
hl.bind("SUPER + ALT + left", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + ALT + up", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + down", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })

-- Window groups
hl.bind(vars.kbToggleGroup, hl.dsp.group.toggle())              -- Stack windows into tabs
hl.bind("ALT + TAB", hl.dsp.group.next(), { repeating = true }) -- Cycle tab forward

-- Testing
hl.bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Testing notification features..."]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    ),
    { locked = true }
)
