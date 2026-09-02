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

-- §2.2 Окна
rebind("SUPER + Q",           hl.dsp.window.close())
rebind("SUPER + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
rebind("SUPER + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
rebind("SUPER + ALT + Space", hl.dsp.window.float())
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

-- §2.3 Воркспейсы
rebind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
for i = 1, 10 do
    local key = i % 10 -- 10 → клавиша 0
    rebind("SUPER + " .. key,         hl.dsp.workspace(tostring(i)))
    rebind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end
