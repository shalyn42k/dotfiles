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
    local hl, live, config = hl_stub.new()
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

    return ok, err, live, _G.__rig, config
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

    -- Вид вкладок (ALT+Q собирает окна в группу) — единственная настройка
    -- группы, которую свитч НЕ переприменяет сам: apply_rig_colors в
    -- bin/dotprofile шлёт только group.col.border_*, а плашку не трогает.
    -- Пока её задавал один caelestia, зайти в него было достаточно, чтобы
    -- вкладки остались его — уже в serpantinum и до перезапуска Hyprland.
    -- Поэтому требуем от КАЖДОГО рига: точка входа настроила плашку сама.
    it(rig .. ": configures the groupbar (tabs don't leak across rigs)", function()
        local ok, err, _, _, config = load_entrypoint(rig, entry)
        if not ok then error(tostring(err), 2) end

        local gb = ((config.group or {}).groupbar)
        if not gb then error("group.groupbar не задан вовсе", 2) end

        -- Форма и цвет проверяются вместе: общий файл ставит их одним вызовом,
        -- и половина от него означала бы, что риг зовёт его не так.
        for _, key in ipairs({ "font_family", "height", "text_color" }) do
            if gb[key] == nil then error("group.groupbar." .. key .. " не задан", 2) end
        end
        for _, key in ipairs({ "active", "inactive", "locked_active", "locked_inactive" }) do
            local v = (gb.col or {})[key]
            if type(v) ~= "string" or v == "" then
                error("group.groupbar.col." .. key .. " не задан", 2)
            end
        end
    end)
end

-- Свитч применяет слои рига runtime-чанками. Чанка нет — стадия молча ничего
-- не делает, и слой остаётся от того рига, в который ты ЗАШЁЛ. Так у
-- serpantinum потерялись сначала анимации, потом правила окон: обе стадии
-- отрабатывали "успешно", просто применять было нечего.
--
-- rules-runtime не обязателен: риг может не иметь правил вовсе (у serpantinum
-- их нет ни своих, ни апстримовских). Остальные — обязаны быть.
local REQUIRED_CHUNKS = { "animations-runtime.lua", "settings-runtime.lua" }

for rig in pairs(ENTRYPOINTS) do
    it(rig .. ": has every runtime chunk the switch applies", function()
        local missing = {}
        for _, chunk in ipairs(REQUIRED_CHUNKS) do
            local f = io.open(REPO .. "profiles/" .. rig .. "/" .. chunk, "r")
            if f then f:close() else missing[#missing + 1] = chunk end
        end
        if #missing > 0 then
            error(("нет чанков: %s — соответствующие стадии свитча будут no-op")
                :format(table.concat(missing, ", ")), 2)
        end
    end)

    -- Мало иметь чанк — он должен ГРУЗИТЬСЯ и ставить плашку вкладок. Логин и
    -- горячий свитч идут разными путями (require из точки входа против dofile
    -- через hyprctl eval), и течь вкладок жила именно во втором: точка входа
    -- caelestia плашку красила, а settings-runtime рига, в который ты уходишь,
    -- её не переписывал. Проверяем тот путь, по которому баг и приходил.
    it(rig .. ": settings-runtime re-applies the groupbar on a hot switch", function()
        local hl, _, config = hl_stub.new()
        _G.hl = hl
        _G.HOME = os.getenv("HOME")

        local saved_path = package.path
        local saved_loaded = {}
        for k, v in pairs(package.loaded) do saved_loaded[k] = v end

        local ok, err = pcall(dofile, REPO .. "profiles/" .. rig .. "/settings-runtime.lua")

        package.path = saved_path
        for k in pairs(package.loaded) do
            if saved_loaded[k] == nil then package.loaded[k] = nil end
        end

        if not ok then error(tostring(err), 2) end

        local active = (((config.group or {}).groupbar or {}).col or {}).active
        if type(active) ~= "string" or active == "" then
            error("чанк загрузился, но group.groupbar.col.active не задан — " ..
                  "на свитче вкладки останутся от прежнего рига", 2)
        end
    end)
end

-- Стадия reload в свитче. Слои, которые применяются через hyprctl eval, не
-- достают до кеша текстур рендерера: замерено 2026-09-04 на живой сессии —
-- group:groupbar:col.active уже показывал янтарь serpantinum, а плашка на
-- экране оставалась бирюзовой, caelestia'вской, до перескладывания группы
-- руками по ALT+Q. Перечитывание конфига целиком — единственное, что её
-- перекрашивает (force_renderer_reload и правка геометрии не помогают,
-- hyprctl keyword при lua-парсере недоступен).
--
-- Тест статический: живой свитч тут не поднять. Он ловит ровно то, чем эта
-- стадия рискует — тихо исчезнуть при правке порядка стадий.
it("switch runs a reload stage, and it comes after the eval stages", function()
    local f = assert(io.open(REPO .. "bin/dotprofile", "r"), "нет bin/dotprofile")
    local src = f:read("*a")
    f:close()

    if not src:match("apply_rig_reload%s*%(%)%s*{") then
        error("нет функции apply_rig_reload", 2)
    end

    local rules  = src:find("stage%s+rules%s+apply_rig_rules")
    local reload = src:find("stage%s+reload%s+apply_rig_reload")
    if not reload then
        error("стадия reload не подключена — плашка вкладок останется от прежнего рига", 2)
    end
    if not rules or reload < rules then
        error("стадия reload обязана идти ПОСЛЕ стадий eval, иначе они её перекроют", 2)
    end
end)

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
