#!/bin/bash

# СПИСОК ТВОИХ СПЕЦ. ВОРКСПЕЙСОВ (в нужном порядке)
# Важно: пиши только названия (без special:)
WORKSPACES=("music" "communication" "todo")

# Получаем текущий активный спец. воркспейс на фокусном мониторе
CURRENT=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name' | sed 's/special://g')

# Если ничего не открыто (пустота или none), открываем первый из списка
if [[ "$CURRENT" == "" ]] || [[ "$CURRENT" == "none" ]]; then
    hyprctl dispatch togglespecialworkspace "${WORKSPACES[0]}"
    exit 0
fi

# Ищем индекс текущего воркспейса
for i in "${!WORKSPACES[@]}"; do
   if [[ "${WORKSPACES[$i]}" == "$CURRENT" ]]; then
       CURRENT_INDEX=$i
       break
   fi
done

# Определяем направление (next или prev), передаем аргументом скрипту
DIRECTION=$1
NEXT_INDEX=0

if [[ "$DIRECTION" == "next" ]]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WORKSPACES[@]} ))
elif [[ "$DIRECTION" == "prev" ]]; then
    NEXT_INDEX=$(( (CURRENT_INDEX - 1 + ${#WORKSPACES[@]}) % ${#WORKSPACES[@]} ))
fi

# Переключаем
TARGET="${WORKSPACES[$NEXT_INDEX]}"
hyprctl dispatch togglespecialworkspace "$TARGET"