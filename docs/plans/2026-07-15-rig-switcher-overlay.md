# rig-switcher overlay — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Заменить fuzzel-меню `SUPER+SHIFT+D` богатым quickshell-overlay
(карточки ригов) и замаскировать голый Hyprland при свитче transition-сплэшем —
один standalone-процесс `qs -c rigswitch`.

**Architecture:** Независимый quickshell-конфиг на layer-shell Overlay. Две фазы:
пикер → transition. `dotprofile menu` запускает его; overlay зовёт
`dotprofile switch`. `cmd_switch` не меняется.

**Tech Stack:** Quickshell (QML, Quickshell.Wayland Layershell), fish/bash
(`bin/dotprofile`), Hyprland.

## Global Constraints

- Спека: `docs/specs/2026-07-15-rig-switcher-overlay-design.md`.
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
- `.config/quickshell/rigswitch/Rigs.qml` — модель ригов (список + активный + обои)

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

## Task 2: Модель ригов

**Files:**
- Create: `.config/quickshell/rigswitch/Rigs.qml`
- Reference: `bin/dotprofile` (`list_profiles`, `current`), спека §2 (пути обоев)

**Interfaces:**
- Produces: `Rigs.list` = [{name, active, wallpaper}], потребляет Task 3.

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

    // список профилей
    Process {
        id: listProc
        command: ["dotprofile", "status"]   // или прямой ls profiles/
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseActive(this.text) }
    }
    function parseActive(t) {
        root.active = (t.match(/active:\s*(\S+)/) || [])[1] || "";
    }

    // риги = каталоги в ~/dotfiles/profiles
    Process {
        id: dirs
        command: ["sh","-c","ls ~/dotfiles/profiles | grep -v '^active$'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.build(this.text) }
    }
    function wallpaperFor(name) {
        // пути wallpaper-state per rig (спека §2)
        if (name === "caelestia") return "file://" + Quickshell.env("HOME") + "/.local/state/caelestia/wallpaper/path.txt";
        if (name === "ilyamiro")  return "file://" + Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper_picker/last_wallpaper";
        return "";  // end4 и прочие — заглушка (Task 4)
    }
    function build(t) {
        const names = t.trim().split("\n").filter(x => x);
        root.list = names.map(n => ({ name: n, active: n === root.active, wallpaperRef: wallpaperFor(n) }));
    }
}
```

Примечание: wallpaper-state хранит *путь* в файле (не сам образ) — для caelestia
`path.txt` содержит путь к обоям. Прочитать содержимое (FileView) и подставить в
Image. Реализовать чтение в RigCard (Task 3) через `FileView`.

- [ ] **Step 2: Проверить парсинг**

Временно вывести `Rigs.list.length` и `Rigs.active` в overlay (Text) — запустить
`qs -c rigswitch`, убедиться: список = число ригов, active = текущий.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/Rigs.qml
git commit -m "feat(rigswitch): модель ригов (список, активный, пути обоев)"
```

**Проверка:** overlay показывает верное число ригов и активный.

---

## Task 3: Пикер-карточки

**Files:**
- Create: `.config/quickshell/rigswitch/RigCard.qml`
- Modify: `.config/quickshell/rigswitch/shell.qml` (Row карточек + навигация)

**Interfaces:**
- Consumes: `Rigs.list` (Task 2).
- Produces: сигнал выбора `selected(name)` (потребляет Task 4).

- [ ] **Step 1: RigCard.qml**

Карточка: обои-thumbnail (Image, source = прочитанный путь через FileView),
имя рига (Text), маркер активного (точка/рамка), состояние hover/selected
(подсветка рамки). Фиксированный размер (напр. 220x160), rounding.

- [ ] **Step 2: Row карточек в shell.qml**

`Repeater { model: Rigs.list }` в центрированном `Row`. Свойство
`currentIndex`. `Keys.onLeftPressed/RightPressed` двигают индекс;
`Keys.onReturnPressed` эмитит `selected(Rigs.list[currentIndex].name)`;
мышь-hover ставит индекс, клик = select. `Esc` = `Qt.quit()`.

- [ ] **Step 3: Проверить**

`qs -c rigswitch` — карточки с обоями, активный помечен, стрелки/мышь двигают
подсветку, Enter пока печатает выбор (временный `console.log`).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/RigCard.qml .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): пикер-карточки с навигацией и обоями"
```

**Проверка:** карточки рисуются с thumbnail'ами; навигация работает; активный
риг помечен; Enter логирует имя.

---

## Task 4: Transition-фаза + запуск свитча

**Files:**
- Modify: `.config/quickshell/rigswitch/shell.qml`

**Interfaces:**
- Consumes: `selected(name)` (Task 3).
- Produces: overlay зовёт `dotprofile switch`, держит сплэш ~2с+guard, выходит.

- [ ] **Step 1: На выборе — свитч + смена фазы**

```qml
property string phase: "picker"   // "picker" | "transition"
property string target: ""

function onSelected(name) {
    target = name;
    phase = "transition";
    switchProc.command = ["dotprofile", "switch", name];
    switchProc.running = true;
    holdTimer.start();
}
Process { id: switchProc }
```

- [ ] **Step 2: Transition-визуал**

При `phase === "transition"` скрыть Row карточек, показать: тёмный/blur backdrop
(Rectangle `#dd101010` или заглушка-обои цели с затемнением) + по центру Text с
именем `target`. Fade-in через Behavior on opacity (~200мс).

- [ ] **Step 3: Guard + fixed-минимум + кап**

```qml
Timer { id: holdTimer; interval: 2000; onTriggered: shellCheck.running = true }  // fixed-минимум 2с
Process {
    id: shellCheck
    // имя шелла целевого рига
    command: ["sh","-c", root.shellPgrep(target)]
    onExited: (code) => { if (code === 0 || capReached) fadeOutAndQuit(); else shellCheck.running = true; }
}
Timer { id: capTimer; interval: 2500; running: phase === "transition"; onTriggered: fadeOutAndQuit() }
```

`shellPgrep(name)`: caelestia→`pgrep -f 'qs -c caelestia'`,
ilyamiro→`pgrep -f 'quickshell -p .*Shell.qml'`, end4→`pgrep -f 'qs -c ii'`.
`fadeOutAndQuit`: opacity→0 (~300мс) затем `Qt.quit()`.

- [ ] **Step 4: Проверить вживую**

`qs -c rigswitch` → выбрать другой риг → наблюдать: карточки исчезают, сплэш с
именем, свитч идёт под ним, голого Hyprland не видно, через ~2с fade-out, новый
риг с обоями. Проверить оба направления (в т.ч. кросс-движковый).

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): transition-сплэш (свитч под overlay, guard+fixed 2с)"
```

**Проверка:** свитч не показывает голый Hyprland; сплэш держит ~2с; fade-out
после появления нового шелла; процесс выходит.

---

## Task 5: Интеграция в dotprofile + fallback

**Files:**
- Modify: `bin/dotprofile` (`cmd_menu`)

**Interfaces:**
- Consumes: `qs -c rigswitch`.
- Produces: `SUPER+SHIFT+D` открывает overlay; fuzzel-фолбэк если нет quickshell.

- [ ] **Step 1: cmd_menu — overlay + фолбэк**

Сохранить текущий fuzzel-код как ветку `else`. Новый `cmd_menu`:

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

**Проверка:** `SUPER+SHIFT+D` → overlay; без quickshell → fuzzel; свитч работает
обоими путями.

---

## Task 6: bootstrap-симлинк + e2e

**Files:**
- Modify: `bootstrap.sh`

- [ ] **Step 1: Симлинк**

Добавить в `bootstrap.sh` (по образцу других `.config`-симлинков):
`ln -sfn ~/dotfiles/.config/quickshell/rigswitch ~/.config/quickshell/rigswitch`

- [ ] **Step 2: e2e**

`bash -n bootstrap.sh` (синтаксис). Полный прогон: `SUPER+SHIFT+D` в двух ригах
(caelestia, ilyamiro) → пикер → свитч без голого Hyprland в обе стороны. Esc
отменяет. Fuzzel-фолбэк отрабатывает.

- [ ] **Step 3: Commit + merge**

```bash
cd ~/dotfiles && git add bootstrap.sh
git commit -m "feat(rigswitch): симлинк в bootstrap"
git switch main && git merge --no-ff rig-switcher-overlay
```
(merge — по решению пользователя, см. finishing-a-development-branch.)

**Проверка:** свежая установка симлинкует конфиг; свитч в двух ригах гладкий,
без голого Hyprland; фолбэк цел.

---

## Self-review (покрытие спеки)

- Спека §Архитектура → Task 1 (overlay), 4 (фазы). §Компонент 1 (конфиг) →
  1,2,3,4. §2 пикер → 3. §3 transition → 4. §4 интеграция dotprofile → 5.
  §5 установка → 6. §Риски (z-order, guard, fallback) → проверки Task 1,4,5.
- Значения путей обоев (§2) — в Rigs.qml (Task 2); end4-путь осознанно
  заглушка до интеграции end4 (спека §Риски), не плейсхолдер плана.
- qml-скелеты — стартовые; выравнивание под точную quickshell-версию API по
  референсу `~/caelestia/modules/` при импле (отмечено в Global Constraints).
