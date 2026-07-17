-- Правила рига end4 для применения в живую lua-сессию (hyprctl eval).
-- custom/rules.lua standalone (без require) — просто перевыполняем.
local home = os.getenv("HOME")
dofile(home .. "/dotfiles/profiles/end4/hypr/custom/rules.lua")
