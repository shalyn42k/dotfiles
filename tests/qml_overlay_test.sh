#!/usr/bin/env bash
# Проверка QML свитчера на несуществующие свойства между компонентами.
#
# Зачем отдельный тест, если qmllint и так есть. Голый `qmllint файл.qml` НЕ
# видит наши собственные типы: quickshell генерит модуль на лету, а на диске
# qmldir нет, поэтому линтер не знает, какие свойства есть у Assembly или
# RigCard, и молча пропускает обращения к ним.
#
# Цена этого пробела известна: 2026-09-03 в shell.qml осталась передача
# `stageLabels`, уже удалённого из Assembly.qml. qmllint промолчал, а оверлей
# на бинде выдавал «Failed to load configuration» — то есть свитчер просто не
# открывался, и понять почему можно было только из его лога.
#
# Здесь мы собираем модуль сами: копия файлов + сгенерированный qmldir, и
# линтуем уже с -I. Тогда межкомпонентные обращения проверяются по-настоящему.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.config/quickshell/rigswitch"
QMLLINT=/usr/lib/qt6/bin/qmllint

if [[ ! -x "$QMLLINT" ]]; then
    echo "  skip  qmllint не найден ($QMLLINT)"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/qs"
cp "$DIR"/*.qml "$tmp/qs/"

# qmldir по факту: singleton — те, у кого есть pragma. shell.qml — точка входа,
# компонентом не объявляется.
{
    echo "module qs"
    for f in "$DIR"/*.qml; do
        n="$(basename "$f" .qml)"
        [[ "$n" == "shell" ]] && continue
        if grep -q "^pragma Singleton" "$f"; then
            echo "singleton $n 1.0 $n.qml"
        else
            echo "$n 1.0 $n.qml"
        fi
    done
} > "$tmp/qs/qmldir"

failed=0
for f in "$tmp"/qs/*.qml; do
    name="$(basename "$f")"
    # Интересуют только реальные поломки склейки компонентов: обращение к
    # свойству, которого у типа нет. Остальные категории (qmldir у чужих
    # модулей, ComponentBehavior) — фоновый шум, одинаковый для всех файлов.
    out="$("$QMLLINT" -I "$tmp" "$f" 2>&1 | grep -E "missing-property|^Error")"
    if [[ -n "$out" ]]; then
        echo "  FAIL $name"
        printf '       %s\n' "$out"
        failed=1
    else
        echo "  ok   $name"
    fi
done

[[ $failed -eq 0 ]] || exit 1
