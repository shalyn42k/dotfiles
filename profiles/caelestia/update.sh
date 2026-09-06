#!/usr/bin/env bash
# update.sh — хук рига caelestia. Зовётся rig-update после сдвига пина шелла.
#
# Риг не запускает quickshell из исходников сабмодуля: он запускает то, что
# положил `cmake --install`. Причина не в удобстве, а в апстриме — их
# CMakeLists при установке подменяет в shell.qml одну строку:
#
#     string(REPLACE "settings.watchFiles: true" "settings.watchFiles: false" …)
#
# В дереве исходников стоит true (режим разработки, шелл перезагружает себя на
# каждое изменение файла), в установленном конфиге — false. Запуск прямо из
# сабмодуля означал бы либо жизнь с автоперезагрузкой посреди git checkout,
# либо правку их файла. Мы не делаем ни того, ни другого: ставим так, как
# апстрим и задумал, и сабмодуль остаётся байт-в-байт чистым.
#
# Ставим ТОЛЬКО QML (-DENABLE_MODULES=shell) и в юзерский XDG — поэтому sudo
# здесь не нужен, а ~/.config/quickshell перебивает /etc/xdg. C++-плагин и
# extras живут в /usr, ставятся отдельно и редко: только когда апстрим трогает
# C++ (см. README рига).
set -euo pipefail

RIG="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
BUILD="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-build"

command -v cmake >/dev/null || { echo "update.sh: нет cmake" >&2; exit 1; }

cmake -S "$RIG/shell" -B "$BUILD" \
      -DENABLE_MODULES=shell \
      -DINSTALL_QSCONFDIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia" \
      >/dev/null
cmake --install "$BUILD" >/dev/null

echo "caelestia: QML переустановлен в ${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
