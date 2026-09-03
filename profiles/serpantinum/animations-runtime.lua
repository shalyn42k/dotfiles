-- Анимации рига serpantinum для применения в живую сессию (hyprctl eval).
--
-- Зачем отдельный файл, а не dofile апстримовского config/settings.lua: там
-- анимации лежат вперемешку с general/decoration/input/misc, и перевыполнение
-- всего файла на горячем свитче переписало бы ещё и их. Здесь только то, что
-- относится к анимациям — ровно этот слой и меняется при переключении рига.
--
-- Без этого файла apply_rig_animations для рига был no-op, и после свитча
-- из caelestia оставались ЕГО анимации: своя кривая применялась только на
-- релогине, когда settings.lua выполнялся целиком. Выглядело это как «анимации
-- зависят от того, в какой риг зашёл».
--
-- Источник — profiles/serpantinum/shell/compositors/hyprland/config/settings.lua:44-54.
-- При обновлении сабмодуля сверить: если апстрим поменяет кривую или набор
-- leaf'ов, здесь останется старое, и риг будет анимироваться по-разному на
-- логине и на свитче.

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",             enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "layers",              enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersIn",            enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersOut",           enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "fade",                enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
