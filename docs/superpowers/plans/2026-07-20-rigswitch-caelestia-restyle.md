# Rigswitch caelestia-restyle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перерисовать overlay-пикер `qs -c rigswitch` под визуальную грамматику caelestia (material-палитра, M3 spring-моушен, morph пикер→сплэш), не трогая логику свитча.

**Architecture:** Токены caelestia вшиты числами в QML rigswitch (системный `qs` не имеет плагина `Caelestia.Config`). Новый синглтон `Tokens.qml` читает `scheme.json` в рантайме с fallback-дефолтами и держит кривые/радиусы. `RigCard.qml` переписан из карточки в строку списка с state-морфом. `shell.qml` — framed-panel пикер + crossfade+rise transition. Backdrop-blur — через hyprland `layer_rule` на namespace `rigswitch` в обоих lua-ригах.

**Tech Stack:** Quickshell (QML/Qt6), системный `/usr/bin/qs`, hyprland lua-конфиг (`hl.layer_rule`), bash smoke-тесты.

## Global Constraints

- Токены — **числовые константы в QML**, не импорты (нет плагина `Caelestia.Config` в системном `qs`).
- Цвета — рантайм-чтение `~/.local/state/caelestia/scheme.json`, fallback на вшитые дефолты; rigswitch ВСЕГДА caelestia-палитра.
- НЕ трогать: `bin/dotprofile`, `.config/quickshell/rigswitch/Rigs.qml`, `.config/quickshell/rigswitch/scan-rigs.sh`, `profiles/end4/session.sh`.
- Логика transition (execDetached `dotprofile switch`, hot guard-поллинг, relogin safetyQuit, кап 2.5с, fadeOutAndQuit) сохраняется дословно — меняется только представление.
- UI-тексты только английские.
- Motion-кривые (verbatim из caelestia tokens.hpp): spring `[0.38,1.21,0.22,1,1,1]` 500ms, effects `[0.34,0.8,0.34,1,1,1]` 200ms, decel `[0.05,0.7,0.1,1,1,1]` 400ms.
- Смоук-гейт каждой задачи: `timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1; ! grep -iE '(error|warning|is not a type|cannot assign|unable to)' /tmp/rs.log` — лог чистый. (Overlay откроется на 4с и закроется по timeout; keyboardFocus Exclusive → не трогай клаву эти 4с.)

---

### Task 1: `Tokens.qml` — синглтон токенов

**Files:**
- Create: `.config/quickshell/rigswitch/Tokens.qml`
- Modify: `.config/quickshell/rigswitch/shell.qml` (одна строка — цвет surface тянем из Tokens, чтобы синглтон грузился и смоук проверял парс)

**Interfaces:**
- Produces: singleton `Tokens` с:
  - `property var c` — map ролей → hex-строка `"#rrggbb"`: `surface`, `surfaceContainer`, `surfaceContainerLow`, `onSurface`, `onSurfaceVariant`, `primary`, `secondaryContainer`, `onSecondaryContainer`, `outline`, `outlineVariant`, `errorContainer`, `onErrorContainer`.
  - `readonly property var springCurve: [0.38,1.21,0.22,1,1,1]`
  - `readonly property var effectsCurve: [0.34,0.8,0.34,1,1,1]`
  - `readonly property var decelCurve: [0.05,0.7,0.1,1,1,1]`
  - `readonly property int durSpring: 500`, `durEffects: 200`, `durDecel: 400`
  - `readonly property int radMedium: 12`, `radLarge: 16`, `radRow: 22`, `radPanel: 28`

- [ ] **Step 1: Создать `Tokens.qml`**

```qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Дефолты = caelestia scheme.json (vibrant dark). Fallback при
    // отсутствии/битом scheme.json. rigswitch всегда caelestia-палитра.
    readonly property var fallback: ({
        surface: "#0a0f0f",
        surfaceContainer: "#131b1a",
        surfaceContainerLow: "#0e1514",
        onSurface: "#dce8e6",
        onSurfaceVariant: "#a2adac",
        primary: "#9bd0cc",
        secondaryContainer: "#27403e",
        onSecondaryContainer: "#a9c5c2",
        outline: "#6d7876",
        outlineVariant: "#3f4a49",
        errorContainer: "#871f21",
        onErrorContainer: "#ff9993"
    })

    property var c: fallback

    readonly property var springCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var effectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var decelCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int durSpring: 500
    readonly property int durEffects: 200
    readonly property int durDecel: 400
    readonly property int radMedium: 12
    readonly property int radLarge: 16
    readonly property int radRow: 22
    readonly property int radPanel: 28

    // Путь можно переопределить env RIGSWITCH_SCHEME (для теста fallback).
    readonly property string schemePath:
        Quickshell.env("RIGSWITCH_SCHEME") ||
        (Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json")

    Process {
        command: ["cat", root.schemePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseScheme(this.text)
        }
    }

    function parseScheme(txt) {
        try {
            const j = JSON.parse(txt);
            const src = j.colours || {};
            const out = {};
            for (const k in root.fallback) {
                const v = src[k];
                out[k] = (typeof v === "string" && v.length >= 6) ? "#" + v : root.fallback[k];
            }
            root.c = out;
        } catch (e) {
            root.c = root.fallback;   // битый/пустой JSON — дефолты
        }
    }
}
```

- [ ] **Step 2: Прогрузить синглтон из shell.qml (иначе не инстанцируется)**

В `.config/quickshell/rigswitch/shell.qml` заменить строку цвета surface:

```qml
            color: root.phase === "picker" ? "#cc000000" : "#dd101010"
```

на:

```qml
            color: root.phase === "picker" ? Tokens.c.surface : Tokens.c.surface
```

(Временно — Task 3/4 перепишут этот блок; здесь только чтобы Tokens грузился и смоук проверил парс+fallback.)

- [ ] **Step 3: Смоук — реальный scheme.json**

Run:
```bash
timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1; grep -iE '(error|warning|is not a type|cannot assign|unable to)' /tmp/rs.log || echo CLEAN
```
Expected: `CLEAN` (Tokens загрузился, распарсил scheme.json).

- [ ] **Step 4: Смоук — fallback на битом JSON**

Run:
```bash
printf 'not json{' > /tmp/bad-scheme.json
RIGSWITCH_SCHEME=/tmp/bad-scheme.json timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1
grep -iE '(error|warning|TypeError|cannot assign|unable to)' /tmp/rs.log || echo CLEAN
```
Expected: `CLEAN` (catch сработал, дефолты, без краша).

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .config/quickshell/rigswitch/Tokens.qml .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): Tokens.qml — caelestia-палитра из scheme.json + fallback"
```

---

### Task 2: `RigCard.qml` — карточка → строка списка со state-морфом

**Files:**
- Rewrite: `.config/quickshell/rigswitch/RigCard.qml`

**Interfaces:**
- Consumes: `Tokens` (Task 1); `rig` = `{name, engine, active, relogin, wallpaper}` (из `Rigs.qml`, не меняем).
- Produces: `RigCard` — строка списка. Свойства `required property var rig`, `property bool current`, сигналы `hovered()`, `activated()`. Ширина `implicitWidth`/фикс 300, высота ~58.

- [ ] **Step 1: Переписать `RigCard.qml`**

```qml
import QtQuick

// Строка рига в списке-пикере: thumb обоев + имя + сабтайтл (движок·режим),
// active-dot / бейдж relogin справа. State-морф по current (signature caelestia):
// фон surfaceContainer→secondaryContainer, border outlineVariant→primary,
// radius large→row, всё через Behavior.
Rectangle {
    id: row
    required property var rig
    property bool current: false
    signal hovered()
    signal activated()

    width: 300
    height: 58
    radius: current ? Tokens.radRow : Tokens.radLarge
    color: current ? Tokens.c.secondaryContainer : Tokens.c.surfaceContainer
    border.width: current ? 1.5 : 1
    border.color: current ? Tokens.c.primary : Tokens.c.outlineVariant
    clip: true

    Behavior on color { ColorAnimation { duration: Tokens.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.effectsCurve } }
    Behavior on radius { NumberAnimation { duration: Tokens.durSpring; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.springCurve } }
    Behavior on border.color { ColorAnimation { duration: Tokens.durEffects } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 13
        spacing: 12

        // thumb обоев (или градиент-заглушка)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 48; height: 36; radius: 9; clip: true
            color: Tokens.c.surfaceContainerLow

            Image {
                anchors.fill: parent
                source: row.rig.wallpaper
                visible: row.rig.wallpaper !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 96
            }
            Text {
                anchors.centerIn: parent
                visible: row.rig.wallpaper === ""
                text: row.rig.name.charAt(0).toUpperCase()
                color: Tokens.c.onSurfaceVariant
                font.pixelSize: 20; font.bold: true
            }
        }

        // имя + сабтайтл
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48 - 12 - 40
            spacing: 4
            Text {
                text: row.rig.name
                color: row.current ? Tokens.c.onSecondaryContainer : Tokens.c.onSurface
                font.pixelSize: 14; font.weight: Font.DemiBold
                Behavior on color { ColorAnimation { duration: Tokens.durEffects } }
            }
            Text {
                text: row.rig.engine + " · " + (row.rig.relogin ? "relogin" : "hot-switch")
                color: Tokens.c.onSurfaceVariant
                font.pixelSize: 10; font.weight: Font.Medium
            }
        }
    }

    // active-dot / бейдж relogin (правый край)
    Rectangle {
        visible: row.rig.active && !row.rig.relogin
        width: 8; height: 8; radius: 4
        color: Tokens.c.primary
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    }
    Rectangle {
        visible: row.rig.relogin
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        radius: 6
        width: reloginText.width + 12
        height: reloginText.height + 6
        color: Tokens.c.errorContainer
        Text {
            id: reloginText
            anchors.centerIn: parent
            text: "relogin"
            color: Tokens.c.onErrorContainer
            font.pixelSize: 9; font.weight: Font.DemiBold
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.hovered()
        onClicked: row.activated()
    }
}
```

- [ ] **Step 2: Смоук**

Run:
```bash
timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1; grep -iE '(error|warning|is not a type|cannot assign|unable to)' /tmp/rs.log || echo CLEAN
```
Expected: `CLEAN`. (Пикер ещё горизонтальный Row из старого shell.qml, но RigCard рендерится как строка — визуально криво, норм; чинит Task 3.)

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add .config/quickshell/rigswitch/RigCard.qml
git commit -m "feat(rigswitch): RigCard — строка списка со state-морфом (caelestia)"
```

---

### Task 3: `shell.qml` — framed-panel пикер, Up/Down nav, stagger-вход

**Files:**
- Rewrite: `.config/quickshell/rigswitch/shell.qml` (picker-часть; transition-часть пока старый Column-плейсхолдер — заменит Task 4)

**Interfaces:**
- Consumes: `Tokens` (T1), `RigCard` (T2), `Rigs` (не меняем).
- Produces: полный `shell.qml` с `root.phase`/`target`/`targetRelogin`/`select()`/таймерами/`fadeOutAndQuit()` (логика verbatim), framed-panel пикер, `win.currentIndex`, Up/Down/Enter/Esc.

- [ ] **Step 1: Записать полный `shell.qml`** (транзишн — временный Column, Task 4 заменит)

```qml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property string phase: "picker"       // "picker" | "transition"
    property string target: ""
    property bool targetRelogin: false

    function select(name) {
        if (phase !== "picker")
            return;
        const rig = Rigs.list.find(r => r.name === name);
        target = name;
        targetRelogin = rig ? rig.relogin : false;
        phase = "transition";
        Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/bin/dotprofile", "switch", name]);
        if (targetRelogin)
            safetyQuit.start();
        else
            holdTimer.start();
    }

    Timer { id: holdTimer; interval: 2000; onTriggered: shellCheck.running = true }
    Timer {
        id: capTimer
        interval: 2500
        running: root.phase === "transition" && !root.targetRelogin
        onTriggered: root.fadeOutAndQuit()
    }
    Timer { id: pollTimer; interval: 150; onTriggered: shellCheck.running = true }
    Process {
        id: shellCheck
        command: ["sh", "-c", root.shellPgrep(root.target)]
        onExited: code => { if (code === 0) root.fadeOutAndQuit(); else pollTimer.start(); }
    }
    function shellPgrep(name) {
        if (name === "caelestia") return "pgrep -f 'qs -c caelesti[a]'";
        if (name === "end4")      return "pgrep -f -- '-c i[i]'";
        return "true";
    }

    Timer { id: safetyQuit; interval: 5000; onTriggered: Qt.quit() }

    property bool quitting: false
    function fadeOutAndQuit() {
        if (quitting) return;
        quitting = true;
        quitAnim.start();
    }

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rigswitch"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#00000000"

        property int currentIndex: 0

        Connections {
            target: Rigs
            function onListChanged() {
                const i = Rigs.list.findIndex(r => r.active);
                if (i >= 0) win.currentIndex = i;
            }
        }

        Rectangle {
            id: surface
            anchors.fill: parent
            // полупрозрачный скрим — блюр стола даёт hyprland layer_rule
            color: Qt.rgba(0.03, 0.06, 0.06, 0.55)
            focus: true
            Keys.onEscapePressed: if (root.phase === "picker") Qt.quit()
            Keys.onUpPressed: win.currentIndex = Math.max(0, win.currentIndex - 1)
            Keys.onDownPressed: win.currentIndex = Math.min(Rigs.list.length - 1, win.currentIndex + 1)
            Keys.onReturnPressed: if (Rigs.list.length) root.select(Rigs.list[win.currentIndex].name)

            NumberAnimation {
                id: quitAnim
                target: surface
                property: "opacity"
                to: 0
                duration: 300
                onFinished: Qt.quit()
            }

            // ── Фаза 1: framed-panel пикер ──
            Rectangle {
                id: panel
                anchors.centerIn: parent
                visible: root.phase === "picker"
                width: pickerCol.width + 40
                height: pickerCol.height + 40
                radius: Tokens.radPanel
                color: Qt.rgba(Qt.color(Tokens.c.surfaceContainerLow).r,
                               Qt.color(Tokens.c.surfaceContainerLow).g,
                               Qt.color(Tokens.c.surfaceContainerLow).b, 0.85)
                border.width: 1.5
                border.color: Tokens.c.outline

                Column {
                    id: pickerCol
                    anchors.centerIn: parent
                    spacing: 9

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "SWITCH RIG"
                        color: Tokens.c.primary
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        bottomPadding: 5
                    }

                    Repeater {
                        model: Rigs.list
                        RigCard {
                            id: card
                            required property int index
                            required property var modelData
                            rig: modelData
                            current: index === win.currentIndex
                            onHovered: win.currentIndex = index
                            onActivated: { win.currentIndex = index; root.select(rig.name); }

                            // stagger-вход: снизу + fade, задержка по индексу
                            opacity: 0
                            transform: Translate { id: tr; y: 12 }
                            Component.onCompleted: entrance.start()
                            ParallelAnimation {
                                id: entrance
                                PauseAnimation { duration: card.index * 40 }
                                NumberAnimation { target: card; property: "opacity"; to: 1; duration: Tokens.durDecel; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.decelCurve }
                                NumberAnimation { target: tr; property: "y"; to: 0; duration: Tokens.durDecel; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.decelCurve }
                            }
                        }
                    }
                }
            }

            // ── Фаза 2: transition (ВРЕМЕННО — Task 4 заменит на crossfade+rise) ──
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: root.phase === "transition"
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.target
                    color: Tokens.c.onSurface
                    font.pixelSize: 42; font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.targetRelogin
                    text: "logging out to SDDM…"
                    color: Tokens.c.onSurfaceVariant
                    font.pixelSize: 16
                }
            }
        }
    }
}
```

- [ ] **Step 2: Смоук**

Run:
```bash
timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1; grep -iE '(error|warning|is not a type|cannot assign|unable to)' /tmp/rs.log || echo CLEAN
```
Expected: `CLEAN`. Пикер — вертикальный список в панели, хедер SWITCH RIG, строки въезжают снизу.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): framed-panel пикер, Up/Down nav, stagger-вход"
```

---

### Task 4: `shell.qml` — transition crossfade + rise

**Files:**
- Modify: `.config/quickshell/rigswitch/shell.qml` (заменить фазу-2 Column и добавить fade панели)

**Interfaces:**
- Consumes: `Tokens`, всё из Task 3.
- Produces: crossfade+rise сплэш; логика таймеров/guard не меняется.

- [ ] **Step 1: Панель-пикер гасим при transition — добавить Behavior+opacity в `panel`**

В блоке `Rectangle { id: panel ... }` заменить `visible: root.phase === "picker"` на:

```qml
                visible: opacity > 0
                opacity: root.phase === "picker" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.effectsCurve } }
```

- [ ] **Step 2: Заменить временный transition-Column на crossfade+rise сплэш**

Удалить блок `// ── Фаза 2: transition (ВРЕМЕННО ...` целиком (Column от `anchors.centerIn` до закрывающей `}` перед `}` surface) и вставить:

```qml
            // ── Фаза 2: transition-сплэш (crossfade + rise) ──
            Item {
                id: splash
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.phase === "transition" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.effectsCurve } }

                Column {
                    anchors.centerIn: parent
                    spacing: 18
                    scale: root.phase === "transition" ? 1 : 0.9
                    Behavior on scale { NumberAnimation { duration: Tokens.durSpring; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.springCurve } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 74; height: 74; radius: Tokens.radPanel
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Tokens.c.primary }
                            GradientStop { position: 1.0; color: Tokens.c.secondaryContainer }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.target.charAt(0).toUpperCase()
                            color: Tokens.c.surface
                            font.pixelSize: 34; font.bold: true
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.target
                        color: Tokens.c.onSurface
                        font.pixelSize: 34; font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.targetRelogin
                        text: "logging out to SDDM…"
                        color: Tokens.c.onSurfaceVariant
                        font.pixelSize: 15
                    }
                }
            }
```

- [ ] **Step 3: Смоук**

Run:
```bash
timeout 4 /usr/bin/qs -c rigswitch >/tmp/rs.log 2>&1; grep -iE '(error|warning|is not a type|cannot assign|unable to)' /tmp/rs.log || echo CLEAN
```
Expected: `CLEAN`.

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles
git add .config/quickshell/rigswitch/shell.qml
git commit -m "feat(rigswitch): transition-сплэш crossfade+rise (icon-tile + spring)"
```

---

### Task 5: Backdrop-blur — hyprland `layer_rule` в обоих lua-ригах

**Files:**
- Modify: `profiles/caelestia/hypr/hyprland/rules.lua`
- Modify: `profiles/end4/hypr/hyprland/rules.lua`

**Interfaces:**
- Consumes: namespace `rigswitch` (из `WlrLayershell.namespace` в shell.qml).
- Produces: блюр+fade фона под overlay в обоих lua-ригах.

- [ ] **Step 1: caelestia — добавить правила**

В конец `profiles/caelestia/hypr/hyprland/rules.lua` (после существующих `hl.layer_rule` блоков):

```lua

-- rigswitch overlay: блюр стола под полупрозрачной панелью пикера
hl.layer_rule({ match = { namespace = "rigswitch" }, blur = true })
hl.layer_rule({ match = { namespace = "rigswitch" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "rigswitch" }, animation = "fade" })
```

- [ ] **Step 2: end4 — добавить правила**

В конец `profiles/end4/hypr/hyprland/rules.lua` (после существующих `hl.layer_rule` блоков):

```lua

-- rigswitch overlay: блюр стола под полупрозрачной панелью пикера
hl.layer_rule({ match = { namespace = "rigswitch" }, blur = true })
hl.layer_rule({ match = { namespace = "rigswitch" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "rigswitch" }, animation = "fade" })
```

- [ ] **Step 3: Проверка синтаксиса lua (offline, без hl-глобала)**

Run:
```bash
cd ~/dotfiles
for f in profiles/caelestia/hypr/hyprland/rules.lua profiles/end4/hypr/hyprland/rules.lua; do
  luac -p "$f" 2>&1 && echo "OK: $f"
done
```
Expected: `OK:` для обоих (luac -p парсит без исполнения; `hl` — глобал рантайма, синтаксис валиден). Если `luac` нет — `lua -e "assert(loadfile('$f'))"`.

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles
git add profiles/caelestia/hypr/hyprland/rules.lua profiles/end4/hypr/hyprland/rules.lua
git commit -m "feat(rigswitch): backdrop-blur через layer_rule (caelestia + end4)"
```

---

## Финальная проверка (после всех задач)

- Смоук всех фаз: `timeout 4 /usr/bin/qs -c rigswitch` → лог чистый.
- **E2E глазами (на пользователе, вне плана):** SUPER+SHIFT+D → панель с блюром, stagger-вход, Up/Down, выбор end4 → crossfade+rise сплэш → hot-свитч. Отдельно relogin →ilyamiro (убивает сессию).
- Backdrop-blur виден только после relogin/reload рига (layer_rule применяется на старте Hyprland).

## Self-review заметки

- Спек-покрытие: Tokens (T1) ✓, RigCard list-row+морф (T2) ✓, framed-panel+stagger+nav (T3) ✓, crossfade+rise (T4) ✓, layer_rule blur (T5) ✓. Rigs/scan/dotprofile — вне области, не трогаются ✓.
- Типы: `Tokens.c.*` строки, `Tokens.*Curve` массивы, `Tokens.dur*`/`rad*` int — консистентны T1→T4. `RigCard`: `rig`/`current`/`hovered()`/`activated()` — совпадают T2↔T3.
- Плейсхолдеров нет; весь QML/lua дан целиком.
