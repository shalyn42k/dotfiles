# end-4 (illogical-impulse) — журнал установки

> Артефакт Задач 1–2. Потребители: Задачи 3,5,6,9,10,11.
> Заполняется по мере установки. НЕ плейсхолдеры — явная зависимость от клона.

## Task 1 — prep

- Ветка: `end4-rig` (от `main`).
- Дата старта: 2026-07-15.

### quickshell-версия (мина №1)

```
quickshell-git 0.3.0.r3.g7d1c9a9-1
Quickshell 0.3.0 (revision 7d1c9a9c6721606b129829134d6f614f015621e2, AUR quickshell-git)
```

- Шелл ilyamiro использует `quickshell-git`. end4 (ii) тоже требует quickshell-git.
- **TODO (Task 2):** сверить точное требование ii к тегу/ревизии из его `setup`/README.
  Если ii требует тег, несовместимый с текущим `quickshell-git` — СТОП до установки.

### Бэкап общих конфигов

- `~/end4-preinstall-backup/` ← fish, foot, fuzzel, matugen (до прогона installer).

---

## Task 2 — clone / install / факты

> Заполнить после клона `~/src/dots-hyprland`.

### setup: что пишет в ~/.config

`sdata/subcmd-install/3.files*.sh` копирует в `~/.config`:
`chrome-flags.conf, code-flags.conf, darklyrc, dolphinrc, fish, fontconfig,
foot, fuzzel, hypr, kdeglobals, kde-material-you-colors, kitty, Kvantum,
matugen, mpv, qt5ct, qt6ct, quickshell, starship.toml, thorium-flags.conf,
wlogout, xdg-desktop-portal, zshrc.d`.

**Общие с другими ригами (перезапишутся!):** fish, foot, fuzzel, matugen,
fontconfig, Kvantum, qt5ct, qt6ct, kde-material-you-colors, hypr, quickshell,
kitty, mpv, wlogout, starship.toml.
Task 1 бэкапнул только fish/foot/fuzzel/matugen — **дыра закрыта** доп-бэкапом
всего списка в `~/end4-preinstall-backup/`.

### Список пакетов (`illogical-impulse-*`)

`ags, audio, backlight, basic, bibata-modern-classic-bin, fonts-themes,
hyprland, kde, microtex-git, portal, python, quickshell-git,
quickshell-wrapper, repo, screencapture, toolkit, widgets`.

### Требование ii к quickshell — МИНА №1 СРАБОТАЛА

`sdata/dist-arch/illogical-impulse-quickshell-git/PKGBUILD`:
```
_commit='7511545ee20664e3b8b8d3322c0ffe7567c56f7a'
pkgver=0.1.0.r1
provides=(quickshell quickshell-git)
conflicts=(quickshell quickshell-git)
```
- ii пинит quickshell коммит `7511545`, **conflicts+provides** системный
  `quickshell-git`.
- Система сейчас: `quickshell-git 0.3.0.r3.g7d1c9a9` (коммит `7d1c9a9`) — на нём
  крутится шелл ilyamiro (`qs`).
- **Установка ii ЗАМЕНИТ системный quickshell-git → риск поломки ilyamiro-шелла.**
- РЕШЕНИЕ ДО УСТАНОВКИ (план §мина №1): проверить, работает ли ilyamiro-шелл на
  ii-пиновом quickshell (7511545). Если нет — держать обе версии / решить стратегию.
  **Ожидает решения пользователя.**

#### Разведка коммитов (2026-07-15)

| commit | author date | |
|---|---|---|
| `7d1c9a9` (система) | 2026-05-10 | текущий, "wayland/toplevel: reorganize toplevel management" |
| `7511545` (ii пин)  | 2026-03-18 | "build: add missing wayland-client CFLAGS" |

- **Это ДАУНГРЕЙД ~2 мес** (май→март). Не ii требует новее — ii пинит старее.
- Между ними реорг toplevel-management (API-changes) → текущий qs-шелл может
  юзать пост-мартовский API → риск поломки на ii-билде.
- Upstream: `git.outfoxxed.me/quickshell/quickshell`.
- **Rollback дешёвый:** quickshell-git из AUR, `paru -S quickshell-git`
  пересоберёт latest (май) → восстановит текущий шелл. Worst-case обратимо.

#### Test-first — статус (2026-07-15, для другой сессии)

Выбран путь test-first: собрать `7511545` в локальный префикс (БЕЗ install),
прогнать шеллы на нём.

**Уточнение — quickshell юзают ДВА рига (оба под риском даунгрейда):**
- ilyamiro: `quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml` (кастом)
- caelestia: `qs -c caelestia`
- end4 будет: `qs -c ii`

**Прогресс сборки:**
- Клон upstream → `~/src/quickshell-test`, checkout `7511545` ✓.
- Build-депсы: все есть КРОМЕ `cli11` → нужен `sudo pacman -S cli11` (гейт).
- cmake-config доходит до `find_package(CLI11)` и падает ТОЛЬКО на нём;
  Wayland 1.25.0 / Qt6 / XKB найдены. cli11 — единственный блокер конфига.

**Дальше (после cli11):**
1. `cmake -GNinja -B build ...` (config добьётся) → `cmake --build build` (долгая C++/Qt сборка).
2. `cmake --install build --prefix ~/qs-test-prefix` (локальный, без /usr).
3. Прогон: `~/qs-test-prefix/usr/bin/quickshell -p .../Shell.qml` +
   `qs -c caelestia` — стартуют ли на март-билде.
4. **ОГОВОРКА:** live-прогон на активном рабочем столе создаст дубль-слои
   поверх текущего (мешает, `pkill` убивает). Решить: тестить в отдельном
   nested-compositor (Hyprland/labwc в окне) vs live-прогон с pkill-подчисткой.

#### СТАТУС СБОРКИ (2026-07-15, обновление)

- **cli11 гейт ЗАКРЫТ:** `cli11 2.6.2-1` установлен (cpptrace 1.0.4, vulkan-headers
  1.4.350 тоже на месте). Sudo не понадобился отдельным шагом.
- **cmake config ✓** (exit 0): `cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX=~/qs-test-prefix/usr`. Все депы найдены (Wayland 1.25,
  Qt6, XCB, pipewire, polkit, jemalloc, libdrm/gbm/egl). Каталог сборки:
  `~/src/quickshell-test/build`.
- **ninja build ЗАПУЩЕН** (фон, долгий). Лог: см. task-output.
- **МЕТОД ТЕСТА РЕШЁН: nested Hyprland** (изолирует, без дубль-слоёв на рабочем
  столе). НЕ live-прогон.

#### ШАГИ ДЛЯ АГЕНТА (после завершения сборки)

1. Проверить сборку удалась: `ls ~/src/quickshell-test/build/quickshell` (бинарь).
2. `cmake --install ~/src/quickshell-test/build` → встанет в `~/qs-test-prefix/usr`.
   Проверить: `~/qs-test-prefix/usr/bin/quickshell --version` → ревизия `7511545`.
3. **Материализовать ii-конфиг** (нужен для `qs -c ii`): его qml в
   `~/src/dots-hyprland/dots/.config/quickshell/ii/`. Симлинк/копия в
   `~/.config/quickshell/ii` (Task 3 снапшот всё равно потребует). ОСТОРОЖНО: не
   затереть чужое — `~/.config/quickshell/` сейчас пуст (проверено).
4. **Nested-тест ii на март-билде** (интерактивно, пользователь смотрит экран):
   - запустить nested: `Hyprland` из терминала (авто-windowed при живом
     WAYLAND_DISPLAY) с минимальным конфигом;
   - внутри: `~/qs-test-prefix/usr/bin/quickshell -c ii` (или `-p .../ii/shell.qml`);
   - наблюдать: стартует ли бар/виджеты, ошибки ToplevelManager-API в stderr.
   - Ожидание по гипотезе: ii ДОЛЖЕН работать на март-билде (он под него пинован);
     это подтверждает деплой-стратегию сосуществования.
5. Симметрично (опционально): `qs -c caelestia` на март-билде НЕ обязателен —
   caelestia остаётся на системном (май) quickshell, март-билд только для ii.
   Прогонять caelestia на марте нужно ТОЛЬКО если рассматривать даунгрейд (он
   отвергнут, см. ВЕРДИКТ выше).
6. Если ii стартует чисто → продолжить план: снапшот профиля (Task 3),
   `session.sh` зовёт `~/qs-test-prefix/usr/bin/quickshell -c ii`, дальше бинды/
   rigdo/цвета. ОБНОВИТЬ спеку под локальный бинарь (см. ВЕРДИКТ).

**Мина упирается в:** совместимость кастомного ilyamiro Shell.qml + caelestia-конфига
с quickshell API март-билда (7511545). Март→май был реорг toplevel-management.

#### РЕЗУЛЬТАТ NESTED-ТЕСТА (2026-07-15): ✅ ii ГРУЗИТСЯ НА МАРТ-БИЛДЕ

Метод: nested Hyprland (`nested-ii-test.conf`), `~/qs-test-prefix/usr/bin/quickshell
-c ii`, авто-выход 25с, лог stderr.

**Провал №1 (устранён):** `module qs.modules.common.widgets.shapes is not installed`
— `shapes/` это git-submodule (`github.com/end-4/rounded-polygon-qmljs`), наш
`clone --depth=1` его не инитил. Фикс: `git submodule update --init <path>`.
**bootstrap ОБЯЗАН делать `--recurse-submodules` или явный submodule init.**

**Итог (после submodule init):**
```
INFO: Configuration Loaded          ← QML полностью загрузился
DEBUG: [GlobalFocusGrab] Initialized
WARN: quickshell.hyprland.ipc: Got openwindow ...  ← Hyprland-IPC работает
```
- **Ни одной ToplevelManager/API-ошибки.** Шелл дошёл до рантайма, запустил
  сервисы (focus-grab, notifications, hyprland-ipc, todo, updates).
- Прочие WARN — отсутствующие user-state (`config.json`, `colors.json`,
  `states.json`) → чинятся реальным install+matugen, НЕ API-мина.
- **Вывод: гипотеза сосуществования ПОДТВЕРЖДЕНА. ii совместим с локальным
  март-quickshell 7511545.** Мина №1 закрыта.
- Побочно: `~/.config/quickshell/ii` был скопирован для теста — почищен, Task 3
  сделает чистый снапшот из `~/src/dots-hyprland/dots/` с submodule.

#### ВЕРДИКТ (2026-07-15): СОСУЩЕСТВОВАНИЕ, НЕ ДАУНГРЕЙД

Статик-замер использования toplevel-API (то что реорганизовали март→май):

| Шелл | Toplevel refs | quickshell | Вывод |
|---|---|---|---|
| ii | 80× (ToplevelManager жёстко) | пин март 7511545 (ДО реорга) | нужен март |
| caelestia | 27× | система май 7d1c9a9 | даунгрейд рискует им |
| ilyamiro Shell.qml | 0× | система май | безразличен |

- ii пин **осмысленный**: код на pre-reorg toplevel-API → на мае рискует упасть.
- caelestia юзает toplevel на мае → **даунгрейд системы на март отпадает** (риск caelestia).
- **Стратегия:** система (май) остаётся для caelestia+ilyamiro. ii крутится на
  ОТДЕЛЬНОМ локальном март-quickshell (`~/qs-test-prefix`). Систему НЕ трогаем.
- Пакеты: ставить `illogical-impulse-*` КРОМЕ `illogical-impulse-quickshell-git`
  (единственный с пином; остальные от него не зависят — проверено grep'ом
  PKGBUILD'ов). ii-шелл запускать локальным бинарём.
- **Последствие для спеки/плана:** `session.sh` для end4 зовёт
  `~/qs-test-prefix/usr/bin/qs -c ii`, НЕ системный `qs`. bootstrap собирает
  март-quickshell в префикс воспроизводимо (`--recurse-submodules`!).
- **`quickshell-wrapper` — только Nix** (`sdata/dist-nix/home-manager`), на Arch
  НЕ существует. Мульти-версийность на Arch решаем локальным префиксом сами.
- **Arch-пакеты для установки** = `sdata/dist-arch/illogical-impulse-*` МИНУС
  `illogical-impulse-quickshell-git`:
  audio, backlight, basic, bibata-modern-classic-bin, fonts-themes, hyprland,
  kde, microtex-git, portal, python, screencapture, toolkit, widgets.
  (+ их upstream-депы из `install-deps.sh`/`previous_dependencies.conf`.)
- **Config-clobber:** НЕ давать `3.files.sh` затирать общие `~/.config`
  (fish/foot/fuzzel/matugen/…). Вместо `./setup install` целиком — deps-only,
  а конфиги end4 брать снапшотом в `profiles/end4/` (Task 3) под dotprofile.
- cli11-гейт — зелёный свет (деплой-стратегия, не просто тест).
- Метод теста: nested Hyprland (изолирует, без дубль-слоёв).

### Diff — перезаписанные общие конфиги (fish/foot/fuzzel/matugen)

- Прямой `./setup install` ОТМЕНЁН (см. вердикт). Общие конфиги НЕ клобберим —
  end4 конфиги идут снапшотом в `profiles/end4/` под dotprofile.

### ОТКРЫТО: execs-оверрайд шелла (для custom-задачи)

- ii-дефолт `hypr/hyprland/execs.lua` стартует шелл СИСТЕМНЫМ `qs`/`quickshell`.
  При сосуществовании нужен март-бинарь → **`custom/execs.lua` должен
  переопределить старт шелла на `~/qs-test-prefix/usr/bin/quickshell -c ii`**
  (или заглушить дефолтный exec, а старт отдать session.sh).
- Проверить `hypr/hyprland/execs.lua` снапшота: какой exec-once поднимает шелл,
  как его подавить/переопределить в custom.

### Task 4 — session.sh / SDDM / post-update (статус)

- `session.sh` ✓: стартует локальный март-quickshell `-c ii`, стоп матчит по
  локальному бинарю (не трогает системный qs). Путь `QS_II` — единый ISTOCHNIK.
- `sddm/hyprland-end4.desktop` ✓: Exec = `start-hyprland-profile end4`.
- **post-update.sh ПРОПУЩЕН** (осознанно, отход от плана): `hyprland.lua`
  авто-грузит `custom/*.lua`, ii-updater перезапишет hyprland.lua тем же
  авто-сорсом → custom переживает апдейты нативно (как caelestia, у него тоже
  нет post-update). Восстанавливать нечего.

### Task 5 — порт биндов: ВХОДЫ СОБРАНЫ (готово к написанию)

**hl-API (hyprkcs-git, стаб `/usr/share/hypr/stubs/hl.meta.lua`):**
- `hl.bind(keys, disp, opts) -> HL.Keybind`. `hl.unbind(...)` ЕСТЬ (top-level,
  L814). `HL.Keybind` имеет `:remove()/:unbind()` (L615-619).
- Арг-форма unbind в стабе размыта (`...`); инференс: `hl.unbind("SUPER + Tab")`
  (строка комбо, как в bind). **ПОДТВЕРДИТЬ nested-тестом (hyprctl binds) —**
  ре-бинд в hyprkcs вероятно СТЕКАЕТСЯ, unbind дефолтов обязателен.
- Диспатчеры (из caelestia-эталона): `hl.dsp.exec_cmd`, `hl.dsp.global`,
  `hl.dsp.window.{fullscreen{mode=},float,pin,close,drag,resize,move{direction=}}`,
  `hl.dsp.focus({workspace=|direction=})`, `hl.dsp.workspace.toggle_special(name)`.

**Эталон порта:** `profiles/caelestia/hypr/hyprland/keybinds.lua` (та же hl-API,
абсолютные пути к scripts, wsaction.fish-цикл, специалы через pgrep+toggle_special).

**ii-дефолты под UNBIND (конфликт с §2, из `hyprland/keybinds.lua`):**
SUPER+Tab(overview), SUPER+V(clipboard), SUPER+Period(emoji), SUPER+A/B/O/N
(сайдбары), SUPER+Slash(cheatsheet), SUPER+K(osk), SUPER+M(media), SUPER+G(overlay),
SUPER+J(bar), SUPER+SUPER_L/R(search), CTRL+ALT+Delete(session), брайтнес/audio
(если наш OSD), + мышь SUPER+mouse:273/274. Полный список — сверить перед портом.

**Порт §2 (что писать в custom/keybinds.lua):**
- §2.1 rigdo: `hl.bind("<combo>", hl.dsp.exec_cmd(rigdo.."<action>"))` — 14 биндов.
  wsaction/специалы — скопировать `wsaction.fish` в `profiles/end4/hypr/scripts/`.
- §2.2 окна: fullscreen/float/pin/close/focus IJKL/move/resize — как caelestia.
- §2.3 воркспейсы: focus{workspace±1}, цикл 1..10 через wsaction, специалы Z/X/C/V/S.
- §2.4 apps: TAB=foot, W=zen, R=codium, E=thunar, T=hyprkcs (exec_cmd).
- §2.5 мышь, §2.6 poweroff+gamemode submap, §2.7 XF86 (оставить ii-нативные —
  у ii свой OSD через `qsIpcCall brightness/volume`, см. keybinds.lua:40-46).
- **ОТКРЫТО (execs):** `custom/execs.lua` переопределить старт шелла на
  `~/qs-test-prefix/usr/bin/quickshell -c ii` (ii-дефолт зовёт системный qs).

**Task 5 СТАТУС: НАПИСАН (luac -p ✓, 176 строк).**
- `custom/keybinds.lua`: unbind 13 ii-конфликтов + порт всего §2 (rigdo×14,
  окна, фокус/move/resize IJKL, группы, воркспейсы+специалы, apps app2unit,
  мышь, poweroff, gamemode submap). §2.7 XF86 оставлены ii-нативными (OSD).
- `hypr/scripts/{wsaction,specialcycle}.fish` скопированы из caelestia.
- resize инлайнен (end4 без hyprland.functions).
- **НЕ верифицировано** — Task 13 relogin: `hyprctl binds`, жать бинды, проверить
  что unbind сработал (нет дублей SUPER+Tab overview) + hl.unbind арг-форма ок.

### IPC-вокабуляр end4 (`quickshell:*`) — СОБРАНО

Из `~/src/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` (`hl.dsp.global`).
Диспатч в rigdo end4-ветке: `hyprctl dispatch "hl.dsp.global(\"quickshell:<X>\")"`.

Мап под наш rigdo (контракт §2.1):
- launcher → `searchToggleRelease`
- wallpaper → `wallpaperSelectorToggle` (рандом: `wallpaperSelectorRandom`)
- settings → `sidebarRightToggle` (настройки/система в правом сайдбаре)
- music → `mediaControlsToggle`
- clipboard → `overviewClipboardToggle`
- screenshot → `regionScreenshot`
- guide → `cheatsheetToggle`
- lock → `loginctl lock-session` (НЕ quickshell-глобал, keybinds.lua:335)
- shell → `killall quickshell; ~/qs-test-prefix/usr/bin/quickshell -c ii &`
- **battery / network / calendar → `sidebarRightToggle`** (отдельных IPC НЕТ —
  всё в правом сайдбаре; подтверждено: в keybinds нет отдельных глобалов)
- movies → нет аналога → `hint`

Уникальные end4 (Task 7, свободные слоты §7 / аналоги caelestia на тех же комбо):
- light/dark → `toggleLightDark` | record → `regionRecord` | OCR → `regionOcr`
- Google Lens → `regionSearch` | screen-translate → `screenTranslate`
- OSK → `oskToggle` | widget-overlay → `overlayToggle` | bar → `barToggle`
- panel-cycle → `panelFamilyCycle` | emoji → `overviewEmojiToggle`
- overview → `overviewWorkspacesToggle` | sidebarLeft → `sidebarLeftToggle`
  (+`sidebarLeftToggleDetach`) | session-меню → `sessionToggle`

### Файл итоговой палитры end4 — СОБРАНО (для Task 10)

matugen-пайплайн ii (`~/src/dots-hyprland/dots/.config/matugen/config.toml`):
- **m3-палитра (accent/фон, JSON):**
  `~/.local/state/quickshell/user/generated/colors.json`
  ← ГЛАВНЫЙ для `apply_rig_colors` end4-ветки (парсить отсюда accent).
  Читается шеллом ii через `services/MaterialThemeLoader.qml` (FileView).
- **border-цвета Hyprland (lua):** `~/.config/hypr/hyprland/colors.lua`
  (matugen пишет напрямую — можно переиспользовать для active/inactive border).
- **wallpaper-state (путь обоев):**
  `~/.local/state/quickshell/user/generated/wallpaper/path.txt`
  ← ЗАКРЫВАЕТ плейсхолдер end4-обоев в [[rig-switcher-overlay]] Rigs.qml.

### matugen-конфиг end4 — СОБРАНО (для Task 9)

- Путь: `~/src/dots-hyprland/dots/.config/matugen/config.toml` (+ `templates/`:
  colors.json, hyprland/, fuzzel/, gtk-3.0/, gtk-4.0/, kde/, wallpaper.txt).
- **КОНФЛИКТ подтверждён**: его config.toml пишет в ОБЩИЕ пути —
  `~/.config/fuzzel/fuzzel_theme.ini`, `~/.config/gtk-3.0/gtk.css`,
  `~/.config/gtk-4.0/gtk.css`. Пересекается с ilyamiro-matugen → **обязателен
  контестируемый matugen (Task 9)**, иначе риги дерутся за эти файлы.
