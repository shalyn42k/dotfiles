-- Загрузка ПОЛНОЙ точки входа рига (hypr/hyprland.lua) под стабом `hl`.
--
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
--
-- rig_keybinds_test грузит только набор биндов. Здесь — весь конфиг рига целиком,
-- как это делает Hyprland при старте сессии: прелюдия, все require, оверрайды,
-- контракт последним. Смысл теста в одном: **не залогиниться в сломанный риг**.
-- Ошибка в точке входа (опечатка в package.path, отсутствующий модуль, лишний
-- require) вылезает иначе только на живом релогине, и цена ей — чёрный экран.
--
-- Сессия 2026-09-02 закончилась двумя падениями композитора именно потому, что
-- проверки шли на живом десктопе. Этот файл — попытка перенести всё, что можно,
-- на стол.
package.path = "./?.lua;" .. package.path
local hl_stub = require("support.hl_stub")

local passed, failed = 0, 0
local function it(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("  ok   " .. name)
    else
        failed = failed + 1
        print("  FAIL " .. name .. "\n       " .. tostring(err))
    end
end

local REPO = "../"

-- Все риги теперь на lua-провайдере: hyprlang-ветка ушла вместе с ilyamiro.
local ENTRYPOINTS = {
    caelestia   = "profiles/caelestia/hypr/hyprland.lua",
    serpantinum = "profiles/serpantinum/hypr/hyprland.lua",
}

-- Точка входа резолвит require через ~/.config/hypr — симлинк на АКТИВНЫЙ риг.
-- В тесте активный риг может быть любым, поэтому подставляем каталог самого
-- проверяемого рига: так тест видит то же, что увидел бы Hyprland после того,
-- как ensure_links переставил симлинки на этот риг.
local function load_entrypoint(rig, entry)
    local hl, live = hl_stub.new()
    _G.hl = hl
    _G.__rig = nil
    _G.HOME = os.getenv("HOME")
    _G.is_file_exists = function(path)
        local f = io.open(path, "r")
        if f then f:close() return true end
        return false
    end

    local saved_path = package.path
    local saved_loaded = {}
    for k, v in pairs(package.loaded) do saved_loaded[k] = v end

    package.path = table.concat({
        REPO .. "profiles/" .. rig .. "/hypr/?.lua",
        REPO .. "profiles/" .. rig .. "/hypr/?/init.lua",
        saved_path,
    }, ";")

    local ok, err = pcall(dofile, REPO .. entry)

    package.path = saved_path
    -- Точки входа ригов делают require своих модулей; без сброса второй риг
    -- получил бы модули первого из кеша.
    for k in pairs(package.loaded) do
        if saved_loaded[k] == nil then package.loaded[k] = nil end
    end

    return ok, err, live, _G.__rig
end

for rig, entry in pairs(ENTRYPOINTS) do
    it(rig .. ": full hyprland.lua loads without error", function()
        local ok, err = load_entrypoint(rig, entry)
        if not ok then error(tostring(err), 2) end
    end)

    -- Прелюдия обязана стоять ПЕРВОЙ строкой: бинд, созданный до неё, не попадёт
    -- в реестр, и снести его на свитче будет нечем. Проверяем арифметикой —
    -- сумма по владельцам должна сойтись с числом живых биндов.
    it(rig .. ": every bind is owned (prelude really is first)", function()
        local ok, err, live, reg = load_entrypoint(rig, entry)
        if not ok then error(tostring(err), 2) end
        if not reg then error("__rig не поднялся — прелюдия не отработала", 2) end

        local owned = reg.count("shared") + reg.count(rig)
        if owned ~= #live then
            error(("владельцы держат %d биндов, живых %d — %d ушли мимо реестра")
                :format(owned, #live, #live - owned), 2)
        end
    end)

    -- Контракт грузится последним и переживает свитч. Если он пуст, значит
    -- точка входа его не подключила — свитчер SUPER+SHIFT+D не появится.
    it(rig .. ": contract set is loaded and non-empty", function()
        local ok, err, _, reg = load_entrypoint(rig, entry)
        if not ok then error(tostring(err), 2) end
        if reg.count("shared") == 0 then
            error("контракт не загружен: владелец shared пуст", 2)
        end
    end)
end

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
