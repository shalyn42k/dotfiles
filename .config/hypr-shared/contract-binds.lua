-- contract-binds.lua — кросс-риг контракт (KEYBINDS.md §2.1): одна комба во
-- всех ригах, `rigdo` маршрутизирует её в шелл АКТИВНОГО рига.
--
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
--
-- Владелец — "shared": набор переживает любой свитч. Это не оптимизация, а
-- требование безопасности: сюда входит SUPER+SHIFT+D, то есть сам свитчер.
-- Уедь он вместе с набором рига — и упавшая загрузка нового набора оставила бы
-- систему без способа переключиться обратно.
--
-- Переключать эти бинды не нужно и незачем: `rigdo` читает profiles/active в
-- момент нажатия, поэтому одна и та же комба сама собой означает разное в
-- разных ригах. Это инсайт спеки 2026-07-17, и он остаётся в силе.
--
-- ПОРЯДОК: модуль применяется ПОСЛЕДНИМ, после набора рига. Причина — hl.unbind
-- адресует по строке комбы, без разбора владельца: unbind-список end4
-- (custom/keybinds.lua) снёс бы и контрактный бинд, загрузись он раньше. Идя
-- последним и снимая комбу перед своей, контракт выигрывает всегда.
--
-- То же на свитче: набор нового рига может занять контрактную комбу (ii-дефолты
-- вешают SUPER+B, SUPER+N, SUPER+M и др.), поэтому dotprofile переприменяет
-- контракт после загрузки рига.
local dot   = os.getenv("HOME") .. "/dotfiles/bin/"
local rigdo = dot .. "rigdo "

-- Снять комбу, затем повесить свою: иначе бинд рига продолжит срабатывать
-- вместе с контрактным (ре-бинд стекается, замерено на живой сессии: 99 -> 187).
local function bind(keys, dispatcher, opts)
    hl.unbind(keys)
    return hl.bind(keys, dispatcher, opts)
end

__rig.own("shared", function()
    -- Сам свитчер.
    bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(dot .. "dotprofile menu"))

    -- Действия, которые у каждого рига свои, но комба общая.
    bind("SHIFT + TAB",       hl.dsp.exec_cmd(rigdo .. "launcher"))
    bind("SUPER + M",         hl.dsp.exec_cmd(rigdo .. "shell"))
    bind("SUPER + Y",         hl.dsp.exec_cmd(rigdo .. "wallpaper"))
    bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(rigdo .. "settings"))
    bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(rigdo .. "screenshot"))
    bind("SUPER + grave",     hl.dsp.exec_cmd(rigdo .. "clipboard"))
    bind("SUPER + F1",        hl.dsp.exec_cmd(rigdo .. "lock"), { locked = true })
    bind("SUPER + B",         hl.dsp.exec_cmd(rigdo .. "battery"))
    bind("SUPER + N",         hl.dsp.exec_cmd(rigdo .. "network"))
    bind("SUPER + H",         hl.dsp.exec_cmd(rigdo .. "guide"))
    bind("SUPER + ALT + M",   hl.dsp.exec_cmd(rigdo .. "music"))
    bind("SUPER + ALT + S",   hl.dsp.exec_cmd(rigdo .. "calendar"))
    bind("SUPER + ALT + P",   hl.dsp.exec_cmd(rigdo .. "movies"))
end)
