pragma Singleton
import Quickshell
import QtQml
import Quickshell.Io
import QtQuick

// Палитры ВСЕХ ригов, а не только активного.
//
// Зачем все сразу. Оверлей рисует себя палитрой активного рига, но карточка и
// анимация сборки целевого рига должны быть в ЕГО цветах — иначе переход
// выглядит одинаково, куда бы ты ни шёл, и «свитчер берёт тему от рига»
// выполняется наполовину. Ригов два, файлы крошечные, читаем оба на старте.
//
// Формат у ригов разный, потому что палитру пишет их собственный конвейер:
//   caelestia   — ~/.local/state/caelestia/scheme.json, ключи material-you
//                 ({"colours":{"primary":"9bd0cc",...}}, БЕЗ решётки)
//   serpantinum — ~/.local/state/serpantinum/qs_colors.json, ключи
//                 catppuccin-образные ({"base":"#0c0e13","blue":"#b9c3ff",...},
//                 С решёткой), их пишет matugen самого шелла
//
// Поэтому у каждого рига свой адаптер: где файл и как назвать его ключи в
// наших терминах. Новый риг — одна запись здесь, ничего больше.
Singleton {
    id: root

    readonly property var tokenKeys: [
        "surface", "surfaceContainer", "surfaceContainerLow",
        "onSurface", "onSurfaceVariant", "primary",
        "secondaryContainer", "onSecondaryContainer",
        "outline", "outlineVariant", "errorContainer", "onErrorContainer"
    ]

    // Палитра, которой рисуется сам оверлей, если про риг ничего не известно.
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

    readonly property string home: Quickshell.env("HOME")

    readonly property var adapters: ({
        caelestia: {
            path: root.home + "/.local/state/caelestia/scheme.json",
            // ключи лежат под "colours" и без ведущей решётки
            root: "colours",
            hashPrefix: true,
            map: {
                surface: "surface", surfaceContainer: "surfaceContainer",
                surfaceContainerLow: "surfaceContainerLow",
                onSurface: "onSurface", onSurfaceVariant: "onSurfaceVariant",
                primary: "primary",
                secondaryContainer: "secondaryContainer",
                onSecondaryContainer: "onSecondaryContainer",
                outline: "outline", outlineVariant: "outlineVariant",
                errorContainer: "errorContainer", onErrorContainer: "onErrorContainer"
            }
        },
        serpantinum: {
            path: root.home + "/.local/state/serpantinum/qs_colors.json",
            root: "",
            hashPrefix: false,
            // "blue" — тот же ключ, который берёт bin/kbd-theme-sync как акцент
            // рига; остальное разложено по смыслу: base темнее mantle темнее
            // surface0, text/subtext0 — основной и приглушённый текст.
            map: {
                surface: "base", surfaceContainer: "surface0",
                surfaceContainerLow: "mantle",
                onSurface: "text", onSurfaceVariant: "subtext0",
                primary: "blue",
                secondaryContainer: "surface1",
                onSecondaryContainer: "subtext1",
                outline: "overlay0", outlineVariant: "surface2",
                errorContainer: "red", onErrorContainer: "maroon"
            }
        }
    })

    // name -> палитра в наших токенах
    property var byRig: ({})

    function paletteFor(name) {
        const p = root.byRig[name];
        return p ? p : root.fallback;
    }

    function accentFor(name) {
        return root.paletteFor(name).primary;
    }

    function parseInto(name, txt) {
        const a = root.adapters[name];
        if (!a)
            return;
        let src;
        try {
            const j = JSON.parse(txt);
            src = a.root ? (j[a.root] || {}) : j;
        } catch (e) {
            return;   // битый/пустой файл — риг просто останется на fallback
        }
        const out = {};
        for (const t of root.tokenKeys) {
            const v = src[a.map[t]];
            out[t] = (typeof v === "string" && v.length >= 6)
                ? (a.hashPrefix ? "#" + v : v)
                : root.fallback[t];
        }
        const next = Object.assign({}, root.byRig);
        next[name] = out;
        root.byRig = next;
    }

    // Читатели: по одному на риг, из списка адаптеров — добавление рига не
    // требует правок здесь. Instantiator, а не Repeater: синглтон невизуальный,
    // а Repeater хочет Item-родителя.
    Instantiator {
        model: Object.keys(root.adapters)
        delegate: QtObject {
            required property string modelData
            readonly property Process reader: Process {
                command: ["cat", root.adapters[modelData].path]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: root.parseInto(modelData, this.text)
                }
            }
        }
    }
}
