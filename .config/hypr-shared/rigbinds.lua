-- rigbinds.lua — реестр владения биндами.
--
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
--
-- Зачем: hl.bind только ДОБАВЛЯЕТ (замерено на живой сессии: повторная загрузка
-- набора дала 99 -> 187 биндов), а бинды, созданные при загрузке конфига, не
-- имеют хендлов — снести их нечем. Реестр оборачивает hl.bind и приписывает
-- каждый бинд владельцу, чтобы на свитче набор старого рига снимался точно.
--
-- Владельцы: "shared" — кросс-риг контракт, не сносится никогда; имя рига —
-- всё остальное, меняется на свитче.
--
-- Подключается ПЕРВОЙ строкой hypr/hyprland.lua каждого рига: всё, что
-- забайндится до него, останется без хендла и станет несносимым.

-- registry[owner] = { { handle = <HL.Keybind>, keys = <строка комбы> }, ... }
--
-- Строка комбы хранится РЯДОМ с хендлом, а не берётся с него: настоящий
-- HL.Keybind — userdata, полей с данными у него нет, только методы.
local registry = {}
local current = nil   -- владелец, которому приписываются новые бинды

local raw_bind = hl.bind
local raw_unbind = hl.unbind

hl.bind = function(keys, ...)
    local handle = raw_bind(keys, ...)
    if current and handle then
        local owned = registry[current]
        if not owned then
            owned = {}
            registry[current] = owned
        end
        owned[#owned + 1] = { handle = handle, keys = keys }
    end
    return handle
end

-- Бинд, снятый по строке комбы, больше не существует — вычёркиваем его запись,
-- иначе drop позже дёрнет :remove() по мёртвому хендлу. Так делает end4:
-- custom/keybinds.lua снимает 13 конфликтных ii-комбо перед своими биндами.
hl.unbind = function(keys, ...)
    for _, owned in pairs(registry) do
        for i = #owned, 1, -1 do
            if owned[i].keys == keys then
                table.remove(owned, i)
            end
        end
    end
    return raw_unbind(keys, ...)
end

-- Владелец кросс-риг контракта (KEYBINDS.md §2 + громкость/яркость). Грузится
-- один раз при старте сессии и переживает любой свитч.
local SHARED = "shared"

-- Снять набор владельца без оглядки на защиту SHARED — для отката внутри own().
--
-- Каждое снятие в pcall: хендл мог умереть в обход реестра, и один сбойный
-- не должен обрывать снос остального набора — иначе половина чужих биндов
-- останется висеть и стрелять.
local function drop_owner(owner)
    local owned = registry[owner]
    if not owned then return end
    for i = #owned, 1, -1 do
        pcall(function() owned[i].handle:remove() end)
        owned[i] = nil
    end
end

__rig = {}

-- Приписать ригу всё, что забайндится дальше.
--
-- Загрузка конфига — не функция, которую можно обернуть: hyprland.lua просто
-- выполняется сверху вниз. Прелюдия зовёт begin(<риг>) первой строкой, и весь
-- набор рига попадает в реестр под его именем.
function __rig.begin(owner)
    current = owner
end

-- Выполнить fn, приписав все созданные ею бинды владельцу owner.
-- Возвращает true, либо false и текст ошибки.
--
-- Падение на середине откатывает полуприменённый набор: свитч ставит новый
-- набор ДО сноса старого, поэтому неудача обязана вернуть систему ровно к
-- прежним клавишам, а не оставить обрубок поверх них.
function __rig.own(owner, fn)
    local outer = current
    current = owner
    local ok, err = pcall(fn)
    current = outer   -- вложенный вызов внутри begin() не должен обесхозить остаток загрузки
    if not ok then
        drop_owner(owner)
        return false, err
    end
    return true
end

-- Снять все бинды владельца. Контрактный набор защищён: свитч, снёсший его,
-- оставил бы систему без самого свитчера (SUPER+SHIFT+D).
function __rig.drop(owner)
    if owner == SHARED then return end
    drop_owner(owner)
end

-- Модули lua-stdlib: их package.loaded трогать нельзя. Список замерен на живой
-- сессии (Hyprland на Lua 5.5) — всё остальное в package.loaded принадлежит
-- конфигу рига.
local STDLIB = {
    ["_G"] = true, ["coroutine"] = true, ["debug"] = true, ["io"] = true,
    ["math"] = true, ["os"] = true, ["package"] = true, ["string"] = true,
    ["table"] = true, ["utf8"] = true,
}

-- Забыть модули конфига рига, чтобы require() в загружаемом наборе взял файлы
-- ЦЕЛЕВОГО рига, а не отдал закешированные значения прежнего.
--
-- Зовётся ДО __rig.own(<новый риг>), иначе dofile подтянет чужие variables.
function __rig.reset_modules()
    for name in pairs(package.loaded) do
        if not STDLIB[name] then
            package.loaded[name] = nil
        end
    end
end

-- Сколько живых биндов числится за владельцем.
function __rig.count(owner)
    local owned = registry[owner]
    return owned and #owned or 0
end
