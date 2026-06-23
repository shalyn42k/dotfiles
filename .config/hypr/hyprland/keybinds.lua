local vars = require("variables")
local fn   = require("hyprland.functions")
local home = os.getenv("HOME")
local wsaction     = home .. "/.config/hypr/scripts/wsaction.fish"
local specialcycle = home .. "/.config/hypr/scripts/specialcycle.fish"

-- Shell & Caelestia actions
hl.bind("SHIFT + TAB", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"))
hl.bind("SUPER + M", hl.dsp.exec_cmd([[fish -c "qs -c caelestia kill && qs -c caelestia -d"]])) -- Restart shell
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("systemctl poweroff"))                                -- Full off
hl.bind(vars.kbRestoreLock, hl.dsp.global("caelestia:lock"), { locked = true })                -- Lock screen

-- Window state & layout
hl.bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float())                              -- Toggle floating (F mnemonic)
hl.bind(vars.kbPinWindow, hl.dsp.window.pin())                                   -- Pin window
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
-- NOTE: under the Lua config provider the legacy `togglespecialworkspace`
-- dispatcher is renamed; toggle via the Lua dispatcher instead.
hl.bind(vars.kbMusicWs,
    hl.dsp.exec_cmd(
        [[pgrep -x feishin && hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")' || feishin]]))
hl.bind(vars.kbCommunicationWs,
    hl.dsp.exec_cmd(
        [[pgrep -x vesktop && hyprctl dispatch 'hl.dsp.workspace.toggle_special("communication")' || vesktop]]))
hl.bind(vars.kbTodoWs,
    hl.dsp.exec_cmd(
        [[pgrep -x obsidian && hyprctl dispatch 'hl.dsp.workspace.toggle_special("todo")' || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
hl.bind(vars.kbMessangerWs,
    hl.dsp.exec_cmd(
        [[pgrep -x AyuGram && hyprctl dispatch 'hl.dsp.workspace.toggle_special("messanger")' || AyuGram]]))

-- Special workspace cycle (Caps-hold = CTRL via keyd)
hl.bind("CTRL + J", hl.dsp.exec_cmd(specialcycle .. " prev"))
hl.bind("CTRL + L", hl.dsp.exec_cmd(specialcycle .. " next"))

-- Application launchers (via app2unit)
hl.bind(vars.kbTerminal, hl.dsp.exec_cmd("app2unit -- " .. vars.terminal))
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd("app2unit -- " .. vars.browser))
hl.bind(vars.kbEditor, hl.dsp.exec_cmd("app2unit -- " .. vars.editor))
hl.bind(vars.kbManagerApp, hl.dsp.exec_cmd("app2unit -- " .. vars.kbManager))
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd("app2unit -- " .. vars.fileExplorer))

-- Utilities & tools
hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshotFreeze"))        -- Screenshot region (freeze)
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.global("caelestia:screenshot"))        -- Screenshot region
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("caelestia record -s"))               -- Record + sound
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("caelestia record"))                   -- Record
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("caelestia record -r"))       -- Record region
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("caelestia record -p"))             -- Pause/resume recording
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))                   -- Colour picker
hl.bind("SUPER + O",         hl.dsp.exec_cmd("caelestia resizer pip"))            -- Picture-in-Picture
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("caelestia scheme set -r"))         -- Random colour scheme
hl.bind("SUPER + ALT + N",                                                        -- Toggle dark/light theme
    hl.dsp.exec_cmd(
        [[fish -c "set m (caelestia scheme get -m); if test $m = dark; caelestia scheme set -m light; else; caelestia scheme set -m dark; end"]]))

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

-- Focus navigation (IJKL + arrows)
hl.bind("SUPER + I",     hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J",     hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + K",     hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + L",     hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up",    hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + left",  hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + down",  hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))

-- Move window (SHIFT + IJKL + arrows)
hl.bind("SUPER + SHIFT + I",     hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J",     hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + K",     hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- Resize active window (ALT + IJKL + arrows)
hl.bind("SUPER + ALT + I", hl.dsp.window.resize(fn.resize_active_window(0, -10)),  { repeating = true })
hl.bind("SUPER + ALT + K", hl.dsp.window.resize(fn.resize_active_window(0, 10)),   { repeating = true })
hl.bind("SUPER + ALT + J", hl.dsp.window.resize(fn.resize_active_window(-10, 0)),  { repeating = true })
hl.bind("SUPER + ALT + L", hl.dsp.window.resize(fn.resize_active_window(10, 0)),   { repeating = true })
hl.bind("SUPER + ALT + left",  hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize(fn.resize_active_window(10, 0)),  { repeating = true })
hl.bind("SUPER + ALT + up",    hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + down",  hl.dsp.window.resize(fn.resize_active_window(0, 10)),  { repeating = true })

-- Window groups
hl.bind(vars.kbToggleGroup, hl.dsp.group.toggle())               -- Stack windows into tabs
hl.bind("ALT + TAB",   hl.dsp.group.next(), { repeating = true }) -- Cycle tab forward
hl.bind("ALT + grave", hl.dsp.group.prev(), { repeating = true }) -- Cycle tab backward

-- Gamemode submap
hl.bind("SUPER + G", function()
    hl.dispatch(hl.dsp.exec_cmd("notify-send -u critical 'GAMEMODE' 'ON: Keys Locked'"))
    hl.dispatch(hl.dsp.submap("gamemode"))
end)

hl.define_submap("gamemode", function()
    hl.bind("SUPER + G", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send -u low 'GAMEMODE' 'OFF'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
        { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        { repeating = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
    hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
end)

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
