#!/usr/bin/env bash
# bootstrap.sh — развёртывание dual-rig сетапа (caelestia + ilyamiro) с нуля
# на Arch. Репозиторий уже содержит оба профиля целиком (снапшоты) — скрипт
# ставит пакеты, раскладывает симлинки и SDDM-сессии.
# Идемпотентен: повторный запуск ничего не ломает.
set -euo pipefail

DOTFILES="$HOME/dotfiles"
cd "$DOTFILES"

# ─────────────────────────────────────────────────────────────────────────
echo "== 1/6 Пакеты =="
# ВАЖНО: hyprland нужен с lua config provider (0.55+; сборка CachyOS или git) —
# профиль caelestia использует hyprland.lua.
PKGS=(
    # WM + сессия
    hyprland hypridle hyprpolkitagent hyprpicker sddm
    # шеллы обоих ригов
    quickshell-git caelestia-cli
    # терминал/шелл/лаунчер
    foot fish fuzzel
    # обои (awww = форк swww; mpvpaper = видео)
    awww mpvpaper
    # его риг: OSD, скриншоты, тема
    swayosd-git grim satty zbar matugen-bin
    # интеграция
    app2unit cliphist wl-clipboard playerctl
    # сервисы из execs
    gnome-keyring network-manager-applet gammastep geoclue bluez-utils
    easyeffects trash-cli
    # тулкиты/темы
    qt5ct qt6ct xdg-user-dirs volantes_cursors
    ttf-jetbrains-mono-nerd
    # утилиты скриптов
    jq inotify-tools luajit imagemagick curl
    # кастомное
    hyprkcs-git
)
missing=()
for p in "${PKGS[@]}"; do pacman -Qi "$p" &>/dev/null || missing+=("$p"); done
if ((${#missing[@]})); then
    echo "не хватает: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}" 2>/dev/null || true
    still=()
    for p in "${missing[@]}"; do pacman -Qi "$p" &>/dev/null || still+=("$p"); done
    if ((${#still[@]})); then
        if command -v yay >/dev/null; then yay -S --needed "${still[@]}"
        elif command -v paru >/dev/null; then paru -S --needed "${still[@]}"
        else echo ">>> AUR-хелпера нет — поставь вручную: ${still[*]}"; fi
    fi
else
    echo "все пакеты на месте"
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== 2/6 Caelestia shell =="
if [[ -d /etc/xdg/quickshell/caelestia || -d "$HOME/.config/quickshell/caelestia" ]]; then
    echo "caelestia shell найден"
else
    echo ">>> caelestia shell не установлен. Варианты:"
    echo ">>>   yay -S caelestia-shell-git"
    echo ">>>   или: git clone https://github.com/caelestia-dots/shell ~/caelestia"
    echo ">>>        cd ~/caelestia && cmake -B build && cmake --build build && sudo cmake --install build"
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== 3/6 Симлинки профилей =="
[[ -L "$DOTFILES/profiles/active" ]] || ln -sfn caelestia "$DOTFILES/profiles/active"
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct; do
    if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
        echo "бэкап живого ~/.config/$d -> $d.pre-bootstrap"
        mv "$HOME/.config/$d" "$HOME/.config/$d.pre-bootstrap"
    fi
    ln -sfn "$DOTFILES/profiles/active/$d" "$HOME/.config/$d"
done
for d in caelestia fish foot fastfetch; do
    [[ -d "$DOTFILES/.config/$d" ]] || continue
    if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
        mv "$HOME/.config/$d" "$HOME/.config/$d.pre-bootstrap"
    fi
    ln -sfn "$DOTFILES/.config/$d" "$HOME/.config/$d"
done

# ─────────────────────────────────────────────────────────────────────────
echo "== 4/6 Каталоги =="
mkdir -p "$HOME/Pictures/Wallpapers"
xdg-user-dirs-update 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────
echo "== 5/6 SDDM-сессии =="
# В репо Exec захардкожен на /home/shalyn42k — подставляем текущий $HOME.
tmpd="$(mktemp -d)"
for f in "$DOTFILES"/sddm/hyprland-*.desktop; do
    sed "s|/home/shalyn42k|$HOME|g" "$f" > "$tmpd/$(basename "$f")"
done
if sudo -n true 2>/dev/null || sudo -v; then
    sudo cp "$tmpd"/hyprland-*.desktop /usr/share/wayland-sessions/
    sudo systemctl enable sddm 2>/dev/null || true
else
    echo ">>> нет sudo — вручную: sudo cp $tmpd/hyprland-*.desktop /usr/share/wayland-sessions/"
fi
rm -rf "$tmpd"

# ─────────────────────────────────────────────────────────────────────────
echo "== 6/6 Статус =="
# первичный рендер генерируемых конфигов (fastfetch)
"$DOTFILES/bin/dotprofile" colors 2>/dev/null || true
"$DOTFILES/bin/dotprofile" status
echo
echo "Готово. Дальше:"
echo "  1. Положи обои (jpg/png/mp4) в ~/Pictures/Wallpapers"
echo "  2. Relogin через SDDM → сессия 'Hyprland (caelestia)' или 'Hyprland (ilyamiro)'"
echo "  3. Переключение на лету: SUPER+SHIFT+D"
