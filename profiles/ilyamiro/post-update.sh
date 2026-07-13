#!/usr/bin/env bash
# post-update.sh — запускается dotprofile update после снапшота профиля.
# Его installer перегенерирует hyprland.conf без наших source-строк —
# возвращаем их (идемпотентно).
set -u

CONF="$(dirname "${BASH_SOURCE[0]}")/hypr/hyprland.conf"
[[ -f "$CONF" ]] || { echo "post-update: нет $CONF" >&2; exit 1; }

LINES=(
    'source = ~/dotfiles/.config/hypr-shared/binds.conf'
    'source = ~/dotfiles/.config/hypr-shared/binds-ilyamiro.conf'
    'source = ~/dotfiles/.config/hypr-shared/rules-ilyamiro.conf'
    'source = ~/dotfiles/.config/hypr-shared/settings-ilyamiro.conf'
)

added=0
for line in "${LINES[@]}"; do
    if ! grep -qxF "$line" "$CONF"; then
        if [[ $added -eq 0 ]] && ! grep -q '# Общие кастомные бинды' "$CONF"; then
            printf '\n# Общие кастомные бинды (dotfiles profile switcher)\n' >> "$CONF"
        fi
        printf '%s\n' "$line" >> "$CONF"
        added=1
        echo "post-update: восстановлена строка: $line"
    fi
done
[[ $added -eq 0 ]] && echo "post-update: source-строки на месте"
exit 0
