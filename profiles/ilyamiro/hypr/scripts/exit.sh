#!/usr/bin/env bash

systemctl --user stop graphical-session.target
systemctl --user stop graphical-session-pre.target

sleep 0.5

# `dispatch exit` не работает под lua-провайдером (сессия загружена в
# caelestia, риг переключён горячо) — там выход через hl.dsp.exit()
if [[ "$(hyprctl systeminfo 2>/dev/null | awk -F': ' '/configProvider/{print $2}')" == lua ]]; then
    hyprctl dispatch 'hl.dsp.exit()'
else
    hyprctl dispatch exit
fi
