#!/usr/bin/env bash
# session.sh — демоны рига ilyamiro (из config/autostart.conf снапшота).
# Контракт: start|stop. Общесистемные (nm-applet, keyring, polkit, cliphist,
# playerctld, hypridle) не трогаем — риг-независимые или дублируются relogin'ом.
set -u
case "${1:-}" in
    start)
        awww-daemon &
        quickshell -p "$HOME/.config/hypr/scripts/quickshell/Shell.qml" &
        swayosd-server --top-margin 0.9 --style "$HOME/.config/swayosd/style.css" &
        "$HOME/.config/hypr/scripts/settings_watcher.sh" &
        "$HOME/.config/hypr/scripts/volume_listener.sh" &
        "$HOME/.config/hypr/scripts/init.sh" &
        ;;
    stop)
        pkill -f 'quickshell -p .*hypr/scripts/quickshell' 2>/dev/null || true
        pkill -f 'settings_watcher.sh|volume_listener.sh|qs_manager.sh' 2>/dev/null || true
        pkill -x swayosd-server 2>/dev/null || true
        pkill -x awww-daemon 2>/dev/null || true
        pkill -x swww-daemon 2>/dev/null || true
        pkill -x mpvpaper 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
