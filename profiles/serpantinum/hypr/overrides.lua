-- overrides.lua — наши бинды и правила поверх базы serpantinum.
--
-- Грузится ПОСЛЕ config/keybinds апстрима. Ре-бинд в hyprkcs стекается, а не
-- замещает (замерено на живой сессии 2026-09-02: 99 -> 187), поэтому каждый наш
-- бинд снимает комбу перед тем как повесить своё. Контракт §2.1 здесь НЕ
-- дублируется — он живёт в .config/hypr-shared/contract-binds.lua и грузится
-- последним.
local function rebind(keys, dispatcher, opts)
    hl.unbind(keys)
    return hl.bind(keys, dispatcher, opts)
end

local home    = os.getenv("HOME")
local scripts = home .. "/dotfiles/profiles/serpantinum/hypr/scripts"

-- Относительный ресайз активного окна на x%/y% от его текущего размера.
-- serpantinum не вендорит аналог caelestia/hypr/hyprland/functions.lua,
-- поэтому берём форму хелпера как есть — inline здесь.
local function resize_active_window(x, y)
    local win = hl.get_active_window()
    if win and win.size then
        return { x = win.size.x * (x / 100), y = win.size.y * (y / 100), relative = true }
    end
    return { x = x, y = y, relative = true }
end

-- §2.2 Окна
rebind("SUPER + Q",           hl.dsp.window.close())
rebind("SUPER + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
rebind("SUPER + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
rebind("SUPER + ALT + space", hl.dsp.window.float())
rebind("SUPER + SHIFT + F",   hl.dsp.window.float())      -- та же мнемоника F, что у caelestia
rebind("SUPER + P",           hl.dsp.window.pin())

-- Фокус (IJKL)
rebind("SUPER + I", hl.dsp.focus({ direction = "up" }))
rebind("SUPER + J", hl.dsp.focus({ direction = "left" }))
rebind("SUPER + K", hl.dsp.focus({ direction = "down" }))
rebind("SUPER + L", hl.dsp.focus({ direction = "right" }))

-- Двигать окно (SHIFT + IJKL)
rebind("SUPER + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
rebind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
rebind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
rebind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Ресайз активного окна (ALT + IJKL)
rebind("SUPER + ALT + I", hl.dsp.window.resize(resize_active_window(0, -10)), { repeating = true })
rebind("SUPER + ALT + K", hl.dsp.window.resize(resize_active_window(0, 10)),  { repeating = true })
rebind("SUPER + ALT + J", hl.dsp.window.resize(resize_active_window(-10, 0)), { repeating = true })
rebind("SUPER + ALT + L", hl.dsp.window.resize(resize_active_window(10, 0)),  { repeating = true })

-- Группы окон (вкладки)
rebind("ALT + Q",   hl.dsp.group.toggle())
rebind("ALT + TAB", hl.dsp.group.next(), { repeating = true })

-- §2.3 Воркспейсы
rebind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
rebind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "+1" }))
for i = 1, 10 do
    local key = i % 10 -- 10 → клавиша 0
    -- hl.dsp.workspace — ПРОСТРАНСТВО ИМЁН (change_id/move/rename/
    -- swap_monitors/toggle_special), а не функция; вызов его как функции роняет
    -- весь файл, а с ним и всё, что подключается после. Переход на номерной
    -- воркспейс — тот же focus, что и относительный выше.
    rebind("SUPER + " .. key,         hl.dsp.focus({ workspace = tostring(i) }))
    rebind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Спец-воркспейсы (scratchpad). Имя "special" — наше, внутреннее для рига.
-- У caelestia скретчпад называется "specialws" и тогглится через его CLI
-- (`caelestia toggle specialws`), которого здесь нет. Имя видно только внутри
-- рига, и specialcycle.fish этого же профиля перечисляет ровно его, поэтому
-- расхождение с caelestia безвредно. Комба SUPER+S одинаковая — это и есть
-- то, что требует контракт.
rebind("SUPER + S", hl.dsp.workspace.toggle_special("special"))

-- Приложения-специалы: тоггл, если уже запущено, иначе запуск. Матчим по
-- КЛАССУ окна hyprctl clients, а не по имени процесса — pgrep -x не видит
-- Electron-приложения (класс окна не совпадает с именем процесса), это
-- ровно баг, исправленный в caelestia коммитом 1853895
-- ("fix(caelestia): match special-workspace apps by window class").
-- feishin матчим по классу для единообразия с vesktop/obsidian, а НЕ потому
-- что pgrep у него сломан: замерено 2026-09-02 на живой сессии — `pgrep -x
-- feishin` процесс находит, то есть строка в caelestia/keybinds.lua:44
-- исправна. Класс устойчивее к переименованию бинаря, поэтому здесь класс.
-- Значение "feishin" сверено с caelestia/hypr/hyprland/rules.lua:29,62, где
-- по этому же классу висят правила прозрачности и воркспейса.
-- AyuGram — нативный Qt/C++-форк Telegram Desktop, имя процесса совпадает
-- с классом, pgrep -x там верен и менять его не на что.
rebind("SUPER + Z",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class: feishin' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")' || feishin]]))
rebind("SUPER + X",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class: vesktop' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("communication")' || vesktop]]))
rebind("SUPER + C",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class:.*obsidian' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("todo")' || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
rebind("SUPER + V",
    hl.dsp.exec_cmd(
        [[pgrep -x AyuGram && hyprctl dispatch 'hl.dsp.workspace.toggle_special("messanger")' || AyuGram]]))

-- Вытащить окно из любого спец-воркспейса на текущий обычный
rebind("SUPER + SHIFT + X", hl.dsp.window.move({ workspace = "e+0" }))

-- Цикл спец-воркспейсов prev/next. specialcycle.fish не завязан на caelestia
-- (только hyprctl/jq), поэтому набор serpantinum держит свою копию со своим
-- (более коротким) списком специалов вместо шаринга рискованной кросс-риг
-- зависимости на чужой profiles/caelestia/hypr/scripts.
rebind("CTRL + J", hl.dsp.exec_cmd(scripts .. "/specialcycle.fish prev"))
rebind("CTRL + L", hl.dsp.exec_cmd(scripts .. "/specialcycle.fish next"))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.4 Приложения
-- ─────────────────────────────────────────────────────────────────────────
-- Три комбо апстрим занимает под своё, и это прямое нарушение контракта:
-- одна клавиша означала бы в двух ригах разное. Перевешиваем на контрактное
-- (значения — profiles/caelestia/hypr/variables.lua):
--   SUPER+E  ii: nautilus                  -> thunar
--   SUPER+R  ii: serpantinum reload        -> codium
--   SUPER+W  ii: msg toggle wallpaper      -> zen-browser
-- Обои у serpantinum остаются на контрактном SUPER+Y через rigdo, рестарт
-- шелла — на контрактном SUPER+M, так что ничего из его функций не теряется.
--
-- app2unit — как у caelestia: приложение уезжает в свой systemd-скоуп и не
-- умирает вместе с процессом, который его запустил.
rebind("SUPER + TAB", hl.dsp.exec_cmd("app2unit -- kitty"))
rebind("SUPER + W",   hl.dsp.exec_cmd("app2unit -- zen-browser"))
rebind("SUPER + R",   hl.dsp.exec_cmd("app2unit -- codium"))
rebind("SUPER + E",   hl.dsp.exec_cmd("app2unit -- thunar"))
rebind("SUPER + T",   hl.dsp.exec_cmd("app2unit -- hyprkcs"))

-- SUPER+SPACE переключает раскладку — это xkb-опция grp:win_space_toggle из
-- input.lua, и обрабатывает её xkb, а не биндер (в `hyprctl binds` её не
-- видно). Апстрим вешает на ту же комбу playerctl play-pause, и срабатывали
-- оба: смена языка заодно снимала плеер с паузы. В caelestia раскладка сидит
-- на этом же комбо и одна, так что расхождение — то самое «одна клавиша
-- значит в ригах разное», ради которого написан блок выше.
-- rebind здесь не подходит: своего действия у комбы нет, xkb справляется сам.
-- play-pause не теряется — апстрим тут же вешает XF86AudioPlay/XF86AudioPause.
hl.unbind("SUPER + SPACE")

-- ─────────────────────────────────────────────────────────────────────────
-- §2.5 Мышь
-- ─────────────────────────────────────────────────────────────────────────
-- { mouse = true } обязателен для drag/resize — без него бинд не получает
-- зажатую кнопку и жест не работает.
rebind("SHIFT + mouse:274", hl.dsp.window.drag(),   { mouse = true })
rebind("CTRL + mouse:274",  hl.dsp.window.resize(), { mouse = true })
rebind("SUPER + SHIFT + mouse:272", hl.dsp.window.move({ workspace = "e+0" }))
rebind("SUPER + SHIFT + mouse:273", hl.dsp.window.move({ workspace = "special:secret" }))

-- ─────────────────────────────────────────────────────────────────────────
-- §2.6 Питание / gamemode
-- ─────────────────────────────────────────────────────────────────────────
rebind("SUPER + ALT + Escape", hl.dsp.exec_cmd("systemctl poweroff"))

-- Gamemode: сабмап, который лочит всё, кроме громкости. Смысл в том, что в
-- игре случайный SUPER+Q не закрывает окно. Выход — тем же SUPER+G.
-- Громкость внутри сабмапа переопределяется явно: сабмап отменяет ВСЕ бинды
-- сессии, включая XF86, и без этих четырёх строк регулятор в игре умрёт.
rebind("SUPER + G", function()
    hl.dispatch(hl.dsp.exec_cmd("notify-send -u critical 'GAMEMODE' 'ON: Keys Locked'"))
    hl.dispatch(hl.dsp.submap("gamemode"))
end)

hl.define_submap("gamemode", function()
    hl.bind("SUPER + G", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send -u low 'GAMEMODE' 'OFF'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("XF86AudioRaiseVolume",
        hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
    hl.bind("XF86AudioLowerVolume",
        hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
    hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
end)
