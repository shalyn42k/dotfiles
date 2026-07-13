#!/usr/bin/env bash
# session.sh — демоны рига caelestia. Контракт: start|stop.
set -u
case "${1:-}" in
    start)
        qs -c caelestia -d
        ;;
    stop)
        qs -c caelestia kill 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
