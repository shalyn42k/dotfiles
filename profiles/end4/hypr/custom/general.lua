-- custom/general.lua — end4 оверрайды поверх hyprland/general.lua (переживают апдейт ii).
--
-- Раскладка + переключение языка. ii-дефолт general.lua ставит kb_layout="us" БЕЗ
-- второй раскладки и БЕЗ kb_options → привычный SUPER+SPACE не переключал (нечего).
-- Зеркалим caelestia (input.lua): pl/ru, тумблер по SUPER+SPACE. hl.config мержит
-- в существующий input (numlock/repeat/touchpad из ii-дефолта сохраняются).
hl.config({
    input = {
        kb_layout  = "pl, ru",
        kb_options = "grp:win_space_toggle",
    },
})
