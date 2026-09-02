-- ── Реестр владения биндами ──────────────────────────────────────────────
-- ПЕРВОЙ строкой: всё, что забайндится до неё, останется без хендла и станет
-- несносимым при переключении рига.
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/rigbinds.lua")
__rig.begin("serpantinum")

local rig = os.getenv("HOME") .. "/dotfiles/profiles/serpantinum"

-- Конфиг композитора апстрима написан тем же hl-API, что у нас, поэтому берём
-- его как базу вместо порта. Резолвим require из вендоренной копии.
package.path = rig .. "/shell/compositors/hyprland/?.lua;" .. package.path

require("config/variables")
require("config/env")
require("config/autostart")   -- нужен: поднимает serpantinumd
-- Мониторы берём апстримовые как есть: их config/monitors.lua — тот же
-- generic catch-all (output="", mode="preferred", position="auto", scale=1),
-- что и блок caelestia (profiles/caelestia/hypr/hyprland.lua:60-66). Свой
-- файл был бы дословным дублем этого блока, поэтому не заводим его.
require("config/monitors")
require("config/settings")
require("config/keybinds")

-- Наше поверх их базы: наши бинды и правила.
dofile(rig .. "/hypr/overrides.lua")

-- ── Кросс-риг контракт ───────────────────────────────────────────────────
-- ПОСЛЕДНИМ: снимает комбу перед своим биндом, поэтому обязан идти после
-- набора рига. Владелец "shared" — переживает переключение ригов.
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
