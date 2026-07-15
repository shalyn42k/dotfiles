# Дизайн: end-4/dots-hyprland как третий риг (утверждённый)

Статус: **утверждён 2026-07-15**, готов к плану имплементации.
Уточняет и конкретизирует ранний набросок `2026-07-14-end4-rig-plan.md`
(тот остаётся как контекст; при расхождении — этот документ главнее).
Источник: https://github.com/end-4/dots-hyprland

## Контекст, проверенный по upstream (2026-07-15)

Конфиги end-4 живут в `dots/.config/hypr/`. Ключевые факты:

- **lua-провайдер**: `hyprland.lua` (есть), `hyprland.conf` отсутствует — как caelestia.
- **Официальные оверрайды**: `custom/*.lua` (`keybinds`, `rules`, `env`, `execs`,
  `general`, `variables`) подключаются ПОСЛЕ дефолтов, переживают апдейты.
  `hyprland/lib/init.lua` создаёт `custom/*.lua` заглушками если их нет
  (`create_if_not_exists`) с шапкой «will not be overwritten across updates».
- **Тот же bind-API что caelestia**: `custom/keybinds.lua` upstream'а —
  `hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd(...), {description=...})`.
  Оба lua-рига говорят на одном `hl.bind`/`hl.dsp`.
- **Shell-действия** = `hl.dsp.global("quickshell:<action>")` (GlobalShortcut),
  часть — `qs -c ii ipc call`. `$qsConfig = ii`.
- end-4 несёт нативные видео-обои (`custom/scripts/__restore_video_wallpaper.sh`) —
  на будущее, вне скоупа этой задачи.

## Решения (зафиксированы с пользователем)

1. **Бинд-набор**: end4 зеркалит **текущий** набор caelestia как есть. Отдельный
   dedupe-пасс биндов ilyamiro/caelestia — потом; end4 позже подтянем под новый.
2. **Подход к биндам — B (независимый end4-порт)**: end4 получает свой
   `custom/keybinds.lua` = порт набора + unbind дефолтов. caelestia НЕ трогаем.
   Унификация двух lua-ригов в общий модуль — отдельный tech-debt пункт потом
   (дёшево: `hl.bind` общий).
3. **Цвета — полная интеграция**: обои end4 гонят Material You в общую тему
   (рамки/группы/fastfetch/Discord/Obsidian), как caelestia/ilyamiro.
4. **Анимации** — его (lua, работают нативно). **Rules** — порт наших
   (case-by-case, наши приоритетны) + transparency-оверрайды.
5. **Общие app-конфиги** (fish/foot/fuzzel/fastfetch/thunar) — наши; installer
   end4 их не должен переписать.
6. **Хот-свитч остаётся** (архитектуру не меняем).

## 1. Каркас профиля (`profiles/end4/`)

Снапшот end4-специфики после установки на материализованных каталогах:
`hypr` (его lua-дефолты + наш `custom/`), `quickshell/ii`, его варианты
`gtk-3.0/4.0`, `qt5ct/qt6ct`, `Kvantum`, `kde-material-you-colors`, `fontconfig`.
Контестируемые каталоги (gtk/qt/kvantum) уже есть — его варианты лягут в профиль.

- `session.sh` — start/stop его шелла (`qs -c ii`); стоп шелла предыдущего рига
  в `cmd_switch`.
- `post-update.sh` — вернуть source-строки, которые затирает его installer
  (аналог ilyamiro).

## 2. Бинды (подход B)

### `profiles/end4/hypr/custom/keybinds.lua` — lua-порт нашего набора

- **unbind** конфликтных дефолтов end4: overview `SUPER+Tab`, сайдбары
  `SUPER+A/B/N/O`, буфер `SUPER+V`, эмодзи `SUPER+Period`, медиа `SUPER+M`,
  бар `SUPER+J`, cheatsheet `SUPER+Slash`, OSK `SUPER+K`, overlay `SUPER+G`,
  и прочие пересечения с нашими клавишами (полный список — при клоне, из
  `hyprland/keybinds.lua`).
- **порт наших клавиш** (тот же `hl.bind`): окна (`F`/`Q`/`P`/фуллскрин/флоат),
  фокус IJKL+стрелки, move SHIFT+IJKL, resize ALT+IJKL, apps (`TAB`=foot,
  `W`=zen, `R`=codium, `T`=hyprkcs, `E`=thunar), спец-воркспейсы
  (`Z`/`X`/`C`/`V`/`S`), группы (`ALT+Q`/`ALT+TAB`), gamemode (`SUPER+G` submap),
  громкость/медиа-клавиши, мышь.
- **switcher** `SUPER+SHIFT+D` → `~/dotfiles/bin/dotprofile menu`.
- **риг-действия через rigdo** (та же клавиша, работает после хот-свитча):
  `Y`=wallpaper, `U`=launcher, `SHIFT+O`=settings, `ALT+M`=music,
  `ALT+S`=calendar, `ALT+P`=movies, `B`=battery, `N`=network, `H`=guide,
  `SHIFT+S`=screenshot, `F1`=lock, `grave`=clipboard, `M`=shell.
- **уникальные end4-фичи** на свободные клавиши (задать при импле):
  OCR `regionOcr`, Google Lens `regionSearch`, screen-translate,
  OSK `oskToggle`, light/dark `toggleLightDark`, widget-overlay `overlayToggle`,
  panel-cycle `panelFamilyCycle`, emoji-overview `overviewEmojiToggle`.

Воркспейс-навигация: у end4 свой `workspace_in_group`/`workspaceGroupSize`;
у нас — `wsaction.fish` (мультимонитор). Решить при импле: наш скрипт или его
механизм. Профиль-специфичные пути (`$csScripts`) в шаред НЕ идут — это часть,
которая осознанно остаётся пер-риговой.

### `bin/rigdo` — третья ветка `end4`

Каждый action получает ветку end4. Диспатч через существующий `hypr_global()`
(выбирает lua-форму `hl.dsp.global(...)` для end4-сессии). Мап:

| action | end4 |
| :--- | :--- |
| launcher | `quickshell:searchToggleRelease` |
| wallpaper | `quickshell:wallpaperSelectorToggle` |
| settings | `quickshell:sidebarRightToggle` |
| music | `quickshell:mediaControlsToggle` |
| clipboard | `quickshell:overviewClipboardToggle` |
| screenshot | `quickshell:regionScreenshot` |
| lock | `loginctl lock-session` |
| guide | `quickshell:cheatsheetToggle` |
| shell | `killall qs quickshell; qs -c ii &` |
| battery / network / calendar / movies | его сайдбар (`sidebarRightToggle`) или `hint` — у end4 нет 1:1-виджетов; уточнить какие есть при клоне |

Точные IPC-имена верифицировать при клоне (`hyprland/keybinds.lua` +
его shell-конфиг); часть действий может быть через `qs -c ii ipc call`, а не
`global`.

## 3. Rules + анимации

- **Анимации**: берём его (lua, нативно). Для кросс-движкового свитча в ilyamiro —
  перевод в `animations-runtime.keywords` (см. п.6).
- **Rules** → `profiles/end4/hypr/custom/rules.lua`: порт наших правил
  (case-by-case, наши приоритетны, его дефолты смотрим по случаю) +
  transparency-оверрайды: Discord/Obsidian/AyuGram/Feishin `opacity 1.0 override`,
  Thunar `0.90`.

## 4. Цвета (полная интеграция)

- **`apply_rig_colors` — 3-я ветка**: парсит итоговую палитру end4 (найти его
  state/generated-файл при клоне) → active/inactive border, группы,
  fastfetch `{{ACCENT}}`, Discord `rig.theme.css`, Obsidian `rig-theme.css`.
  Генерим его вариант тем через его же matugen (шаблоны Discord/Obsidian уже
  есть — переиспользуем).
- **matugen → контестируемый каталог**: `~/.config/matugen` сейчас
  не-контестируемый, под ilyamiro (наши шаблоны + `config.toml`). end-4 несёт
  свой matugen-конфиг. Решение: добавить `matugen` в CONTESTED у dotprofile +
  перенести в `profiles/*/matugen`. Контестируемый чище мержа.
- **Хук смены обоев**: его `switchwall` дёргает `dotprofile colors`
  (аналог `matugen_reload.sh` у ilyamiro).

## 5. Защита общих конфигов

Его installer агрессивно пишет `~/.config`.
- Перед прогоном — бэкап `fish`, `foot`, `fuzzel`, `matugen`.
- Общие (fish/foot/fuzzel/fastfetch/thunar) оставляем наши; его варианты игнорим.
- `post-update.sh` возвращает наши source-строки после его апдейтов.

## 6. Хот-свитч (остаётся)

- **end4 ↔ caelestia** — однодвижковый (оба lua): путь
  `~/.config/hypr/hyprland.lua` после смены `active` резолвится в конфиг нового
  рига, `hyprctl reload` работает по-настоящему. Оговорка: `require()` кеширует
  lua-модули — reload может не подхватить изменения внутри уже загруженных;
  проверить на месте.
- **end4 ↔ ilyamiro** — кросс-движковый, со всеми оговорками (бинды/правила
  после релогина, `disable_autoreload`). Нужен `animations-runtime.{lua,keywords}`
  для end4 (перевод его анимаций на оба движка).
- `rigdo` end4-ветка (п.2) — то, что делает риг-действия рабочими после свитча.

## 7. SDDM

Нужна **третья сессия** `sddm/hyprland-end4.desktop` + запись в `bootstrap.sh` —
чтобы выбирать end4 на входе. Switcher-бинд `SUPER+SHIFT+D` — только внутри живой
сессии (SDDM это login-менеджер, бинды там не исполняются).

## 8. Безопасность установки

Перед `./setup install`:
1. **Проверить quickshell-версию** ii vs текущую (`quickshell-git`, на которой
   живёт шелл ilyamiro) — главная мина: апдейт quickshell может уронить
   ilyamiro-шелл. При конфликте — собрать ii-совместимую и прогнать шелл ilyamiro
   на ней.
2. dotfiles в чистом git-состоянии (коммит/стеш) — чтобы diff'ом видеть что
   installer наменял.
3. Бэкапы (п.5).
4. `git clone`, прочитать `setup`, прогон интерактивно (каждый шаг показывается);
   sudo — через `!` пользователя.

## 9. Финализация

- e2e: relogin во все 3 сессии + 6 направлений хот-свитча.
- `bootstrap.sh`: AUR-метапакеты `illogical-impulse-*` (фактический список из
  setup), симлинки новых контестируемых каталогов, SDDM-запись.
- README: таблица ригов + новые оговорки.

## Оценка

Один длинный заход (~вечер) + участие пользователя на установке (sudo, выборы
installer'а) и e2e-тестах. Категоризация биндов и точные IPC-имена
доуточняются при клоне (репо тогда доступен локально).
