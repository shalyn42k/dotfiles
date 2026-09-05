-- Вид группы окон (ALT+Q) для рига serpantinum.
--
-- Апстрим не задаёт group ВООБЩЕ (`grep group shell/compositors/hyprland/
-- config/*.lua` пуст), поэтому файл наш целиком. Форма плашки — общая,
-- см. .config/hypr-shared/groupbar.lua; здесь только источник цветов.
--
-- Цвета у этого рига живут не таблицей, как схема caelestia, а $-переменными
-- в hypr/colors.conf (автоген matugen'а профиля). Формат тот же, что уже жуёт
-- awk-ом bin/dotprofile apply_rig_colors, поэтому парсим его же: одна строка —
-- `$имя = значение`.
-- Каталог рига — от собственного файла, а не от ~/rigger: риг обязан
-- работать там, куда его положили, включая свой отдельный репозиторий.
local rig = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or ".") .. "/.."

local function read_colors(path)
    local vars = {}
    local f = io.open(path, "r")
    if not f then return vars end
    for line in f:lines() do
        local k, v = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if k then vars[k] = v end
    end
    f:close()
    return vars
end

local c = read_colors(rig .. "/hypr/colors.conf")

-- Фоллбэк на рамки окна. Нужен ровно один раз в жизни файла: colors.conf —
-- автоген, и до первой перегенерации matugen'ом (смена обоев) в нём лежит
-- старая версия без $gb_*. Без фоллбэка риг поднялся бы с nil-цветами вкладок.
-- Белый текст — не выбор дизайна, а единственное, что тут можно угадать:
-- контрастной к primary пары в старом файле просто нет.
local active   = c.gb_active   or c.active_border   or "rgba(7171acd4)"
local inactive = c.gb_inactive or c.inactive_border or "rgba(47464fd4)"

local apply_groupbar = dofile(os.getenv("HOME") .. "/.config/hypr-shared/groupbar.lua")

apply_groupbar({
    active          = active,
    inactive        = inactive,
    locked_inactive = c.gb_locked_inactive or inactive,
    text            = c.gb_text or "rgb(ffffff)",
})
