#!/usr/bin/env bash
# session.sh — демоны рига end4 (illogical-impulse). Контракт: start|stop.
# СОСУЩЕСТВОВАНИЕ: ii-шелл крутится на ЛОКАЛЬНОМ март-quickshell (7511545),
# НЕ системном (май, для caelestia/ilyamiro). Мина №1, см. NOTES-install.md.
#
# Разворачивание не-контест конфигов (quickshell/ii, fontconfig, Kvantum,
# kde-material-you-colors) делает dotprofile ensure_links (OPTIONAL_LINKS) —
# и на хот-свитче, и на relogin (--links-only). Здесь ТОЛЬКО демоны.
set -u

# Единый источник правды пути к март-quickshell. bootstrap формализует префикс
# (сейчас ~/qs-test-prefix из test-first сборки; спека обновляется).
QS_II="$HOME/qs-test-prefix/usr/bin/quickshell"

case "${1:-}" in
    start)
        # Хот-свитч В end4: custom/env.lua (PATH на март-quickshell) НЕ отработал
        # (сессия стартовала не в end4). Ставим PATH для ii-шелла и его вотчеров.
        export PATH="$HOME/qs-test-prefix/usr/bin:$PATH"
        if [[ -x "$QS_II" ]]; then
            "$QS_II" -c ii &
        else
            echo "session.sh: НЕ найден март-quickshell: $QS_II" >&2
            echo "  собери: cmake --install ~/src/quickshell-test/build (см. NOTES)" >&2
        fi
        "$HOME/.local/bin/kbd-theme-sync" &
        # Видео-обои: на логине их рестартит exec-once (hyprland/execs.lua),
        # на хот-свитче В end4 — только мы. Скрипт генерится switchwall.sh
        # (pkill mpvpaper + mpvpaper с текущим видео); для статичных обоев
        # он no-op после pkill.
        RESTORE="$(dirname "${BASH_SOURCE[0]}")/hypr/custom/scripts/__restore_video_wallpaper.sh"
        [[ -x "$RESTORE" ]] && "$RESTORE" &
        ;;
    stop)
        # Две формы cmdline одного шелла: "$QS_II -c ii" (session.sh start,
        # полный путь) и "qs -c ii" (exec-once из hyprland/execs.lua на логине —
        # bare, PATH-резолв). Убиваем обе, иначе логин-инстанс переживает свитч
        # и висит зомби-баром над новым ригом. Конфиги других ригов (-c caelestia,
        # -c rigswitch) не матчатся.
        pkill -f "$QS_II -c ii" 2>/dev/null || true
        pkill -f 'qs -c ii' 2>/dev/null || true
        # Видео-обои end4: иначе mpvpaper переживает свитч и декодит видео
        # невидимо под фоном нового рига (GPU впустую). ilyamiro не задет —
        # кросс-движок достижим только релогином (свежая сессия).
        pkill mpvpaper 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
