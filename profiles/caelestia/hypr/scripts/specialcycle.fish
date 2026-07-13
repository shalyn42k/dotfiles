#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo 'Usage: specialcycle.fish <next|prev>'
    exit 1
end

set specials specialws sysmon music communication todo messanger
set direction $argv[1]
set count (count $specials)

# Under Hyprland Lua config, hyprctl dispatch uses Lua syntax.
# togglespecialworkspace -> hl.dsp.workspace.toggle_special("name")
function toggle_special
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$argv[1]\")"
end

# Get focused monitor ID, then its active special workspace
set mon_id (hyprctl activeworkspace -j | jq '.monitorID')
set raw (hyprctl monitors -j | jq -r ".[] | select(.id == $mon_id) | .specialWorkspace.name // \"\"")
set active (string replace "special:" "" -- $raw)

if test -z $active
    toggle_special $specials[1]
    exit 0
end

# Close current
toggle_special $active

# Find index of current in list (1-based)
set idx 0
for i in (seq 1 $count)
    if test $specials[$i] = $active
        set idx $i
        break
    end
end

if test $idx -eq 0
    # Not in list -> fall back to first
    toggle_special $specials[1]
    exit 0
end

# Wrap-around next/prev
if test $direction = next
    set next_idx (math "($idx % $count) + 1")
else
    set next_idx (math "(($idx - 2 + $count) % $count) + 1")
end

toggle_special $specials[$next_idx]
