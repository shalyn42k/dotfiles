#!/usr/bin/env bash
# session.sh — демоны рига caelestia. Контракт: start|stop.
# Абсолютный путь к СИСТЕМНОМУ quickshell (0.3.0): при хот-свитче из end4 его
# env.lua префиксит PATH на ~/qs-test-prefix (март-quickshell 0.2.1), и голый
# `qs` поймал бы несовместимый бинарь (падает на pragma DefaultEnv). См.
# profiles/end4/hypr/custom/env.lua.
set -u
QS_SYS="/usr/bin/qs"
case "${1:-}" in
    start)
        "$QS_SYS" -c caelestia -d
        "$HOME/.local/bin/kbd-theme-sync" &
        ;;
    stop)
        "$QS_SYS" -c caelestia kill 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
