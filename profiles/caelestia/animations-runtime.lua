-- Анимации рига caelestia для применения в живую lua-сессию (hyprctl eval).
-- Сам конфиг standalone — просто перевыполняем его.
-- Свой каталог, а не путь через $HOME: риг обязан работать там, куда его
-- положили, включая отдельный репозиторий.
local rigdir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."

dofile(rigdir .. "/hypr/hyprland/animations.lua")
