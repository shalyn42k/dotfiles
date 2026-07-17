# Rig Switch Engine-Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Свитч ригов выбирает режим по конфиг-движку цели: caelestia↔end4 (lua↔lua) горячий свитч, любой↔ilyamiro (кросс-движок) через релогин в SDDM.

**Architecture:** `dotprofile switch` определяет движок цели (наличие `hyprland.lua`) и запущенного (`hyprctl systeminfo`). Совпали → горячий свитч (как сейчас). Не совпали → релогин (записать `~/.dmrc` + `profiles/.last-lua`, выйти в SDDM грайтер). SDDM три сессии → две (`hyprland-lua` + `hyprland-ilyamiro`); lua-сессия читает `.last-lua`.

**Tech Stack:** bash, Hyprland (hyprctl), SDDM (`.desktop` в `/usr/share/wayland-sessions/`), fish-совместимость не требуется (скрипты `#!/usr/bin/env bash`).

## Global Constraints

- Все правки shell — `#!/usr/bin/env bash`, `set -euo pipefail` где уже есть; не ломать.
- `DOTFILES="$HOME/dotfiles"`, `PROFILES="$DOTFILES/profiles"`, `ACTIVE="$PROFILES/active"` — существующие переменные `dotprofile`, использовать их.
- Движковая карта фиксирована: caelestia=lua, end4=lua, ilyamiro=hyprlang. Признак lua = существует `profiles/<name>/hypr/hyprland.lua`.
- SDDM `.desktop` в репо хранят `Exec=/home/shalyn42k/...`; `bootstrap.sh` подставляет `$HOME` при install. Новые файлы — тот же захардкоженный префикс.
- Установленные `.desktop` в `/usr/share/wayland-sessions/` — root-owned; правка через `sudo`.
- Верификация shell: `bash -n <file>` обязателен; `shellcheck <file>` если установлен (`command -v shellcheck`).
- Каждый коммит — на ветке `rig-switch-engine-split` (уже создана, там лежит спека).

---

### Task 1: SDDM три сессии → две (`hyprland-lua` + `hyprland-ilyamiro`)

**Files:**
- Create: `sddm/hyprland-lua.desktop`
- Delete: `sddm/hyprland-caelestia.desktop`, `sddm/hyprland-end4.desktop`
- Keep unchanged: `sddm/hyprland-ilyamiro.desktop`
- Runtime install target: `/usr/share/wayland-sessions/` (root)

**Interfaces:**
- Produces: имена SDDM-сессий `hyprland-lua`, `hyprland-ilyamiro` — Task 2 (`session_desktop`) и Task 5 (`start-hyprland-profile`) на них ссылаются.

- [ ] **Step 1: Создать `sddm/hyprland-lua.desktop`**

```ini
[Desktop Entry]
Name=Hyprland (lua rig)
Comment=Hyprland lua-провайдер: caelestia/end4 (горячий свитч SUPER+SHIFT+D)
Exec=/home/shalyn42k/dotfiles/bin/start-hyprland-profile --lua
Type=Application
```

- [ ] **Step 2: Удалить старые репо-desktop caelestia/end4**

```bash
git rm sddm/hyprland-caelestia.desktop sddm/hyprland-end4.desktop
```

- [ ] **Step 3: Проверить, что остались ровно 2 репо-desktop**

Run: `ls sddm/*.desktop`
Expected: `sddm/hyprland-ilyamiro.desktop  sddm/hyprland-lua.desktop`

- [ ] **Step 4: Установить в wayland-sessions, снести stale caelestia/end4**

```bash
sudo rm -f /usr/share/wayland-sessions/hyprland-caelestia.desktop \
           /usr/share/wayland-sessions/hyprland-end4.desktop
tmpd="$(mktemp -d)"
for f in sddm/hyprland-*.desktop; do
    sed "s|/home/shalyn42k|$HOME|g" "$f" > "$tmpd/$(basename "$f")"
done
sudo cp "$tmpd"/hyprland-*.desktop /usr/share/wayland-sessions/
rm -rf "$tmpd"
```

- [ ] **Step 5: Проверить установленные сессии**

Run: `ls /usr/share/wayland-sessions/hyprland-*.desktop`
Expected: присутствуют `hyprland-lua.desktop`, `hyprland-ilyamiro.desktop`; ОТСУТСТВУЮТ `hyprland-caelestia.desktop`, `hyprland-end4.desktop` (generic `hyprland.desktop`/`hyprland-uwsm.desktop` не трогаем).

- [ ] **Step 6: Дефолт грайтера → lua-сессия**

```bash
printf '[Desktop]\nSession=hyprland-lua\n' > "$HOME/.dmrc"
```

Run: `cat "$HOME/.dmrc"`
Expected: `Session=hyprland-lua`

- [ ] **Step 7: Коммит**

```bash
git add sddm/hyprland-lua.desktop
git commit -m "sddm: слить caelestia+end4 в одну lua-сессию (3 сессии -> 2)"
```

---

### Task 2: `dotprofile` — режим-детект движка + горячий/релогин ветвление

**Files:**
- Modify: `bin/dotprofile` (добавить хелперы; переписать `cmd_switch`)

**Interfaces:**
- Consumes: `hyprland-lua`, `hyprland-ilyamiro` (имена сессий из Task 1).
- Produces:
  - `rig_engine <name>` → печатает `lua` или `hyprlang`.
  - `session_desktop <name>` → печатает basename SDDM-сессии без `.desktop`.
  - `write_last_lua <name>` → пишет `profiles/.last-lua` если `<name>` — lua-риг.
  - `trigger_relogin <name>` → готовит релогин и выходит из сессии (не возвращается).
  - `profiles/.last-lua` — файл с именем последнего lua-рига (читает Task 5).

- [ ] **Step 1: Тест «мёртвый кросс-движковый note ещё в коде» (должен упасть после правки)**

Run: `grep -n 'применятся после relogin' bin/dotprofile`
Expected СЕЙЧАС: строка найдена (~219). После Task 2 команда должна давать пусто (exit 1). Это маркер удаления кросс-движковой ветки.

- [ ] **Step 2: Добавить хелперы после `hypr_provider()`**

В `bin/dotprofile` найти конец функции `hypr_provider()` (строка `}` после `awk ... configProvider`). Сразу ПОСЛЕ неё вставить:

```bash
# Движок конфига рига: lua если есть hyprland.lua, иначе hyprlang.
rig_engine() {
    [[ -f "$PROFILES/$1/hypr/hyprland.lua" ]] && echo lua || echo hyprlang
}

# Имя SDDM-сессии (.desktop без расширения) для рига. Все lua-риги делят
# одну сессию hyprland-lua; ilyamiro — своя.
session_desktop() {
    [[ "$(rig_engine "$1")" == lua ]] && echo hyprland-lua || echo "hyprland-$1"
}

# Запомнить последний lua-риг — hyprland-lua сессия стартует в него (Task 5).
write_last_lua() {
    [[ "$(rig_engine "$1")" == lua ]] && echo "$1" > "$PROFILES/.last-lua" || true
}

# Кросс-движковый переход невозможен в живой сессии (Hyprland фиксирует
# движок при старте). Готовим релогин: active уже переключён вызывающим,
# ставим подсветку целевой сессии в SDDM и выходим. exec — не возвращаемся.
trigger_relogin() {
    local name="$1"
    write_last_lua "$name"
    printf '[Desktop]\nSession=%s\n' "$(session_desktop "$name")" > "$HOME/.dmrc"
    echo "relogin -> $name (сессия $(session_desktop "$name")); выхожу в SDDM..."
    systemctl --user stop graphical-session.target 2>/dev/null || true
    sleep 0.3
    if [[ "$(hypr_provider)" == lua ]]; then
        hyprctl dispatch 'hl.dsp.exit()'
    else
        hyprctl dispatch exit
    fi
}
```

- [ ] **Step 3: Переписать `cmd_switch` — заменить кросс-движковый блок на ветвление**

Заменить всю функцию `cmd_switch` (от `cmd_switch() {` до её закрывающей `}` перед `cmd_menu()`) на:

```bash
cmd_switch() {
    local name="${1:-}"; [[ -n "$name" ]] || usage
    local links_only="${2:-}"
    [[ -d "$PROFILES/$name" ]] || { echo "no such profile: $name" >&2; exit 1; }
    local old; old="$(current || true)"

    ln -sfn "$name" "$ACTIVE"
    ensure_links

    if [[ "$links_only" == "--links-only" ]]; then
        echo "active: $name"
        return 0
    fi

    # Кросс-движковый переход — только через релогин (не возвращается).
    if command -v hyprctl >/dev/null; then
        local target running
        target="$(rig_engine "$name")"
        running="$(hypr_provider)"
        if [[ -n "$running" && "$running" != "$target" ]]; then
            trigger_relogin "$name"
            return 0
        fi
    fi

    # Одномувижковый горячий свитч.
    if [[ -n "$old" && -x "$PROFILES/$old/session.sh" ]]; then
        "$PROFILES/$old/session.sh" stop || true
    fi
    command -v hyprctl >/dev/null && hyprctl reload || true
    [[ -x "$PROFILES/$name/session.sh" ]] && "$PROFILES/$name/session.sh" start
    if command -v hyprctl >/dev/null; then
        apply_rig_colors "$name"
        apply_rig_animations "$name"
    fi
    write_last_lua "$name"
    echo "active: $name"
}
```

- [ ] **Step 4: Синтаксис-проверка**

Run: `bash -n bin/dotprofile && command -v shellcheck >/dev/null && shellcheck bin/dotprofile || echo "bash -n ok (shellcheck skipped/clean)"`
Expected: без ошибок синтаксиса (shellcheck-варнинги о существующем коде допустимы, новых ошибок быть не должно).

- [ ] **Step 5: Тест хелперов резолвинга**

Run:
```bash
bash -c 'source bin/dotprofile 2>/dev/null; PROFILES="$HOME/dotfiles/profiles"; \
  echo "caelestia=$(rig_engine caelestia)/$(session_desktop caelestia)"; \
  echo "end4=$(rig_engine end4)/$(session_desktop end4)"; \
  echo "ilyamiro=$(rig_engine ilyamiro)/$(session_desktop ilyamiro)"'
```
Expected:
```
caelestia=lua/hyprland-lua
end4=lua/hyprland-lua
ilyamiro=hyprlang/hyprland-ilyamiro
```
(Если `source` падает из-за `case "$1"` внизу файла — обернуть: запустить хелперы через `bash -c 'eval "$(sed -n "/^rig_engine()/,/^}/p;/^session_desktop()/,/^}/p" bin/dotprofile)"; ...'`. Смысл проверки — три строки выше.)

- [ ] **Step 6: Тест «кросс-движковый note удалён»**

Run: `grep -c 'применятся после relogin\|disable_autoreload' bin/dotprofile`
Expected: `0`

- [ ] **Step 7: Коммит**

```bash
git add bin/dotprofile
git commit -m "dotprofile: релогин на кросс-движковом свитче вместо частичного hot-switch"
```

---

### Task 3: `dotprofile` — упростить `apply_rig_colors`/`apply_rig_animations` до lua-only

**Files:**
- Modify: `bin/dotprofile` (`apply_rig_colors`, `apply_rig_animations`)

**Interfaces:**
- Consumes: `hypr_provider()`, `rig_engine()` (Task 2).
- Produces: те же функции, но без hyprlang-веток (свитч теперь только lua↔lua).

- [ ] **Step 1: Убрать hyprlang-ветку применения цветов рамок в `apply_rig_colors`**

Найти в `apply_rig_colors` блок:

```bash
    if [[ "$(hypr_provider)" == lua ]]; then
        hyprctl eval "hl.config({
            general = { col = { active_border = '$active', inactive_border = '$inactive' } },
            group = { col = {
                border_active = '$active', border_inactive = '$inactive',
                border_locked_active = '$active', border_locked_inactive = '$inactive',
            } },
        })" >/dev/null || true
    else
        hyprctl keyword general:col.active_border "$active" >/dev/null || true
        hyprctl keyword general:col.inactive_border "$inactive" >/dev/null || true
        hyprctl keyword group:col.border_active "$active" >/dev/null || true
        hyprctl keyword group:col.border_inactive "$inactive" >/dev/null || true
        hyprctl keyword group:col.border_locked_active "$active" >/dev/null || true
        hyprctl keyword group:col.border_locked_inactive "$inactive" >/dev/null || true
    fi
```

Заменить на (только lua-ветка, безусловно):

```bash
    hyprctl eval "hl.config({
        general = { col = { active_border = '$active', inactive_border = '$inactive' } },
        group = { col = {
            border_active = '$active', border_inactive = '$inactive',
            border_locked_active = '$active', border_locked_inactive = '$inactive',
        } },
    })" >/dev/null || true
```

- [ ] **Step 2: Упростить `apply_rig_animations` до lua-only**

Заменить всю функцию `apply_rig_animations` на:

```bash
# Анимации живут в конфиг-движке — применяем набор активного рига runtime.
# Свитч теперь только lua↔lua, поэтому единственная ветка — lua.
apply_rig_animations() {
    local name="$1"
    local chunk="$PROFILES/$name/animations-runtime.lua"
    [[ -f "$chunk" ]] && hyprctl eval "dofile('$chunk')" >/dev/null || true
}
```

- [ ] **Step 3: Проверить, что `.keywords` больше не читается кодом**

Run: `grep -n 'animations-runtime.keywords' bin/dotprofile`
Expected: пусто (exit 1).

- [ ] **Step 4: Синтаксис-проверка**

Run: `bash -n bin/dotprofile && echo ok`
Expected: `ok`

- [ ] **Step 5: Коммит**

```bash
git add bin/dotprofile
git commit -m "dotprofile: apply_rig_colors/animations только lua (свитч lua-only)"
```

---

### Task 4: Удалить мёртвые `animations-runtime.keywords`

**Files:**
- Delete: `profiles/caelestia/animations-runtime.keywords`, `profiles/end4/animations-runtime.keywords`, `profiles/ilyamiro/animations-runtime.keywords`
- Note: `profiles/active/animations-runtime.keywords` — через симлинк `active`, не отдельный файл в git; удалять не нужно (резолвится в целевой профиль).

**Interfaces:**
- Consumes: подтверждение Task 3, что код их не читает.

- [ ] **Step 1: Подтвердить отсутствие читателей в коде**

Run: `grep -rl 'animations-runtime.keywords' --include='*.sh' bin profiles 2>/dev/null; grep -l 'animations-runtime.keywords' bin/dotprofile bin/rigdo bin/hypr-exec 2>/dev/null`
Expected: пусто (только доки/README могут упоминать — их не трогаем в этом Task).

- [ ] **Step 2: Удалить три файла**

```bash
git rm profiles/caelestia/animations-runtime.keywords \
       profiles/end4/animations-runtime.keywords \
       profiles/ilyamiro/animations-runtime.keywords
```

- [ ] **Step 3: Проверить, что `.lua`-версии на месте (их использует Task 3)**

Run: `ls profiles/*/animations-runtime.lua`
Expected: caelestia/end4/ilyamiro (+ active симлинк) `.lua` присутствуют.

- [ ] **Step 4: Коммит**

```bash
git commit -m "profiles: удалить мёртвые animations-runtime.keywords (hot-switch lua-only)"
```

---

### Task 5: `start-hyprland-profile` — резолв lua-рига из `.last-lua`

**Files:**
- Modify: `bin/start-hyprland-profile`
- Modify: `.gitignore` (игнорить runtime-файл `profiles/.last-lua`)

**Interfaces:**
- Consumes: `profiles/.last-lua` (пишет Task 2 `write_last_lua`); аргумент `--lua` из `hyprland-lua.desktop` (Task 1).
- Produces: запуск Hyprland с корректным ригом (arg > `.last-lua` > caelestia).

- [ ] **Step 1: Переписать `bin/start-hyprland-profile`**

Заменить содержимое на:

```bash
#!/usr/bin/env bash
# Запуск Hyprland с выбранным риг-профилем.
#   start-hyprland-profile <rig>   — явный риг (SDDM hyprland-ilyamiro)
#   start-hyprland-profile --lua   — последний lua-риг из profiles/.last-lua
#                                    (SDDM hyprland-lua), дефолт caelestia
DOTFILES="$HOME/dotfiles"
name="${1:-}"

if [[ -z "$name" || "$name" == "--lua" ]]; then
    name="$(cat "$DOTFILES/profiles/.last-lua" 2>/dev/null || true)"
    # валидируем: реально существующий lua-риг, иначе caelestia
    if [[ -z "$name" || ! -f "$DOTFILES/profiles/$name/hypr/hyprland.lua" ]]; then
        name=caelestia
    fi
fi

"$DOTFILES/bin/dotprofile" switch "$name" --links-only
exec /usr/bin/start-hyprland
```

- [ ] **Step 2: Синтаксис-проверка**

Run: `bash -n bin/start-hyprland-profile && echo ok`
Expected: `ok`

- [ ] **Step 3: Тест резолва (без реального запуска — подменяем dotprofile/start)**

Run:
```bash
bash -c '
DOTFILES="$HOME/dotfiles"
resolve() { local name="$1"
  if [[ -z "$name" || "$name" == "--lua" ]]; then
    name="$(cat "$DOTFILES/profiles/.last-lua" 2>/dev/null || true)"
    [[ -z "$name" || ! -f "$DOTFILES/profiles/$name/hypr/hyprland.lua" ]] && name=caelestia
  fi; echo "$name"; }
rm -f "$DOTFILES/profiles/.last-lua"
echo "no file, --lua      -> $(resolve --lua)"     # caelestia
echo end4 > "$DOTFILES/profiles/.last-lua"
echo "last=end4, --lua    -> $(resolve --lua)"     # end4
echo ilyamiro > "$DOTFILES/profiles/.last-lua"
echo "last=ilyamiro(bad)  -> $(resolve --lua)"     # caelestia (ilyamiro не lua)
echo "explicit ilyamiro   -> $(resolve ilyamiro)"  # ilyamiro
rm -f "$DOTFILES/profiles/.last-lua"'
```
Expected:
```
no file, --lua      -> caelestia
last=end4, --lua    -> end4
last=ilyamiro(bad)  -> caelestia
explicit ilyamiro   -> ilyamiro
```

- [ ] **Step 4: Игнорить runtime-файл**

Добавить в `.gitignore` строку:

```
profiles/.last-lua
```

Run: `grep -q 'profiles/.last-lua' .gitignore && echo ok`
Expected: `ok`

- [ ] **Step 5: Коммит**

```bash
git add bin/start-hyprland-profile .gitignore
git commit -m "start-hyprland-profile: lua-сессия резолвит риг из .last-lua"
```

---

### Task 6: End-to-end проверка (человеко-гейтед, реальные релогины)

**Files:** нет правок — только проверка поведения на живой машине.

**Interfaces:**
- Consumes: всё из Task 1–5, установленные сессии.

> ⚠️ Требует релогинов — выполняет пользователь за машиной. Агент останавливается здесь и передаёт чеклист.

- [ ] **Step 1: Горячий свитч lua↔lua**

Вход в `hyprland-lua` (→ caelestia). `SUPER+SHIFT+D` → end4.
Expected: WM реально ребиндится (проверить бинд, уникальный для end4), темы/бар end4, БЕЗ наслоения caelestia. `dotprofile status` → `active: end4`. Назад → caelestia так же.

- [ ] **Step 2: Релогин lua → ilyamiro**

Из caelestia `SUPER+SHIFT+D` → ilyamiro.
Expected: сообщение `relogin -> ilyamiro`, выход в SDDM грайтер, подсвечена сессия `Hyprland (ilyamiro)`. Вход → чистый ilyamiro, темы применены, без остатков caelestia.

- [ ] **Step 3: Релогин ilyamiro → end4 (проверка `.last-lua`)**

Из ilyamiro `SUPER+SHIFT+D` → end4.
Expected: выход в SDDM, подсвечена `Hyprland (lua rig)`. Вход → сессия стартует в **end4** (не caelestia), потому что `.last-lua`=end4. `dotprofile status` → `active: end4`.

- [ ] **Step 4: Проверить `.dmrc` и статус после переходов**

Run: `cat ~/.dmrc; ~/dotfiles/bin/dotprofile status; cat ~/dotfiles/profiles/.last-lua 2>/dev/null`
Expected: `Session=` соответствует последней целевой сессии; `active` корректен; `.last-lua` = последний lua-риг.

- [ ] **Step 5: Финальный коммит-метка (если были фиксы в ходе проверки)**

Если во время E2E потребовались правки — коммитить их отдельно с описанием симптома. Если всё зелёное — Task без коммита.

---

## Self-Review

**Spec coverage:**
- Режим-детект (движок цели vs запущенного) → Task 2 ✓
- Релогин-флоу (active/ensure_links/.dmrc/.last-lua/exit) → Task 2 (`trigger_relogin`; active+ensure_links в `cmd_switch` до ветвления) ✓
- SDDM 3→2 → Task 1 ✓
- `.last-lua` резолв → Task 2 (запись) + Task 5 (чтение) ✓
- Удалить animations-runtime.keywords → Task 4 ✓
- Убрать кросс-движковую ветку/disable_autoreload → Task 2 ✓
- apply_* lua-only → Task 3 ✓
- Оставить rigdo/hypr-exec/порты/exit-логику → не трогаются (ни один Task их не удаляет) ✓
- Проверка (4 сценария) → Task 6 ✓

**Placeholder scan:** код показан в каждом шаге; команды с ожидаемым выводом; плейсхолдеров нет.

**Type/имя consistency:** `rig_engine`/`session_desktop`/`write_last_lua`/`trigger_relogin`/`.last-lua` — согласованы между Task 2 и Task 5; имена сессий `hyprland-lua`/`hyprland-ilyamiro` — между Task 1, 2, 5.

**Примечание по `active` в релогине:** `cmd_switch` делает `ln -sfn active` + `ensure_links` ДО ветвления, поэтому к моменту `trigger_relogin` симлинк уже указывает на цель (спека, шаг 1 релогин-флоу). `trigger_relogin` не свапает повторно — только `.last-lua`/`.dmrc`/exit.
