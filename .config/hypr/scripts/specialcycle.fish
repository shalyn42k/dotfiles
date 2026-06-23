#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo 'Usage: specialcycle.fish <next|prev>'
    exit 1
end

set specials specialws sysmon music communication todo messanger
set direction $argv[1]
set count (count $specials)

# Get focused monitor ID, then its active special workspace
set mon_id (hyprctl activeworkspace -j | jq '.monitorID')
set raw (hyprctl monitors -j | jq -r ".[] | select(.id == $mon_id) | .specialWorkspace.name // \"\"")
set active (string replace "special:" "" -- $raw)

if test -z $active
    hyprctl dispatch togglespecialworkspace $specials[1]
    exit 0
end

# Close current
hyprctl dispatch togglespecialworkspace $active

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
    hyprctl dispatch togglespecialworkspace $specials[1]
    exit 0
end

# Wrap-around next/prev
if test $direction = next
    set next_idx (math "($idx % $count) + 1")
else
    set next_idx (math "(($idx - 2 + $count) % $count) + 1")
end

hyprctl dispatch togglespecialworkspace $specials[$next_idx]
