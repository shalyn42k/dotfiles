# legacy-hyprlang

Old hyprlang (`.conf`) Hyprland config, replaced by the Lua config in `../`
(commit `5b8f082`, migration to Lua provider). Kept for reference — some binds
here aren't ported yet and may be worth re-adding to the `.lua` files later
(see `hyprland/keybinds.conf`, including the commented `DISABLED / NOT WORKING`
block at the bottom).

NOT loaded by Hyprland: with `../hyprland.lua` present, Hyprland uses the Lua
config and ignores `.conf`. These files no longer act as a fallback from this
sub-folder. To roll back to hyprlang, restore them to `../` (or `git checkout`
the pre-migration commit `ff70707`).
