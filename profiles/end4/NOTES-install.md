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

**Мина упирается в:** совместимость кастомного ilyamiro Shell.qml + caelestia-конфига
с quickshell API март-билда (7511545). Март→май был реорг toplevel-management.

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
  март-quickshell в префикс воспроизводимо. Проверить роль пакета
  `quickshell-wrapper` (может уже решать мульти-версийность). ОБНОВИТЬ спеку.
- cli11-гейт — зелёный свет (деплой-стратегия, не просто тест).
- Метод теста: nested Hyprland (изолирует, без дубль-слоёв).

### Diff — перезаписанные общие конфиги (fish/foot/fuzzel/matugen)

- TODO

### IPC-вокабуляр end4 (`quickshell:*`)

Из `~/.config/hypr/hyprland/keybinds.lua` (`hl.dsp.global` / `ipc call`):

- launcher (search): TODO
- wallpaperSelector: TODO
- sidebarRight / sidebarLeft: TODO
- mediaControls: TODO
- overviewClipboard: TODO
- regionScreenshot: TODO
- cheatsheet: TODO
- session: TODO
- regionRecord: TODO
- toggleLightDark: TODO
- regionOcr / regionSearch: TODO
- oskToggle: TODO
- overlay: TODO
- panelFamily: TODO
- overviewEmoji: TODO
- battery / network / calendar: отдельный IPC или только сайдбар? TODO

### Файл итоговой палитры end4

- Путь (для Task 10): TODO
- Откуда accent/border: TODO

### matugen-конфиг end4

- Путь: TODO
