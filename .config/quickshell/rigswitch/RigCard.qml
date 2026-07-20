import QtQuick
import Quickshell

// Строка рига в списке-пикере: лого рига + имя + сабтайтл (движок·режим),
// active-dot / бейдж relogin справа. State-морф по current (signature caelestia):
// фон surfaceContainer→secondaryContainer, border outlineVariant→primary,
// radius large→row, всё через Behavior.
Rectangle {
    id: row
    required property var rig
    property bool current: false
    signal hovered()
    signal activated()

    // Лого рига (vendored) по имени: logos/<name>.svg. Drop-in: положил
    // logos/<newrig>.svg — появится. Нет файла → fallback первая буква.
    readonly property string logoPath:
        Quickshell.env("HOME") + "/.config/quickshell/rigswitch/logos/" + rig.name + ".svg"

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

        // лого рига (или буква-заглушка, если файла нет)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 48; height: 36; radius: 9; clip: true
            color: Tokens.c.surfaceContainerLow

            Image {
                id: logo
                anchors.fill: parent
                anchors.margins: 6
                source: row.logoPath
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.height: 64
            }
            Text {
                anchors.centerIn: parent
                visible: logo.status !== Image.Ready
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
