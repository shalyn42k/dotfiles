-- Паритет комбо между lua-ригами.
--
-- Контракт KEYBINDS.md §2: одна и та же комба означает одно и то же во всех
-- ригах. Пока это жило только в голове, набор serpantinum успел разойтись с
-- caelestia на 16 комбо, причём три из них были ЗАНЯТЫ чужим действием
-- (SUPER+E открывал nautilus вместо thunar, SUPER+R перезагружал шелл вместо
-- редактора, SUPER+W тоггл обоев вместо браузера). Это хуже, чем отсутствие:
-- клавиша есть, но делает не то, и обнаруживается это только пальцами.
--
-- Инвариант здесь простой: набор одного lua-рига обязан покрывать набор
-- другого, КРОМЕ комбо, явно перечисленных ниже как уникальные. Список
-- уникальных — это и есть место, где расхождение разрешается сознательно.
-- Добавил риговую фичу — впиши её сюда, и тест снова зелёный.
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

-- Комбо, которым разрешено быть только у своего рига: они зовут CLI, которого
-- у другого рига физически нет.
local RIG_ONLY = {
    caelestia = {
        ["SUPER + O"]              = "caelestia resizer pip",
        ["SUPER + SHIFT + R"]      = "caelestia record",
        ["ALT + SHIFT + R"]        = "caelestia record -s",
        ["SUPER + SHIFT + N"]      = "caelestia scheme (случайная)",
        ["SUPER + ALT + N"]        = "caelestia scheme (тёмная/светлая)",
        ["SUPER + ALT + F12"]      = "caelestia toggle sysmon-специалы",
        ["CTRL + SHIFT + Escape"]  = "спец-воркспейс sysmon caelestia",
    },
    -- Дефолты апстрима сверх контракта. Ничему не противоречат: это лишние
    -- удобства рига, а не занятые контрактные комбо. Перечислены поимённо,
    -- чтобы новый бинд апстрима после обновления сабмодуля всплыл здесь, а не
    -- растворился молча.
    serpantinum = {
        ["SUPER + RETURN"]     = "ii: терминал (у нас контрактный SUPER+TAB)",
        ["SUPER + SPACE"]      = "ii: лаунчер (у нас контрактный SHIFT+TAB)",
        ["ALT + F4"]           = "ii: закрыть окно (у нас контрактный SUPER+Q)",
        ["SUPER + Left"]       = "ii: фокус стрелками (у нас IJKL)",
        ["SUPER + Right"]      = "ii: фокус стрелками",
        ["SUPER + Up"]         = "ii: фокус стрелками",
        ["SUPER + Down"]       = "ii: фокус стрелками",
        ["SUPER + SHIFT + Left"]  = "ii: двигать окно стрелками",
        ["SUPER + SHIFT + Right"] = "ii: двигать окно стрелками",
        ["SUPER + SHIFT + Up"]    = "ii: двигать окно стрелками",
        ["SUPER + SHIFT + Down"]  = "ii: двигать окно стрелками",
        ["SUPER + CTRL + Left"]   = "ii: ресайз стрелками (у нас SUPER+ALT+IJKL)",
        ["SUPER + CTRL + Right"]  = "ii: ресайз стрелками",
        ["SUPER + CTRL + Up"]     = "ii: ресайз стрелками",
        ["SUPER + CTRL + Down"]   = "ii: ресайз стрелками",
        ["Print"]              = "ii: скриншот (у нас контрактный SUPER+SHIFT+S)",
        ["SHIFT + Print"]      = "ii: скриншот",
        ["SUPER + Print"]      = "ii: скриншот",
        ["SUPER + SHIFT + Print"] = "ii: скриншот",
        ["XF86AudioPlay"]      = "ii: медиа-клавиша",
        ["XF86AudioPause"]     = "ii: медиа-клавиша",
        ["XF86PowerOff"]       = "ii: кнопка питания",
    },
}

-- Настройки, которые обязаны совпадать у всех ригов. Раскладка — такой же
-- контракт, как комбо: у serpantinum апстрим ставил одну "us", и смена языка
-- в риге просто не работала, а комбо переключения отличалось от caelestia.
-- Проверяется здесь, потому что это ровно тот же класс расхождения, только не
-- в биндах, а в input.
local SHARED_SETTINGS = { "kb_layout", "kb_options" }

local function load_rig(rig)
    local hl, live, cfg = hl_stub.new()
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
    package.path = REPO .. "profiles/" .. rig .. "/hypr/?.lua;" ..
                   REPO .. "profiles/" .. rig .. "/hypr/?/init.lua;" .. saved_path

    local ok, err = pcall(dofile, REPO .. "profiles/" .. rig .. "/hypr/hyprland.lua")

    package.path = saved_path
    for k in pairs(package.loaded) do
        if saved_loaded[k] == nil then package.loaded[k] = nil end
    end
    if not ok then error(("риг %s не загрузился: %s"):format(rig, tostring(err)), 3) end

    local set = {}
    for _, rec in ipairs(live) do set[rec.keys] = true end
    return set, cfg
end

local function combos_of(rig)
    local set = load_rig(rig)
    return set
end

local function assert_covers(from, to)
    local a, b = combos_of(from), combos_of(to)
    local allowed = RIG_ONLY[from] or {}
    local missing = {}
    for combo in pairs(a) do
        if not b[combo] and not allowed[combo] then
            missing[#missing + 1] = combo
        end
    end
    table.sort(missing)
    if #missing > 0 then
        error(("%d комбо есть у %s, но нет у %s: %s\n       Либо добавь их в %s, либо впиши в RIG_ONLY с объяснением.")
            :format(#missing, from, to, table.concat(missing, ", "), to), 3)
    end
end

it("rigs agree on the shared input settings", function()
    local _, a = load_rig("caelestia")
    local _, b = load_rig("serpantinum")
    local diff = {}
    for _, key in ipairs(SHARED_SETTINGS) do
        local va = a.input and a.input[key]
        local vb = b.input and b.input[key]
        if va ~= vb then
            diff[#diff + 1] = ("%s: caelestia=%s serpantinum=%s")
                :format(key, tostring(va), tostring(vb))
        end
    end
    if #diff > 0 then
        error("настройки ввода разошлись:\n       " .. table.concat(diff, "\n       "), 2)
    end
end)

it("serpantinum covers caelestia's contract combos", function()
    assert_covers("caelestia", "serpantinum")
end)

it("caelestia covers serpantinum's contract combos", function()
    assert_covers("serpantinum", "caelestia")
end)

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
