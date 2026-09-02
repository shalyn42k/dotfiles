-- Тесты реестра владения биндами (.config/hypr-shared/rigbinds.lua).
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
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

local function assert_eq(got, want, what)
    if got ~= want then
        error(("%s: got %s, want %s"):format(what or "value", tostring(got), tostring(want)), 2)
    end
end

-- Свежий реестр поверх свежего стаба. rigbinds.lua ставит глобал __rig и
-- оборачивает hl.bind/hl.unbind, поэтому и hl, и __rig пересоздаются на тест.
local RIGBINDS = "../.config/hypr-shared/rigbinds.lua"
local function fresh()
    local hl, live = hl_stub.new()
    _G.hl = hl
    _G.__rig = nil
    dofile(RIGBINDS)
    return _G.__rig, hl, live
end

it("binds created inside own() are attributed to that owner", function()
    local rig, hl = fresh()
    rig.own("caelestia", function()
        hl.bind("SUPER + O", "pip")
        hl.bind("SUPER + M", "restart-shell")
    end)
    assert_eq(rig.count("caelestia"), 2, "caelestia bind count")
end)

it("drop() removes the owner's binds from the compositor", function()
    local rig, hl, live = fresh()
    rig.own("caelestia", function()
        hl.bind("SUPER + O", "pip")
        hl.bind("SUPER + M", "restart-shell")
    end)
    assert_eq(#live, 2, "live binds before drop")

    rig.drop("caelestia")

    assert_eq(#live, 0, "live binds after drop")
    assert_eq(rig.count("caelestia"), 0, "caelestia bind count after drop")
end)

-- Набор рига может снимать конфликтные комбы через hl.unbind перед своими
-- биндами (так делал удалённый риг end4, так же устроен contract-binds.lua).
-- Без обёртки снятый бинд остаётся в реестре мёртвым хендлом, и drop позже
-- дёргает :remove() по нему.
it("drop() survives binds already removed via hl.unbind", function()
    local rig, hl, live = fresh()
    rig.own("rig", function()
        hl.bind("SUPER + Tab", "ii-overview")
        hl.bind("SUPER + O", "region-search")
    end)
    hl.unbind("SUPER + Tab")
    assert_eq(#live, 1, "live binds after unbind")

    rig.drop("rig")

    assert_eq(#live, 0, "live binds after drop")
    assert_eq(rig.count("rig"), 0, "rig bind count after drop")
end)

-- Свитч ставит новый набор ДО сноса старого. Если загрузка падает на середине,
-- полуприменённый набор обязан откатиться, иначе останешься с обрубком чужих
-- клавиш поверх своих.
it("own() rolls back its partial set when the chunk fails", function()
    local rig, hl, live = fresh()
    rig.own("caelestia", function() hl.bind("SUPER + M", "restart-shell") end)

    local ok = rig.own("rig", function()
        hl.bind("SUPER + O", "region-search")
        hl.bind("SUPER + B", "sidebar")
        error("keybinds.lua: attempt to index a nil value")
    end)

    assert_eq(ok, false, "own() reports failure")
    assert_eq(rig.count("rig"), 0, "rig bind count after failed load")
    assert_eq(#live, 1, "only the old rig's bind is left live")
end)

it("own() reports success for a chunk that loads cleanly", function()
    local rig, hl = fresh()
    local ok = rig.own("caelestia", function() hl.bind("SUPER + O", "pip") end)
    assert_eq(ok, true, "own() reports success")
end)

-- package.loaded кеширует variables/hyprland.functions/scheme.current СТАРОГО
-- рига (замерено на живой сессии). Без сброса dofile нового набора подтянет
-- чужие значения. Сбрасывать надо ДО загрузки, поэтому это не часть drop().
it("reset_modules() drops rig modules but keeps the lua stdlib", function()
    local rig = fresh()
    package.loaded["variables"] = { kbGoToWs = "SUPER" }
    package.loaded["hyprland.keybinds"] = {}
    package.loaded["scheme.current"] = {}

    rig.reset_modules()

    assert_eq(package.loaded["variables"], nil, "variables unloaded")
    assert_eq(package.loaded["hyprland.keybinds"], nil, "hyprland.keybinds unloaded")
    assert_eq(package.loaded["scheme.current"], nil, "scheme.current unloaded")
    assert_eq(package.loaded["string"] ~= nil, true, "string kept")
    assert_eq(package.loaded["table"] ~= nil, true, "table kept")
    assert_eq(package.loaded["os"] ~= nil, true, "os kept")
end)

-- Контракт §2 (в т.ч. SUPER+SHIFT+D — сам свитчер) живёт под владельцем
-- "shared" и грузится один раз при старте. Снести его — значит остаться без
-- свитчера посреди переключения. Реестр обязан отказать, даже если позовут.
it("drop() refuses to touch the shared owner", function()
    local rig, hl, live = fresh()
    rig.own("shared", function() hl.bind("SUPER + SHIFT + D", "dotprofile menu") end)
    rig.own("caelestia", function() hl.bind("SUPER + O", "pip") end)

    rig.drop("shared")

    assert_eq(rig.count("shared"), 1, "shared bind survives")
    assert_eq(#live, 2, "nothing was removed")
end)

it("drop() of a rig leaves the shared set alone", function()
    local rig, hl, live = fresh()
    rig.own("shared", function() hl.bind("SUPER + SHIFT + D", "dotprofile menu") end)
    rig.own("caelestia", function() hl.bind("SUPER + O", "pip") end)

    rig.drop("caelestia")

    assert_eq(rig.count("shared"), 1, "shared bind count")
    assert_eq(#live, 1, "only the shared bind is left live")
end)

-- Загрузка конфига — не функция, которую можно обернуть: hyprland.lua просто
-- выполняется сверху вниз. Поэтому прелюдия зовёт begin(<риг>), и всё
-- забайнженное дальше принадлежит ригу. Контрактный модуль внутри этой загрузки
-- оборачивает себя в own("shared", ...) — то есть own обязан быть вложенным.
it("begin() attributes everything loaded afterwards to the rig", function()
    local rig, hl = fresh()
    rig.begin("caelestia")
    hl.bind("SUPER + O", "pip")
    hl.bind("SUPER + M", "restart-shell")
    assert_eq(rig.count("caelestia"), 2, "caelestia bind count")
end)

it("own() nested inside begin() restores the outer owner", function()
    local rig, hl = fresh()
    rig.begin("caelestia")
    hl.bind("SUPER + O", "pip")

    rig.own("shared", function() hl.bind("SUPER + SHIFT + D", "dotprofile menu") end)

    hl.bind("SUPER + M", "restart-shell")   -- снова риговый, а не бесхозный
    assert_eq(rig.count("shared"), 1, "shared bind count")
    assert_eq(rig.count("caelestia"), 2, "caelestia bind count")
end)

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
