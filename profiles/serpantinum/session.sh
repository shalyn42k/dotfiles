#!/usr/bin/env bash
# session.sh — демоны рига serpantinum. Контракт: start|stop.
#
# Апстрим вендорится в shell/ (submodule) и запускается через SERPANTINUM_DIR:
# системная установка не нужна, их install.sh мы не запускаем никогда
# (sudo pacman -Syyu --noconfirm + отбрасывание существующего конфига).
set -u

RIG="$HOME/dotfiles/profiles/serpantinum"
export SERPANTINUM_DIR="$RIG/shell/src"
SERPANTINUMD="$RIG/shell/bin/serpantinumd"

case "${1:-}" in
    start)
        if [[ -x "$SERPANTINUMD" ]]; then
            "$SERPANTINUMD" start &
        else
            echo "session.sh: нет $SERPANTINUMD — забыт git submodule update --init" >&2
        fi
        "$HOME/.local/bin/kbd-theme-sync" &
        ;;
    stop)
        [[ -x "$SERPANTINUMD" ]] && "$SERPANTINUMD" stop 2>/dev/null || true
        # Подстраховка: serpantinumd мог не успеть подняться и не знает про свой
        # quickshell. Матчим по пути Shell.qml вендоренной копии, чтобы не задеть
        # шелл другого рига (-c caelestia, -c rigswitch).
        pkill -f "$RIG/shell/src/quickshell" 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
