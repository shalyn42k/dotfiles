#!/usr/bin/env bash
# Прогон тестов dotfiles. Требует lua (Hyprland на 5.5, тесты пишем под него).
#
#   tests/run.sh            — все
#   tests/run.sh rigbinds   — только файлы, чьё имя содержит подстроку
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
filter="${1:-}"
lua_bin="$(command -v lua || command -v lua5.4 || command -v luajit)"
[[ -n "$lua_bin" ]] || { echo "no lua interpreter found" >&2; exit 1; }

failed=0
for f in *_test.lua; do
    [[ -n "$filter" && "$f" != *"$filter"* ]] && continue
    echo "── $f"
    "$lua_bin" "$f" || failed=1
done

[[ $failed -eq 0 ]] && echo "ALL PASS" || echo "FAILURES"
exit $failed
