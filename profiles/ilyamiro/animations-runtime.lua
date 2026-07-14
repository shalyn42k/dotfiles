-- Анимации рига ilyamiro для применения в живую lua-сессию (hyprctl eval).
-- Перевод блока animations из profiles/ilyamiro/hypr/config/settings.conf
-- (автогенерён из settings.json — при изменении его настроек обновить тут).
-- Листья задаются явно: ветки не перекрывают листовые оверрайды другого рига.
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windowsIn",           enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",          enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",         enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "layersIn",            enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersOut",           enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "fadeLayers",          enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "fade",                enabled = true, speed = 5, bezier = "myBezier" })
-- fadeIn выключен: прозрачные окна иначе «доезжают» до целевой альфы
-- пол-секунды после открытия, а нужен финальный вид с первого кадра
hl.animation({ leaf = "fadeIn",              enabled = false })
hl.animation({ leaf = "fadeDim",             enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "border",              enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces",          enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
