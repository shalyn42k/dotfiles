-- Настройки WM рига serpantinum для применения в живую сессию (hyprctl eval).
--
-- Апстрим держит general/decoration/input/misc ОДНИМ вызовом hl.config в
-- config/settings.lua, поэтому переприменяем файл целиком — а следом наш
-- input.lua, иначе вернулась бы его единственная раскладка "us" и смена языка
-- снова перестала бы работать. Тот же порядок, что в hypr/hyprland.lua.
--
-- Побочно файл переприменит и анимации (они там же, строки 44-54). Это
-- безвредно: значения те же, что в animations-runtime.lua.
local rig = os.getenv("HOME") .. "/dotfiles/profiles/serpantinum"

-- require внутри их конфига резолвится от каталога compositors/hyprland
package.path = rig .. "/shell/compositors/hyprland/?.lua;" .. package.path

dofile(rig .. "/shell/compositors/hyprland/config/settings.lua")
dofile(rig .. "/hypr/input.lua")
