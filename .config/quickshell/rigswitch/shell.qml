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
        }
    }
}
