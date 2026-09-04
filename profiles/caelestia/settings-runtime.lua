-- Настройки WM рига caelestia для применения в живую сессию (hyprctl eval).
--
-- Что сюда входит и почему: general (гапсы, рамки), decoration (скругление,
-- блюр, тени), group (вид вкладок в группах), misc. Всё это ставится один раз
-- при загрузке конфига, поэтому до появления этого файла на горячем свитче
-- оставались настройки того рига, в который ты ЗАШЁЛ, — вкладки, гапсы и
-- скругления не менялись вовсе.
--
-- НЕ входит: input (раскладка одинакова у ригов по контракту, переприменять
-- нечего), execs (демоны — забота session.sh), keybinds (свой слой, стадия
-- binds), rules (свой файл rules-runtime.lua), animations (свой файл).
--
-- package.path: файлы делают require("variables"); при свитче из другого рига
-- ~/.config/hypr уже указывает сюда, но модуль мог остаться в кеше от прежнего
-- рига — путь добавляем явно, как в rules-runtime.lua.
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/dotfiles/profiles/caelestia/hypr/?.lua"

local base = home .. "/dotfiles/profiles/caelestia/hypr/hyprland/"
for _, f in ipairs({ "general", "decoration", "group", "misc" }) do
    dofile(base .. f .. ".lua")
end
