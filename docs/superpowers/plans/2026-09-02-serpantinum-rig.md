# Serpantinum как второй lua-риг — план реализации

> **Для агентов:** ОБЯЗАТЕЛЬНЫЙ САБ-СКИЛЛ: используй superpowers:subagent-driven-development
> (рекомендуется) или superpowers:executing-plans, задача за задачей. Шаги
> размечены чекбоксами (`- [ ]`).

**Цель:** поднять `profiles/serpantinum` как второй риг на lua-провайдере, чтобы
пара caelestia ↔ serpantinum стала однодвижковой и свитч перестал требовать
релогина.

**Архитектура:** апстрим вендорится git-submodule'ом в `profiles/serpantinum/shell`
и запускается через `$SERPANTINUM_DIR` — системная установка не нужна, их
`install.sh` не запускается никогда. Конфиг композитора берём их (он уже на
том же `hl`-API), но монитор-раскладку, env и бинды подменяем своими. Темизацию
рабочего стола (GTK/Qt/kitty/…) несёт профиль: у serpantinum matugen красит
только его собственный шелл.

**Стек:** Hyprland 0.56.2 с lua config provider (hyprkcs), quickshell 0.3.1
(системный), matugen, bash, lua 5.5.

**Спека:** `docs/specs/2026-09-02-serpantinum-rig-design.md`

## Глобальные ограничения

- **Их `install/install.sh` не запускать никогда.** `install/modules/deps.sh`
  делает `sudo pacman -Syyu --noconfirm`, а README обещает отложить существующую
  конфигурацию. Наш репозиторий и есть живой конфиг (`~/.config/hypr` — симлинк
  в `profiles/active/hypr`), их инсталлер снёс бы риг.
- Профиль обязан соблюдать контракт рига: `role`, `session.sh` (`start|stop`),
  `hypr/`, и все каталоги `CONTESTED` — `hypr gtk-3.0 gtk-4.0 qt5ct qt6ct matugen`.
  Проверяется `bin/dotprofile doctor`.
- Строки в виджетах — только английские.
- Апстрим пинится коммитом: тегов в репозитории нет (`git tag` пуст).
- **Стадия `binds` в `cmd_switch` отключена** и в этом плане не включается:
  снос набора через хендлы роняет композитор (`docs/tech-debt.md` п.8). Горячий
  свитч в этом плане проверяется по цветам/анимациям/правилам/демонам; бинды
  приезжают релогином, как сейчас.
- Проверки, способные уронить композитор, — только в отдельном инстансе, не в
  рабочей сессии. В этом плане таких нет.

---

### Task 1: Вендоринг апстрима и недостающая зависимость

**Файлы:**
- Создать: `.gitmodules` (появится сам), `profiles/serpantinum/shell` (submodule)
- Изменить: `bootstrap.sh` (клон с сабмодулями, установка `wl-gammarelay-rs`)

**Интерфейсы:**
- Отдаёт: путь `profiles/serpantinum/shell` с `src/quickshell/Shell.qml`,
  `bin/serpantinumd`, `compositors/hyprland/config/*.lua` — на него опираются
  задачи 2 и 3.

- [ ] **Шаг 1: Добавить submodule, пиннув текущий проверенный коммит**

```bash
cd ~/dotfiles
git submodule add https://github.com/ilyamiro/serpantinum.git profiles/serpantinum/shell
cd profiles/serpantinum/shell
git checkout 934ca1f
cd ~/dotfiles
```

`934ca1f` — коммит, на котором проверялась разведка (2026-09-02). Тегов у
апстрима нет, поэтому пин только по SHA.

- [ ] **Шаг 2: Убедиться, что вендоринг самодостаточен**

```bash
test -f profiles/serpantinum/shell/src/quickshell/Shell.qml && echo "Shell.qml ok"
test -x profiles/serpantinum/shell/bin/serpantinumd && echo "serpantinumd ok"
grep -q 'SERPANTINUM_DIR' profiles/serpantinum/shell/bin/serpantinumd && echo "SERPANTINUM_DIR ok"
```

Ожидается три строки `ok`. `serpantinumd` дефолтит `SERPANTINUM_DIR` в
`$(dirname BIN_DIR)/src`, поэтому системная установка не нужна.

- [ ] **Шаг 3: Поставить единственную недостающую зависимость**

```bash
paru -S --needed wl-gammarelay-rs
```

Остальные ~59 зависимостей уже стоят с ilyamiro v1. Проверка:

```bash
command -v wl-gammarelay-rs && echo "dep ok"
```

- [ ] **Шаг 4: Научить bootstrap тянуть сабмодуль и зависимость**

В `bootstrap.sh`, в списке `PKGS`, добавить строку рядом с прочими пакетами:

```bash
    # serpantinum: единственная его зависимость, которой не было у ilyamiro v1
    wl-gammarelay-rs
```

И сразу после блока симлинков профилей (`== 3/7 Симлинки профилей ==`) добавить:

```bash
# Вендоренный апстрим serpantinum. Клон репы без --recurse-submodules оставляет
# profiles/serpantinum/shell пустым, и риг не стартует.
if [[ -f "$DOTFILES/.gitmodules" ]]; then
    git -C "$DOTFILES" submodule update --init --recursive
fi
```

- [ ] **Шаг 5: Проверить и закоммитить**

```bash
bash -n bootstrap.sh && echo "syntax ok"
git add .gitmodules profiles/serpantinum/shell bootstrap.sh
git commit -m "feat(serpantinum): vendor the upstream shell as a pinned submodule"
```

---

### Task 2: Каркас профиля — риг стартует и поднимает бар

**Файлы:**
- Создать: `profiles/serpantinum/role`, `profiles/serpantinum/session.sh`
- Тест: `bin/dotprofile doctor`

**Интерфейсы:**
- Потребляет: `profiles/serpantinum/shell` из задачи 1.
- Отдаёт: `session.sh start|stop` — контракт, который зовёт `cmd_switch`
  (стадия `daemons`) и `swap_session_daemons`.

- [ ] **Шаг 1: Роль**

```bash
echo third > profiles/serpantinum/role
```

`daily` остаётся за ilyamiro, пока новый риг не отработает как основной —
требование 1 спеки: рабочий ilyamiro не трогаем, откат бесплатный.

- [ ] **Шаг 2: session.sh**

Создать `profiles/serpantinum/session.sh`:

```bash
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

case "${1:-}" in
    start)
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
```

```bash
chmod +x profiles/serpantinum/session.sh
```

- [ ] **Шаг 3: Обязательные каталоги CONTESTED**

`doctor` требует все шесть. `hypr` наполняется в задаче 3, `matugen` — в
задаче 4; здесь создаём каталоги тем, скопировав рабочие от ilyamiro (они не
шелл-специфичны — это GTK/Qt-темы, которые serpantinum не трогает вообще).

```bash
mkdir -p profiles/serpantinum/hypr
for d in gtk-3.0 gtk-4.0 qt5ct qt6ct; do
    cp -a "profiles/ilyamiro/$d" "profiles/serpantinum/$d"
done
mkdir -p profiles/serpantinum/matugen
```

- [ ] **Шаг 4: Проверить, что doctor видит риг целым**

```bash
bin/dotprofile doctor
```

Ожидается строка `serpantinum ok` — все шесть каталогов на месте. Если печатает
`НЕТ обязательных каталогов` — не хватает того, что перечислено; создать.

- [ ] **Шаг 5: Коммит**

```bash
git add profiles/serpantinum
git commit -m "feat(serpantinum): add the rig skeleton and its session contract"
```

---

### Task 3: Конфиг композитора — их база, наши монитор/env/бинды

**Файлы:**
- Создать: `profiles/serpantinum/hypr/hyprland.lua`,
  `profiles/serpantinum/hypr/monitors.lua`,
  `profiles/serpantinum/hypr/overrides.lua`
- Изменить: `tests/rig_keybinds_test.lua`

**Интерфейсы:**
- Потребляет: `__rig.begin(owner)` и `__rig.own(owner, fn)` из
  `.config/hypr-shared/rigbinds.lua`; `contract-binds.lua`.
- Отдаёт: `profiles/serpantinum/hypr/hyprland.lua` — точка входа, которую
  Hyprland находит через симлинк `~/.config/hypr`; и
  `profiles/serpantinum/hypr/overrides.lua` — файл, куда кладутся НАШИ бинды
  (его грузит тест из задачи 3, шаг 4).

- [ ] **Шаг 1: Своя монитор-раскладка**

Их `config/monitors.lua` описывает чужое железо. Создать
`profiles/serpantinum/hypr/monitors.lua`, скопировав раскладку caelestia:

```bash
grep -n "hl.monitor" profiles/caelestia/hypr/hyprland.lua
```

Перенести найденные вызовы `hl.monitor({...})` в новый файл как есть. Если в
caelestia раскладка задаётся иначе — взять оттуда фактические значения; цель в
том, чтобы мониторы у обоих ригов были одинаковыми, иначе свитч будет двигать
окна.

- [ ] **Шаг 2: Точка входа**

Создать `profiles/serpantinum/hypr/hyprland.lua`:

```lua
-- ── Реестр владения биндами ──────────────────────────────────────────────
-- ПЕРВОЙ строкой: всё, что забайндится до неё, останется без хендла и станет
-- несносимым при переключении рига.
-- Спека: docs/superpowers/specs/2026-09-02-rig-switch-binds-ownership-design.md
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/rigbinds.lua")
__rig.begin("serpantinum")

local rig = os.getenv("HOME") .. "/dotfiles/profiles/serpantinum"

-- Конфиг композитора апстрима написан тем же hl-API, что у нас, поэтому берём
-- его как базу вместо порта. Резолвим require из вендоренной копии.
package.path = rig .. "/shell/compositors/hyprland/?.lua;" .. package.path

require("config/variables")
require("config/env")
require("config/autostart")   -- нужен: поднимает serpantinumd
require("config/settings")
require("config/keybinds")

-- Наше поверх их базы: мониторы (у них чужое железо) и наши бинды/правила.
dofile(rig .. "/hypr/monitors.lua")
dofile(rig .. "/hypr/overrides.lua")

-- ── Кросс-риг контракт ───────────────────────────────────────────────────
-- ПОСЛЕДНИМ: снимает комбу перед своим биндом, поэтому обязан идти после
-- набора рига. Владелец "shared" — переживает переключение ригов.
dofile(os.getenv("HOME") .. "/dotfiles/.config/hypr-shared/contract-binds.lua")
```

- [ ] **Шаг 3: Наши оверрайды поверх их биндов**

Создать `profiles/serpantinum/hypr/overrides.lua`. Апстримовые бинды остаются,
наши перебивают конфликтные — со снятием, потому что ре-бинд СТЕКАЕТСЯ, а не
замещает (замерено: 99 → 187 биндов):

```lua
-- overrides.lua — наши бинды и правила поверх базы serpantinum.
--
-- Грузится ПОСЛЕ config/keybinds апстрима. Ре-бинд в hyprkcs стекается, а не
-- замещает (замерено на живой сессии 2026-09-02: 99 -> 187), поэтому каждый наш
-- бинд снимает комбу перед тем как повесить своё. Контракт §2.1 здесь НЕ
-- дублируется — он живёт в .config/hypr-shared/contract-binds.lua и грузится
-- последним.
local function rebind(keys, dispatcher, opts)
    hl.unbind(keys)
    return hl.bind(keys, dispatcher, opts)
end

local home    = os.getenv("HOME")
local scripts = home .. "/dotfiles/profiles/serpantinum/hypr/scripts"

-- §2.2 Окна
rebind("SUPER + Q",           hl.dsp.window.close())
rebind("SUPER + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
rebind("SUPER + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
rebind("SUPER + ALT + Space", hl.dsp.window.float())
rebind("SUPER + P",           hl.dsp.window.pin())

-- Фокус (IJKL)
rebind("SUPER + I", hl.dsp.focus({ direction = "up" }))
rebind("SUPER + J", hl.dsp.focus({ direction = "left" }))
rebind("SUPER + K", hl.dsp.focus({ direction = "down" }))
rebind("SUPER + L", hl.dsp.focus({ direction = "right" }))

-- Двигать окно (SHIFT + IJKL)
rebind("SUPER + SHIFT + I", hl.dsp.window.move({ direction = "up" }))
rebind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
rebind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
rebind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- §2.3 Воркспейсы
rebind("SUPER + A", hl.dsp.focus({ workspace = "-1" }))
rebind("SUPER + D", hl.dsp.focus({ workspace = "+1" }))
for i = 1, 10 do
    local key = i % 10 -- 10 → клавиша 0
    rebind("SUPER + " .. key,         hl.dsp.workspace(tostring(i)))
    rebind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end
```

Сверить получившийся набор с `KEYBINDS.md` §2 — это тот же контракт, что у
caelestia. Комбы, которых у serpantinum в базе нет, `hl.unbind` просто не найдёт;
это безвредно.

- [ ] **Шаг 4: Тест — набор рига грузится и попадает в реестр**

В `tests/rig_keybinds_test.lua`, в таблицу `RIGS`, добавить:

```lua
    serpantinum = {
        entry = "profiles/serpantinum/hypr/overrides.lua",
        paths = { "profiles/serpantinum/shell/compositors/hyprland/?.lua" },
    },
```

- [ ] **Шаг 5: Прогнать тесты**

```bash
tests/run.sh
```

Ожидается, что появятся два новых зелёных: `serpantinum: bind set loads and
lands in the registry` и `serpantinum: contract wins every shared combo when
loaded last`. Второй провалится, если `overrides.lua` вешает контрактную комбу
(например `SUPER + M`) — такую строку надо убрать, контракт покрывает её сам.

- [ ] **Шаг 6: Синтаксис и коммит**

```bash
for f in profiles/serpantinum/hypr/*.lua; do
    lua -e "assert(loadfile('$f'))" || echo "PARSE FAIL $f"
done
git add profiles/serpantinum/hypr tests/rig_keybinds_test.lua
git commit -m "feat(serpantinum): build the compositor config on the upstream lua base"
```

---

### Task 4: Темизация — matugen профиля красит рабочий стол

**Файлы:**
- Создать: `profiles/serpantinum/matugen/config.toml`,
  `profiles/serpantinum/matugen/templates/*`
- Изменить: `bin/dotprofile` (`apply_rig_colors`, ветка Discord/Obsidian)

**Интерфейсы:**
- Потребляет: `profiles/serpantinum/{gtk-3.0,gtk-4.0,qt5ct,qt6ct}` из задачи 2.
- Отдаёт: `profiles/serpantinum/hypr/colors.conf` — файл, который читает
  `apply_rig_colors` (`$active_border` / `$inactive_border`).

- [ ] **Шаг 1: Перенести шаблоны от ilyamiro, кроме шелл-специфичных**

У serpantinum matugen красит ТОЛЬКО его собственный шелл (единственный шаблон —
`serpantinum_matugen_colors.json.template`). GTK/Qt/kitty/cava/swayosd остаются
на нас.

```bash
mkdir -p profiles/serpantinum/matugen/templates
cd profiles/ilyamiro/matugen/templates
cp cava-colors.ini.template discord.css.template gtk.css.template \
   kitty-colors.conf.template nvim-colors.lua.template obsidian.css.template \
   qtct.conf.template qt-style.qss.template sddm-colors.qml.template \
   swayosd.css.template \
   ~/dotfiles/profiles/serpantinum/matugen/templates/
cd ~/dotfiles
```

Не переносим: `qs_colors.json.template` (шелл ilyamiro, у serpantinum свой) и
`hyprland.conf.template` (hyprlang; для lua-рига нужен свой, шаг 2).

- [ ] **Шаг 2: Шаблон цветов рамок для lua-рига**

`apply_rig_colors` читает `hypr/colors.conf` и берёт оттуда `$active_border` /
`$inactive_border` — формат hyprlang, но файл читается `awk`, а не Hyprland,
поэтому для lua-рига он тоже годится. Создать
`profiles/serpantinum/matugen/templates/hypr-colors.conf.template`:

```
# АВТОГЕН matugen — не править руками.
# Читается bin/dotprofile apply_rig_colors (awk по $active_border).
$active_border = rgba({{colors.primary.default.hex_stripped}}ee)
$inactive_border = rgba({{colors.outline_variant.default.hex_stripped}}55)
```

- [ ] **Шаг 3: config.toml профиля**

Создать `profiles/serpantinum/matugen/config.toml`, взяв за основу ilyamiro-овский
и заменив шелл-специфичные выходы:

```bash
sed -n '1,80p' profiles/ilyamiro/matugen/config.toml
```

В новом файле оставить секции `gtk`, `qtct`, `kitty`, `cava`, `swayosd`, `nvim`,
`discord`, `obsidian`, `sddm` с теми же `output_path`, и добавить:

```toml
[templates.hyprcolors]
input_path = "~/.config/matugen/templates/hypr-colors.conf.template"
output_path = "~/.config/hypr/colors.conf"
```

Убрать секцию `quickshell` (её выход `~/.config/hypr/scripts/quickshell/qs_colors.json`
принадлежит шеллу ilyamiro и у serpantinum не существует).

- [ ] **Шаг 4: Ветки Discord и Obsidian в dotprofile**

`apply_rig_colors` сейчас знает только `ilyamiro` и дефолт caelestia. Открыть
`bin/dotprofile`, найти блок с комментарием «Vencord-тема Discord» и заменить
условие так, чтобы matugen-вариант брался для любого рига, у которого он есть:

```bash
    local dsrc="$HOME/.cache/matugen/discord-$name.theme.css"
    [[ -f "$dsrc" ]] || dsrc="$PROFILES/caelestia/discord.theme.css"
```

И симметрично для Obsidian:

```bash
    local osrc="$HOME/.cache/matugen/obsidian-$name.css"
    [[ -f "$osrc" ]] || osrc="$PROFILES/caelestia/obsidian.css"
```

Это убирает захардкоженные имена ригов и заодно снимает ветку, оставшуюся от
удалённого end4.

- [ ] **Шаг 5: Проверка**

```bash
bash -n bin/dotprofile && echo "syntax ok"
bin/dotprofile doctor
```

`doctor` должен печатать `serpantinum ok`.

- [ ] **Шаг 6: Коммит**

```bash
git add profiles/serpantinum/matugen bin/dotprofile
git commit -m "feat(serpantinum): theme the desktop from the rig's own matugen"
```

---

### Task 5: Свитчер знает про новый риг

**Файлы:**
- Создать: `.config/quickshell/rigswitch/logos/serpantinum.svg`
- Изменить: `.config/quickshell/rigswitch/scan-rigs.sh`,
  `.config/quickshell/rigswitch/shell.qml`, `bin/rigdo`

**Интерфейсы:**
- Потребляет: `profiles/serpantinum/session.sh` из задачи 2.
- Отдаёт: рабочий пикер, показывающий три рига.

- [ ] **Шаг 1: Обои для карточки рига**

`scan-rigs.sh` достаёт превью обоев на риг. Найти, где serpantinum хранит путь
к текущим обоям:

```bash
grep -rn "wallpaper" ~/src/serpantinum/src/scripts/wallpaper/*.sh | head -10
```

Добавить в `case` функции получения обоев ветку `serpantinum)` по образцу
существующих, указав найденный путь.

- [ ] **Шаг 2: Определение живого шелла**

В `.config/quickshell/rigswitch/shell.qml`, в функции `shellPgrep`, добавить
строку перед `return "true";`:

```javascript
        if (name === "serpantinum") return "pgrep -f serpantinumd";
```

Оверлей по этому признаку понимает, что новый шелл поднялся, и гасит себя.

- [ ] **Шаг 3: Ветки rigdo**

`bin/rigdo` маршрутизирует контрактные действия в шелл активного рига.
Разведано по вендоренной копии (2026-09-02):

- `serpantinum msg <action> <target>` проксирует в `src/scripts/qs_manager.sh` —
  **тот же интерфейс, что у ilyamiro**, с тем же словарём виджетов
  (`wallpaper`, `network`, `volume`, `guide`, `calendar`, `music`);
- скрипт-команды первого уровня: `lock`, `screenshot`, `reload`, `exit`,
  `volume`, `brightness`, `weather`.

В начало `bin/rigdo`, рядом с `QSM` и `ILSCRIPTS`, добавить:

```bash
SERP="$HOME/dotfiles/profiles/serpantinum/shell/bin/serpantinum"
```

Затем в каждом `case`-блоке добавить ветку перед `else`:

```bash
    launcher)
        if [[ "$ACTIVE" == ilyamiro ]]; then bash "$QSM" toggle applauncher
        elif [[ "$ACTIVE" == serpantinum ]]; then "$SERP" msg toggle applauncher
        else caelestia shell drawers toggle launcher; fi ;;
    wallpaper)
        if [[ "$ACTIVE" == ilyamiro ]]; then bash "$QSM" toggle wallpaper
        elif [[ "$ACTIVE" == serpantinum ]]; then "$SERP" msg toggle wallpaper
        else hint "пикер обоев — в риге serpantinum (SUPER+SHIFT+D)"; fi ;;
```

По тому же образцу: `settings` → `msg toggle settings`, `music` →
`msg toggle music`, `calendar` → `msg toggle calendar`, `battery` →
`msg toggle battery`, `network` → `msg toggle network`, `guide` →
`msg toggle guide`, `clipboard` → `msg toggle clipboard`.

Действия со своей скрипт-командой не идут через `msg`:

```bash
    screenshot)
        if [[ "$ACTIVE" == ilyamiro ]]; then bash "$ILSCRIPTS/screenshot.sh"
        elif [[ "$ACTIVE" == serpantinum ]]; then "$SERP" screenshot
        else hypr_global caelestia:screenshotFreeze; fi ;;
    lock)
        if [[ "$ACTIVE" == ilyamiro ]]; then bash "$ILSCRIPTS/lock.sh"
        elif [[ "$ACTIVE" == serpantinum ]]; then "$SERP" lock
        else hypr_global caelestia:lock; fi ;;
```

Рестарт шелла — их же `reload`:

```bash
        elif [[ "$ACTIVE" == serpantinum ]]; then "$SERP" reload
```

`movies` аналога не имеет — `hint "movies — нет аналога в serpantinum"`.

- [ ] **Шаг 3b: Проверить, что действия доезжают**

После логина в риг (задача 6) прогнать каждое:

```bash
for a in launcher wallpaper settings music calendar clipboard screenshot guide; do
    echo "== $a"; bin/rigdo "$a"; sleep 1
done
```

Каждое должно открыть свой виджет либо напечатать `hint`. Молчание без реакции
означает, что имя действия у serpantinum другое — сверить с
`profiles/serpantinum/shell/src/scripts/qs_manager.sh`.

- [ ] **Шаг 4: Логотип**

У апстрима есть готовый `src/assets/logo.svg`:

```bash
cp profiles/serpantinum/shell/src/assets/logo.svg \
   .config/quickshell/rigswitch/logos/serpantinum.svg
```

- [ ] **Шаг 5: Проверка синтаксиса и коммит**

```bash
bash -n .config/quickshell/rigswitch/scan-rigs.sh && bash -n bin/rigdo && echo "syntax ok"
git add .config/quickshell/rigswitch bin/rigdo
git commit -m "feat(serpantinum): teach the switcher and rigdo about the new rig"
```

---

### Task 6: Приёмка

**Файлы:** не меняются — это проверка.

- [ ] **Шаг 1: Логин в новый риг**

```bash
bin/dotprofile switch serpantinum --links-only
```

Затем релогин через SDDM в «Hyprland (rig)». `--links-only` переставляет
симлинки без попытки горячего свитча, а SDDM-запись читает `profiles/active`.

- [ ] **Шаг 2: Проверить, что риг поднялся целым**

```bash
hyprctl systeminfo | grep configProvider   # ожидается: lua
pgrep -f serpantinumd && echo "шелл поднялся"
bin/dotprofile doctor                       # все каталоги ok, битых симлинков нет
```

- [ ] **Шаг 3: Проверить владение биндами**

```bash
hyprctl eval "local f=io.open('/tmp/rig.txt','w')
f:write('shared=', __rig.count('shared'), ' serpantinum=', __rig.count('serpantinum'))
f:close()"
sleep 0.3; cat /tmp/rig.txt
hyprctl binds -j | jq length
```

Сумма `shared + serpantinum` обязана совпасть с числом биндов. Расхождение
означает, что часть биндов создана до прелюдии — проверить, что `dofile`
реестра стоит ПЕРВОЙ строкой `hyprland.lua`.

- [ ] **Шаг 4: Главный критерий — свитч без релогина**

```bash
bin/dotprofile switch caelestia
```

Ожидается: все стадии `ok`, бар меняется на caelestia, цвета/анимации/правила
целевого рига, релогина НЕ происходит. Бинды при этом не меняются — стадия
`binds` отключена намеренно (`docs/tech-debt.md` п.8).

Обратно:

```bash
bin/dotprofile switch serpantinum
```

- [ ] **Шаг 5: Зафиксировать результат в tech-debt**

Если шаг 4 прошёл — п.2 tech-debt («горячий свитч — источник половины
сложности») получает закрытие для пары caelestia ↔ serpantinum. Отметить это в
`docs/tech-debt.md` и перечислить, что теперь можно снести: кросс-движковые
ветки `rigdo`, `bin/hypr-exec`, `animations-runtime.keywords`,
`disable_autoreload`.

Вывод ilyamiro из эксплуатации — отдельная задача, только после того как
serpantinum отработал как daily (требование 1 спеки).

- [ ] **Шаг 6: Коммит**

```bash
git add docs/tech-debt.md
git commit -m "docs(tech-debt): record the single-engine switch closing item 2"
```
