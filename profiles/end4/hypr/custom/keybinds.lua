-- custom/keybinds.lua — end4 риг: порт КРОСС-РИГ КОНТРАКТА (KEYBINDS.md §2).
--
-- Грузится ПОСЛЕ hyprland/keybinds.lua (359 строк ii-дефолтов) — hyprland.lua
-- сорсит custom/ в конце. Провайдер — hyprkcs (та же hl-API, что у caelestia).
-- Эталон: profiles/caelestia/hypr/hyprland/keybinds.lua.
--
-- Открытый риск №2 из прежней шапки ЗАКРЫТ замером на живой сессии 2026-09-02:
-- ре-бинд НЕ замещает, а СТЕКАЕТСЯ (повторная загрузка набора: 99 -> 187
-- биндов). Значит перебить ii-дефолт, не сняв его, нельзя: срабатывают оба
-- действия. Ручной список unbind'ов ниже покрывал 13 комбо из 46 занятых —
-- на остальных 33 (SUPER+Q, SUPER+1..0, SUPER+O и др.) в сессии end4 тихо
-- выполнялись обе команды.
--
-- Поэтому каждый НАШ бинд ставится через rebind(): снять комбу, затем повесить
-- своё. Инвариант проверяется тестом
-- tests/rig_keybinds_test.lua «every combo custom/ overrides was unbound first».
local function rebind(keys, dispatcher, opts)
    hl.unbind(keys)
    return hl.bind(keys, dispatcher, opts)
end

-- Дефолтный стаб end4 (редактировать этот файл) — оставлен.
rebind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
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
-- §2.2 Окна
-- ─────────────────────────────────────────────────────────────────────────
rebind("SUPER + Q",           hl.dsp.window.close())
rebind("SUPER + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
rebind("SUPER + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
rebind("SUPER + ALT + Space", hl.dsp.window.float())
rebind("SUPER + SHIFT + F",   hl.dsp.window.float())
rebind("SUPER + P",           hl.dsp.window.pin())

-- Фокус (только IJKL)
rebind("SUPER + I", hl.dsp.focus({ direction = "up" }))
rebind("SUPER + J", hl.dsp.focus({ direction = "left" }))
rebind("SUPER + K", hl.dsp.focus({ direction = "down" }))
rebind("SUPER + L", hl.dsp.focus({ direction = "right" }))

-- Двигать окно (SHIFT + IJKL)
rebind("SUPER + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
rebind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
rebind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
rebind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Ресайз (ALT + IJKL)
rebind("SUPER + ALT + I", hl.dsp.window.resize(resize_active_window(0, -10)), { repeating = true })
rebind("SUPER + ALT + K", hl.dsp.window.resize(resize_active_window(0, 10)),  { repeating = true })
rebind("SUPER + ALT + J", hl.dsp.window.resize(resize_active_window(-10, 0)), { repeating = true })
rebind("SUPER + ALT + L", hl.dsp.window.resize(resize_active_window(10, 0)),  { repeating = true })

-- Группы окон
rebind("ALT + Q",   hl.dsp.group.toggle())
rebind("ALT + TAB", hl.dsp.group.next(), { repeating = true })

-- ─────────────────────────────────────────────────────────────────────────
-- §2.3 Воркспейсы
-- ─────────────────────────────────────────────────────────────────────────
rebind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
rebind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "+1" }))

-- Нумерованные 1..10 (мультимонитор через wsaction.fish)
for i = 1, 10 do
    local key = i % 10 -- 10 → клавиша 0
    rebind("SUPER + " .. key,         hl.dsp.exec_cmd(wsaction .. " workspace " .. i))
    rebind("SUPER + SHIFT + " .. key, hl.dsp.exec_cmd(wsaction .. " movetoworkspace " .. i))
end

-- Спец-воркспейсы (scratchpad + app-специалы)
rebind("SUPER + S", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"special\")'"))
rebind("SUPER + Z",
    hl.dsp.exec_cmd([[pgrep -x feishin && hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")' || feishin]]))
rebind("SUPER + X",
    hl.dsp.exec_cmd([[pgrep -x vesktop && hyprctl dispatch 'hl.dsp.workspace.toggle_special("communication")' || vesktop]]))
rebind("SUPER + C",
    hl.dsp.exec_cmd([[pgrep -x obsidian && hyprctl dispatch 'hl.dsp.workspace.toggle_special("todo")' || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
rebind("SUPER + V",
    hl.dsp.exec_cmd([[pgrep -x AyuGram && hyprctl dispatch 'hl.dsp.workspace.toggle_special("messanger")' || AyuGram]]))
rebind("SUPER + SHIFT + X", hl.dsp.window.move({ workspace = "e+0" }))  -- вытащить из спец на текущий

-- Цикл спец-воркспейсов (Caps-hold = CTRL через keyd)
rebind("CTRL + J", hl.dsp.exec_cmd(specialcycle .. " prev"))
rebind("CTRL + L", hl.dsp.exec_cmd(specialcycle .. " next"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.4 Приложения (app2unit — как ilyamiro/caelestia)
-- ─────────────────────────────────────────────────────────────────────────
rebind("SUPER + TAB", hl.dsp.exec_cmd("app2unit -- foot"))
rebind("SUPER + W",   hl.dsp.exec_cmd("app2unit -- zen-browser"))
rebind("SUPER + R",   hl.dsp.exec_cmd("app2unit -- codium"))
rebind("SUPER + E",   hl.dsp.exec_cmd("app2unit -- thunar"))
rebind("SUPER + T",   hl.dsp.exec_cmd("app2unit -- hyprkcs"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.5 Мышь
-- ─────────────────────────────────────────────────────────────────────────
rebind("SHIFT + mouse:274", hl.dsp.window.drag(),   { mouse = true })
rebind("CTRL + mouse:274",  hl.dsp.window.resize(),  { mouse = true })
rebind("SUPER + mouse:272", hl.dsp.window.move({ workspace = "-1" }))
rebind("SUPER + mouse:273", hl.dsp.window.move({ workspace = "+1" }))
rebind("SUPER + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "e+0" }))
rebind("SUPER + SHIFT + mouse:273", hl.dsp.window.move({ workspace = "special:secret" }))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.6 Питание / gamemode
-- ─────────────────────────────────────────────────────────────────────────
rebind("SUPER + ALT + Escape", hl.dsp.exec_cmd("systemctl poweroff"))

rebind("SUPER + G", function()
    hl.dispatch(hl.dsp.exec_cmd("notify-send -u critical 'GAMEMODE' 'ON: Keys Locked'"))
    hl.dispatch(hl.dsp.submap("gamemode"))
end)
hl.define_submap("gamemode", function()
    rebind("SUPER + G", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send -u low 'GAMEMODE' 'OFF'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    -- Громкость оставлена в gamemode (как caelestia)
    rebind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
    rebind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
    rebind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
end)

-- §2.7 XF86 железные клавиши: НЕ переопределяем — ii-дефолт держит громкость/
-- яркость через свой OSD (hyprland/keybinds.lua:40-46, qsIpcCall brightness/volume
-- + wpctl фолбэк). Дубль сломал бы OSD (как было в ilyamiro). Оставлено ii-нативным.

-- ─────────────────────────────────────────────────────────────────────────
-- §7 УНИКАЛЬНЫЕ end4-фичи (прямые quickshell-глобалы, риг-нативные)
-- ─────────────────────────────────────────────────────────────────────────
-- Аналоги caelestia-уникальных на ТЕ ЖЕ комбо (мышечная память §4):
rebind("SUPER + ALT + N",   hl.dsp.global("quickshell:toggleLightDark"))        -- тёмная/светлая
rebind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })  -- запись
rebind("SUPER + SHIFT + N", hl.dsp.global("quickshell:wallpaperSelectorRandom"))-- рандом обои

-- В освобождённые слоты §7 (SUPER+O свободен вне caelestia, SUPER+U — снят дубль):
rebind("SUPER + O", hl.dsp.global("quickshell:regionSearch"))  -- Google Lens
rebind("SUPER + U", hl.dsp.global("quickshell:regionOcr"))     -- OCR региона

-- Остальные end4-эксклюзивы ОСТАВЛЕНЫ на ii-нативных комбо (не unbind'ились):
--   emoji=SUPER+Period, panelFamily=CTRL+SUPER+P, session=CTRL+ALT+Delete,
--   wallpaperSelector=CTRL+SUPER+T, screenTranslate=SUPER+SHIFT+T,
--   overview=SUPER+Tab был unbind (терминал) → доступен через SUPER+SHIFT+D менюлибо
--   добавить в свободный слот при желании. OSK/overlay/bar — ii-дефолты сняты
--   (K/G/J заняты §2); при нужде повесить на SUPER+CTRL+стрелки.
