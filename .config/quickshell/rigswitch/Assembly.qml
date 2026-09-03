import QtQuick

// Визуальная "сборка" рига по стадиям свитча. Один кусочек = одна стадия
// dotprofile (stage <имя> ok|fail в stdout, см. bin/dotprofile cmd_switch).
// Кусочек оживает ТОЛЬКО когда shell.qml реально получил его строку —
// никаких таймеров вслепую тут нет, вся анимация управляется stageState.
//
// Раскладка и направление входа зависят от пары (откуда, куда):
//   style     — почерк ЦЕЛЕВОГО рига (RigIdentity.identityFor), решает форму
//               раскладки (grid/serpentine/drift) и кривую/длительность входа
//   direction — знак разницы позиций source/target в Rigs.list: кусочки
//               всегда "прилетают" с одной стороны при switch A→B и с
//               противоположной при B→A, это и есть отличие по паре
Item {
    id: root
    property var stageState: ({})   // { links: "pending"|"ok"|"fail", ... }
    property var stageOrder: []
    property var stageLabels: ({})
    property string style: "drift"
    property color accent: Tokens.c.primary
    property int direction: 1
    // relogin: реальных стадий почти не будет (кросс-движковый переход рвётся
    // на первой же ссылке) — кусочки-заглушки гасим, чтобы не врать "почти готово"
    property bool relogin: false

    readonly property int landedCount: root.stageOrder.filter(k => root.stageState[k] !== "pending").length

    implicitWidth: cluster.width
    implicitHeight: cluster.height

    function layout() {
        const n = root.stageOrder.length || 1;
        const slots = [];
        for (let i = 0; i < n; i++) {
            if (root.style === "grid") {
                const col = i % 3, row = Math.floor(i / 3);
                slots.push({ x: (col - 1) * 116, y: (row - 0.5) * 44, rot: 0 });
            } else if (root.style === "serpentine") {
                const t = i - (n - 1) / 2;
                slots.push({ x: t * 56, y: Math.sin(i * 1.15) * 26, rot: Math.sin(i * 1.15) * 9 });
            } else {
                slots.push({ x: 0, y: (i - (n - 1) / 2) * 38, rot: 0 });
            }
        }
        return slots;
    }
    readonly property var slots: root.layout()

    readonly property var styleMotion: root.style === "grid"
        ? ({ dur: Tokens.durDecel, curve: Tokens.decelCurve, travel: 76 })
        : root.style === "serpentine"
            ? ({ dur: Tokens.durSpring, curve: Tokens.springCurve, travel: 132 })
            : ({ dur: Tokens.durDrift, curve: Tokens.effectsCurve, travel: 46 })

    Item {
        id: cluster
        anchors.centerIn: parent
        width: 372
        height: 148

        // ── Каркас ───────────────────────────────────────────────────────
        // Связь между соседними кусочками: прорастает, когда приехал ВТОРОЙ из
        // пары. Без неё стадии просто появляются по одной и читаются как
        // список; со связью видно, что риг именно собирается — детали
        // скручиваются друг с другом в том порядке, в каком их применяет
        // dotprofile.
        //
        // Рисуется ПОД кусочками (объявлено раньше), поэтому линия уходит им
        // под низ, а не перечёркивает подписи.
        Repeater {
            model: Math.max(0, root.stageOrder.length - 1)
            delegate: Rectangle {
                id: link
                required property int index

                readonly property var a: root.slots[index] || ({ x: 0, y: 0 })
                readonly property var b: root.slots[index + 1] || ({ x: 0, y: 0 })
                readonly property real dx: b.x - a.x
                readonly property real dy: b.y - a.y
                readonly property real len: Math.sqrt(dx * dx + dy * dy)

                // Связь считается сделанной, только когда ОБА её конца на месте.
                readonly property bool joined:
                    root.stageState[root.stageOrder[index]] !== undefined &&
                    root.stageState[root.stageOrder[index]] !== "pending" &&
                    root.stageState[root.stageOrder[index + 1]] !== undefined &&
                    root.stageState[root.stageOrder[index + 1]] !== "pending"

                property real grown: joined ? 1 : 0
                Behavior on grown {
                    NumberAnimation {
                        duration: root.styleMotion.dur
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.styleMotion.curve
                    }
                }

                width: link.len * link.grown
                height: 2
                radius: 1
                antialiasing: true
                // Точка роста — конец уже стоящего кусочка, поэтому линия
                // тянется ОТ него к следующему, а не появляется серединой.
                x: cluster.width / 2 + link.a.x
                y: cluster.height / 2 + link.a.y - height / 2
                transformOrigin: Item.Left
                rotation: Math.atan2(link.dy, link.dx) * 180 / Math.PI

                color: root.accent
                opacity: root.relogin ? 0.10 : 0.30 * link.grown
            }
        }

        Repeater {
            model: root.stageOrder
            delegate: Item {
                id: chip
                required property int index
                required property string modelData
                readonly property string key: modelData
                readonly property string status: root.stageState[key] || "pending"
                readonly property var slot: root.slots[index] || ({ x: 0, y: 0, rot: 0 })
                property real shakeOffset: 0

                width: 112
                height: 30
                x: cluster.width / 2 + slot.x - width / 2 + shakeOffset
                y: cluster.height / 2 + slot.y - height / 2

                property real landed: status !== "pending" ? 1 : 0
                Behavior on landed {
                    NumberAnimation { duration: root.styleMotion.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: root.styleMotion.curve }
                }

                opacity: root.relogin ? (chip.status !== "pending" ? 1 : 0.22)
                                       : (0.2 + 0.8 * chip.landed)
                scale: 0.86 + 0.14 * chip.landed
                rotation: chip.slot.rot + (1 - chip.landed) * root.direction * (root.style === "serpentine" ? 24 : 9)
                transform: Translate { x: (1 - chip.landed) * root.direction * root.styleMotion.travel }

                // Тряска — по факту смены статуса (once), не через binding на
                // running: тот же биндинг после того как анимация сама себя
                // остановит может повести себя непредсказуемо (движок пишет
                // running=false, а с активным binding — неочевидно, чем это
                // кончится). onStatusChanged — однозначный триггер один раз.
                onStatusChanged: if (status === "fail") shakeAnim.start();
                SequentialAnimation {
                    id: shakeAnim
                    running: false
                    NumberAnimation { target: chip; property: "shakeOffset"; from: 0; to: -5; duration: 55 }
                    NumberAnimation { target: chip; property: "shakeOffset"; from: -5; to: 5; duration: 90 }
                    NumberAnimation { target: chip; property: "shakeOffset"; from: 5; to: 0; duration: 55 }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.radMedium
                    color: chip.status === "fail" ? Tokens.c.errorContainer
                         : chip.status === "ok"   ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                                                   : "transparent"
                    border.width: chip.status === "pending" ? 1 : 1.5
                    border.color: chip.status === "fail" ? Tokens.c.errorContainer
                                : chip.status === "ok"   ? root.accent
                                                          : Tokens.c.outlineVariant
                    Behavior on color { ColorAnimation { duration: Tokens.durEffects } }
                    Behavior on border.color { ColorAnimation { duration: Tokens.durEffects } }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.stageLabels[chip.key] || chip.key
                        color: chip.status === "fail" ? Tokens.c.onErrorContainer
                             : chip.status === "ok"   ? Tokens.c.onSurface
                                                       : Tokens.c.onSurfaceVariant
                        font.pixelSize: 10
                        font.weight: chip.status === "pending" ? Font.Normal : Font.DemiBold
                    }
                }
            }
        }
    }
}
