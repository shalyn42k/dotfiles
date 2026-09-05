-- Правила рига caelestia для применения в живую lua-сессию (hyprctl eval).
-- rules.lua делает require("variables"); package.path для него ставит конфиг
-- caelestia при старте. При хот-свитче из другого рига этого пути нет — чиним сами.
-- Свой каталог, а не путь через $HOME: риг обязан работать там, куда его
-- положили, включая отдельный репозиторий.
local rigdir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."

local home = os.getenv("HOME")
package.path = package.path .. ";" .. rigdir .. "/hypr/?.lua"
dofile(rigdir .. "/hypr/hyprland/rules.lua")
