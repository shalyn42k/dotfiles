#!/usr/bin/env bash
# session.sh — демоны рига end4 (illogical-impulse). Контракт: start|stop.
# СОСУЩЕСТВОВАНИЕ: ii-шелл крутится на ЛОКАЛЬНОМ март-quickshell (7511545),
# НЕ системном (май, для caelestia/ilyamiro). Мина №1, см. NOTES-install.md.
set -u

# Единый источник правды пути к март-quickshell. bootstrap формализует префикс
# (сейчас ~/qs-test-prefix из test-first сборки; спека обновляется).
QS_II="$HOME/qs-test-prefix/usr/bin/quickshell"

case "${1:-}" in
    start)
        if [[ -x "$QS_II" ]]; then
            "$QS_II" -c ii &
        else
            echo "session.sh: НЕ найден март-quickshell: $QS_II" >&2
            echo "  собери: cmake --install ~/src/quickshell-test/build (см. NOTES)" >&2
        fi
        "$HOME/.local/bin/kbd-theme-sync" &
        ;;
    stop)
        # матч по локальному бинарю — НЕ трогаем системный qs других ригов
        pkill -f "$QS_II -c ii" 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
