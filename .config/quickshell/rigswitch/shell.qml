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
            safetyQuit.start();   // Hyprland выйдет сам и заберёт overlay
        else
            holdTimer.start();
    }

    // ── hot: fixed-минимум 2с, затем guard-поллинг pgrep нового шелла, кап 2.5с ──
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
        // guard нужен только lua-паре — relogin-цели не поллим.
        // [x]-скобки: иначе pgrep матчит собственный sh -c враппер.
        if (name === "caelestia") return "pgrep -f 'qs -c caelesti[a]'";
        if (name === "end4")      return "pgrep -f -- '-c i[i]'";
        return "true";
    }

    // ── relogin: страховка, если релогин не сработал ──
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

        // стартовая подсветка — на активном риге
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
            color: root.phase === "picker" ? Tokens.c.surface : Tokens.c.surface
            focus: true
            Keys.onEscapePressed: if (root.phase === "picker") Qt.quit()
            Keys.onLeftPressed: win.currentIndex = Math.max(0, win.currentIndex - 1)
            Keys.onRightPressed: win.currentIndex = Math.min(Rigs.list.length - 1, win.currentIndex + 1)
            Keys.onReturnPressed: if (Rigs.list.length) root.select(Rigs.list[win.currentIndex].name)

            NumberAnimation {
                id: quitAnim
                target: surface
                property: "opacity"
                to: 0
                duration: 300
                onFinished: Qt.quit()
            }

            // ── Фаза 1: пикер ──
            Row {
                anchors.centerIn: parent
                spacing: 24
                visible: root.phase === "picker"

                Repeater {
                    model: Rigs.list
                    RigCard {
                        required property int index
                        required property var modelData
                        rig: modelData
                        current: index === win.currentIndex
                        onHovered: win.currentIndex = index
                        onActivated: { win.currentIndex = index; root.select(rig.name); }
                    }
                }
            }

            // ── Фаза 2: transition-сплэш ──
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: root.phase === "transition"
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.target
                    color: "#eeeeee"
                    font.pixelSize: 42
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.targetRelogin
                    text: "logging out to SDDM…"
                    color: "#999999"
                    font.pixelSize: 16
                }
            }
        }
    }
}
