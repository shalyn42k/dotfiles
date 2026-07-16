#!/usr/bin/env fish

# Проверяем аргументы
if test (count $argv) -ne 2
    echo 'Usage: ./wsaction.fish <dispatcher> <workspace>'
    exit 1
end

# 1. Получаем ID текущего монитора (0, 1, 2...)
set mon_id (hyprctl activeworkspace -j | jq '.monitorID')

# 2. Считаем смещение (offset).
# Монитор 0 -> 0
# Монитор 1 -> 10
# Монитор 2 -> 20
set offset (math "$mon_id * 10")

# 3. Считаем итоговый номер воркспейса
set target (math "$offset + $argv[2]")
set dispatcher $argv[1]

# 4. Выполняем команду.
# Hyprland Lua config requires Lua syntax for hyprctl dispatch.
if test $dispatcher = workspace
    hyprctl dispatch "hl.dsp.focus({workspace = $target})"
else if test $dispatcher = movetoworkspace
    hyprctl dispatch "hl.dsp.window.move({workspace = $target})"
else
    hyprctl dispatch $dispatcher $target
end
