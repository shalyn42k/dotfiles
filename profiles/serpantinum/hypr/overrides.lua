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
rebind("SUPER + ALT + Space", hl.dsp.window.float())
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
    rebind("SUPER + " .. key,         hl.dsp.workspace(tostring(i)))
    rebind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Спец-воркспейсы (scratchpad). Имя "special" — то же, что использует
-- гест caelestia/hypr/hyprland/gestures.lua:15 (workspace_name = "special").
rebind("SUPER + S", hl.dsp.workspace.toggle_special("special"))

-- Приложения-специалы: тоггл, если уже запущено, иначе запуск. Матчим по
-- КЛАССУ окна hyprctl clients, а не по имени процесса — pgrep -x не видит
-- Electron-приложения (класс окна не совпадает с именем процесса), это
-- ровно баг, исправленный в caelestia коммитом 1853895
-- ("fix(caelestia): match special-workspace apps by window class").
-- feishin — тоже Electron (тот же класс проблемы, что vesktop/obsidian),
-- поэтому матчим по классу, а не pgrep -x: caelestia/hypr/hyprland/keybinds.lua
-- всё ещё держит там pgrep -x и это НЕ прецедент — та строка не была
-- проверена, просто не попала под ревью. AyuGram — нативный Qt/C++-форт
-- Telegram Desktop, там процесс реально совпадает с классом, pgrep -x верен.
-- Строка класса "feishin" взята из caelestia/hypr/hyprland/rules.lua:29,62
-- (там matchится `class = "feishin"` для правил прозрачности/воркспейса) —
-- но НЕ подтверждена на живой сессии serpantinum; сверить при приёмке рига.
rebind("SUPER + Z",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class: feishin' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")' || feishin]]))
rebind("SUPER + X",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class: vesktop' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("communication")' || vesktop]]))
rebind("SUPER + C",
    hl.dsp.exec_cmd(
        [[hyprctl clients | grep -qi 'class: obsidian' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("todo")' || obsidian "obsidian://open?vault=Shalyn_Vault"]]))
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
