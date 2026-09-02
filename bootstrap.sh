#!/usr/bin/env bash
# bootstrap.sh — развёртывание dual-rig сетапа (caelestia + ilyamiro) с нуля
# на Arch. Репозиторий уже содержит оба профиля целиком (снапшоты) — скрипт
# ставит пакеты, раскладывает симлинки и SDDM-сессии.
# Идемпотентен: повторный запуск ничего не ломает.
set -euo pipefail

DOTFILES="$HOME/dotfiles"
cd "$DOTFILES"

# ─────────────────────────────────────────────────────────────────────────
echo "== 1/7 Пакеты =="
# ВАЖНО: hyprland нужен с lua config provider (0.55+; сборка CachyOS или git) —
# профиль caelestia использует hyprland.lua.
PKGS=(
    # WM + сессия
    hyprland hypridle hyprpolkitagent hyprpicker sddm
    # шеллы обоих ригов
    quickshell caelestia-cli
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
    # kbd-theme-sync: PIL читает обои, asusctl красит подсветку (только ASUS —
    # на другом железе скрипт молча ничего не делает)
    python-pillow asusctl
    # кастомное
    hyprkcs-git
    # serpantinum: единственная его зависимость, которой не было у ilyamiro v1
    wl-gammarelay-rs
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
echo "== 2/7 Caelestia shell =="
if [[ -d /etc/xdg/quickshell/caelestia || -d "$HOME/.config/quickshell/caelestia" ]]; then
    echo "caelestia shell найден"
else
    echo ">>> caelestia shell не установлен. Варианты:"
    echo ">>>   yay -S caelestia-shell-git"
    echo ">>>   или: git clone https://github.com/caelestia-dots/shell ~/caelestia"
    echo ">>>        cd ~/caelestia && cmake -B build && cmake --build build && sudo cmake --install build"
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== 3/7 Симлинки профилей =="
[[ -L "$DOTFILES/profiles/active" ]] || ln -sfn caelestia "$DOTFILES/profiles/active"
# CONTESTED-каталоги (см. bin/dotprofile): свой у каждого рига, симлинк на active.
# matugen тоже контестируемый — риги держат разные config.toml, пишущие в общие
# пути (gtk.css, fuzzel, colors.lua); caelestia matugen не юзает.
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct matugen; do
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

# rigswitch — overlay-свитчер ригов, вложен в ~/.config/quickshell рядом с
# конфигами шеллов ригов, поэтому не в списке выше.
mkdir -p "$HOME/.config/quickshell"
ln -sfn "$DOTFILES/.config/quickshell/rigswitch" "$HOME/.config/quickshell/rigswitch"

# Вендоренный апстрим serpantinum. Клон репы без --recurse-submodules оставляет
# profiles/serpantinum/shell пустым, и риг не стартует.
if [[ -f "$DOTFILES/.gitmodules" ]]; then
    git -C "$DOTFILES" submodule update --init --recursive
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== 4/7 Каталоги =="
mkdir -p "$HOME/Pictures/Wallpapers"
xdg-user-dirs-update 2>/dev/null || true

# matugen теперь контестируемый (симлинк на profiles/active/matugen выше) —
# config.toml + templates/ живут в профиле целиком, копировать в живой каталог
# не нужно. Discord/Obsidian-шаблоны и их [templates.*] уже в снапшоте ilyamiro.

# ─────────────────────────────────────────────────────────────────────────
echo "== 5/7 Скрипты и systemd-юниты =="
# Скрипты живут в репо; ~/.local/bin — симлинки на них, потому что юниты и
# session.sh зовут их по %h/.local/bin/<имя>.
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
for s in kbd-theme-sync thunar-css-fix; do
    ln -sfn "$DOTFILES/bin/$s" "$HOME/.local/bin/$s"
done
# kbd-theme-sync.path  — подсветка клавиатуры за цветом обоев активного рига
# thunar-css-fix.path  — откатывает thunar.css, который caelestia CLI
#                        перерендеривает на каждой смене схемы (upstream PR #122)
cp "$DOTFILES"/.config/systemd/user/*.{service,path} "$HOME/.config/systemd/user/"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now kbd-theme-sync.path thunar-css-fix.path 2>/dev/null \
    || echo ">>> нет systemd --user сессии — юниты включатся после relogin"

# ─────────────────────────────────────────────────────────────────────────
echo "== 6/7 SDDM-сессии =="
# В репо Exec захардкожен на /home/shalyn42k — подставляем текущий $HOME.
tmpd="$(mktemp -d)"
for f in "$DOTFILES"/sddm/hyprland-*.desktop; do
    sed "s|/home/shalyn42k|$HOME|g" "$f" > "$tmpd/$(basename "$f")"
done
# Цель — РОВНО две записи в греетере: наша «Hyprland (rig)» и plasma как
# запасное DE. Остальное убираем: прежние per-rig записи промахиваются мимо
# profiles/active, а пакетные запускают композитор в обход
# start-hyprland-profile (симлинки ~/.config остаются от прежнего рига).
STALE_OURS=(hyprland-caelestia hyprland-lua hyprland-ilyamiro hyprland-end4)
# Пакетные (владелец — hyprland): голая запись и uwsm, которого мы не ставим.
# Их мало удалить — pacman вернёт файлы при обновлении, молча и без .pacnew,
# потому что это /usr/share, а не /etc. Отсюда NoExtract ниже.
STALE_PKG=(hyprland hyprland-uwsm)

if sudo -n true 2>/dev/null || sudo -v; then
    for n in "${STALE_OURS[@]}" "${STALE_PKG[@]}"; do
        sudo rm -f "/usr/share/wayland-sessions/$n.desktop"
    done
    sudo cp "$tmpd"/hyprland-*.desktop /usr/share/wayland-sessions/
    sudo systemctl enable sddm 2>/dev/null || true

    # Update-proof: без этого запись возвращается при каждом обновлении hyprland.
    for n in "${STALE_PKG[@]}"; do
        line="NoExtract   = usr/share/wayland-sessions/$n.desktop"
        grep -qxF "$line" /etc/pacman.conf \
            || echo "$line" | sudo tee -a /etc/pacman.conf >/dev/null
    done
else
    echo ">>> нет sudo — вручную:"
    echo ">>>   sudo cp $tmpd/hyprland-*.desktop /usr/share/wayland-sessions/"
    echo ">>>   и удалить лишние записи (см. STALE_OURS/STALE_PKG выше)"
fi
rm -rf "$tmpd"

# ─────────────────────────────────────────────────────────────────────────
echo "== 7/7 Статус =="
# первичный рендер генерируемых конфигов (fastfetch)
"$DOTFILES/bin/dotprofile" colors 2>/dev/null || true
"$DOTFILES/bin/dotprofile" status
echo
echo "Готово. Дальше:"
echo "  1. Положи обои (jpg/png/mp4) в ~/Pictures/Wallpapers"
echo "  2. Relogin через SDDM → 'Hyprland (rig)'"
echo "  3. Переключение на лету: SUPER+SHIFT+D"
