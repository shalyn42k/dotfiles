pragma Singleton
import Quickshell
import QtQuick

// Идентичность рига для transition-анимации в shell.qml: акцент (цвет
// "пришивается" собранным кусочкам) и почерк сборки (раскладка кусочков).
//
// Три известных рига — акцент НЕ выдуман, это их собственный реальный цвет:
//   caelestia   — primary из scheme/current.lua (та же плашка, что красит рамки окон)
//   ilyamiro    — active_border из hypr/colors.conf (matugen поверх текущих обоев)
//   serpantinum — у рига пока нет отрендеренного matugen-вывода (свежий риг,
//                 см. 2026-09-02-serpantinum-rig-design.md), поэтому взят
//                 змеино-чешуйчатый тон вместо несуществующего файла.
// Раскладки задают исходный "почерк":
//   grid       — ровная сетка 3x2, детерминированное оседание (caelestia = work)
//   serpentine — плашки вдоль синусоиды, пружинный вход (serpantinum = змея)
//   drift      — спокойный вертикальный столбик (ilyamiro = daily, но ilyamiro
//                почти всегда даёт relogin, так что этот почерк реже всего виден живьём)
//
// Дроп-ин риг без записи в known не ломается: акцент получает через
// hue-rotate текущего Tokens.primary, раскладку — по хэшу role/имени. Это
// специально не копирует ни одного из трёх стилей "случайно" совпадением —
// стабильно для одного имени, но не спутать с реальными акцентами известных ригов.
Singleton {
    id: root

    readonly property var known: ({
        caelestia:   { accent: "#9bd0cc", style: "grid" },
        serpantinum: { accent: "#8caa74", style: "serpentine" },
        ilyamiro:    { accent: "#e0b95f", style: "drift" }
    })
    readonly property var styles: ["grid", "serpentine", "drift"]

    function hashOf(s) {
        let h = 0;
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) >>> 0;
        return h;
    }

    function hueRotate(hex, deg) {
        const c = Qt.color(hex);
        const h = (c.hslHue + deg / 360.0 + 1) % 1;
        return Qt.hsla(h, c.hslSaturation, c.hslLightness, 1);
    }

    // { accent: color, style: "grid"|"serpentine"|"drift" }
    function identityFor(name, role) {
        if (!name)
            return { accent: Tokens.c.primary, style: "drift" };
        const k = root.known[name];
        if (k)
            return k;
        const seed = root.hashOf(role || name);
        return {
            accent: root.hueRotate(Tokens.c.primary, seed % 360),
            style: root.styles[seed % root.styles.length]
        };
    }
}
