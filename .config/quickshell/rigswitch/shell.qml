import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property string phase: "picker"       // "picker" | "transition"
    property string target: ""
    property string fromName: ""          // риг, с которого уходим (Rigs.active на момент клика)
    property bool targetRelogin: false
    property int direction: 1             // +1/-1 — по позиции target относительно fromName в Rigs.list

    // Контракт со стадиями bin/dotprofile cmd_switch (`stage <имя> ok|fail`).
    // binds сюда сознательно не входит — стадия отключена в dotprofile
    // (сегфолтит композитор), см. её комментарий там же.
    readonly property var stageOrder: ["links", "colors", "animations", "rules", "daemons", "state"]
    readonly property var stageLabels: ({
        links: "config", colors: "palette", animations: "motion",
        rules: "window rules", daemons: "shell", state: "state"
    })
    property var stageState: ({
        links: "pending", colors: "pending", animations: "pending",
        rules: "pending", daemons: "pending", state: "pending"
    })
    property bool anyFailed: false
    property bool switchDone: false
    property bool dismissed: false

    function roleOf(name) {
        const r = Rigs.byName(name);
        return r ? r.role : "";
    }

    readonly property var fromIdentity: RigIdentity.identityFor(root.fromName, root.roleOf(root.fromName))
    readonly property var toIdentity: RigIdentity.identityFor(root.target, root.roleOf(root.target))

    function lerpColor(c1, c2, t) {
        const a = Qt.color(c1), b = Qt.color(c2);
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function computeDirection(fromName, toName) {
        const list = Rigs.list;
        const i1 = list.findIndex(r => r.name === fromName);
        const i2 = list.findIndex(r => r.name === toName);
        if (i1 < 0 || i2 < 0 || i1 === i2)
            return 1;
        return i2 > i1 ? 1 : -1;
    }

    function select(name) {
        if (phase !== "picker")
            return;
        const rig = Rigs.list.find(r => r.name === name);
        root.fromName = Rigs.active;
        root.target = name;
        root.targetRelogin = rig ? rig.relogin : false;
        root.direction = root.computeDirection(root.fromName, root.target);
        root.stageState = {
            links: "pending", colors: "pending", animations: "pending",
            rules: "pending", daemons: "pending", state: "pending"
        };
        root.anyFailed = false;
        root.switchDone = false;
        phase = "transition";
        switchProc.command = [Quickshell.env("HOME") + "/dotfiles/bin/dotprofile", "switch", name];
        switchProc.running = true;
        if (root.targetRelogin)
            safetyQuit.start();
        else
            watchdog.start();
    }

    function handleStageLine(line) {
        const m = /^stage (\S+) (ok|fail)$/.exec(line.trim());
        if (!m)
            return;   // прочий stdout dotprofile (active:, relogin ->, диагностика) — не наш контракт, не показываем сырьём
        const key = m[1], status = m[2];
        if (!(key in root.stageState))
            return;
        const next = Object.assign({}, root.stageState);
        next[key] = status;
        root.stageState = next;
        if (status === "fail")
            root.anyFailed = true;
    }

    function handleSwitchExit(code) {
        root.switchDone = true;
        if (code !== 0)
            root.anyFailed = true;
        if (root.dismissed) {
            // юзер уже попросил закрыть оверлей — окно скрыто, ничего доигрывать не надо
            Qt.quit();
            return;
        }
        resultHold.start();
    }

    Process {
        id: switchProc
        running: false
        stdout: SplitParser { onRead: line => root.handleStageLine(line) }
        onExited: code => root.handleSwitchExit(code)
    }

    // Держим результат на экране, чтобы fail(ы) были ВИДНЫ, а не мигнули и исчезли.
    Timer {
        id: resultHold
        interval: root.anyFailed ? 1800 : 700
        onTriggered: root.fadeOutAndQuit()
    }

    // relogin рвёт горячий свитч на первой стадии — сессия уйдёт сама, это
    // короткий бэкстоп на случай, если systemctl/hyprctl exit не отработали.
    Timer { id: safetyQuit; interval: 5000; onTriggered: root.requestDismiss() }
    // Общий бэкстоп для горячего свитча: не таймер прогресса (тот теперь
    // честный, по stage-строкам), а потолок "process точно не должен висеть вечно".
    Timer { id: watchdog; interval: 20000; onTriggered: root.requestDismiss() }
    // Если юзер попросил закрыть, пока switchProc ещё жив — держим приложение
    // (скрытым) до его настоящего завершения максимум столько, потом добиваем.
    Timer { id: hardCeiling; interval: 15000; onTriggered: Qt.quit() }

    // Закрытие по биндy/Escape НЕ обязано убивать процесс на середине —
    // apply_rig_colors/daemons/rules пишут в живую сессию, и если оборвать
    // dotprofile switch руками, риг останется в получужом состоянии (та же
    // болезнь, что уже роняла GTK4-тему у end4). Поэтому если свитч ещё идёт,
    // просто прячем окно и ждём его настоящего конца.
    function requestDismiss() {
        if (root.dismissed)
            return;
        root.dismissed = true;
        if (switchProc.running) {
            win.visible = false;
            hardCeiling.start();
        } else {
            root.fadeOutAndQuit();
        }
    }

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
            Keys.onEscapePressed: root.requestDismiss()
            Keys.onUpPressed: if (root.phase === "picker") win.currentIndex = Math.max(0, win.currentIndex - 1)
            Keys.onDownPressed: if (root.phase === "picker") win.currentIndex = Math.min(Rigs.list.length - 1, win.currentIndex + 1)
            Keys.onReturnPressed: if (root.phase === "picker" && Rigs.list.length) root.select(Rigs.list[win.currentIndex].name)

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
                visible: opacity > 0
                opacity: root.phase === "picker" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.effectsCurve } }
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

            // ── Фаза 2: сборка целевого рига по стадиям ──
            Item {
                id: splash
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.phase === "transition" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.effectsCurve } }

                Column {
                    anchors.centerIn: parent
                    spacing: 20
                    scale: root.phase === "transition" ? 1 : 0.9
                    Behavior on scale { NumberAnimation { duration: Tokens.durSpring; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.springCurve } }

                    // лого рига на тёмной плашке; рамка перекрашивается живьём
                    // по доле реально прилетевших стадий — от акцента source
                    // рига к акценту target, а не мгновенно (честный прогресс)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 88; height: 88; radius: Tokens.radPanel
                        color: Tokens.c.surfaceContainerLow
                        border.width: 1.5
                        border.color: root.lerpColor(root.fromIdentity.accent, root.toIdentity.accent,
                                                      root.stageOrder.length ? assembly.landedCount / root.stageOrder.length : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.durEffects } }

                        Image {
                            id: splashLogo
                            anchors.centerIn: parent
                            width: 52; height: 52
                            source: root.target ? Quickshell.env("HOME") + "/.config/quickshell/rigswitch/logos/" + root.target + ".svg" : ""
                            visible: status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: 104
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: splashLogo.status !== Image.Ready
                            text: root.target.charAt(0).toUpperCase()
                            color: Tokens.c.onSurface
                            font.pixelSize: 40; font.bold: true
                        }
                    }
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.target
                            color: Tokens.c.onSurface
                            font.pixelSize: 34; font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.roleOf(root.target).length > 0
                            text: root.roleOf(root.target)
                            color: Tokens.c.onSurfaceVariant
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }
                    }

                    // сама сборка — шесть кусочков, по одному на реальную стадию
                    Assembly {
                        id: assembly
                        anchors.horizontalCenter: parent.horizontalCenter
                        stageState: root.stageState
                        stageOrder: root.stageOrder
                        stageLabels: root.stageLabels
                        style: root.toIdentity.style
                        accent: root.toIdentity.accent
                        direction: root.direction
                        relogin: root.targetRelogin
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.targetRelogin ? "logging out — restarting session"
                            : root.anyFailed ? "finished with issues"
                            : root.switchDone ? "ready"
                            : "switching…"
                        color: (root.anyFailed && !root.targetRelogin) ? Tokens.c.onErrorContainer : Tokens.c.onSurfaceVariant
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
