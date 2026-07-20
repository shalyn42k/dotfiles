-- Правила рига caelestia для применения в живую lua-сессию (hyprctl eval).
-- rules.lua делает require("variables"); package.path для него ставит конфиг
-- caelestia при старте. При хот-свитче из end4 этого пути нет — чиним сами.
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/dotfiles/profiles/caelestia/hypr/?.lua"
dofile(home .. "/dotfiles/profiles/caelestia/hypr/hyprland/rules.lua")
