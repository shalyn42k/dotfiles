-- custom/rules.lua — end4 риг: наши window-rules (приоритетны над ii-дефолтами).
-- Грузится ПОСЛЕ hyprland/rules.lua. Эталон: profiles/caelestia/hypr/hyprland/rules.lua.
-- Фокус: transparency-политика (убрать раздражающий переход при старте) +
-- спец-воркспейсы под наши бинды (keybinds.lua: SUPER+Z/X/C/V).

------------------------
---- Transparency ----
------------------------
-- Thunar: умеренная прозрачность
hl.window_rule({ match = { class = "(?i)thunar" }, opacity = "0.90 0.90" })

-- Без прозрачности Hyprland (цвето-критичные / нативная тема; override снимает
-- и общее правило шелла). Переход при старте раздражает.
hl.window_rule({ match = { class = "vesktop|discord|equibop" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "obsidian" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "feishin" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "com.ayugram.desktop" }, opacity = "1.0 override 1.0 override" })

-- Zen Browser
hl.window_rule({ match = { class = "^(zen-alpha)$" }, opacity = "0.85 0.85" })
hl.window_rule({ match = { class = "^(zen)$" }, opacity = "0.85 0.85" })

------------------------------
---- Спец-воркспейсы ----
------------------------------
-- Под бинды keybinds.lua: SUPER+Z(feishin)/X(vesktop)/C(obsidian)/V(AyuGram).
-- Имена спецов совпадают с caelestia (toggle_special("music"/…)).
hl.window_rule({ match = { class = "feishin" },              workspace = "special:music silent" })
hl.window_rule({ match = { class = "(?i)vesktop" },          workspace = "special:communication silent" })
hl.window_rule({ match = { class = "com.ayugram.desktop" },  workspace = "special:messanger silent" })
hl.window_rule({ match = { class = "obsidian" },             workspace = "special:todo silent", no_initial_focus = true })

------------------------
---- Floating ----
------------------------
hl.window_rule({ match = { title = "^(Discord)$" }, float = true })
hl.window_rule({ match = { class = "guifetch|yad|zenity|wev|blueman-manager|feh|imv|system-config-printer|nwg-look" }, float = true })
hl.window_rule({ match = { class = "org\\.gnome\\.FileRoller|file-roller" }, float = true })
hl.window_rule({ match = { float = true, xwayland = false }, center = true })
