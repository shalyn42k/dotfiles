#!/usr/bin/env bash
# session.sh — демоны рига caelestia. Контракт: start|stop.
# Абсолютный путь к СИСТЕМНОМУ quickshell, а не голый `qs`: риг может
# префиксить PATH своей сборкой quickshell, и тогда голое имя поймало бы
# несовместимый бинарь. Так было с удалённым ригом end4 (март-сборка в
# ~/qs-test-prefix, падала на pragma DefaultEnv).
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
