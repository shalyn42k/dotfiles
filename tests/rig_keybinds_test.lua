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
    serpantinum = {
        entry = "profiles/serpantinum/hypr/overrides.lua",
        paths = { "profiles/serpantinum/shell/compositors/hyprland/?.lua" },
    },
}

-- Загрузить набор рига под свежим стабом. Возвращает (ok, err, live, rig).
local function load_rig(spec, owner)
    local hl, live = hl_stub.new()
    _G.hl = hl
    _G.__rig = nil
    -- Глобалы, которые набор рига может ждать от своего hyprland.lua.
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

-- Контрактный набор грузится ОДИН раз при старте под владельцем "shared" и
-- переживает свитч. Если риговый набор вешает ту же комбу, он забирает её себе
-- (а если набор рига снимает комбу перед своей — ещё и снесёт контрактную) —
-- и первый же свитч унесёт её
-- вместе с набором рига. Для SUPER+SHIFT+D это означает остаться без свитчера.
local CONTRACT = REPO .. ".config/hypr-shared/contract-binds.lua"

it("contract binds are owned by 'shared'", function()
    local hl, live = hl_stub.new()
    _G.hl = hl
    _G.__rig = nil
    dofile(RIGBINDS)
    local rig = _G.__rig
    dofile(CONTRACT)
    if #live == 0 then error("contract set is empty", 2) end
    assert(rig.count("shared") == #live,
        ("shared owns %d of %d contract binds"):format(rig.count("shared"), #live))
end)

-- Реальный порядок загрузки: набор рига, контракт последним. Проверяем то, что
-- из этого обязано следовать — на контрактной комбе живёт ровно один бинд, и
-- он контрактный. Иначе действие рига срабатывает вместе с контрактным.
for name, spec in pairs(RIGS) do
    it(name .. ": contract wins every shared combo when loaded last", function()
        local hl, live = hl_stub.new()
        _G.hl = hl
        _G.__rig = nil
        _G.HOME = os.getenv("HOME")
        _G.is_file_exists = function(path)
            local f = io.open(path, "r")
            if f then f:close() return true end
            return false
        end
        dofile(RIGBINDS)
        local rig = _G.__rig

        local saved_path = package.path
        local prefixes = {}
        for _, p in ipairs(spec.paths) do prefixes[#prefixes + 1] = REPO .. p end
        package.path = table.concat(prefixes, ";") .. ";" .. saved_path
        rig.begin("rig")
        local ok, err = pcall(dofile, REPO .. spec.entry)
        package.path = saved_path
        if not ok then error(tostring(err), 2) end

        dofile(CONTRACT)

        -- Контракт грузился последним, значит его записи — хвост live длиной
        -- в размер набора shared.
        local shared_n = rig.count("shared")
        if shared_n == 0 then error("contract set is empty", 2) end

        local counts = {}
        for _, rec in ipairs(live) do
            counts[rec.keys] = (counts[rec.keys] or 0) + 1
        end

        local doubled = {}
        for i = #live - shared_n + 1, #live do
            local keys = live[i].keys
            if counts[keys] > 1 then doubled[#doubled + 1] = keys end
        end
        if #doubled > 0 then
            error("rig still fires on contract combos: " .. table.concat(doubled, ", "), 2)
        end
    end)
end

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
