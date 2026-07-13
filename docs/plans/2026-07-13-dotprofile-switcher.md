# Dotprofile Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Переключатель риг-профилей caelestia ⇄ ilyamiro: симлинк-профили, SDDM-сессии, горячее меню на бинде, общие бинды, воспроизводимость.

**Architecture:** Спорные каталоги (`hypr`, `gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct`) живут в `~/dotfiles/profiles/<name>/`; `~/.config/*` — симлинки через `profiles/active` (симлинк на активный профиль). Один bash-скрипт `dotprofile` управляет всем. Спека: `docs/specs/2026-07-13-dotprofile-switcher-design.md`.

**Tech Stack:** bash, hyprland/hyprctl, hyprkcs (lua-конфиг), quickshell, fuzzel, SDDM wayland-sessions.

## Global Constraints

- Код caelestia и ilyamiro НЕ патчим.
- `profiles/active` — в `.gitignore` (состояние машины).
- Симлинк `active` — относительный (`ln -sfn <name> profiles/active`).
- Опции установщика ilyamiro: SDDM — нет, zsh — нет, nvidia — нет.
- Live-сессия во время миграции: после каждой перестановки симлинков контент должен резолвиться в идентичные файлы.
- Задачи 5–6 требуют пользователя у клавиатуры (интерактивный installer, relogin-тесты).

---

### Task 1: Бэкап + миграция caelestia в профиль

**Files:**
- Create: `~/dotfiles/profiles/caelestia/` (переезд + снапшоты)
- Modify: `~/dotfiles/.gitignore`
- Симлинки: `~/.config/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct}`

**Interfaces:**
- Produces: структура `profiles/caelestia/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct}`, симлинк `profiles/active → caelestia`, симлинки в `~/.config` через `active`. Все последующие задачи полагаются на неё.

- [ ] **Step 1: Бэкап вне репо**

```bash
tar czf ~/config-backup-$(date +%Y%m%d-%H%M).tar.gz \
  -C ~ .config/gtk-3.0 .config/gtk-4.0 .config/qt5ct .config/qt6ct \
  dotfiles/.config/hypr
ls -lh ~/config-backup-*.tar.gz
```
Expected: архив создан, размер > 0.

- [ ] **Step 2: Переезд hypr внутри репо + снапшот gtk/qt**

```bash
cd ~/dotfiles
mkdir -p profiles/caelestia
git mv .config/hypr profiles/caelestia/hypr
cp -a ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/qt5ct ~/.config/qt6ct profiles/caelestia/
ln -sfn caelestia profiles/active
printf 'profiles/active\n' >> .gitignore
```

- [ ] **Step 3: Перестановка симлинков в ~/.config**

`~/.config/hypr` — уже симлинк (перекидываем), gtk/qt — реальные каталоги (убираем в сторону, линкуем).

```bash
ln -sfn ~/dotfiles/profiles/active/hypr ~/.config/hypr
for d in gtk-3.0 gtk-4.0 qt5ct qt6ct; do
  mv ~/.config/$d ~/.config/$d.pre-switcher
  ln -s ~/dotfiles/profiles/active/$d ~/.config/$d
done
```

- [ ] **Step 4: Проверка целостности live-сессии**

```bash
ls -l ~/.config/hypr ~/.config/gtk-4.0
readlink -f ~/.config/hypr   # → /home/shalyn42k/dotfiles/profiles/caelestia/hypr
hyprctl reload && echo RELOAD_OK
test -f ~/.config/hypr/hyprland.lua && echo CONFIG_OK
```
Expected: `RELOAD_OK`, `CONFIG_OK`, рабочий стол не изменился.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add -A && git commit -m "feat: migrate caelestia configs into profiles/caelestia"
```

---

### Task 2: Скрипт `dotprofile` + `session.sh` caelestia

**Files:**
- Create: `~/dotfiles/bin/dotprofile`
- Create: `~/dotfiles/profiles/caelestia/session.sh`

**Interfaces:**
- Consumes: структуру профилей из Task 1.
- Produces: `dotprofile switch <name> [--links-only] | menu | status | update <name>`; контракт `session.sh start|stop`. Task 4 использует `switch --links-only`, Task 5 — `update`.

- [ ] **Step 1: Написать `bin/dotprofile`**

```bash
#!/usr/bin/env bash
# dotprofile — переключатель риг-профилей (см. docs/specs/2026-07-13-*.md)
set -euo pipefail

DOTFILES="$HOME/dotfiles"
PROFILES="$DOTFILES/profiles"
ACTIVE="$PROFILES/active"
CONTESTED=(hypr gtk-3.0 gtk-4.0 qt5ct qt6ct)

usage() {
    echo "usage: dotprofile switch <name> [--links-only] | menu | status | update <name>" >&2
    exit 1
}

current() { [[ -L "$ACTIVE" ]] && basename "$(readlink -f "$ACTIVE")"; }

list_profiles() {
    find "$PROFILES" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

ensure_links() {
    for d in "${CONTESTED[@]}"; do
        ln -sfn "$PROFILES/active/$d" "$HOME/.config/$d"
    done
}

cmd_switch() {
    local name="${1:-}"; [[ -n "$name" ]] || usage
    local links_only="${2:-}"
    [[ -d "$PROFILES/$name" ]] || { echo "no such profile: $name" >&2; exit 1; }
    local old; old="$(current || true)"

    ln -sfn "$name" "$ACTIVE"
    ensure_links

    if [[ "$links_only" != "--links-only" ]]; then
        if [[ -n "$old" && "$old" != "$name" && -x "$PROFILES/$old/session.sh" ]]; then
            "$PROFILES/$old/session.sh" stop || true
        fi
        command -v hyprctl >/dev/null && hyprctl reload || true
        [[ -x "$PROFILES/$name/session.sh" ]] && "$PROFILES/$name/session.sh" start
    fi
    echo "active: $name"
}

cmd_menu() {
    local cur choice
    cur="$(current || true)"
    choice="$(list_profiles | sed "s/^${cur}\$/& (active)/" \
        | fuzzel --dmenu --prompt 'profile> ' --lines 4)" || exit 0
    choice="${choice% (active)}"
    [[ -z "$choice" || "$choice" == "$cur" ]] && exit 0
    cmd_switch "$choice"
}

cmd_status() {
    echo "active: $(current || echo '<none>')"
    for d in "${CONTESTED[@]}"; do
        local t; t="$(readlink "$HOME/.config/$d" 2>/dev/null || echo 'NOT A SYMLINK')"
        printf '  %-8s -> %s\n' "$d" "$t"
    done
}

# update: материализуем симлинки в реальные каталоги, чтобы чужой installer
# писал в них, потом снимаем снапшот обратно в профиль и возвращаем симлинки.
cmd_update() {
    local name="${1:-}"; [[ -d "$PROFILES/$name" ]] || { echo "no such profile: $name" >&2; exit 1; }
    local prev; prev="$(current || echo caelestia)"

    ln -sfn "$name" "$ACTIVE"
    for d in "${CONTESTED[@]}"; do
        rm -f "$HOME/.config/$d"
        cp -a "$PROFILES/$name/$d" "$HOME/.config/$d"
    done
    echo ">>> Каталоги материализованы. Запусти installer профиля '$name'."
    echo ">>> Enter когда installer закончит (или Ctrl+C для отмены):"
    read -r

    for d in "${CONTESTED[@]}"; do
        rm -rf "$PROFILES/$name/${d:?}"
        cp -a "$HOME/.config/$d" "$PROFILES/$name/$d"
        rm -rf "$HOME/.config/${d:?}"
    done
    ensure_links
    ln -sfn "$prev" "$ACTIVE"
    ensure_links
    echo "profile '$name' updated; active: $prev"
}

case "${1:-}" in
    switch) shift; cmd_switch "$@" ;;
    menu)   cmd_menu ;;
    status) cmd_status ;;
    update) shift; cmd_update "$@" ;;
    *) usage ;;
esac
```

```bash
chmod +x ~/dotfiles/bin/dotprofile
```

- [ ] **Step 2: Проверить shellcheck и status**

```bash
shellcheck ~/dotfiles/bin/dotprofile || pacman -Q shellcheck || echo "shellcheck отсутствует — пропустить"
~/dotfiles/bin/dotprofile status
```
Expected: `active: caelestia`, все 5 путей → `profiles/active/...`.

- [ ] **Step 3: Написать `profiles/caelestia/session.sh`**

Команды взяты из `profiles/caelestia/hypr/hyprland/execs.lua` (`qs -c caelestia`) и `keybinds.lua` (`qs -c caelestia kill`). Общесистемные демоны (nm-applet, cliphist, keyring) не трогаем — они риг-независимые.

```bash
#!/usr/bin/env bash
# session.sh — демоны рига caelestia. Контракт: start|stop.
set -u
case "${1:-}" in
    start)
        qs -c caelestia -d
        ;;
    stop)
        qs -c caelestia kill 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
```

```bash
chmod +x ~/dotfiles/profiles/caelestia/session.sh
```

- [ ] **Step 4: Тест switch на месте (no-op путь + полный цикл на одном профиле)**

```bash
~/dotfiles/bin/dotprofile switch caelestia --links-only && ~/dotfiles/bin/dotprofile status
~/dotfiles/bin/dotprofile switch caelestia   # stop+start caelestia shell
```
Expected: `active: caelestia`; после второй команды шелл перезапустился, бар/обои на месте.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add bin/dotprofile profiles/caelestia/session.sh && git commit -m "feat: add dotprofile switcher script and caelestia session"
```

---

### Task 3: Общие бинды + подключение в caelestia

**Files:**
- Create: `~/dotfiles/.config/hypr-shared/binds.conf`
- Modify: `~/dotfiles/.config/caelestia/hypr-user.lua` (сейчас пустой)

**Interfaces:**
- Consumes: `dotprofile menu` из Task 2.
- Produces: `binds.conf` (hyprlang) — Task 5 подключит его в риг ilyamiro строкой `source=`.

- [ ] **Step 1: Создать `binds.conf`**

```conf
# Общие кастомные бинды для всех риг-профилей (hyprlang).
# caelestia: подключается через hypr-user.lua (hl.source)
# ilyamiro:  подключается через source= в его user-конфиге
bind = SUPER SHIFT, D, exec, ~/dotfiles/bin/dotprofile menu
```

- [ ] **Step 2: Подключить в caelestia через `hypr-user.lua`**

hyprkcs API — по образцу `keybinds.lua` (`hl.bind(...)`). В `~/dotfiles/.config/caelestia/hypr-user.lua`:

```lua
-- Переключатель риг-профилей (см. dotfiles/docs/specs/2026-07-13-*.md)
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/dotfiles/bin/dotprofile menu"))
```

Если `hl.source` для hyprlang-файлов поддерживается hyprkcs — использовать его вместо дублирования бинда; проверить: `grep -rn 'hl.source\|source' ~/dotfiles/profiles/caelestia/hypr/hyprland.lua`. Если нет — оставить lua-бинд как выше (единственный дубль, помечен комментарием в обоих файлах).

- [ ] **Step 3: Проверить**

```bash
hyprctl reload && hyprctl binds | grep -A2 -i 'dotprofile'
```
Expected: бинд `SUPER SHIFT D → exec ~/dotfiles/bin/dotprofile menu` в списке. Нажать бинд: fuzzel-меню с `caelestia (active)`.

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles && git add .config/hypr-shared .config/caelestia/hypr-user.lua && git commit -m "feat: add shared binds with profile switcher menu"
```

---

### Task 4: SDDM-сессии

**Files:**
- Create: `~/dotfiles/bin/start-hyprland-profile`
- Create: `~/dotfiles/sddm/hyprland-caelestia.desktop`, `~/dotfiles/sddm/hyprland-ilyamiro.desktop`
- System: копии в `/usr/share/wayland-sessions/` (sudo)

**Interfaces:**
- Consumes: `dotprofile switch <name> --links-only` из Task 2; `/usr/bin/start-hyprland` (штатный лаунчер, из `hyprland.desktop`).
- Produces: два entry на экране входа SDDM.

- [ ] **Step 1: Обёртка `bin/start-hyprland-profile`**

```bash
#!/usr/bin/env bash
# Запуск Hyprland с выбранным риг-профилем (аргумент 1 = имя профиля).
"$HOME/dotfiles/bin/dotprofile" switch "${1:-caelestia}" --links-only
exec /usr/bin/start-hyprland
```

```bash
chmod +x ~/dotfiles/bin/start-hyprland-profile
```

- [ ] **Step 2: .desktop-файлы**

`~/dotfiles/sddm/hyprland-caelestia.desktop`:
```ini
[Desktop Entry]
Name=Hyprland (caelestia)
Comment=Hyprland with caelestia rig profile
Exec=/home/shalyn42k/dotfiles/bin/start-hyprland-profile caelestia
Type=Application
```

`~/dotfiles/sddm/hyprland-ilyamiro.desktop`:
```ini
[Desktop Entry]
Name=Hyprland (ilyamiro)
Comment=Hyprland with ilyamiro rig profile
Exec=/home/shalyn42k/dotfiles/bin/start-hyprland-profile ilyamiro
Type=Application
```

- [ ] **Step 3: Установить в систему**

```bash
sudo cp ~/dotfiles/sddm/hyprland-caelestia.desktop ~/dotfiles/sddm/hyprland-ilyamiro.desktop /usr/share/wayland-sessions/
ls /usr/share/wayland-sessions/
```
Expected: оба файла на месте рядом с `hyprland.desktop`.

- [ ] **Step 4: Dry-run обёртки (без relogin)**

```bash
bash -n ~/dotfiles/bin/start-hyprland-profile && echo SYNTAX_OK
~/dotfiles/bin/dotprofile switch caelestia --links-only && echo LINKS_OK
```
Expected: `SYNTAX_OK`, `LINKS_OK`. Полный relogin-тест — в Task 6.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add bin/start-hyprland-profile sddm/*.desktop && git commit -m "feat: add SDDM session entries per rig profile"
```

---

### Task 5: Установка рига ilyamiro (нужен пользователь у клавиатуры)

**Files:**
- Create: `~/dotfiles/profiles/ilyamiro/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct,session.sh}`
- Modify: user-конфиг ilyamiro-рига (source общих биндов)

**Interfaces:**
- Consumes: `dotprofile update`-механику из Task 2 (материализация каталогов), `binds.conf` из Task 3.
- Produces: рабочий профиль `ilyamiro`; `session.sh start|stop` для него.

- [ ] **Step 1: Заготовка профиля из текущих каталогов**

Installer ilyamiro пишет в `~/.config/hypr` напрямую → материализуем как в `cmd_update`, но профиль создаём копией текущего (бэкапы installer сделает сам в `~/.config-backup-*`):

```bash
mkdir -p ~/dotfiles/profiles/ilyamiro
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct; do
  cp -a ~/dotfiles/profiles/caelestia/$d ~/dotfiles/profiles/ilyamiro/$d
done
~/dotfiles/bin/dotprofile switch ilyamiro --links-only
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct; do
  rm ~/.config/$d && cp -a ~/dotfiles/profiles/ilyamiro/$d ~/.config/$d
done
```

- [ ] **Step 2: Запуск установщика (интерактивно, пользователь отвечает)**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)"
```
Ответы на опции: драйверы — по железу (спросить пользователя), **SDDM — НЕТ, zsh — НЕТ**, neovim — на вкус пользователя. Expected: installer завершился без ошибок, `~/.config/hypr` теперь конфиг ilyamiro.

- [ ] **Step 3: Снапшот в профиль + возврат на caelestia**

```bash
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct; do
  rm -rf ~/dotfiles/profiles/ilyamiro/$d
  cp -a ~/.config/$d ~/dotfiles/profiles/ilyamiro/$d
  rm -rf ~/.config/$d
done
~/dotfiles/bin/dotprofile switch caelestia --links-only
~/dotfiles/bin/dotprofile status
```
Expected: `active: caelestia`, симлинки целы. Caelestia-сессия работает как раньше (`hyprctl reload`).

- [ ] **Step 4: `session.sh` для ilyamiro**

Точные команды взять из его конфига:
```bash
grep -rn 'exec-once' ~/dotfiles/profiles/ilyamiro/hypr/ | grep -viE 'nm-applet|polkit|keyring|cliphist'
```
Шаблон (уточнить по факту grep — имена/пути quickshell-конфига и обоев из `qs_manager.sh`):
```bash
#!/usr/bin/env bash
# session.sh — демоны рига ilyamiro. Контракт: start|stop.
set -u
case "${1:-}" in
    start)
        swww-daemon &
        # команда запуска его quickshell — точная строка из exec-once (см. grep выше)
        bash ~/.config/hypr/scripts/qs_manager.sh &
        ;;
    stop)
        pkill -f 'qs_manager|quickshell' 2>/dev/null || true
        pkill mpvpaper 2>/dev/null || true
        pkill swww-daemon 2>/dev/null || true
        ;;
    *) echo "usage: session.sh start|stop" >&2; exit 1 ;;
esac
```
ВАЖНО: строку запуска quickshell вписать точную из grep, шаблонную — заменить. `chmod +x`.

- [ ] **Step 5: Подключить общие бинды в риг ilyamiro**

В его hypr-конфиге найти user-include (`grep -rn 'source' ~/dotfiles/profiles/ilyamiro/hypr/*.conf | head`) и добавить в соответствующий user-файл:
```conf
source = ~/dotfiles/.config/hypr-shared/binds.conf
```
Если у него бинд SUPER+SHIFT+D уже занят — конфликт решить переименованием НАШЕГО бинда в binds.conf (и коммитом).

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles && git add -A && git commit -m "feat: add ilyamiro rig profile with session script"
```

---

### Task 6: E2E-тесты переключения (пользователь смотрит глазами)

**Files:** нет новых; только проверки и push.

- [ ] **Step 1: Горячее переключение caelestia → ilyamiro**

```bash
~/dotfiles/bin/dotprofile switch ilyamiro
```
Expected: caelestia-шелл погас, шелл ilyamiro поднялся, hyprctl reload прошёл. Пользователь подтверждает визуал (бар, обои, бинды). `SUPER+SHIFT+D` открывает меню и там `ilyamiro (active)`.

- [ ] **Step 2: Горячее обратно**

```bash
~/dotfiles/bin/dotprofile switch caelestia
```
Expected: caelestia вернулась целиком. Известные допустимые артефакты: темы уже открытых окон, env.

- [ ] **Step 3: Relogin-тест через SDDM (обе сессии)**

Пользователь: logout → на экране SDDM выбрать «Hyprland (ilyamiro)» → войти → проверить → logout → «Hyprland (caelestia)» → войти. Expected: каждая сессия поднимается со своим ригом, `dotprofile status` показывает верный профиль.

- [ ] **Step 4: Видео-обои в риге ilyamiro**

Положить тестовый mp4 в его каталог обоев (путь из `WallpaperPicker.qml`, обычно `~/Pictures/wallpapers` или его настройка), открыть его пикер, фильтр «Video», применить. Expected: mpvpaper запущен (`pgrep -a mpvpaper`), видео на фоне.

- [ ] **Step 5: Финальный commit + push**

```bash
cd ~/dotfiles && git add -A && git commit -m "chore: finalize dotprofile switcher rollout" --allow-empty
git push
```

---

### Task 7: `bootstrap.sh` (воспроизводимость с нуля)

**Files:**
- Create: `~/dotfiles/bootstrap.sh`

**Interfaces:**
- Consumes: всю структуру репо из Task 1–5.
- Produces: одна команда для новой машины. На текущей машине проверяется только идемпотентность (ничего не ломает при повторном запуске).

- [ ] **Step 1: Написать `bootstrap.sh`**

```bash
#!/usr/bin/env bash
# bootstrap.sh — развёртывание сетапа с нуля на Arch.
# Идемпотентен: повторный запуск безопасен.
set -euo pipefail

DOTFILES="$HOME/dotfiles"
cd "$DOTFILES"

echo "== 1/5 Пакеты =="
sudo pacman -S --needed --noconfirm hyprland quickshell-git fuzzel fish foot \
    swww mpvpaper ffmpeg qt6-multimedia python-pillow \
    gtk3 gtk4 qt5ct qt6ct sddm 2>/dev/null \
    || echo "часть пакетов из AUR — поставить хелпером: yay -S --needed quickshell-git caelestia-cli"

echo "== 2/5 Caelestia (апстрим) =="
command -v caelestia >/dev/null || yay -S --needed caelestia-cli
caelestia install || echo "caelestia уже установлена — пропуск"

echo "== 3/5 Риг ilyamiro (апстрим, интерактивно) =="
if [[ ! -d "$DOTFILES/profiles/ilyamiro/hypr" ]]; then
    echo "профиль ilyamiro пуст — установи риг через: dotprofile update ilyamiro"
fi

echo "== 4/5 Симлинки профилей =="
[[ -L "$DOTFILES/profiles/active" ]] || ln -sfn caelestia "$DOTFILES/profiles/active"
for d in hypr gtk-3.0 gtk-4.0 qt5ct qt6ct; do
    if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
        mv "$HOME/.config/$d" "$HOME/.config/$d.pre-bootstrap"
    fi
    ln -sfn "$DOTFILES/profiles/active/$d" "$HOME/.config/$d"
done
for d in caelestia fish foot fastfetch; do
    [[ -d "$DOTFILES/.config/$d" ]] && ln -sfn "$DOTFILES/.config/$d" "$HOME/.config/$d"
done

echo "== 5/5 SDDM =="
sudo cp "$DOTFILES"/sddm/hyprland-*.desktop /usr/share/wayland-sessions/
sudo systemctl enable sddm

"$DOTFILES/bin/dotprofile" status
echo "Готово. Relogin через SDDM → выбрать сессию профиля."
```

```bash
chmod +x ~/dotfiles/bootstrap.sh
```

- [ ] **Step 2: Проверка синтаксиса и идемпотентности симлинк-части**

```bash
bash -n ~/dotfiles/bootstrap.sh && echo SYNTAX_OK
shellcheck ~/dotfiles/bootstrap.sh || true
```
Expected: `SYNTAX_OK`. Полный прогон — только на новой машине; на текущей не запускать целиком (pacman/sddm шаги безвредны, но не нужны).

- [ ] **Step 3: Commit + push**

```bash
cd ~/dotfiles && git add bootstrap.sh && git commit -m "feat: add bootstrap script for fresh installs" && git push
```

---

## Откаты

- После Task 1–4: `~/dotfiles/bin/dotprofile switch caelestia --links-only`; полный откат — распаковать `~/config-backup-*.tar.gz`, `git revert`.
- После Task 5: риг не понравился → `dotprofile switch caelestia`, каталог `profiles/ilyamiro` можно удалить, sddm-entry убрать (`sudo rm /usr/share/wayland-sessions/hyprland-ilyamiro.desktop`).
