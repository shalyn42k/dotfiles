# Хендофф 2026-09-02: починка после апдейта + аудит свитчера

Сессия начиналась как «всё сломалось после обновления caelestia». Корень
оказался не в caelestia, а по дороге вскрылось несколько вещей в свитчере.
Документ — чтобы продолжить в IDE, не перечитывая переписку.

---

## Часть 1. Что сделано

### Поломка системы (закрыто)

`quickshell-git` был собран 1 июня против Qt 6.10. Qt уехал на 6.11.2
29 августа → `qs` падал на `undefined symbol ... Qt_6_PRIVATE_API`, и вместе с
ним всё: шеллы обоих ригов, rigswitch.

Чинилось не пересборкой: **`quickshell-git` из репозиториев CachyOS исчез**.
Первая попытка (`paru -S quickshell-git --rebuild`) молча подменила пакет на
`noctalia-qs` — форк quickshell под чужой шелл, который объявляет
`provides=quickshell-git`. Вернули настоящий upstream: `extra/quickshell 0.3.1`.
Теперь система на репозиторной сборке, ручная пересборка на каждый апдейт Qt
больше не нужна.

**Следствие для репы:** `bootstrap.sh` ставил `quickshell-git` — чистая
установка сломалась бы так же. Исправлено на `quickshell` (`17c1034`).

### caelestia (закрыто)

- Подтянуто 15 коммитов апстрима, HEAD `750e67d9`.
- Локальный патч `plugin/src/Caelestia/Config/rootnodes.hpp` **дропнут**:
  апстрим коммитом `be3d6522 revert(config): don't forward declare` вернул ровно
  те же include'ы. Сверено построчно, ничего не потеряно.
- Патч `shell.qml` (`settings.watchFiles: false`) сохранён — единственная наша
  правка в том репозитории.
- 8 плагинов пересобраны и установлены, `qmllint` резолвит все модули,
  тестовый запуск `qs -c caelestia` продержался 8 с без единой ошибки.
- Снесён `build.stale` (1.9 ГБ).

Остаточная мелочь: в `/usr/lib/qt6/qml/Caelestia/` лежат сироты от старой
раскладки модулей — `caelestia.qmltypes`, `libcaelestiaplugin.so`,
`lib/libcaelestia.so`, каталог `Internal/` (июнь–июль, собраны под Qt 6.10).
`qmldir` на них не ссылается, `Caelestia.Internal` нигде не импортируется —
инертны. Убрать при случае:

```
sudo rm -rf /usr/lib/qt6/qml/Caelestia/{caelestia.qmltypes,libcaelestiaplugin.so,Internal} \
            /usr/lib/qt6/qml/Caelestia/lib/libcaelestia.so
```

### ilyamiro: апстрим архивирован (закрыто, `d09578a`)

`ilyamiro/imperative-dots` **архивирован 2026-09-02**, финальный
`DOTS_VERSION="2.0.0"`, переехал в `ilyamiro/serpantinum`.

Три места опрашивали мёртвую репу и показывали вечное «доступно обновление
2.0.0» против нашей локальной 1.7.6-1. Хуже: **две** кнопки (`UpdaterPopup.qml`,
`GuidePopup.qml`) выполняли `eval "$(curl -fsSL .../install.sh)"`. Инсталлер
serpantinum при этом делает `sudo pacman -Syyu --noconfirm` и, по его же README,
откладывает всю прежнюю конфигурацию — а наша репа **и есть** живой конфиг через
симлинк `profiles/active`. Обе кнопки разоружены (`xdg-open` страницы проекта),
версии читаются из `serpantinum/version.txt` информационно.

### Баги ригов (закрыто)

- `1853895` — тоггл спец-воркспейсов в caelestia: `pgrep -x vesktop`/`obsidian`
  не срабатывал (Electron не даёт совпадения по имени процесса), бинд
  перезапускал приложение вместо переключения. Теперь по классу окна.
- `ba3d349` — **у end4 не было каталога `gtk-4.0`**, при том что он в
  обязательном `CONTESTED`. Симлинк `~/.config/gtk-4.0` на end4 был битым, а его
  matugen рендерит туда `gtk.css` → GTK4-тема на end4 не применялась вообще.
  Тихо, потому что gtk-3.0 половина той же пары работала.
- `569a2cb` — генерируемые артефакты end4 (обои, matugen-цвета, thumbnails).

### Свитчер: релогин целился в никуда (закрыто, `17c1034`)

Кросс-движковый свитч **никогда** не приземлялся в запрошенный риг.
`trigger_relogin` записывал целевую сессию в `~/.dmrc`, но **SDDM этот файл не
читает** — он держит последнюю сессию в root-овом `/var/lib/sddm/state.conf`.
Запись была холостой, SDDM восстанавливал что помнил, а `Exec` той записи
переставлял `profiles/active` обратно. Доказательство из journal:

```
13:40:09  ~/.dmrc = hyprland-lua           ← trigger_relogin
13:41:00  Session "hyprland-ilyamiro.desktop" selected
13:41:01  profiles/active -> ilyamiro
```

Заменено на **одну** запись `sddm/hyprland-rig.desktop` →
`start-hyprland-profile --auto`, которая берёт риг из `profiles/active` —
симлинка, который `cmd_switch` и так переставляет перед релогином. Одна запись
покрывает все риги, включая hyprlang-ilyamiro: Hyprland выбирает движок по
тому, что лежит в `~/.config/hypr`, а симлинки ставятся до `exec`.

Попутно: `session_desktop()` удалён как мёртвый, добавлен
`DesktopNames=Hyprland` (его не было ни в одной старой записи — `loginctl`
показывал пустой `Desktop=`).

Резолвинг проверен на всех формах: `--auto`→active, `--lua`→`.last-lua`,
явное имя, мусор→`caelestia`.

### Документы

- `docs/specs/2026-09-02-serpantinum-rig-design.md` — дизайн миграции.
- `docs/tech-debt.md` — п.1/п.2 размечены как получившие путь закрытия;
  добавлены п.8 (бинды), п.9 (`CONTESTED`), п.10 (пакетные SDDM-записи).
- Удалены ветки `rig-switch-engine-split` и `end4-rig` — обе имели 0
  уникальных коммитов относительно main.

---

## Часть 2. Главная находка

**Serpantinum сводит все риги на lua.** Его конфиг композитора —
`compositors/hyprland/config/{variables,env,autostart,monitors,settings,keybinds}.lua`
— написан тем же `hl`-API, что у нас:

```lua
hl.on("hyprland.start", function() hl.exec_cmd("serpantinumd start") end)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
```

То есть hyprlang-ветка, на которой держатся п.1 и п.2 tech-debt, исчезает
**у источника** — не мостом и не генератором, её просто нет.

Разведка: вендорится через `$SERPANTINUM_DIR` (системная установка не нужна),
из ~60 зависимостей не хватает **одной** — `wl-gammarelay-rs`. Клон для чтения
лежит в `~/src/serpantinum`.

**Красная линия:** их `install/install.sh` не запускать никогда —
`sudo pacman -Syyu --noconfirm` плюс отбрасывание существующего конфига.

---

## Часть 3. Что надо сделать

### Немедленно (одна команда)

Старые SDDM-записи **не удалились** — прошла только половина команды. Сейчас в
греетере шесть вкладок:

```
sudo rm -f /usr/share/wayland-sessions/hyprland-lua.desktop \
           /usr/share/wayland-sessions/hyprland-ilyamiro.desktop \
           /usr/share/wayland-sessions/hyprland-uwsm.desktop
```

`hyprland-rig.desktop` уже установлен. Голая `hyprland.desktop` оставлена
сознательно как аварийный вход. После этого — залогиниться в **«Hyprland
(rig)»**, SDDM её запомнит.

### Требует повторения симптома

- **Схема цветов.** `dotprofile colors` для активного рига отрабатывает с
  exit 0, `profiles/ilyamiro/hypr/colors.conf` валиден
  (`$active_border = rgba(edc06cee)`). Значит ломается не здесь. Нужно: какой
  риг, что именно не перекрашивается (рамки / шелл / gtk / fastfetch), в какой
  момент (смена обоев / свитч / логин).
- **Вид свитчера.** «Не выглядит как должен» — нужен конкретный делта:
  overlay `rigswitch` (`.config/quickshell/rigswitch/`), или пикер, или сплэш.

### Работа по коду

| # | Что | Где | Блокер |
| :-- | :--- | :--- | :--- |
| 1 | `apply_rig_binds` — бинды не меняются при горячем свитче | `bin/dotprofile`, рядом с `apply_rig_animations`/`apply_rig_rules` | нужна lua-сессия |
| 2 | `CONTESTED` линкует безусловно → битые симлинки | `bin/dotprofile:31` `ensure_links` | нет |
| 3 | Порт end4 из апстрима, 2.5 мес | `profiles/end4`, апстрим `~/src/dots-hyprland` | нет |
| 4 | Миграция ilyamiro → serpantinum | спека готова | решение по вендорингу |
| 5 | Два конфликтующих конфига SDDM | `/etc/sddm.conf` vs `/etc/sddm.conf.d/10-wayland.conf` | нет |

**По п.1.** Механика та же, что у анимаций: chunk `binds-runtime.lua` на риг +
`hyprctl eval "dofile(...)"`. Разница — `hl.bind` только добавляет, старые
бинды чужого рига останутся и будут стрелять. Нужен снос предыдущего набора;
`hl.unbind(key)` в API **есть**, проверено на Hyprland 0.56.2
(`/usr/share/hypr/stubs/hl.meta.lua:860`). Разрабатывать и проверять можно
только из lua-сессии: из ilyamiro любой свитч кросс-движковый и уходит в
релогин, горячая ветка не исполняется вообще.

Не путать с `docs/superpowers/specs/2026-07-18-unified-keybinds-variants.md` —
там про то, *какими должны быть* бинды (3 варианта, раздел «Открытое» не
закрыт). Здесь — про то, что *текущие* не следуют за ригом. Чинится независимо.

**По п.3.** Ломающее в апстриме: `notifications.monitor` → `notifications.forceMonitor`
(`9e1568fc`). Полезное: `hl.unbind()` (`68c67ace`), фиксы XDG_DATA_DIRS
(`737eb7c3`, `b470bf3f`), hyprsunset под lua-схемой (`d4d78a5e`). Локальный клон
grafted, HEAD от 14 июня, апстрим от 27 августа.

**По п.4.** Развилка перед стартом: как вендорить serpantinum — submodule,
subtree или внешний клон с pin-файлом. Копией в репу не стоит, там ~2000 файлов.
Склоняюсь к submodule: держит pin честно и ложится на видение «риг = drop-in
модуль по контракту».

### Прочее

- 88 коммитов не запушено в origin.
- `hyprland-uwsm.desktop` вернётся при обновлении `hyprland` (файл пакетный).
  Update-proof вариант — `NoExtract` в `/etc/pacman.conf`, см. tech-debt п.10.

---

## Коммиты сессии

```
17c1034 fix(switcher): one SDDM entry, drop the dead .dmrc relogin targeting
efaef61 docs(tech-debt): record two switcher gaps found while auditing
ba3d349 fix(end4): add missing gtk-4.0 directory
0b613a6 docs: design for migrating ilyamiro onto serpantinum
569a2cb chore(end4): refresh generated wallpaper and matugen colors
1853895 fix(caelestia): match special-workspace apps by window class
d09578a fix(ilyamiro): disarm update path after upstream archive
```
