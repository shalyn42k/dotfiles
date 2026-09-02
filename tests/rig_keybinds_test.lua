-- Загрузка НАСТОЯЩИХ наборов биндов каждого рига под стабом `hl`.
--
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
--
-- Юнит-тесты реестра (rigbinds_test.lua) проверяют механику на выдуманных
-- биндах. Здесь — та же механика на том, что реально лежит в профилях: набор
-- обязан загрузиться целиком, попасть в реестр под своим владельцем и не
-- содержать двух записей на одну комбу.
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
local RIGBINDS = REPO .. ".config/hypr-shared/rigbinds.lua"

-- Набор биндов рига: точка входа и каталоги, из которых он резолвит require.
local RIGS = {
    caelestia = {
        entry = "profiles/caelestia/hypr/hyprland/keybinds.lua",
        paths = { "profiles/caelestia/hypr/?.lua", "profiles/caelestia/hypr/?/init.lua" },
    },
    end4 = {
        entry = "profiles/end4/hypr/hyprland/keybinds.lua",
        paths = { "profiles/end4/hypr/?.lua", "profiles/end4/hypr/?/init.lua" },
    },
    ["end4 (custom)"] = {
        entry = "profiles/end4/hypr/custom/keybinds.lua",
        paths = { "profiles/end4/hypr/?.lua", "profiles/end4/hypr/?/init.lua" },
    },
}

-- Загрузить набор рига под свежим стабом. Возвращает (ok, err, live, rig).
local function load_rig(spec, owner)
    local hl, live = hl_stub.new()
    _G.hl = hl
    _G.__rig = nil
    -- Глобалы, которые конфиг end4 ожидает от своего hyprland.lua.
    _G.HOME = os.getenv("HOME")
    _G.is_file_exists = function(path)
        local f = io.open(path, "r")
        if f then f:close() return true end
        return false
    end

    local saved_path = package.path
    local prefixes = {}
    for _, p in ipairs(spec.paths) do prefixes[#prefixes + 1] = REPO .. p end
    package.path = table.concat(prefixes, ";") .. ";" .. saved_path

    dofile(RIGBINDS)
    local rig = _G.__rig
    local ok, err = rig.own(owner, function() dofile(REPO .. spec.entry) end)

    package.path = saved_path
    return ok, err, live, rig
end

for name, spec in pairs(RIGS) do
    it(name .. ": bind set loads and lands in the registry", function()
        local ok, err, live, rig = load_rig(spec, "rig")
        if not ok then error(tostring(err), 2) end
        if #live == 0 then error("no binds were created", 2) end
        if rig.count("rig") ~= #live then
            error(("registry has %d binds, compositor has %d — some bind escaped ownership")
                :format(rig.count("rig"), #live), 2)
        end
    end)
end

-- «Комба не повторяется» инвариантом НЕ является: апстрим end4 намеренно вешает
-- одну комбу дважды — press/release для SUPER_L и идиому «шелл жив → действие,
-- иначе fuzzel-фолбэк» для SUPER+V и CTRL+Print. Оба срабатывания там задуманы.
--
-- Инвариант — тот, что заявляет шапка нашего custom/keybinds.lua: «стратегия —
-- hl.unbind() конфликтных ii-комбо, затем hl.bind() наших». Раз стекание
-- подтверждено замером (99 -> 187), не снятая комба означает, что действие
-- апстрима продолжает срабатывать вместе с нашим.
it("end4: every combo custom/ overrides was unbound from the ii defaults first", function()
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
    package.path = REPO .. "profiles/end4/hypr/?.lua;" ..
                   REPO .. "profiles/end4/hypr/?/init.lua;" .. saved_path
    dofile(RIGBINDS)
    local rig = _G.__rig

    -- Тот же порядок, что в profiles/end4/hypr/hyprland.lua: сначала дефолты ii,
    -- потом наш custom.
    local ok_up = rig.own("end4", function() dofile(REPO .. "profiles/end4/hypr/hyprland/keybinds.lua") end)

    -- Метим дефолты по ИДЕНТИЧНОСТИ хендла, а не по позиции: custom-файл зовёт
    -- hl.unbind, тот выбрасывает записи из середины live, и любые запомненные
    -- индексы съезжают.
    local from_upstream = {}
    for _, rec in ipairs(live) do from_upstream[rec.handle] = true end

    local ok_custom = rig.own("end4", function() dofile(REPO .. "profiles/end4/hypr/custom/keybinds.lua") end)
    package.path = saved_path

    if not ok_up then error("ii defaults failed to load", 2) end
    if not ok_custom then error("custom/keybinds.lua failed to load", 2) end

    -- Сколько дефолтов ii пережило загрузку custom, по комбам.
    local surviving = {}
    for _, rec in ipairs(live) do
        if from_upstream[rec.handle] then
            surviving[rec.keys] = (surviving[rec.keys] or 0) + 1
        end
    end

    -- Комба, которую вешает custom, а дефолт ii на неё уцелел → срабатывают оба.
    local clashes, seen = {}, {}
    for _, rec in ipairs(live) do
        if not from_upstream[rec.handle] and surviving[rec.keys] and not seen[rec.keys] then
            seen[rec.keys] = true
            clashes[#clashes + 1] = rec.keys
        end
    end
    if #clashes > 0 then
        error("still bound by the ii defaults: " .. table.concat(clashes, ", "), 2)
    end
end)

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
