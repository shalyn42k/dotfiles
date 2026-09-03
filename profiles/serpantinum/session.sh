#!/usr/bin/env bash
# session.sh — демоны рига serpantinum. Контракт: start|stop.
#
# Апстрим вендорится в shell/ (submodule) и запускается через SERPANTINUM_DIR:
# системная установка не нужна, их install.sh мы не запускаем никогда
# (sudo pacman -Syyu --noconfirm + отбрасывание существующего конфига).
set -u

RIG="$HOME/dotfiles/profiles/serpantinum"
export SERPANTINUM_DIR="$RIG/shell/src"
SERPANTINUMD="$RIG/shell/bin/serpantinumd"

SHELL_COLORS="$HOME/.local/state/serpantinum/qs_colors.json"

# Первый запуск: у шелла нет палитры, пока в риге не сменили обои — он красит
# себя сам, но только по событию смены. Без файла ThemeBackend поднимается без
# цветов, и риг выглядит как чёрный экран с невидимым баром (поймано на первом
# реальном логине 2026-09-03). Засеваем один раз из текущих обоев; дальше
# палитру ведёт сам шелл и сюда мы больше не заходим.
#
# --source-color-index 0 — тем же аргументом зовёт matugen сам шелл
# (singletons/Matugen.qml). Без него matugen на многоцветных обоях требует
# интерактивного выбора и падает в неинтерактивной сессии.
seed_shell_colors() {
    [[ -f "$SHELL_COLORS" ]] && return 0
    command -v matugen >/dev/null || return 0

    local wp
    for wp in "$(cat "$HOME/.local/state/caelestia/wallpaper/path.txt" 2>/dev/null)" \
              "$HOME/.cache/serpantinum/wallpaper/current_wallpaper.png"; do
        [[ -f "$wp" ]] || continue
        mkdir -p "$(dirname "$SHELL_COLORS")"
        matugen --config "$RIG/matugen/shell-seed.toml" \
                --source-color-index 0 -m dark image "$wp" >/dev/null 2>&1 && return 0
    done
    echo "session.sh: не нашёл обоев для засева палитры — шелл поднимется без цветов" >&2
}

# Настройки шелла. Бар показывается ТОЛЬКО если в settings.json есть секция
# bar: Bar.qml гасит окно, пока `Config.rawSettings.bar.autohide === undefined`
# (bar/Bar.qml:81-85). Апстрим раскладывает свой дефолт config/serpantinum/
# инсталлером, который мы не запускаем никогда — и без него шелл поднимается
# молча, с обоями и без единого элемента интерфейса. Ровно это и выглядело как
# «риг не работает»: процесс жив, слоёв два (обои и оверлей), бара нет.
#
# Дефолт кладём как БАЗУ, а поверх — то, что уже есть у пользователя: шелл сам
# дописывает в этот файл настройки, и затирать их нельзя.
seed_shell_settings() {
    local user="$HOME/.config/serpantinum/settings.json"
    local default="$RIG/shell/config/serpantinum/settings.json"
    [[ -f "$default" ]] || return 0
    command -v python3 >/dev/null || return 0

    python3 - "$default" "$user" <<'PY'
import json, sys, pathlib

default_path, user_path = sys.argv[1], pathlib.Path(sys.argv[2])
default = json.load(open(default_path))
user = {}
if user_path.exists():
    try:
        user = json.load(open(user_path))
    except json.JSONDecodeError:
        pass   # битый файл: дефолт лучше, чем шелл без интерфейса

if "bar" in user:
    raise SystemExit(0)   # уже полноценный конфиг, не трогаем

def merge(base, over):
    out = dict(base)
    for k, v in over.items():
        out[k] = merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out

user_path.parent.mkdir(parents=True, exist_ok=True)
user_path.write_text(json.dumps(merge(default, user), indent=2) + "\n")
PY
}

case "${1:-}" in
    start)
        seed_shell_settings
        seed_shell_colors
        if [[ -x "$SERPANTINUMD" ]]; then
            "$SERPANTINUMD" start &
        else
            echo "session.sh: нет $SERPANTINUMD — забыт git submodule update --init" >&2
        fi
        "$HOME/.local/bin/kbd-theme-sync" &
        ;;
    stop)
        [[ -x "$SERPANTINUMD" ]] && "$SERPANTINUMD" stop 2>/dev/null || true
        # Подстраховка: serpantinumd мог не успеть подняться и не знает про свой
        # quickshell. Матчим по пути Shell.qml вендоренной копии, чтобы не задеть
        # шелл другого рига (-c caelestia, -c rigswitch).
        pkill -f "$RIG/shell/src/quickshell" 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
