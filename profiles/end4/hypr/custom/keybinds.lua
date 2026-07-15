-- custom/keybinds.lua — end4 риг: порт КРОСС-РИГ КОНТРАКТА (KEYBINDS.md §2).
--
-- Грузится ПОСЛЕ hyprland/keybinds.lua (359 строк ii-дефолтов) — hyprland.lua
-- сорсит custom/ в конце. Стратегия: hl.unbind() конфликтных ii-комбо, затем
-- hl.bind() наших. Провайдер — hyprkcs (та же hl-API, что у caelestia).
-- Эталон: profiles/caelestia/hypr/hyprland/keybinds.lua.
--
-- ⚠ НЕ ВЕРИФИЦИРОВАНО статикой — домен без юнит-тестов. Проверка = Task 13
--   relogin в end4 + `hyprctl binds`. Открытые риски:
--   1. hl.unbind арг-форма (стаб размыт `...`); тут строка комбо, как в bind.
--   2. Если ре-бинд в hyprkcs НЕ стекается, а замещает — unbind избыточен (безвреден).

-- Дефолтный стаб end4 (редактировать этот файл) — оставлен.
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "Edit user keybinds" })

local home         = os.getenv("HOME")
local scripts      = home .. "/dotfiles/profiles/end4/hypr/scripts"
local wsaction     = scripts .. "/wsaction.fish"
local specialcycle = scripts .. "/specialcycle.fish"
local rigdo        = home .. "/dotfiles/bin/rigdo "

-- Относительный ресайз (end4 без hyprland.functions — инлайн из caelestia).
local function resize_active_window(x, y)
    local win = hl.get_active_window()
    if win and win.size then
        return { x = win.size.x * (x / 100), y = win.size.y * (y / 100), relative = true }
    end
    return { x = x, y = y, relative = true }
end

-- ─────────────────────────────────────────────────────────────────────────
-- UNBIND ii-дефолтов, чьё комбо занято нашим контрактом §2
-- ─────────────────────────────────────────────────────────────────────────
local unbinds = {
    "SUPER + Tab",              -- ii: overview        → нам: терминал (§2.4)
    "SUPER + V",                -- ii: clipboard/emoji → нам: мессенджер спец (§2.3)
    "SUPER + A",                -- ii: sidebarLeft     → нам: ws -1 (§2.3)
    "SUPER + B",                -- ii: sidebarLeft     → нам: rigdo battery (§2.1)
    "SUPER + N",                -- ii: sidebarRight    → нам: rigdo network (§2.1)
    "SUPER + K",                -- ii: osk             → нам: фокус вниз (§2.2)
    "SUPER + J",                -- ii: bar             → нам: фокус влево (§2.2)
    "SUPER + M",                -- ii: mediaControls   → нам: rigdo shell (§2.1)
    "SUPER + G",                -- ii: overlay         → нам: gamemode submap (§2.6)
    "SUPER + SHIFT + S",        -- ii: regionScreenshot→ нам: rigdo screenshot (§2.1)
    "SUPER + mouse:272",        -- ii: drag            → нам: move-to-ws -1 (§2.5)
    "SUPER + mouse:273",        -- ii: resize          → нам: move-to-ws +1 (§2.5)
    "SUPER + mouse:274",        -- ii: drag            → нам: (не используем)
}
for _, combo in ipairs(unbinds) do
    hl.unbind(combo)
end

-- ─────────────────────────────────────────────────────────────────────────
-- §2.1 Действия через rigdo (переживают горячий свитч)
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(home .. "/dotfiles/bin/dotprofile menu"))
hl.bind("SHIFT + TAB",       hl.dsp.exec_cmd(rigdo .. "launcher"))
hl.bind("SUPER + Y",         hl.dsp.exec_cmd(rigdo .. "wallpaper"))
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(rigdo .. "settings"))
hl.bind("SUPER + M",         hl.dsp.exec_cmd(rigdo .. "shell"))
hl.bind("SUPER + F1",        hl.dsp.exec_cmd(rigdo .. "lock"), { locked = true })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(rigdo .. "screenshot"))
hl.bind("SUPER + grave",     hl.dsp.exec_cmd(rigdo .. "clipboard"))
hl.bind("SUPER + B",         hl.dsp.exec_cmd(rigdo .. "battery"))
hl.bind("SUPER + N",         hl.dsp.exec_cmd(rigdo .. "network"))
hl.bind("SUPER + H",         hl.dsp.exec_cmd(rigdo .. "guide"))
hl.bind("SUPER + ALT + M",   hl.dsp.exec_cmd(rigdo .. "music"))
hl.bind("SUPER + ALT + S",   hl.dsp.exec_cmd(rigdo .. "calendar"))
hl.bind("SUPER + ALT + P",   hl.dsp.exec_cmd(rigdo .. "movies"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.2 Окна
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + Q",           hl.dsp.window.close())
hl.bind("SUPER + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + ALT + Space", hl.dsp.window.float())
hl.bind("SUPER + SHIFT + F",   hl.dsp.window.float())
hl.bind("SUPER + P",           hl.dsp.window.pin())

-- Фокус (только IJKL)
hl.bind("SUPER + I", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))

-- Двигать окно (SHIFT + IJKL)
hl.bind("SUPER + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Ресайз (ALT + IJKL)
hl.bind("SUPER + ALT + I", hl.dsp.window.resize(resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + K", hl.dsp.window.resize(resize_active_window(0, 10)),  { repeating = true })
hl.bind("SUPER + ALT + J", hl.dsp.window.resize(resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + L", hl.dsp.window.resize(resize_active_window(10, 0)),  { repeating = true })

-- Группы окон
hl.bind("ALT + Q",   hl.dsp.group.toggle())
hl.bind("ALT + TAB", hl.dsp.group.next(), { repeating = true })

-- ─────────────────────────────────────────────────────────────────────────
-- §2.3 Воркспейсы
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "+1" }))

-- Нумерованные 1..10 (мультимонитор через wsaction.fish)
for i = 1, 10 do
    local key = i % 10 -- 10 → клавиша 0
    hl.bind("SUPER + " .. key,         hl.dsp.exec_cmd(wsaction .. " workspace " .. i))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.exec_cmd(wsaction .. " movetoworkspace " .. i))
end

-- Спец-воркспейсы (scratchpad + app-специалы)
hl.bind("SUPER + S", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"special\")'"))
hl.bind("SUPER + Z",
    hl.dsp.exec_cmd([[pgrep -x feishin && hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")' || feishin]]))
hl.bind("SUPER + X",
    hl.dsp.exec_cmd([[pgrep -x vesktop && hyprctl dispatch 'hl.dsp.workspace.toggle_special("communication")' || vesktop]]))
hl.bind("SUPER + C",
    hl.dsp.exec_cmd([[pgrep -x obsidian && hyprctl dispatch 'hl.dsp.workspace.toggle_special("todo")' || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
hl.bind("SUPER + V",
    hl.dsp.exec_cmd([[pgrep -x AyuGram && hyprctl dispatch 'hl.dsp.workspace.toggle_special("messanger")' || AyuGram]]))
hl.bind("SUPER + SHIFT + X", hl.dsp.window.move({ workspace = "e+0" }))  -- вытащить из спец на текущий

-- Цикл спец-воркспейсов (Caps-hold = CTRL через keyd)
hl.bind("CTRL + J", hl.dsp.exec_cmd(specialcycle .. " prev"))
hl.bind("CTRL + L", hl.dsp.exec_cmd(specialcycle .. " next"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.4 Приложения (app2unit — как ilyamiro/caelestia)
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("app2unit -- foot"))
hl.bind("SUPER + W",   hl.dsp.exec_cmd("app2unit -- zen-browser"))
hl.bind("SUPER + R",   hl.dsp.exec_cmd("app2unit -- codium"))
hl.bind("SUPER + E",   hl.dsp.exec_cmd("app2unit -- thunar"))
hl.bind("SUPER + T",   hl.dsp.exec_cmd("app2unit -- hyprkcs"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.5 Мышь
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SHIFT + mouse:274", hl.dsp.window.drag(),   { mouse = true })
hl.bind("CTRL + mouse:274",  hl.dsp.window.resize(),  { mouse = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + mouse:273", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + SHIFT + mouse:273", hl.dsp.window.move({ workspace = "special:secret" }))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.6 Питание / gamemode
-- ─────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + ALT + Escape", hl.dsp.exec_cmd("systemctl poweroff"))

hl.bind("SUPER + G", function()
    hl.dispatch(hl.dsp.exec_cmd("notify-send -u critical 'GAMEMODE' 'ON: Keys Locked'"))
    hl.dispatch(hl.dsp.submap("gamemode"))
end)
hl.define_submap("gamemode", function()
    hl.bind("SUPER + G", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send -u low 'GAMEMODE' 'OFF'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    -- Громкость оставлена в gamemode (как caelestia)
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
end)

-- §2.7 XF86 железные клавиши: НЕ переопределяем — ii-дефолт держит громкость/
-- яркость через свой OSD (hyprland/keybinds.lua:40-46, qsIpcCall brightness/volume
-- + wpctl фолбэк). Дубль сломал бы OSD (как было в ilyamiro). Оставлено ii-нативным.

-- ─────────────────────────────────────────────────────────────────────────
-- §7 УНИКАЛЬНЫЕ end4-фичи (прямые quickshell-глобалы, риг-нативные)
-- ─────────────────────────────────────────────────────────────────────────
-- Аналоги caelestia-уникальных на ТЕ ЖЕ комбо (мышечная память §4):
hl.bind("SUPER + ALT + N",   hl.dsp.global("quickshell:toggleLightDark"))        -- тёмная/светлая
hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })  -- запись
hl.bind("SUPER + SHIFT + N", hl.dsp.global("quickshell:wallpaperSelectorRandom"))-- рандом обои

-- В освобождённые слоты §7 (SUPER+O свободен вне caelestia, SUPER+U — снят дубль):
hl.bind("SUPER + O", hl.dsp.global("quickshell:regionSearch"))  -- Google Lens
hl.bind("SUPER + U", hl.dsp.global("quickshell:regionOcr"))     -- OCR региона

-- Остальные end4-эксклюзивы ОСТАВЛЕНЫ на ii-нативных комбо (не unbind'ились):
--   emoji=SUPER+Period, panelFamily=CTRL+SUPER+P, session=CTRL+ALT+Delete,
--   wallpaperSelector=CTRL+SUPER+T, screenTranslate=SUPER+SHIFT+T,
--   overview=SUPER+Tab был unbind (терминал) → доступен через SUPER+SHIFT+D менюлибо
--   добавить в свободный слот при желании. OSK/overlay/bar — ii-дефолты сняты
--   (K/G/J заняты §2); при нужде повесить на SUPER+CTRL+стрелки.
