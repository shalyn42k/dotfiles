# Rig Hot-Switch (Shared Binds, No Reload) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** caelestia↔end4 (lua↔lua) переключается быстро и чисто БЕЗ релогина: убираем `hyprctl reload` (источник наслоения), тема/анимации/правила применяются точечно, бинды — общий источник + rigdo-роутинг.

**Architecture:** `cmd_switch` (lua↔lua) больше не зовёт reload. На свитче: swap active/links → session.sh stop/start (бар) → apply_rig_colors → apply_rig_animations → apply_rig_rules (новое) → write .last-lua. Бинды загружены при старте из общего lua-модуля (оба рига require), на свитче не трогаются; `rigdo` маршрутизирует действия по `profiles/active`. Релогин остаётся только для ilyamiro (кросс-движок).

**Tech Stack:** bash, Hyprland lua-провайдер (hyprkcs, `hyprctl eval`), lua (`hl.*` API).

## Global Constraints

- Движок рига = lua если есть `profiles/<name>/hypr/hyprland.lua`. caelestia/end4=lua, ilyamiro=hyprlang.
- `bin/dotprofile`: `set -euo pipefail`; переменные `DOTFILES`, `PROFILES`, `ACTIVE` уже есть.
- Хот-свитч ТОЛЬКО lua↔lua (caelestia↔end4). Кросс-движок (ilyamiro) уже уходит в релогин через `trigger_relogin` — НЕ трогать эту ветку.
- Рантайм-применение через `hyprctl eval "..."` (lua). Уже так работают `apply_rig_colors`/`apply_rig_animations`.
- `rigdo` читает `profiles/active` и маршрутизирует shell-действия — НЕ ломать.
- Верификация shell: `bash -n <file>`; lua-синтаксис: `luajit -bl <file> >/dev/null` если есть luajit, иначе `hyprctl eval "dofile('<file>')"` в живой сессии.
- Ветка: `rig-switch-engine-split` (та же, где предыдущая работа + фиксы E2E).
- Правила на хот-свитче — «best effort» (целевые добавляются последними, старые лингерят безвредно); идеально чистые только на релогине. Это сознательный компромисс спеки, НЕ дефект.

---

### Task 1: Убрать `hyprctl reload` из lua↔lua хот-свитча

**Files:**
- Modify: `bin/dotprofile` (`cmd_switch`, строка с `hyprctl reload`)

**Interfaces:**
- Consumes: существующая структура `cmd_switch` (ветка после релогин-проверки).
- Produces: хот-свитч без reload — бинды/правила не пересобираются reload'ом (источник наслоения убран).

**Why:** reload перечитывает чужую кодбазу в тот же процесс → кеш модулей + наслоение биндов. Бинды идентичны и загружены при старте, править их на свитче не нужно.

- [ ] **Step 1: Тест — reload ещё в hot-switch ветке**

Run: `grep -n 'hyprctl reload' bin/dotprofile`
Expected СЕЙЧАС: одна строка (~233) в `cmd_switch`. После Task — пусто.

- [ ] **Step 2: Удалить строку reload**

В `bin/dotprofile`, `cmd_switch`, удалить строку целиком:

```bash
    command -v hyprctl >/dev/null && hyprctl reload || true
```

(Строка между `... session.sh stop ... fi` и `[[ -x "$PROFILES/$name/session.sh" ]] && ... start`.)

- [ ] **Step 3: Проверить синтаксис + отсутствие reload**

Run: `bash -n bin/dotprofile && echo ok`
Expected: `ok`
Run: `grep -c 'hyprctl reload' bin/dotprofile`
Expected: `0`

- [ ] **Step 4: Коммит**

```bash
git add bin/dotprofile
git commit -m "dotprofile: убрать hyprctl reload из lua хот-свитча (источник наслоения)"
```

---

### Task 2: `apply_rig_rules` + `rules-runtime.lua` на риг

**Files:**
- Create: `profiles/caelestia/rules-runtime.lua`
- Create: `profiles/end4/rules-runtime.lua`
- Modify: `bin/dotprofile` (добавить `apply_rig_rules`, вызвать в `cmd_switch`)

**Interfaces:**
- Consumes: `hyprctl eval`, существующий паттерн `apply_rig_animations`.
- Produces: `apply_rig_rules "$name"` — применяет window/workspace-rules целевого рига в рантайме.

**Why:** без свитча правил вид окон (прозрачность/блюр/флоат общих классов + глобальная opacity) замерзает на риге, чьи правила последние. `apply_rig_rules` до-добавляет правила целевого рига последними → целевой выигрывает.

**Risk (в код заложено):** `caelestia/hypr/hyprland/rules.lua` делает `require("variables")`; `package.path` для этого ставит только конфиг caelestia при старте. При хот-свитче из end4 путь отсутствует → `rules-runtime.lua` сам чинит `package.path` перед dofile.

- [ ] **Step 1: Создать `profiles/caelestia/rules-runtime.lua`**

```lua
-- Правила рига caelestia для применения в живую lua-сессию (hyprctl eval).
-- rules.lua делает require("variables"); package.path для него ставит конфиг
-- caelestia при старте. При хот-свитче из end4 этого пути нет — чиним сами.
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/dotfiles/profiles/caelestia/hypr/?.lua"
dofile(home .. "/dotfiles/profiles/caelestia/hypr/hyprland/rules.lua")
```

- [ ] **Step 2: Создать `profiles/end4/rules-runtime.lua`**

end4 `custom/rules.lua` без require — dofile напрямую:

```lua
-- Правила рига end4 для применения в живую lua-сессию (hyprctl eval).
-- custom/rules.lua standalone (без require) — просто перевыполняем.
local home = os.getenv("HOME")
dofile(home .. "/dotfiles/profiles/end4/hypr/custom/rules.lua")
```

- [ ] **Step 3: Добавить `apply_rig_rules` в `bin/dotprofile`**

Сразу ПОСЛЕ функции `apply_rig_animations` (её закрывающей `}`) вставить:

```bash
# Window/workspace-правила рига — применяем набор целевого рига в рантайме
# (mirror apply_rig_animations). Целевые добавляются последними → выигрывают
# конфликтные (opacity/blur общих классов). Старые правила рига лингерят, но
# целят классы уже закрытого чужого шелла. Идеально чисто — на релогине.
apply_rig_rules() {
    local name="$1"
    local chunk="$PROFILES/$name/rules-runtime.lua"
    [[ -f "$chunk" ]] && hyprctl eval "dofile('$chunk')" >/dev/null || true
}
```

- [ ] **Step 4: Вызвать `apply_rig_rules` в `cmd_switch`**

В `cmd_switch`, в блоке `if command -v hyprctl ...` где уже есть `apply_rig_colors "$name"` и `apply_rig_animations "$name"`, добавить третьей строкой:

```bash
        apply_rig_rules "$name"
```

Итог блока:
```bash
    if command -v hyprctl >/dev/null; then
        apply_rig_colors "$name"
        apply_rig_animations "$name"
        apply_rig_rules "$name"
    fi
```

- [ ] **Step 5: Синтаксис-проверки**

Run: `bash -n bin/dotprofile && echo bash-ok`
Expected: `bash-ok`
Run (lua-синтаксис, если luajit есть): `for f in profiles/caelestia/rules-runtime.lua profiles/end4/rules-runtime.lua; do luajit -bl "$f" >/dev/null 2>&1 && echo "$f ok" || echo "$f (luajit n/a — verify in Task 6)"; done`
Expected: `ok` для обоих, либо пометка «verify in Task 6».

- [ ] **Step 6: Коммит**

```bash
git add profiles/caelestia/rules-runtime.lua profiles/end4/rules-runtime.lua bin/dotprofile
git commit -m "dotprofile: apply_rig_rules — правила целевого рига на хот-свитче"
```

---

### Task 3: env мина №1 — PATH март-quickshell при хот-свитче В end4

**Files:**
- Modify: `profiles/end4/session.sh` (start: экспорт PATH перед стартом ii-шелла)

**Interfaces:**
- Consumes: `$QS_II` (уже определён в end4 session.sh).
- Produces: end4-шелл и его вотчеры видят март-quickshell в PATH даже при хот-свитче (когда `custom/env.lua` не отрабатывал).

**Why:** `custom/env.lua` префиксит PATH на `~/qs-test-prefix/usr/bin` только при СТАРТЕ рига end4. Хот-свитч В end4 (сессия стартовала caelestia) этот env не ставит → ipc-вотчеры end4 ловят системный quickshell. Экспорт в session.sh чинит для хот-свитча.

- [ ] **Step 1: Прочитать текущий `profiles/end4/session.sh`**

Run: `cat profiles/end4/session.sh`
(Убедиться в структуре `case start) ... $QS_II -c ii & ...`.)

- [ ] **Step 2: Добавить экспорт PATH в ветку start**

В `profiles/end4/session.sh`, в начале ветки `start)` (перед проверкой/запуском `$QS_II`), добавить:

```bash
        # Хот-свитч В end4: custom/env.lua (PATH на март-quickshell) НЕ отработал
        # (сессия стартовала не в end4). Ставим PATH для ii-шелла и его вотчеров.
        export PATH="$HOME/qs-test-prefix/usr/bin:$PATH"
```

- [ ] **Step 3: Синтаксис**

Run: `bash -n profiles/end4/session.sh && echo ok`
Expected: `ok`

- [ ] **Step 4: Коммит**

```bash
git add profiles/end4/session.sh
git commit -m "end4/session.sh: export март-quickshell PATH для хот-свитча в end4"
```

---

### Task 4: Баги тем — matugen, end4 gtk, gtk-theme-name

**Files:**
- Modify: `bin/dotprofile` (`ensure_links` — matugen как реальный каталог)
- Create/populate: `profiles/end4/gtk-3.0/settings.ini` (+ gtk.css если нужен)

**Interfaces:**
- Consumes: `ensure_links`, `CONTESTED` (matugen там уже есть).
- Produces: matugen переключается по ригу; end4 gtk-3.0 не пустой; end4 gtk-theme-name для reload-хака в apply_rig_colors.

**Why:** «тема не применяется приложениями»: (1) `~/.config/matugen` — реальный каталог, `ln -sfn active/matugen ~/.config/matugen` кладёт симлинк ВНУТРЬ (`matugen/matugen`), matugen не свитчится; (2) `profiles/end4/gtk-3.0/` пуст → свитч в end4 роняет gtk.css; (3) end4 без `gtk-theme-name` → Adwaita-хак в apply_rig_colors скипается.

- [ ] **Step 1: Диагностика matugen**

Run: `ls -la ~/.config/matugen; readlink ~/.config/matugen`
Expected: реальный каталог (не симлинк), внутри вероятен мусорный `matugen/matugen`.

- [ ] **Step 2: Починить matugen в `ensure_links`**

В `ensure_links`, цикл `for d in "${CONTESTED[@]}"` сейчас: `ln -sfn "$PROFILES/active/$d" "$HOME/.config/$d"`. Для реального каталога это создаёт вложенный симлинк. Заменить тело цикла на снос реального каталога перед симлинком:

```bash
    for d in "${CONTESTED[@]}"; do
        # реальный каталог (не наш симлинк) — снести, иначе ln положит симлинк
        # ВНУТРЬ (напр. ~/.config/matugen/matugen)
        [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]] && rm -rf "$HOME/.config/${d:?}"
        ln -sfn "$PROFILES/active/$d" "$HOME/.config/$d"
    done
```

- [ ] **Step 3: Убрать мусорный вложенный симлинк и переставить**

```bash
rm -rf ~/.config/matugen
./bin/dotprofile status
```
Run после: `readlink ~/.config/matugen`
Expected: `/home/shalyn42k/dotfiles/profiles/active/matugen` (теперь корректный симлинк).

- [ ] **Step 4: Наполнить `profiles/end4/gtk-3.0/settings.ini`**

Создать `profiles/end4/gtk-3.0/settings.ini` (mirror caelestia, тема adw-gtk3-dark для Adwaita-хака):

```ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=volantes_cursors
gtk-cursor-theme-size=24
```

- [ ] **Step 5: Проверки**

Run: `bash -n bin/dotprofile && echo ok`
Expected: `ok`
Run: `awk -F= '/^gtk-theme-name/{print $2}' profiles/end4/gtk-3.0/settings.ini`
Expected: `adw-gtk3-dark`

- [ ] **Step 6: Коммит**

```bash
git add bin/dotprofile profiles/end4/gtk-3.0/settings.ini
git commit -m "themes: matugen как реальный каталог в ensure_links + end4 gtk-3.0 settings"
```

---

### Task 5: Один источник правды для биндов (контракт → общий lua-модуль)

**Files:**
- Create: `.config/hypr-shared/contract-binds.lua`
- Modify: `.config/caelestia/hypr-user.lua` (require общий модуль вместо своей копии контракта)
- Modify: `profiles/end4/hypr/custom/keybinds.lua` (require общий модуль после unbind ii-дефолтов; убрать ручной порт контракта)

**Interfaces:**
- Consumes: `hl.bind`/`hl.dsp.exec_cmd` (hyprkcs API, общий у обоих lua-ригов); `rigdo` (маршрутизация).
- Produces: контракт §2.1 (rigdo-действия) + §2.2-2.6 (WM) в ОДНОМ файле; оба рига `require()`.

**Why (и границы):** сейчас контракт продублирован (caelestia hypr-user.lua + end4 custom/keybinds.lua-порт) — tech-debt #1. Оба на lua → сливаем в один. НЕ требуется для работы хот-свитча (бинды и так идентичны при старте) — это устранение долга. §C-уникальные (caelestia record/PiP и т.п.) НЕ трогаем — остаются в своих файлах.

**Note для реализатора:** контент общего модуля = существующие проверенные бинды контракта. Извлечь ВЕРБАТИМ из текущих файлов (не переписывать логику):
- rigdo-действия §2.1: строки `hl.bind("...", hl.dsp.exec_cmd(dot .. "rigdo <action>"))` из `.config/caelestia/hypr-user.lua` (SUPER+Y, SUPER+SHIFT+O, SUPER+ALT+M/S/P, SUPER+B, SUPER+N, SHIFT+TAB launcher, и т.д. по KEYBINDS.md §2.1).
- WM §2.2-2.6: из `profiles/caelestia/hypr/hyprland/keybinds.lua` (эталон контракта).

- [ ] **Step 1: Прочитать оба источника целиком**

Run:
```bash
cat .config/caelestia/hypr-user.lua
echo "=== end4 ==="; cat profiles/end4/hypr/custom/keybinds.lua
echo "=== caelestia keybinds ==="; cat profiles/caelestia/hypr/hyprland/keybinds.lua
```
Задача: выделить подмножество, идентичное в обоих (контракт §2.1 + §2.2-2.6). Различия (§C, §D-тулы) — НЕ в общий модуль.

- [ ] **Step 2: Создать `.config/hypr-shared/contract-binds.lua`**

Модуль с контрактными биндами. Требует, чтобы `dot` (путь к `~/dotfiles/bin/`) был доступен — принять параметром через глобаль или os.getenv. Шаблон шапки:

```lua
-- Кросс-риг контракт биндов (KEYBINDS.md §2). ЕДИНЫЙ источник правды.
-- Оба lua-рига (caelestia, end4) require() этот файл. rigdo маршрутизирует
-- действия по profiles/active. Править контракт ТОЛЬКО здесь.
local dot = os.getenv("HOME") .. "/dotfiles/bin/"
-- §2.1 rigdo-действия
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(dot .. "dotprofile menu"))
hl.bind("SHIFT + TAB",       hl.dsp.exec_cmd(dot .. "rigdo launcher"))
hl.bind("SUPER + Y",         hl.dsp.exec_cmd(dot .. "rigdo wallpaper"))
-- ... (перенести ВСЕ контрактные бинды из источников, вербатим) ...
-- §2.2-2.6 WM-бинды (окна/воркспейсы/приложения/мышь) — из caelestia keybinds.lua
```
Реализатор дополняет полным списком из Step 1 (вербатим существующие строки).

- [ ] **Step 3: caelestia — require общий модуль**

В `.config/caelestia/hypr-user.lua` заменить продублированный контракт-блок на:

```lua
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
```
Оставить §C-уникальные caelestia-бинды (record/PiP/scheme/sysmon), если они в этом файле.

- [ ] **Step 4: end4 — require общий модуль**

В `profiles/end4/hypr/custom/keybinds.lua`: сохранить блок `hl.unbind(...)` ii-дефолтов, затем заменить ручной порт контракта на:

```lua
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
```

- [ ] **Step 5: Синтаксис lua**

Run: `for f in .config/hypr-shared/contract-binds.lua .config/caelestia/hypr-user.lua profiles/end4/hypr/custom/keybinds.lua; do luajit -bl "$f" >/dev/null 2>&1 && echo "$f ok" || echo "$f (luajit n/a — verify Task 6)"; done`
Expected: `ok` (или пометка verify).

- [ ] **Step 6: Коммит**

```bash
git add .config/hypr-shared/contract-binds.lua .config/caelestia/hypr-user.lua profiles/end4/hypr/custom/keybinds.lua
git commit -m "binds: контракт §2 в один общий lua-модуль (оба рига require) — уходит tech-debt #1"
```

---

### Task 6: End-to-end проверка (человеко-гейтед)

**Files:** нет правок — проверка на живой машине (релогины + хот-свитчи).

> ⚠️ Требует релогинов и нажатий клавиш — выполняет пользователь. Агент останавливается и передаёт чеклист. Правки в ходе — отдельными коммитами с симптомом.

- [ ] **Step 1: Свежий логин hyprland-lua → caelestia**

Проверить: бар caelestia, тема caelestia, `SHIFT+TAB` → caelestia-лаунчер, `SUPER+Q/IJKL/1..0` работают.

- [ ] **Step 2: Хот-свитч caelestia → end4 (без релогина)**

`SUPER+SHIFT+D` → end4. Ожидать: бар→ii, тема→end4, анимации→end4, `SHIFT+TAB`→end4-поиск (rigdo), WM-бинды идентичны, БЕЗ наслоения. Быстро.
Проверить правила: открыть thunar → прозрачность соответствует end4 (0.90).

- [ ] **Step 3: Хот-свитч end4 → caelestia**

`SUPER+SHIFT+D` → caelestia. Зеркально: бар/тема/анимации/правила → caelestia, `SHIFT+TAB` снова caelestia-лаунчер. Без наслоения end4.

- [ ] **Step 4: Уникальные бинды**

В caelestia: `SUPER+O` (PiP) работает. Переключиться в end4, `SUPER+O` → тихо мимо (нет caelestia-шелла) — ожидаемо.

- [ ] **Step 5: Темы приложений + клавиатура**

GTK-приложение (thunar) показывает цвета активного рига после свитча. `kbd-theme-sync` (подсветка клавы) следует за ригом.

- [ ] **Step 6: Кросс-движок (регресс-чек)**

`SUPER+SHIFT+D` → ilyamiro: релогин (не хот-свитч), как в engine-split спеке. Обратно из ilyamiro → end4/caelestia: релогин, `.last-lua` резолвит цель.

---

## Self-Review

**Spec coverage (v2 спека):**
- Убрать reload → Task 1 ✓
- apply_rig_rules + rules-runtime → Task 2 ✓
- env мина №1 → Task 3 ✓
- Баги тем (matugen/end4 gtk) → Task 4 ✓
- Один источник биндов → Task 5 ✓
- rigdo-роутинг (§2.1 разное поведение) → не требует правок (уже работает), проверка Task 6 ✓
- Правила как ⚠-компромисс → Task 2 (комментарий + best-effort), проверка Task 6 ✓
- E2E (6 сценариев) → Task 6 ✓

**Placeholder scan:** Tasks 1-4 — полный код. Task 5 — извлечение ВЕРБАТИМ существующих биндов из названных файлов (не «TODO», а move-рефактор проверенного кода; точные строки в источниках, Step 1 читает их). E2E — ручной.

**Type/имя consistency:** `apply_rig_rules`/`rules-runtime.lua` согласованы (Task 2). `contract-binds.lua` путь одинаков в Task 5 Steps 2-4. `$QS_II`/PATH (Task 3) — существующая переменная end4.

**Риски (verify в Task 6, не блокеры):**
- Рантайм `hl.window_rule` через `hyprctl eval` может применяться частично (правила — «best effort»; релогин чистый). Заложено в спеку.
- Task 5 может изменить набор биндов если источники разошлись — Step 1 сверяет оба перед извлечением.
