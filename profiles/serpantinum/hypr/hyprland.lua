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

-- Наше поверх их базы. input отдельным файлом — его переприменяет
-- settings-runtime.lua на горячем свитче, а overrides.lua туда нельзя:
-- ре-бинд стекается и наплодил бы дубли.
dofile(rig .. "/hypr/input.lua")
dofile(rig .. "/hypr/overrides.lua")

-- Шелл рига по АБСОЛЮТНОМУ пути.
--
-- config/autostart апстрима зовёт `serpantinumd start` голым именем, то есть
-- полагается на PATH. На логине это единственное, что поднимает шелл:
-- start-hyprland-profile вызывает `dotprofile switch <риг> --links-only`, а
-- --links-only возвращается ДО стадии daemons, поэтому session.sh при входе
-- не отрабатывает вовсе (он отрабатывает только на горячем свитче).
-- Промахнись PATH — и риг поднимется без бара, без способа что-либо нажать.
--
-- Симлинки в ~/.local/bin поставлены (bootstrap их делает), но полагаться на
-- содержимое PATH внутри сессии композитора не стоит. Двойного старта не
-- будет: serpantinumd держит /tmp/serpantinumd.pid и проверяет его.
hl.on("hyprland.start", function()
    hl.exec_cmd(rig .. "/shell/bin/serpantinumd start")
end)

-- ── Кросс-риг контракт ───────────────────────────────────────────────────
-- ПОСЛЕДНИМ: снимает комбу перед своим биндом, поэтому обязан идти после
-- набора рига. Владелец "shared" — переживает переключение ригов.
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
