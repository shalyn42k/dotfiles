# Свитчер как софт: контракт рига

Дата: 2026-09-04. Статус: **план реализации**. Заменяет идею
`2026-09-03-rig-contract-idea.md` (удалена) — та фиксировала направление, эта
описывает, что именно делать.

## Цель

Свитчер ригов — самостоятельный проект, а не часть этих дотфайлов. Пользователь
даёт ему каталог рига, и дальше всё работает само: свитчер находит риг, знает
чем его запустить, откуда взять палитру, обои и логотип.

Критерий готовности один: **свитчер не содержит ни одного имени рига.**
Добавить риг = положить каталог. Ни строчки в коде.

---

## 1. Где мы сейчас (замер 2026-09-04)

| Файл | Упоминаний всего | Из них в коде |
| :--- | ---: | ---: |
| `bin/rigdo` | 33 | **30** |
| `bin/kbd-theme-sync` | 18 | **16** |
| `bin/dotprofile` | 19 | 4 |
| `bin/rig-theme` | 15 | 4 |
| `.config/quickshell/rigswitch/Palettes.qml` | 8 | 4 |
| `.config/quickshell/rigswitch/scan-rigs.sh` | 5 | 4 |
| `.config/quickshell/rigswitch/RigIdentity.qml` | 4 | 2 |
| `bin/start-hyprland-profile` | 2 | 1 |
| **Итого** | **126** | **65** |

Сырой счёт (126) завышает: в `dotprofile` и `rig-theme` почти всё — комментарии
с записями замеров, их трогать не нужно. Работа концентрируется в **двух
файлах: `rigdo` и `kbd-theme-sync` дают 46 из 65 упоминаний (71%)**.

Каталогов `actions/` и `theme/`, на которых стоит вся идея, нет ни у одного
рига. Частично нужное уже есть: `scan-rigs.sh` находит риги перебором
`profiles/*/`, у ригов есть `role` и `session.sh`.

---

## 2. Что построить: риг описывает себя структурой каталога

Никакого формата и парсера — только соглашение об именах файлов.

```
<каталог рига>/
  role                    # строка: work | daily | …
  session.sh              # контракт start|stop — обязательный
  logo.svg                # логотип для карточки свитчера
  animations-runtime.lua  # чанк анимаций для горячего свитча
  hypr/                   # конфиг композитора (как сейчас)
  actions/                # по исполняемому файлу на действие контракта
    launcher              #   чего нет — того у рига нет
    lock
    …
  theme/
    palette               # исполняемый: печатает НОРМАЛИЗОВАННЫЙ JSON палитры
    wallpaper             # исполняемый: печатает путь к текущим обоям
```

### 2.1 `actions/` — 13 действий контракта

Список задан `KEYBINDS.md` §2. Что у рига есть сегодня:

| Действие | caelestia | serpantinum |
| :--- | :--- | :--- |
| `launcher` | `caelestia shell drawers toggle launcher` | `serpantinum msg toggle launcher` |
| `clipboard` | `pkill fuzzel \|\| caelestia clipboard` | `serpantinum msg toggle clipboard` |
| `screenshot` | global `caelestia:screenshotFreeze` | `serpantinum screenshot` |
| `lock` | global `caelestia:lock` | `serpantinum lock` |
| `shell` | `qs -c caelestia kill; qs -c caelestia -d` | `serpantinum reload` |
| `wallpaper` | — | `serpantinum msg toggle wallpaper` |
| `music` | — | `serpantinum msg toggle music` |
| `calendar` | — | `serpantinum msg toggle calendar` |
| `network` | — | `serpantinum msg toggle network` |
| `guide` | — | `serpantinum msg toggle guide` |
| `battery` | — | `serpantinum msg toggle system` ⚠ |
| `settings` | — | — |
| `movies` | — | — |

⚠ **`battery` у serpantinum сегодня сломан и чинится этим переездом.** Апстрим
вешал системную панель на `SUPER+B`; контракт грузится последним и перебивает
комбу на `rigdo battery`, а тот показывает подсказку «battery lives in the
system panel (SUPER+B)» — отсылает к самой себе. Панель недостижима с
клавиатуры. Файл `actions/battery` с `serpantinum msg toggle system` закрывает
это заодно.

`movies` — заглушка в обоих ригах, то есть `SUPER+ALT+P` не делает ничего
нигде. После переезда «нет файла = нет действия» это станет видно честно, без
специальной ветки.

### 2.2 Отличия от идеи 2026-09-03 и почему

Два места, где исходная идея не выдерживает встречи с кодом.

**`theme/wallpaper` — исполняемый файл, а не симлинк.** Идея предлагала
симлинк на текущие обои. Для serpantinum это работает: он держит снапшот по
фиксированному пути `~/.cache/serpantinum/wallpaper/current_wallpaper.png`.
Для caelestia — нет: он хранит не файл, а **путь текстом** в
`~/.local/state/caelestia/wallpaper/path.txt`, и путь меняется на каждую смену
обоев. Статический симлинк за этим не угонится, а держать его актуальным
пришлось бы ещё одним path-юнитом. Исполняемый файл, печатающий путь, решает
это без движущихся частей и однороден с `actions/`.

**`theme/palette` печатает нормализованный JSON, а не `accent-key`.** Идея
предлагала симлинк на палитру рига плюс строку с именем ключа акцента. Одного
ключа мало: `Palettes.qml` берёт **12 токенов** (`surface`,
`surfaceContainer`, `onSurface`, `primary`, `outline`, …), и у ригов они
называются по-разному — у caelestia material-you под ключом `colours` без
решётки, у serpantinum catppuccin-образные с решёткой. Сейчас это разложено
адаптерами внутри `Palettes.qml`; там же они и останутся, если контракт
отдаёт сырой файл.

Поэтому нормализация переезжает **в риг**: `theme/palette` печатает JSON ровно
с нашими 12 токенами и `#RRGGBB` значениями. Тогда потребитель — один
`JSON.parse` без единой ветки, а знание «где у этого рига палитра и как
называются её ключи» живёт там, где ему место: в самом риге.

---

## 3. Что убрать

| Файл | Что уходит |
| :--- | :--- |
| `bin/rigdo` | Весь `case` из 13 веток × 2 рига (67 строк → ~8). Скрипт перестаёт знать риги. |
| `bin/kbd-theme-sync` | Детект рига по `qs -c` / `quickshell -p`, константы `CAELESTIA*`/`SERPANTINUM*`, две ветки чтения обоев и схемы |
| `Palettes.qml` | Блок `adapters` (35 строк) целиком — нормализация уехала в риг |
| `scan-rigs.sh` | Функция `wallpaper_for()` с `case` по имени рига |
| `bin/rig-theme` | `case` выбора пути обоев |
| `RigIdentity.qml` | Таблица `caelestia: "grid", serpantinum: "serpentine"` → читать из рига |
| `rigswitch/logos/` | Каталог логотипов свитчера → `<рига>/logo.svg` |

`bin/dotprofile` **не переписывается**: его 4 кодовых упоминания — фолбэки
`|| echo caelestia` и дефолтные пути для discord/obsidian-тем. Их можно снять
позже; на контракт они не влияют.

---

## 4. Как реализовать

По одному шагу с проверкой после каждого — трогаем работающее.

### Шаг 1. `actions/` у обоих ригов + новый `rigdo`

Разложить 5 файлов в `profiles/caelestia/actions/` и 11 в
`profiles/serpantinum/actions/` (таблица §2.1), каждый `chmod +x`. Затем
`bin/rigdo` целиком становится:

```bash
#!/usr/bin/env bash
# rigdo — запускает действие активного рига. Про сами риги не знает ничего:
# что риг умеет, определяется наличием исполняемого файла в его actions/.
set -u
action="${1:-}"
[[ -n "$action" ]] || { echo "usage: rigdo <action>" >&2; exit 1; }

cmd="$HOME/dotfiles/profiles/active/actions/$action"
if [[ -x "$cmd" ]]; then
    exec "$cmd" "${@:2}"
fi
notify-send -u low "rigdo" "действия «$action» у этого рига нет"
```

`profiles/active` — симлинк, поэтому выбор рига происходит в момент нажатия,
ровно как сейчас. Это свойство терять нельзя: на нём держится то, что
контрактные комбы переживают горячий свитч.

**Проверка:** пройти все 13 комб контракта в обоих ригах и сверить с §2.1.
Отдельно убедиться, что `SUPER+B` в serpantinum открывает системную панель.

### Шаг 2. `theme/` у обоих ригов

Четыре исполняемых файла. `theme/wallpaper`:

```bash
# caelestia
cat "$HOME/.local/state/caelestia/wallpaper/path.txt" 2>/dev/null
# serpantinum
echo "$HOME/.cache/serpantinum/wallpaper/current_wallpaper.png"
```

`theme/palette` — `jq`-скрипт, перекладывающий палитру рига в 12 токенов.
Отображения уже написаны и проверены, брать из `Palettes.qml` (`adapters`,
строки 51–86): caelestia — ключи один-в-один под `colours`, с добавлением
решётки; serpantinum — `base`→`surface`, `surface0`→`surfaceContainer`,
`mantle`→`surfaceContainerLow`, `text`→`onSurface`, `subtext0`→
`onSurfaceVariant`, `blue`→`primary`, `surface1`→`secondaryContainer`,
`subtext1`→`onSecondaryContainer`, `overlay0`→`outline`, `surface2`→
`outlineVariant`, `red`→`errorContainer`, `maroon`→`onErrorContainer`.

**Проверка:** `profiles/*/theme/palette | jq` даёт 12 ключей с `#RRGGBB` у
обоих ригов; `profiles/*/theme/wallpaper` печатает существующий файл.

### Шаг 3. Потребители палитры и обоев

По одному, с проверкой: `scan-rigs.sh` → `Palettes.qml` → `kbd-theme-sync` →
`rig-theme`. Каждый меняет свою ветку по имени рига на вызов
`profiles/<rig>/theme/<что нужно>`.

`kbd-theme-sync` — самый заметный: из него уходит и детект активного рига
(вместо `pgrep` по командной строке шелла — чтение симлинка `profiles/active`,
как делает `rigdo`).

**Проверка:** свитч ригов туда-обратно; подсветка клавиатуры уезжает в цвет
обоев нового рига, карточки в оверлее рисуются палитрами своих ригов.

### Шаг 4. Логотипы и идентичность

`rigswitch/logos/<рига>.svg` → `profiles/<рига>/logo.svg`. Стиль анимации из
`RigIdentity.qml` переезжает в риг — проще всего строкой в существующий файл
`role` или отдельным `animation` рядом с `logo.svg`. **Решить при
реализации**: `role` уже используется fastfetch'ем, второе значение в нём
может ему помешать.

### Шаг 5. `dotprofile doctor` под новый контракт

Проверять целиком: есть ли `session.sh`, `role`, `logo.svg`, исполняемы ли
файлы в `actions/`, не битые ли `theme/palette` и `theme/wallpaper`, отдаёт ли
`theme/palette` валидный JSON с 12 ключами.

### Шаг 6. Вынос свитчера в отдельный репозиторий

Только после того как шаги 1–5 прошли и в свитчере не осталось имён ригов
(`grep -c 'caelestia\|serpantinum'` = 0 в исполняемых строках).

---

## 5. Что решить до старта

- **Где живут риги, если свитчер отдельный проект.** Сейчас — жёстко
  `~/dotfiles/profiles/*`. Список путей в конфиге пользователя? Каталог с
  симлинками? От этого зависит, что́ читает `scan-rigs.sh`.
- **Молчать или показывать hint**, когда у рига нет `actions/<действие>`. Выше
  предложен hint (как сейчас), но при 13 комбах и риге, который умеет 5, это
  много шума.
- **Совместимость:** переводить оба рига разом или держать период, когда
  работают обе схемы. Разом проще — ригов всего два и оба свои.
- **Куда девать стиль анимации** (шаг 4): второе поле в `role` или отдельный
  файл.

---

## 6. Готово, когда

1. `grep 'caelestia\|serpantinum'` по исполняемым строкам `bin/` и
   `.config/quickshell/` даёт **0**.
2. Третий риг заводится копированием каталога и не требует правок в коде.
3. `tests/run.sh` — ALL PASS.
4. `dotprofile doctor` проверяет контракт целиком.
