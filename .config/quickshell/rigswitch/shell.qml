import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    // Task 4 заменит на запуск свитча + transition-фазу
    function select(name) {
        console.log("SELECTED:", name);
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
            anchors.fill: parent
            color: "#cc000000"
            focus: true
            Keys.onEscapePressed: Qt.quit()
            Keys.onLeftPressed: win.currentIndex = Math.max(0, win.currentIndex - 1)
            Keys.onRightPressed: win.currentIndex = Math.min(Rigs.list.length - 1, win.currentIndex + 1)
            Keys.onReturnPressed: if (Rigs.list.length) root.select(Rigs.list[win.currentIndex].name)

            Row {
                anchors.centerIn: parent
                spacing: 24

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
        }
    }
}
