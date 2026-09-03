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
    // Спокойная calm-анимация "дрейфа" (запасной стиль сборки рига) —
    // медленнее двух остальных почерков нарочно, это самый тихий из трёх.
    readonly property int durDrift: 640
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
