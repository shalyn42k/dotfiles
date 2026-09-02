-- Стаб Hyprland-овского глобала `hl` для тестов на столе.
--
-- Настоящий `hl` даёт config-провайдер hyprkcs, и вне сессии его нет. Но нам
-- нужна ровно та его часть, вокруг которой построен реестр владения:
--   * hl.bind(keys, dispatcher, opts) -> HL.Keybind (userdata с :remove())
--   * hl.unbind(keys)
-- Замерено на живой сессии 2026-09-02 (Hyprland 0.56.2), стаб повторяет
-- наблюдаемое поведение:
--   * повторный bind той же комбы СТЕКАЕТСЯ, а не замещает (99 -> 187);
--   * :remove() снимает бинд (100 -> 99);
--   * unbind(комба) снимает бинд по строке.
local M = {}

-- Собрать свежий стаб. Возвращает (hl, live), где live — список живых биндов
-- в порядке создания; тесты смотрят в него как в `hyprctl binds`.
function M.new()
    local live = {}
    local hl = {}

    -- live[i] = { handle = <хендл>, keys = <строка комбы> }. Строку держим
    -- ЗДЕСЬ, а не на хендле: настоящий HL.Keybind — userdata, у него нет полей
    -- с данными, только методы. Реестр не имеет права матчить по handle.keys.
    local function forget(handle)
        for i = #live, 1, -1 do
            if live[i].handle == handle then
                table.remove(live, i)
                return
            end
        end
    end

    function hl.bind(keys, dispatcher, opts)
        local dead = false
        local handle = setmetatable({}, {
            __index = {
                remove = function(self)
                    if dead then
                        error("remove() on a dead keybind: " .. tostring(keys), 2)
                    end
                    dead = true
                    forget(self)
                end,
            },
            __newindex = function()
                error("HL.Keybind is userdata; cannot set fields on it", 2)
            end,
        })
        live[#live + 1] = {
            handle = handle, keys = keys, dispatcher = dispatcher, opts = opts,
            kill = function() dead = true end,
        }
        return handle
    end

    function hl.unbind(keys)
        -- Настоящий hl.unbind адресует по строке комбы. Снимаем все совпадения:
        -- в живой сессии одна комба может быть навешана дважды (стекание).
        --
        -- Снятый так бинд помечается мёртвым: повторный :remove() по его хендлу
        -- обязан быть ошибкой. Что настоящий hyprkcs делает при двойном снятии,
        -- не проверено — стаб намеренно берёт СТРОГУЮ модель, чтобы реестр был
        -- обязан пережить и её.
        for i = #live, 1, -1 do
            if live[i].keys == keys then
                live[i].kill()
                table.remove(live, i)
            end
        end
    end

    -- Всё, кроме bind/unbind, автоматически: hl.dsp.window.fullscreen{...},
    -- hl.get_active_window(), hl.config{...} и прочее. Настоящие наборы биндов
    -- зовут десятки таких — стаб отдаёт вызываемую заглушку на любую глубину,
    -- чтобы файл рига догрузился до конца и мы увидели ВСЕ его бинды.
    -- Арифметика нужна потому, что наборы считают геометрию прямо в биндах:
    -- `win.size.x * (x / 100)` в resize_active_window (caelestia functions.lua,
    -- инлайн-копия в end4 custom). Заглушка обязана пережить такие выражения,
    -- иначе файл не догрузится и часть биндов останется невидимой тесту.
    local function auto(name)
        local mt
        local function arith() return auto(name .. "<arith>") end
        mt = {
            __index = function(_, key) return auto(name .. "." .. tostring(key)) end,
            __call = function() return auto(name .. "()") end,
            __tostring = function() return "<hl." .. name .. ">" end,
            __add = arith, __sub = arith, __mul = arith, __div = arith,
            __mod = arith, __pow = arith, __unm = arith, __idiv = arith,
            __concat = function() return name end,
            __len = function() return 0 end,
        }
        return setmetatable({}, mt)
    end
    setmetatable(hl, {
        __index = function(_, key) return auto(tostring(key)) end,
    })

    return hl, live
end

return M
