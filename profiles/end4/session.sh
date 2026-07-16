#!/usr/bin/env bash
# session.sh — демоны рига end4 (illogical-impulse). Контракт: start|stop.
# СОСУЩЕСТВОВАНИЕ: ii-шелл крутится на ЛОКАЛЬНОМ март-quickshell (7511545),
# НЕ системном (май, для caelestia/ilyamiro). Мина №1, см. NOTES-install.md.
set -u

# Единый источник правды пути к март-quickshell. bootstrap формализует префикс
# (сейчас ~/qs-test-prefix из test-first сборки; спека обновляется).
QS_II="$HOME/qs-test-prefix/usr/bin/quickshell"

# Не-контестируемые конфиги end4 (только у этого рига — нет в ilyamiro/caelestia).
# Разворачиваются симлинком на время сессии end4 и убираются на выходе, чтобы
# fontconfig/Kvantum/тема ii не протекали в другие риги. CONTESTED-каталоги
# (hypr/gtk/qt/matugen) разводит dotprofile — здесь ТОЛЬКО end4-эксклюзив.
END4="$HOME/dotfiles/profiles/end4"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
# пара «источник-в-профиле  →  цель-в-.config»
declare -A END4_LINKS=(
    ["$END4/quickshell-ii"]="$CFG/quickshell/ii"
    ["$END4/fontconfig"]="$CFG/fontconfig"
    ["$END4/Kvantum"]="$CFG/Kvantum"
    ["$END4/kde-material-you-colors"]="$CFG/kde-material-you-colors"
)

link_configs() {
    local src dst
    for src in "${!END4_LINKS[@]}"; do
        dst="${END4_LINKS[$src]}"
        [[ -d "$src" ]] || continue
        mkdir -p "$(dirname "$dst")"
        # чужой РЕАЛЬНЫЙ каталог не затираем — бэкапим один раз
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            mv "$dst" "$dst.pre-end4"
        fi
        ln -sfn "$src" "$dst"
    done
}

unlink_configs() {
    local src dst
    for src in "${!END4_LINKS[@]}"; do
        dst="${END4_LINKS[$src]}"
        # убираем ТОЛЬКО наш симлинк (реальные каталоги других ригов не трогаем)
        [[ -L "$dst" ]] && rm -f "$dst"
        # восстановить бэкап, если был
        [[ -e "$dst.pre-end4" ]] && mv "$dst.pre-end4" "$dst"
    done
}

case "${1:-}" in
    start)
        link_configs
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
        unlink_configs
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
