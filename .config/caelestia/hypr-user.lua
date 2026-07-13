-- Переключатель риг-профилей (см. dotfiles/docs/specs/2026-07-13-*.md)
-- Дубль бинда из dotfiles/.config/hypr-shared/binds.conf — hyprkcs не умеет
-- source= для hyprlang-файлов; менять В ОБОИХ местах.
local dot = os.getenv("HOME") .. "/dotfiles/bin/"
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(dot .. "dotprofile menu"))

-- Риг-зависимые действия через rigdo: работают и после горячего свитча
-- в ilyamiro (диспетчер смотрит profiles/active). Те же комбо, что в
-- binds-ilyamiro.conf.
hl.bind("SUPER + Y",           hl.dsp.exec_cmd(dot .. "rigdo wallpaper"))
hl.bind("SUPER + U",           hl.dsp.exec_cmd(dot .. "rigdo launcher"))
hl.bind("SUPER + SHIFT + O",   hl.dsp.exec_cmd(dot .. "rigdo settings"))
hl.bind("SUPER + ALT + M",     hl.dsp.exec_cmd(dot .. "rigdo music"))
hl.bind("SUPER + ALT + S",     hl.dsp.exec_cmd(dot .. "rigdo calendar"))
hl.bind("SUPER + ALT + P",     hl.dsp.exec_cmd(dot .. "rigdo movies"))

-- Его личные виджеты (B батарея, N сеть, H гайд) — свободны в caelestia,
-- работают после горячего свитча на ilyamiro.
hl.bind("SUPER + B",           hl.dsp.exec_cmd(dot .. "rigdo battery"))
hl.bind("SUPER + N",           hl.dsp.exec_cmd(dot .. "rigdo network"))
hl.bind("SUPER + H",           hl.dsp.exec_cmd(dot .. "rigdo guide"))
