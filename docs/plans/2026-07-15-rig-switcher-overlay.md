# rig-switcher overlay — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Revision 2 (2026-07-18): обновлён под движковый v2-свитч
(`rig-switch-engine-split`): transition двухрежимный (hot / relogin),
end4-обои реальные, движок-детект в модели ригов.

**Goal:** Заменить fuzzel-меню `SUPER+SHIFT+D` богатым quickshell-overlay
(карточки ригов) и замаскировать голый Hyprland при lua↔lua хот-свитче
transition-сплэшем — один standalone-процесс `qs -c rigswitch`.

**Architecture:** Независимый quickshell-конфиг на layer-shell Overlay. Две
фазы: пикер → transition. Transition двухрежимный: **hot** (движок цели ==
движок сессии — маскируем свитч, guard+таймеры) / **relogin** (кросс-движок —
короткий сплэш, процесс умирает вместе с Hyprland; SDDM не маскируем).
`dotprofile menu` запускает overlay; overlay зовёт `dotprofile switch`.
`cmd_switch` не меняется.

**Tech Stack:** Quickshell (QML, Quickshell.Wayland Layershell), bash
(`bin/dotprofile`), Hyprland, jq.

## Global Constraints

- Спека: `docs/specs/2026-07-15-rig-switcher-overlay-design.md` (Revision 2).
- **Пререквизит: ветка `rig-switch-engine-split` смержена в main** (v2-свитч в
  `bin/dotprofile`: `rig_engine`, `hypr_provider`, `trigger_relogin`, хот-свитч
  без reload). Перед исполнением ребейзнуть `rig-switcher-overlay` на main.
- Живёт в dotfiles: `dotfiles/.config/quickshell/rigswitch/`, симлинк в
  `~/.config/quickshell/rigswitch`. Не контестируемый.
- **Домен без юнит-тестов**: верификация = наблюдаемое поведение (запустить
  `qs -c rigswitch`, смотреть экран, `pgrep`, свитч вживую).
- **Не ломать свитч**: `cmd_menu` держит fuzzel-фолбэк; `cmd_switch` не трогать.
- Ветка `rig-switcher-overlay`. Коммит после каждой задачи.
- Референс quickshell-паттернов (Layershell, PanelWindow, CachingImage) —
  `~/caelestia/modules/` (рабочий quickshell-шелл).

---

## Файловая структура

**Создаётся:**
- `.config/quickshell/rigswitch/shell.qml` — точка входа, overlay-окно, фазы
- `.config/quickshell/rigswitch/RigCard.qml` — карточка рига (пикер)
- `.config/quickshell/rigswitch/Rigs.qml` — модель ригов (список + активный +
  движки + обои)

**Модифицируется:**
- `bin/dotprofile` — `cmd_menu`: запуск overlay + fuzzel-фолбэк
- `bootstrap.sh` — симлинк каталога

---

## Task 1: Scaffold overlay-окно

**Files:**
- Create: `.config/quickshell/rigswitch/shell.qml`
- Reference: `~/caelestia/modules/background/Background.qml` (Layershell-паттерн)

**Interfaces:**
- Produces: `qs -c rigswitch` открывает полноэкранный overlay, `Esc` закрывает.

- [ ] **Step 1: Минимальный overlay-qml**

`.config/quickshell/rigswitch/shell.qml`:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#00000000"

        Rectangle {
            anchors.fill: parent
            color: "#cc000000"   // временно: видимая заливка для проверки
            focus: true
            Keys.onEscapePressed: Qt.quit()
        }
    }
}
```

- [ ] **Step 2: Запустить и проверить**

Run: `qs -c rigswitch`
Expected: экран затемняется полупрозрачным; `Esc` закрывает процесс.
Проверить слой: `hyprctl layers | grep -i rigswitch` — на `overlay`.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): scaffold overlay-окно на layer Overlay"
```

**Проверка:** `qs -c rigswitch` рисует overlay поверх всего; `Esc` выходит;
`hyprctl layers` показывает слой на `overlay`.

---

## Task 2: Модель ригов (список, активный, движки, обои)

**Files:**
- Create: `.config/quickshell/rigswitch/Rigs.qml`
- Reference: `bin/dotprofile` (`rig_engine`, `hypr_provider`, `current`),
  спека §2 (пути обоев)

**Interfaces:**
- Produces (потребляют Task 3, 4):
  - `Rigs.list` = `[{name: string, active: bool, engine: "lua"|"hyprlang", relogin: bool, wallpaper: string /* file:// URL или "" */}]`
  - `Rigs.sessionEngine: string` — движок запущенной сессии

- [ ] **Step 1: Singleton с процессами чтения**

`.config/quickshell/rigswitch/Rigs.qml`:

```qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var list: []
    property string active: ""
    property string sessionEngine: ""   // "lua" | "hyprlang"

    readonly property string home: Quickshell.env("HOME")
    readonly property string profiles: home + "/dotfiles/profiles"

    // активный риг: readlink profiles/active
    Process {
        command: ["readlink", root.profiles + "/active"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.active = this.text.trim(); root.refresh(); } }
    }

    // движок сессии — как hypr_provider в dotprofile
    Process {
        command: ["sh", "-c", "hyprctl systeminfo 2>/dev/null | awk -F': ' '/configProvider/{print $2}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.sessionEngine = this.text.trim(); root.refresh(); } }
    }

    // список ригов + движок каждого (движок: есть hypr/hyprland.lua → lua) +
    // разрешённый путь обоев (см. resolve-wallpaper, Step 2)
    Process {
        id: scan
        command: ["sh", "-c", root.home + "/.config/quickshell/rigswitch/scan-rigs.sh"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseScan(this.text) }
    }

    property var scanned: []   // [{name, engine, wallpaper}]
    function parseScan(t) {
        // строки вида: name<TAB>engine<TAB>wallpaper-путь-или-пусто
        root.scanned = t.trim().split("\n").filter(l => l).map(l => {
            const p = l.split("\t");
            return { name: p[0], engine: p[1], wallpaper: p[2] || "" };
        });
        root.refresh();
    }

    function refresh() {
        if (!root.scanned.length) return;
        root.list = root.scanned.map(r => ({
            name: r.name,
            engine: r.engine,
            active: r.name === root.active,
            relogin: root.sessionEngine !== "" && r.engine !== root.sessionEngine,
            wallpaper: r.wallpaper ? "file://" + r.wallpaper : ""
        }));
    }
}
```

- [ ] **Step 2: scan-rigs.sh — скан ригов + разрешение обоев**

Разрешение путей обоев — в отдельном sh (QML-процессы не для такой логики).
`.config/quickshell/rigswitch/scan-rigs.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Выводит по ригу: name<TAB>engine<TAB>абсолютный-путь-превью (или пусто).
set -u
PROFILES="$HOME/dotfiles/profiles"

wallpaper_for() {
    local rig="$1" p=""
    case "$rig" in
        caelestia)
            p="$(cat "$HOME/.local/state/caelestia/wallpaper/path.txt" 2>/dev/null)" ;;
        ilyamiro)
            p="$(cat "$HOME/.local/state/quickshell/wallpaper_picker/last_wallpaper" 2>/dev/null)"
            case "$p" in *.mp4|*.webm|*.mkv)
                p="$HOME/.cache/quickshell/wallpaper_picker/current_wallpaper.png" ;;
            esac ;;
        end4)
            p="$(jq -r '.background.wallpaperPath // empty' \
                "$HOME/.config/illogical-impulse/config.json" 2>/dev/null)"
            case "$p" in *.mp4|*.webm|*.mkv)
                p="$PROFILES/end4/hypr/custom/scripts/mpvpaper_thumbnails/$(basename "$p").jpg" ;;
            esac ;;
    esac
    [[ -f "$p" ]] && printf '%s' "$p"
}

for d in "$PROFILES"/*/; do
    name="$(basename "$d")"
    [[ "$name" == "active" ]] && continue
    engine=hyprlang
    [[ -f "$d/hypr/hyprland.lua" ]] && engine=lua
    printf '%s\t%s\t%s\n' "$name" "$engine" "$(wallpaper_for "$name")"
done
```

- [ ] **Step 3: Проверить скрипт отдельно**

Run: `bash ~/dotfiles/.config/quickshell/rigswitch/scan-rigs.sh`
Expected: 3 строки `caelestia	lua	/путь`, `end4	lua	/путь`,
`ilyamiro	hyprlang	/путь`; пути существуют (или пусто, если состояние
рига не инициализировано — это ок, будет заглушка).

- [ ] **Step 4: Проверить модель в overlay**

Временно вывести в overlay (Text):
`Rigs.list.length + " rigs, active=" + Rigs.active + ", session=" + Rigs.sessionEngine`
— запустить `qs -c rigswitch`, убедиться: 3 рига, active = текущий,
sessionEngine = `lua` (в lua-сессии). Убрать временный Text.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/Rigs.qml .config/quickshell/rigswitch/scan-rigs.sh
git commit -m "feat(rigswitch): модель ригов — список, активный, движки, обои"
```

**Проверка:** overlay показывает верное число ригов, активный, движок сессии;
scan-rigs.sh даёт реальные пути превью для всех трёх ригов.

---

## Task 3: Пикер-карточки (+ бейдж «релогин»)

**Files:**
- Create: `.config/quickshell/rigswitch/RigCard.qml`
- Modify: `.config/quickshell/rigswitch/shell.qml` (Row карточек + навигация)

**Interfaces:**
- Consumes: `Rigs.list` (Task 2).
- Produces: сигнал выбора `selected(name)` — потребляет Task 4; сигнатура
  обработчика в shell.qml: `function onSelected(name: string)`.

- [ ] **Step 1: RigCard.qml**

Карточка (фиксированный размер ~220x160, скруглённые углы):
- обои-thumbnail: `Image { source: modelData.wallpaper; fillMode: Image.PreserveAspectCrop }`;
  если `wallpaper === ""` — заглушка: Rectangle-градиент + крупная первая буква
  имени рига;
- имя рига (Text, снизу на затемнённой полосе);
- маркер активного (точка/рамка-подсветка при `modelData.active`);
- **бейдж «релогин»** (маленькая плашка в углу) при `modelData.relogin` —
  предупреждает, что выбор уведёт в SDDM;
- состояние hover/selected — подсветка рамки.

- [ ] **Step 2: Row карточек в shell.qml**

`Repeater { model: Rigs.list }` в центрированном `Row`. Свойство
`currentIndex`. `Keys.onLeftPressed/RightPressed` двигают индекс;
`Keys.onReturnPressed` эмитит `selected(Rigs.list[currentIndex].name)`;
мышь-hover ставит индекс, клик = select. `Esc` = `Qt.quit()`.

- [ ] **Step 3: Проверить**

`qs -c rigswitch` — карточки с обоями, активный помечен, на ilyamiro-карточке
(из lua-сессии) виден бейдж «релогин», стрелки/мышь двигают подсветку, Enter
пока печатает выбор (временный `console.log`).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/RigCard.qml .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): пикер-карточки с обоями и бейджем релогина"
```

**Проверка:** карточки рисуются с thumbnail'ами (включая end4); навигация
работает; активный помечен; кросс-движковый помечен «релогин»; Enter логирует
имя.

---

## Task 4: Transition-фаза (hot / relogin) + запуск свитча

**Files:**
- Modify: `.config/quickshell/rigswitch/shell.qml`

**Interfaces:**
- Consumes: `selected(name)` (Task 3); `Rigs.list[*].relogin`,
  `Rigs.list[*].name` (Task 2).
- Produces: overlay зовёт `dotprofile switch`; hot — держит сплэш ~2с+guard и
  выходит сам; relogin — сплэш «выход в SDDM…», умирает с компоновщиком.

- [ ] **Step 1: На выборе — свитч + смена фазы + режим**

```qml
property string phase: "picker"       // "picker" | "transition"
property string target: ""
property bool targetRelogin: false

function onSelected(name) {
    const rig = Rigs.list.find(r => r.name === name);
    target = name;
    targetRelogin = rig ? rig.relogin : false;
    phase = "transition";
    Quickshell.execDetached(["dotprofile", "switch", name]);
    if (targetRelogin)
        safetyQuit.start();     // Step 3
    else
        holdTimer.start();      // Step 3
}
```

- [ ] **Step 2: Transition-визуал**

При `phase === "transition"` скрыть Row карточек, показать: тёмный backdrop
(Rectangle `#dd101010`) + по центру Text с именем `target`; при
`targetRelogin` — подстрока ниже: `"выход в SDDM…"`. Fade-in через
`Behavior on opacity` (~200мс).

- [ ] **Step 3: Таймеры: hot (guard+кап) / relogin (страховка)**

```qml
// ── hot: fixed-минимум 2с, затем guard-поллинг pgrep, кап 2.5с ──
Timer { id: holdTimer; interval: 2000; onTriggered: shellCheck.running = true }
Timer { id: capTimer; interval: 2500
        running: phase === "transition" && !targetRelogin
        onTriggered: fadeOutAndQuit() }
Process {
    id: shellCheck
    command: ["sh", "-c", shellPgrep(target)]
    onExited: (code) => { if (code === 0) fadeOutAndQuit(); else shellCheck.running = true; }
}
function shellPgrep(name) {
    // только lua-пара — relogin-цели guard не нужен
    if (name === "caelestia") return "pgrep -f 'qs -c caelestia'";
    if (name === "end4")      return "pgrep -f 'qs -c ii'";
    return "true";
}
function fadeOutAndQuit() { /* opacity→0 за ~300мс, затем Qt.quit() */ }

// ── relogin: Hyprland выйдет сам (<1с) и заберёт overlay;
//    страховка на случай, если релогин не сработал ──
Timer { id: safetyQuit; interval: 5000; onTriggered: Qt.quit() }
```

Примечание: `pgrep -f 'qs -c ii'` матчит и март-quickshell end4 — бинарь в
`~/qs-test-prefix/usr/bin` тоже зовётся `qs`. Проверить вживую на Step 4.

- [ ] **Step 4: Проверить hot-свитч вживую (caelestia↔end4)**

Из caelestia: `qs -c rigswitch` → выбрать end4 → наблюдать: карточки исчезают,
сплэш с именем, свитч идёт под ним, голого Hyprland не видно, после подъёма
ii-шелла fade-out, end4 с обоями. Повторить обратно end4→caelestia.

- [ ] **Step 5: Проверить relogin-ветку вживую (→ ilyamiro)**

Из lua-сессии: `qs -c rigswitch` → выбрать ilyamiro → сплэш «ilyamiro · выход
в SDDM…» → SDDM-грайтер (подсвечен hyprland-ilyamiro) → вход → чистый
ilyamiro. Голый кадр до exit не мелькает. Обратно: из ilyamiro выбрать
caelestia → релогин в hyprland-lua.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): transition-сплэш — hot (guard+2с) и relogin-режим"
```

**Проверка:** hot-свитч не показывает голый Hyprland, guard дожидается нового
шелла, кап 2.5с работает; relogin показывает сплэш до выхода компоновщика и
не оставляет висящий процесс.

---

## Task 5: Интеграция в dotprofile + fallback

**Files:**
- Modify: `bin/dotprofile` (`cmd_menu`)

**Interfaces:**
- Consumes: `qs -c rigswitch`.
- Produces: `SUPER+SHIFT+D` открывает overlay; fuzzel-фолбэк если нет
  quickshell/конфига.

- [ ] **Step 1: cmd_menu — overlay + фолбэк**

Сохранить текущий fuzzel-код как fallback-ветку. Новый `cmd_menu`
(текущее тело см. `bin/dotprofile` — не менять его логику, только обернуть):

```bash
cmd_menu() {
    if command -v qs >/dev/null && [[ -d "$HOME/.config/quickshell/rigswitch" ]]; then
        exec qs -c rigswitch
    fi
    # ── fallback: старый fuzzel-путь ──
    local cur choice
    cur="$(current || true)"
    choice="$(list_profiles | sed "s/^${cur}\$/& (active)/" \
        | fuzzel --dmenu --prompt 'profile> ' --lines 4)" || exit 0
    choice="${choice% (active)}"
    [[ -z "$choice" || "$choice" == "$cur" ]] && exit 0
    cmd_switch "$choice"
}
```

- [ ] **Step 2: Проверить бинд**

Жать `SUPER+SHIFT+D` в живой сессии → открывается overlay-пикер. Временно
переименовать каталог rigswitch → жать бинд → открывается fuzzel (фолбэк).
Вернуть каталог.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles && git add bin/dotprofile
git commit -m "feat(rigswitch): cmd_menu запускает overlay, fuzzel как фолбэк"
```

**Проверка:** `SUPER+SHIFT+D` → overlay; без quickshell-конфига → fuzzel;
свитч работает обоими путями.

---

## Task 6: bootstrap-симлинк + e2e

**Files:**
- Modify: `bootstrap.sh`

- [ ] **Step 1: Симлинк**

Добавить в `bootstrap.sh` (по образцу других `.config`-симлинков):
`ln -sfn ~/dotfiles/.config/quickshell/rigswitch ~/.config/quickshell/rigswitch`

- [ ] **Step 2: e2e**

`bash -n bootstrap.sh` (синтаксис). Полный прогон:
1. `SUPER+SHIFT+D` в caelestia → пикер → end4: hot-свитч без голого Hyprland.
2. Обратно end4 → caelestia: то же.
3. → ilyamiro: relogin-сплэш → SDDM → вход → чистый ilyamiro.
4. Из ilyamiro `SUPER+SHIFT+D` → пикер работает и там → caelestia: релогин в
   hyprland-lua (через `.last-lua`).
5. `Esc` в пикере отменяет без свитча.
6. Fuzzel-фолбэк отрабатывает (без каталога rigswitch).

- [ ] **Step 3: Commit + merge**

```bash
cd ~/dotfiles && git add bootstrap.sh
git commit -m "feat(rigswitch): симлинк в bootstrap"
git switch main && git merge --no-ff rig-switcher-overlay
```
(merge — по решению пользователя, см. finishing-a-development-branch.)

**Проверка:** свежая установка симлинкует конфиг; полный e2e-прогон гладкий;
фолбэк цел.

---

## Self-review (покрытие спеки, Revision 2)

- §Контекст v2 (два режима свитча) → Task 2 (движок-детект в модели),
  Task 4 (двухрежимный transition). §Компонент 1 (конфиг) → Task 1,2,3,4.
  §2 пикер + бейдж «релогин» → Task 3. §3 transition hot/relogin → Task 4.
  §4 интеграция dotprofile → Task 5. §5 установка → Task 6.
  §Риски (z-order, guard, движок-рассинхрон, март-qs, fallback) → проверки
  Task 1, 4 (Step 3–5), 5.
- Пути обоев всех трёх ригов (включая end4 через illogical-impulse config.json
  + mpvpaper_thumbnails для видео) → scan-rigs.sh (Task 2), плейсхолдеров нет.
- Движок-детект скопирован 1:1 из `rig_engine`/`hypr_provider`
  (`bin/dotprofile`) — единый источник поведения с `cmd_switch`.
- qml-скелеты — стартовые; выравнивание под точную quickshell-версию API по
  референсу `~/caelestia/modules/` при импле (отмечено в Global Constraints).
