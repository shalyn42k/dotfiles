pragma Singleton
import Quickshell
import QtQuick

// Идентичность рига для transition-анимации в shell.qml: акцент (цвет
// "пришивается" собранным кусочкам) и почерк сборки (раскладка кусочков).
//
// Акцент НЕ задан константой: он читается из ЖИВОЙ палитры рига (Palettes),
// то есть меняется вместе с обоями. Раньше здесь лежали два зашитых хекса, и
// после смены схемы риг в свитчере оставался прежнего цвета — свитчер врал о
// том, как риг сейчас выглядит.
// Раскладки задают исходный "почерк":
//   grid       — ровная сетка 3x2, детерминированное оседание (caelestia = work)
//   serpentine — плашки вдоль синусоиды, пружинный вход (serpantinum = змея)
//   drift      — спокойный вертикальный столбик (запасной стиль: риг без
//                почти всегда даёт relogin, так что этот почерк реже всего виден живьём)
//
// Дроп-ин риг без записи в known не ломается: акцент получает через
// hue-rotate текущего Tokens.primary, раскладку — по хэшу role/имени. Это
// специально не копирует ни одного из трёх стилей "случайно" совпадением —
// стабильно для одного имени, но не спутать с реальными акцентами известных ригов.
Singleton {
    id: root

    // Только почерк сборки. Цвет приходит из палитры рига.
    readonly property var knownStyle: ({
        caelestia:   "grid",
        serpantinum: "serpentine"
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

        const style = root.knownStyle[name];
        if (style)
            return { accent: Palettes.accentFor(name), style: style };

        // Дроп-ин риг: палитры мы не знаем, поэтому акцент выводим из текущей
        // сдвигом тона — стабильно для одного имени и заведомо не совпадёт с
        // реальным акцентом известного рига.
        const seed = root.hashOf(role || name);
        return {
            accent: root.hueRotate(Tokens.c.primary, seed % 360),
            style: root.styles[seed % root.styles.length]
        };
    }
}
