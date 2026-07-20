# Единый кросс-риг контракт биндов — 3 варианта (полная карта)

Дата: 2026-07-18
Статус: черновик на выбор варианта (брейншторм)

Цель: одинаковые фичи открываются одной клавишей во всех ригах (rigdo роутит в
аналог рига), SUPER+ALT убран (неудобно). Ниже: (1) маршрутизация фич по ригам,
(2) общий WM-слой без ALT, (3) три варианта панельного слоя ЦЕЛИКОМ.

Легенда routing: команда, которую вешает `rigdo <action>` в каждом риге.
`—` = у рига нет аналога (тихо/hint). ilyamiro-новьё (session/overview/osk/
sidebar/emoji) помечено `TBD` — ты глянешь позже, пока hint.

---

## 1. Маршрутизация фич (rigdo action → риг)

| rigdo action | ilyamiro | end4 (quickshell:) | caelestia |
| :--- | :--- | :--- | :--- |
| `launcher` | qsm applauncher | searchToggleRelease | `shell drawers toggle launcher` |
| `dashboard` (правый: нотифи/квик-туглы/**настройки**) | qsm settings | sidebarRightToggle | `shell drawers toggle dashboard` |
| `sidebar` (левый/вторичный) | TBD (hint) | sidebarLeftToggle | `shell drawers toggle sidebar` |
| `session` (лог-аут/питание) | TBD (hint) | sessionToggle | `shell drawers toggle session` |
| `wallpaper` | qsm wallpaper | wallpaperSelectorToggle | `caelestia wallpaper` |
| `clipboard` | qsm clipboard | overviewClipboardToggle | `caelestia clipboard` |
| `emoji` | TBD (hint) | overviewEmojiToggle | `caelestia emoji` |
| `media` (плеер/музыка) | qsm music | mediaControlsToggle | `shell mpris` / dashboard |
| `calendar` | qsm calendar | sidebarRightToggle | dashboard |
| `network` | qsm network | sidebarRightToggle | dashboard |
| `battery` | qsm battery | sidebarRightToggle | dashboard |
| `guide` (cheatsheet) | qsm guide | cheatsheetToggle | hint |
| `overview` (воркспейсы) | TBD (hint) | overviewWorkspacesToggle | hint (нет дравера) |
| `osk` (экранная клава) | TBD (hint) | oskToggle | hint |
| `screenshot` | screenshot.sh | regionScreenshot | `caelestia screenshot` |
| `lock` | lock.sh | loginctl lock-session | `shell lock lock` |
| `record` | hint | regionRecord | `caelestia record` |
| `translate` | hint | screenTranslate | hint |
| `ocr` | hint | regionOcr | hint |

Zoom экрана и split-ratio — нативный Hyprland, работают во всех ригах без rigdo.

---

## 2. Общий WM-слой (одинаков во всех вариантах, БЕЗ ALT)

Прямой `hyprctl dispatch`, риг-независим. Тут SUPER+ALT убран.

### Окна
| Комба | Действие |
| :--- | :--- |
| `SUPER+Q` | Закрыть |
| `SUPER+F` | Фуллскрин |
| `SUPER+SHIFT+F` | Maximized (фуллскрин с рамкой) |
| `SUPER+Space` | Toggle floating |
| `SUPER+P` | Pin |
| `SUPER+I/J/K/L` | Фокус ↑/←/↓/→ |
| `SUPER+SHIFT+I/J/K/L` | Двигать окно ↑/←/↓/→ |
| `SUPER+R` → submap `resize` | Ресайз-режим: далее `I/J/K/L` ресайзят, `Esc`/любая другая выход. (убирает SUPER+ALT+IJKL) |
| `ALT+Q` | Собрать в группу/стек |
| `ALT+TAB` | Цикл вкладок группы |
| `SUPER+SHIFT+Q` | Force-zap (`hyprctl kill` зависшего) |

> `SUPER+R` раньше = редактор (codium). Редактор переезжает (см. Приложения).

### Воркспейсы
| Комба | Действие |
| :--- | :--- |
| `SUPER+A` / `SUPER+D` | Воркспейс −1 / +1 |
| `SUPER+scroll` | Воркспейс −1 / +1 |
| `SUPER+1..0` | На воркспейс N |
| `SUPER+SHIFT+1..0` | Перенести окно на N |
| `SUPER+S` | Спец-воркспейс (scratchpad) |
| `SUPER+Z/X/C/V` | Спец-апп: музыка/общение/todo/мессенджер |
| `SUPER+SHIFT+X` | Вытащить из спеца на текущий |
| `SUPER+grave` / `SUPER+SHIFT+grave` | Цикл спец-воркспейсов next/prev (было CTRL+J/L — конфликтовал бы с фокусом; grave свободнее) |

### Приложения
| Комба | Приложение |
| :--- | :--- |
| `SUPER+Return` | Терминал (foot) |
| `SUPER+W` | Браузер (zen) |
| `SUPER+E` | Файлы (thunar) |
| `SUPER+T` | Раскладка (hyprkcs) |
| `SUPER+Backslash` | Редактор (codium) — переехал с `SUPER+R` |

> `SUPER+TAB` освобождается от терминала (терминал → `SUPER+Return`), чтобы
> отдать `SUPER+TAB` под Overview (см. варианты). Или оставить терминал на TAB —
> помечено в вариантах.

---

## 3. Панельный слой — ТРИ ВАРИАНТА

Различаются ТОЛЬКО раскладкой шелл-панелей/фич. WM-слой (п.2) общий.

### ВАРИАНТ A — «SHIFT = панели» (рекомендую)

Правило: WM на `SUPER+буква`, ВСЕ шелл-панели на `SUPER+SHIFT+буква` (мнемо).
Предсказуемо: SHIFT → «открыть панель». Частое (лаунчер/буфер/обои) — исключения
на голом SUPER для скорости.

| Комба | rigdo action | Мнемо |
| :--- | :--- | :--- |
| `SHIFT+TAB` | launcher | лаунчер (как сейчас) |
| `SUPER+grave` | clipboard | буфер (как сейчас) |
| `SUPER+Y` | wallpaper | обои (как сейчас) |
| `SUPER+SHIFT+D` | dashboard | **D**ashboard (нотифи/туглы/настройки) |
| `SUPER+SHIFT+A` | sidebar | левый s**A**idebar |
| `SUPER+SHIFT+E` | session | s**E**ssion (лог-аут/питание) |
| `SUPER+SHIFT+M` | media | **M**edia |
| `SUPER+SHIFT+C` | calendar | **C**alendar |
| `SUPER+SHIFT+N` | network | **N**etwork |
| `SUPER+SHIFT+B` | battery | **B**attery |
| `SUPER+SHIFT+G` | guide | **G**uide/cheatsheet |
| `SUPER+SHIFT+O` | overview | **O**verview воркспейсов |
| `SUPER+SHIFT+K` | osk | **K**eyboard экранная |
| `SUPER+SHIFT+J` | emoji | эмод**J**и (свободная) |
| `SUPER+SHIFT+S` | screenshot | **S**creenshot |
| `SUPER+SHIFT+R` | record | **R**ecord |
| `SUPER+F1` | lock | локскрин |
| `SUPER+SHIFT+T` | translate | **T**ranslate |
| `SUPER+SHIFT+U` | ocr | ocr (U рядом) |
| `SUPER+Equal`/`SUPER+Minus` | zoom ± | зум экрана |
| `SUPER+Semicolon`/`SUPER+Apostrophe` | split-ratio ∓ | сплит |
| `SUPER+SHIFT+D`(switcher был тут!) | — | **КОНФЛИКТ**: свитчер ригов сейчас `SUPER+SHIFT+D`. В A свитчер → `SUPER+SHIFT+Backslash` или `SUPER+SHIFT+Escape`. |

Плюсы: одно правило (SHIFT=панель), масштабируется, ALT нет.
Минусы: `SUPER+SHIFT+D` занят свитчером — надо переселить свитчер; SHIFT+буква
многовато для редких фич.

### ВАРИАНТ B — «Leader-клавиша»

Правило: одна leader-комба открывает which-key-меню, дальше буква. Панели НЕ
занимают отдельные комбы.

| Комба | Действие |
| :--- | :--- |
| `SUPER+Space` (leader) | Открыть панель-меню; далее: `l`auncher `d`ashboard `s`ession `w`allpaper `c`lipboard `m`edia `o`verview `k`osk `e`moji `g`uide … |
| `SHIFT+TAB` | launcher (быстрый дубль вне меню) |
| `SUPER+grave` | clipboard (быстрый дубль) |
| WM-слой | как п.2, но `SUPER+Space` уходит под leader → floating переезжает на `SUPER+SHIFT+Space` |

Плюсы: одна комба, самодокументируемо (меню показывает подсказки).
Минусы: **шеллы не имеют нативного which-key** — надо строить меню (fuzzel-dmenu
или отдельный quickshell-виджет), два нажатия, медленнее для частого. Самый
дорогой в реализации.

### ВАРИАНТ C — «Минимальный ремап»

Правило: оставить весь текущий контракт КАК ЕСТЬ, тронуть только ALT-бинды +
добавить новьё на первые свободные комбы. Меньше всего ломает muscle memory.

Остаётся как сейчас (не меняется):
`SHIFT+TAB` launcher, `SUPER+Y` wallpaper, `SUPER+SHIFT+O` settings→dashboard,
`SUPER+M` shell-restart, `SUPER+F1` lock, `SUPER+SHIFT+S` screenshot,
`SUPER+grave` clipboard, `SUPER+B` battery, `SUPER+N` network, `SUPER+H` guide.

Меняется (ALT убран):
| Было (ALT) | Стало |
| :--- | :--- |
| `SUPER+ALT+M` музыка | `SUPER+SHIFT+M` media |
| `SUPER+ALT+S` календарь | `SUPER+SHIFT+C` calendar |
| `SUPER+ALT+P` кино/movies | `SUPER+SHIFT+P` movies |
| `SUPER+ALT+F` maximized | `SUPER+SHIFT+F` maximized |
| `SUPER+ALT+Space` float | `SUPER+Space` float |
| `SUPER+ALT+IJKL` resize | `SUPER+R` resize-submap |

Добавляется новьё (первые свободные):
| Комба | action |
| :--- | :--- |
| `SUPER+SHIFT+A` | dashboard (правый) |
| `SUPER+SHIFT+E` | session |
| `SUPER+SHIFT+G` | sidebar (левый) |
| `SUPER+Space`? занят float → overview на `SUPER+TAB` (терминал→`SUPER+Return`) | overview |
| `SUPER+SHIFT+K` | osk |
| `SUPER+SHIFT+J` | emoji |
| `SUPER+Equal/Minus` | zoom |
| `SUPER+SHIFT+Q` | force-zap |

Плюсы: минимум переучивания, быстрый переход.
Минусы: менее «стройно» — панели раскиданы (часть на SUPER+буква, часть на
SUPER+SHIFT), нет единого правила.

---

## 4. Сравнение

| | A (SHIFT=панели) | B (leader) | C (мин. ремап) |
| :--- | :--- | :--- | :--- |
| Единое правило | ✅ SHIFT=панель | ✅ leader | ❌ раскидано |
| Скорость частого | ✅ (1 комба) | ⚠ (2 нажатия) | ✅ |
| Переучивание | среднее | большое | малое |
| Реализация | простая | дорогая (which-key нет) | простая |
| Масштаб на новьё | ✅ | ✅ | ⚠ |
| ALT убран | ✅ | ✅ | ✅ |

Рекомендация: **A**. B дорогой (нет which-key в шеллах). C быстрее внедрить, но
не решает «стройность», к которой ты стремишься.

## 5. Открытое (до финала)
- Свитчер ригов `SUPER+SHIFT+D` — куда переселить в A (конфликт с dashboard).
- ilyamiro session/overview/osk/sidebar/emoji — ты глянешь, пока hint.
- caelestia overview/osk/guide — нет дравера → hint (или найти аналог).
- `SUPER+TAB` терминал vs overview — определить.
