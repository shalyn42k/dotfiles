local scheme = require("scheme.current")
local vars   = require("variables")

-- Рамка вокруг группы — своя у рига, берётся из тех же переменных, что и рамка
-- обычного окна. Плашка вкладок — общая форма, см. .config/hypr-shared/groupbar.lua.
hl.config({
    group = {
        col = {
            border_active          = vars.activeWindowBorderColour,
            border_inactive        = vars.inactiveWindowBorderColour,
            border_locked_active   = vars.activeWindowBorderColour,
            border_locked_inactive = vars.inactiveWindowBorderColour,
        },
    },
})

-- Абсолютный путь, как у rigbinds/contract-binds в hypr/hyprland.lua: package.path
-- этого рига указывает внутрь profiles/caelestia/hypr, а общий файл лежит вне его.
local apply_groupbar = dofile(os.getenv("HOME") .. "/.config/hypr-shared/groupbar.lua")

apply_groupbar({
    active          = "rgba(" .. scheme.primary .. "d4)",
    inactive        = "rgba(" .. scheme.outline .. "d4)",
    locked_inactive = "rgba(" .. scheme.secondary .. "d4)",
    text            = "rgb(" .. scheme.onPrimary .. ")",
})
