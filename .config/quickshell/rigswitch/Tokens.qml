pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Оверлей красится палитрой АКТИВНОГО рига, а не одного захардкоженного.
    // Палитры всех ригов читает Palettes (у каждого свой формат файла), здесь
    // только выбор нужной по симлинку profiles/active.
    //
    // Раньше тут был жёстко caelestia scheme.json — из-за этого свитчер
    // выглядел одинаково в любом риге, хотя сами риги давно разные.
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

    property string activeRig: ""
    property var c: activeRig ? Palettes.paletteFor(activeRig) : fallback

    readonly property var springCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var effectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var decelCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int durSpring: 500
    readonly property int durEffects: 200
    readonly property int durDecel: 400
    // Спокойная calm-анимация "дрейфа" (запасной стиль сборки рига) —
    // медленнее двух остальных почерков нарочно, это самый тихий из трёх.
    readonly property int durDrift: 640
    readonly property int radMedium: 12
    readonly property int radLarge: 16
    readonly property int radRow: 22
    readonly property int radPanel: 28

    // Активный риг — цель симлинка profiles/active. basename, потому что
    // readlink отдаёт относительное имя, а readlink -f — полный путь.
    Process {
        command: ["sh", "-c", "basename \"$(readlink -f \"$HOME/dotfiles/profiles/active\")\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.activeRig = this.text.trim()
        }
    }
}
