import QtQuick

// Карточка рига в пикере: превью обоев, имя, маркер активного,
// бейдж «релогин» для кросс-движковых целей.
Rectangle {
    id: card
    required property var rig
    property bool current: false   // подсвечена навигацией
    signal hovered()
    signal activated()

    width: 220
    height: 160
    radius: 12
    color: "#1a1a1a"
    border.width: current ? 3 : 1
    border.color: current ? "#8ab4f8" : "#3a3a3a"
    scale: current ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    clip: true

    Image {
        anchors.fill: parent
        anchors.margins: 1
        source: card.rig.wallpaper
        fillMode: Image.PreserveAspectCrop
        visible: card.rig.wallpaper !== ""
        asynchronous: true
        sourceSize.width: 440
    }

    // заглушка, если превью нет
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        visible: card.rig.wallpaper === ""
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2d2d44" }
            GradientStop { position: 1.0; color: "#1a1a2e" }
        }
        Text {
            anchors.centerIn: parent
            text: card.rig.name.charAt(0).toUpperCase()
            color: "#666"
            font.pixelSize: 64
            font.bold: true
        }
    }

    // имя рига на затемнённой полосе снизу
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.margins: 1
        height: 36
        color: "#c0101010"

        Text {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: card.rig.name
            color: "#eeeeee"
            font.pixelSize: 16
            font.bold: card.rig.active
        }

        // маркер активного рига
        Rectangle {
            visible: card.rig.active
            width: 8; height: 8; radius: 4
            color: "#7fd962"
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        }
    }

    // бейдж «релогин» — выбор уведёт в SDDM
    Rectangle {
        visible: card.rig.relogin
        anchors { top: parent.top; right: parent.right; margins: 8 }
        radius: 6
        width: reloginText.width + 12
        height: reloginText.height + 6
        color: "#d0402020"
        Text {
            id: reloginText
            anchors.centerIn: parent
            text: "relogin"
            color: "#f0b0a0"
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: card.hovered()
        onClicked: card.activated()
    }
}
