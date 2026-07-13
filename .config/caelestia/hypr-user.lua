-- Переключатель риг-профилей (см. dotfiles/docs/specs/2026-07-13-*.md)
-- Дубль бинда из dotfiles/.config/hypr-shared/binds.conf — hyprkcs не умеет
-- source= для hyprlang-файлов; менять В ОБОИХ местах.
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/dotfiles/bin/dotprofile menu"))
