-- Вид плашки вкладок (group.groupbar) — общий для всех ригов.
--
-- ALT+Q собирает окна в группу, и Hyprland рисует над ними плашку. Её форму
-- (шрифт, высота, гапсы, градиенты) держим здесь одну на оба рига: вкладки
-- обязаны ощущаться одинаково, различаться им положено только цветом.
--
-- Почему отдельный файл, а не по копии на риг. group.groupbar — единственная
-- настройка группы, которую свитч НЕ переприменяет сам: apply_rig_colors в
-- bin/dotprofile шлёт только group.col.border_* (строки 101-104), плашку не
-- трогает. Пока её задавал один caelestia, достаточно было зайти в него, чтобы
-- вкладки остались его — уже внутри serpantinum и до перезапуска Hyprland.
-- Лечится не тем, что кто-то ещё её задаёт, а тем, что её задают ВСЕ.
--
-- Подключается ДВАЖДЫ у каждого рига, и обе точки обязательны:
--   * hypr/hyprland.lua      — логин (settings-runtime при входе не бежит:
--                              start-hyprland-profile зовёт switch --links-only,
--                              а тот возвращается до стадии settings);
--   * settings-runtime.lua   — горячий свитч (hyprctl eval).
--
-- Возвращает функцию, а не применяет само: цвета у ригов лежат по-разному
-- (caelestia — таблица scheme/current.lua, serpantinum — $-переменные в
-- hypr/colors.conf), и общий файл не должен знать про оба формата.
--
-- c = { active, inactive, locked_inactive, text } — готовые строки rgba()/rgb().
return function(c)
    hl.config({
        group = {
            groupbar = {
                font_family               = "JetBrains Mono NF",
                font_size                 = 15,
                gradients                 = true,
                gradient_round_only_edges = false,
                gradient_rounding         = 5,
                height                    = 25,
                indicator_height          = 0,
                gaps_in                   = 3,
                gaps_out                  = 3,
                text_color                = c.text,
                col                       = {
                    active          = c.active,
                    inactive        = c.inactive,
                    -- locked_active намеренно равен active: залоченная группа
                    -- отличается от обычной поведением (новое окно не влезает
                    -- внутрь), а не цветом активной вкладки.
                    locked_active   = c.active,
                    locked_inactive = c.locked_inactive,
                },
            },
        },
    })
end
