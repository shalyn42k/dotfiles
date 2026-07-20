# Rigswitch caelestia-restyle — design

**Дата:** 2026-07-20
**Статус:** дизайн утверждён, ждёт спек-ревью → план
**Основа:** v1 rigswitch-overlay реализован (ветка `rig-switcher-overlay`). Это
полиш-проход «в стиле caelestia» поверх него — хотелка пользователя.

## Цель

Перерисовать overlay-пикер `qs -c rigswitch` под визуальную грамматику
caelestia: material-палитра, M3-моушен (spring), morph пикер→сплэш. Функционал
свитча (`dotprofile switch`, hot/relogin-режимы, guard-поллинг) НЕ меняется —
только представление.

## Ограничения контекста

- rigswitch крутится на **системном** `qs` (`/usr/bin/qs`), у которого НЕТ
  плагина `Caelestia.Config`/`Caelestia.Services`/`Colours`/`Tokens` (он
  вкомпилен в build самого caelestia). Значит все токены — **числовые
  константы в QML rigswitch**, не импорты.
- Модель ригов (`Rigs.qml`, `scan-rigs.sh`) уже даёт `{name, engine, active,
  relogin, wallpaper}` — не трогаем.
- `bin/dotprofile` (`cmd_switch`, `cmd_menu`, toggle-гард) — не трогаем.

## Токены (источник caelestia, вшиваем числами)

Из `~/caelestia/plugin/src/Caelestia/Config/tokens.hpp` и `scheme.json`:

**Motion** (`easing.type: Easing.BezierSpline; easing.bezierCurve: [...]`):
- spatial spring — `[0.38, 1.21, 0.22, 1, 1, 1]`, 500ms (`expressiveDefaultSpatial`)
- effects — `[0.34, 0.8, 0.34, 1, 1, 1]`, 200ms (`expressiveDefaultEffects`)
- вход строк — emphasized-decel `[0.05, 0.7, 0.1, 1, 1, 1]`, 400ms

**Rounding:** medium 12, large 16, extraLarge 28.

**Цвета:** рантайм-чтение `~/.local/state/caelestia/scheme.json` (`colours.*`),
fallback — вшитые дефолты:
| роль | ключ scheme.json | fallback |
|---|---|---|
| surface | `surface` | `#0a0f0f` |
| surfaceContainer | `surfaceContainer` | `#131b1a` |
| surfaceContainerLow | `surfaceContainerLow` | `#0e1514` |
| onSurface | `onSurface` | `#dce8e6` |
| onSurfaceVariant | `onSurfaceVariant` | `#a2adac` |
| primary | `primary` | `#9bd0cc` |
| secondaryContainer | `secondaryContainer` | `#27403e` |
| onSecondaryContainer | `onSecondaryContainer` | `#a9c5c2` |
| outline | `outline` | `#6d7876` |
| outlineVariant | `outlineVariant` | `#3f4a49` |
| errorContainer | `errorContainer` | `#871f21` |
| onErrorContainer | `onErrorContainer` | `#ff9993` |

rigswitch ВСЕГДА caelestia-палитра (chrome свитчера, не тема активного рига).
Если scheme.json нет/битый — fallback-дефолты.

## Компонент 1 — `Tokens.qml` (новый синглтон)

`pragma Singleton`. Один источник токенов для панели/строк/сплэша:
- `Process` читает scheme.json → `property var c` (map ролей → hex), с
  fallback-дефолтами при пустом/битом JSON.
- readonly-константы кривых: `property var springCurve: [0.38,1.21,0.22,1,1,1]`
  и т.д., длительности, радиусы.
- Автозарегается по директории (как `Rigs.qml`), `qmldir` не нужен.

## Компонент 2 — `RigCard.qml` (переписать: card → list-row)

Из горизонтальной карточки 220×160 в строку списка:
- Layout: `Row` — thumb (обои, 48×36, radius 9) + колонка [имя (600 14px) +
  сабтайтл (`engine · hot-switch`/`engine · relogin`, onSurfaceVariant 10px)] +
  правый край (active-dot / бейдж `relogin`).
- Ширина ~300, padding 11×13.
- **State-морф** (signature caelestia): фон `surfaceContainer`→
  `secondaryContainer` когда `current`, border `outlineVariant`→`primary`,
  radius large(16)→extraLarge(22), `Behavior` на цвете (effects 200ms) и на
  radius (spring). Имя → `onSecondaryContainer` при current.
- Active-dot: `primary` с glow, виден при `rig.active`.
- Бейдж `relogin` (English): `errorContainer`/`onErrorContainer`, при
  `rig.relogin`.
- Сигналы `hovered()`/`activated()` + `MouseArea hoverEnabled` — как сейчас.

## Компонент 3 — `shell.qml` (переписать представление, логику оставить)

**Панель-пикер (framed panel):**
- Контейнер по центру: фон `surfaceContainerLow` @ ~0.85 alpha, border
  `1.5px outline`, radius 28, тень. Хедер «switch rig» (uppercase, letter-spacing,
  `primary`, 11px) сверху.
- `Column` строк (`RigCard` из `Repeater{model: Rigs.list}`).
- **Вход:** строки stagger-fade-in снизу — `opacity 0→1` + `y +12→0`,
  emphasized-decel, задержка `index * 40ms` (через `PropertyAnimation` с
  `Component.onCompleted`-стартом или `SequentialAnimation`+`PauseAnimation`).
- Nav: Up/Down (было Left/Right — под вертикальный список), hover, Enter выбор,
  Esc закрыть. `currentIndex` + стартовая подсветка на активном (как сейчас).

**Transition (crossfade + rise):**
- При `select()` (логика та же: execDetached `dotprofile switch`, hot→holdTimer,
  relogin→safetyQuit): панель `opacity 1→0` (effects 200ms).
- Сплэш по центру: icon-tile (74×74, radius 28, primary-градиент, glow) + имя
  рига (700 34px, onSurface). `opacity 0→1` (effects) + `scale 0.9→1` (spring
  500ms).
- Relogin: под именем подпись «logging out to SDDM…» (onSurfaceVariant).
- Guard-поллинг нового шелла + кап 2.5с + `fadeOutAndQuit` (300ms) — БЕЗ
  изменений.

## Компонент 4 — backdrop blur (hyprland layer_rule)

Оба lua-рига используют `hl.layer_rule({ match = { namespace = ... }, ... })`.
Добавить в `profiles/caelestia/hypr/hyprland/rules.lua` и
`profiles/end4/hypr/hyprland/rules.lua`:
```lua
hl.layer_rule({ match = { namespace = "rigswitch" }, blur = true })
hl.layer_rule({ match = { namespace = "rigswitch" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "rigswitch" }, animation = "fade" })
```
Панель полупрозрачна → блюр стола просвечивает. `ignore_alpha` — чтобы блюрился
только фон под панелью, не насквозь. ilyamiro (hyprlang) не задет: до него
только релогин, там overlay уже не показывается.

## Тестирование

- Headless smoke: `timeout 4 /usr/bin/qs -c rigswitch >log 2>&1` + grep лога на
  `QML .*(error|Error|warning)` — как в v1-плане. Прогон после каждого
  компонента.
- Скан scheme.json-парсинга: подсунуть битый JSON → проверить fallback (не
  краш).
- Финальный E2E глазами (SUPER+SHIFT+D → выбор → morph; relogin →ilyamiro) — на
  пользователе, вне плана.

## Вне области (YAGNI)

- Морф «shared-element grow» (отклонён в пользу crossfade+rise).
- Hero-carousel / row-layout (отклонены в пользу vertical list).
- Пер-риговая тема пикера (rigswitch всегда caelestia-chrome).
- Изменения `dotprofile`, `Rigs.qml`, `scan-rigs.sh`, `session.sh`.
