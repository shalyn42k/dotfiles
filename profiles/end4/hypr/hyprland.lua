-- ── Реестр владения биндами ──────────────────────────────────────────────
-- ПЕРВОЙ строкой: всё, что забайндится до неё, останется без хендла и станет
-- несносимым при переключении рига.
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/rigbinds.lua")
__rig.begin("end4")

-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Custom configurations --
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
    require("custom.rules")
end
if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
    require("custom.keybinds")
end

-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    require("workspaces")
end
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    require("monitors")
end

-- Shell overrides --
require("hyprland.shellOverrides.main")

-- ── Кросс-риг контракт ───────────────────────────────────────────────────
-- ПОСЛЕДНИМ: снимает комбу перед своим биндом, поэтому обязан идти после
-- набора рига. Владелец "shared" — переживает переключение ригов.
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
