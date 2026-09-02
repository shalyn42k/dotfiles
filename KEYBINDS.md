# Keybinds — карта биндов ригов

Единая справка по горячим клавишам всех риг-профилей. Цель:
- **человеку** — быстро найти/раскидать кнопки, увидеть повторы и дырки;
- **спеке / Claude** — понять, какие бинды образуют **кросс-риг контракт** (обязаны
  быть в каждом риге, в т.ч. в новом end-4), а какие риг-нативные и переносу не подлежат.

> Обновлять при любой правке биндов. Дата последней сверки: **2026-07-15**.

---

## 1. Как биндируется каждый риг (источники правды)

| Риг | Движок | Файлы биндов (порядок загрузки) |
|---|---|---|
| **ilyamiro** | hyprlang | 1) `profiles/ilyamiro/hypr/config/keybindings.conf` — **АВТОГЕН** из `settings.json`; 2) `.config/hypr-shared/binds-ilyamiro.conf` — грузится **последним**, `unbind`+`bind` перекрывает автоген; 3) `.config/hypr-shared/binds.conf` — общий свитчер |
| **caelestia** | hyprkcs (Lua) | 1) `profiles/caelestia/hypr/hyprland/keybinds.lua` — **живой**, риговые бинды; 2) `.config/hypr-shared/contract-binds.lua` — **общий контракт §2**, грузится последним |

⚠️ **Ловушки правки:**
- ilyamiro: не редактируй автоген `keybindings.conf` напрямую — снесётся при `dotprofile update`.
  Все переопределения кладём в `binds-ilyamiro.conf` (слой-оверрайд, переживает регенерацию).
- caelestia: `profiles/caelestia/hypr/legacy-hyprlang/hyprland/keybinds.conf` — **МЁРТВЫЙ** (старый
  до-hyprkcs сетап). Не грузится. Правь только `keybinds.lua`.
- Контракт §2 живёт в ОДНОМ файле — `.config/hypr-shared/contract-binds.lua`
  (владелец `shared`, переживает свитч рига). Для hyprlang-рига ilyamiro та же
  роль у `.config/hypr-shared/binds.conf` — hyprkcs не умеет `source=`, поэтому
  два формата остаются, но каждый в одном экземпляре.
- Контракт применяется ПОСЛЕДНИМ и снимает комбу перед своим биндом: ре-бинд в
  hyprkcs стекается, а не замещает (замерено 2026-09-02: 99 -> 187 биндов).
- **Оговорка lua require-кэш:** `hyprctl reload` может не подхватить правки
  `custom/*.lua` (кэш модулей) — часть биндов «не работает» до **полного свитча
  рига** (`dotprofile menu`). Касается caelestia (hyprkcs).

**Кросс-риг механизм:** риг-зависимые действия идут через `~/dotfiles/bin/rigdo <action>` —
диспетчер смотрит `profiles/active` и вызывает нужный шелл. Поэтому одна комбо работает в
любом риге и **переживает горячий свитч**.

---

## 2. ⭐ КРОСС-РИГ КОНТРАКТ (важно сохранить в каждом риге)

Эти бинды обязаны существовать на **одинаковых** комбо во всех ригах. Новый риг (end-4)
**должен** их реализовать (через `rigdo` или нативно). Это то, что «важно сохранить».

### 2.1 Действия через `rigdo` (идентичны, переживают свитч)

| Комбо | Действие | rigdo |
|---|---|---|
| `SUPER+SHIFT+D` | Свитчер риг-профилей | `dotprofile menu` |
| `SHIFT+TAB` | Лаунчер приложений | `rigdo launcher` |
| `SUPER+Y` | Обои | `rigdo wallpaper` |
| `SUPER+SHIFT+O` | Настройки шелла | `rigdo settings` |
| `SUPER+M` | Рестарт шелла | `rigdo shell` |
| `SUPER+F1` | Локскрин | `rigdo lock` |
| `SUPER+SHIFT+S` | Скриншот региона | `rigdo screenshot` |
| `SUPER+grave` (`` ` ``) | Буфер обмена | `rigdo clipboard` |
| `SUPER+B` | Батарея | `rigdo battery` |
| `SUPER+N` | Сеть | `rigdo network` |
| `SUPER+H` | Гайд/справка | `rigdo guide` |
| `SUPER+ALT+M` | Музыка (виджет) | `rigdo music` |
| `SUPER+ALT+S` | Календарь | `rigdo calendar` |
| `SUPER+ALT+P` | Кино/movies | `rigdo movies` |

> **Лаунчер только на `SHIFT+TAB`.** Легаси-дубль `SUPER+U` удалён (жал то же самое).

### 2.2 Окна

| Комбо | Действие |
|---|---|
| `SUPER+Q` | Закрыть окно *(единственная кнопка закрытия; `ALT+F4` снят)* |
| `SUPER+F` | Фуллскрин |
| `SUPER+ALT+F` | Фуллскрин с рамкой / maximized |
| `SUPER+ALT+Space` | Toggle floating |
| `SUPER+SHIFT+F` | Toggle floating (мнемоника F) |
| `SUPER+P` | Pin |
| `SUPER+I/J/K/L` | Фокус ↑/←/↓/→ *(стрелки-соло убраны, только IJKL)* |
| `SUPER+SHIFT+I/J/K/L` | Двигать окно ↑/←/↓/→ |
| `SUPER+ALT+I/J/K/L` | Ресайз окна |
| `ALT+Q` | Собрать окна в стек (группа/вкладки) |
| `ALT+TAB` | Цикл вкладок в группе |

### 2.3 Воркспейсы

| Комбо | Действие |
|---|---|
| `SUPER+A` / `SUPER+D` | Воркспейс −1 / +1 |
| `SUPER+scroll` | Воркспейс −1 / +1 |
| `SUPER+1..0` | На воркспейс N (мультимонитор через `wsaction.fish`) |
| `SUPER+SHIFT+1..0` | Перенести окно на воркспейс N |
| `SUPER+S` | Спец-воркспейс (scratchpad) |
| `SUPER+Z` | Музыка-плеер (feishin) special |
| `SUPER+X` | Общение (vesktop) special |
| `SUPER+C` | Todo (obsidian) special |
| `SUPER+V` | Мессенджер (AyuGram) special |
| `SUPER+SHIFT+X` | Вытащить окно из спец-воркспейса |
| `CTRL+J` / `CTRL+L` | Цикл спец-воркспейсов prev/next |

### 2.4 Приложения

| Комбо | Приложение |
|---|---|
| `SUPER+TAB` | Терминал (foot) |
| `SUPER+W` | Браузер (zen-browser) |
| `SUPER+R` | Редактор (codium) |
| `SUPER+E` | Файлы (thunar) |
| `SUPER+T` | Раскладка/hyprkcs |

### 2.5 Мышь

| Комбо | Действие |
|---|---|
| `SHIFT+drag` (btn 274) | Двигать окно |
| `CTRL+drag` (btn 274) | Ресайз окна |
| `SUPER+btn 272/273` | Перенести окно на ws −1/+1 |
| `SUPER+SHIFT+btn 272` | Вытащить на текущий ws |
| `SUPER+SHIFT+btn 273` | На `special:secret` |

### 2.6 Питание / gamemode

| Комбо | Действие |
|---|---|
| `SUPER+ALT+Escape` | Poweroff |
| `SUPER+G` | Gamemode submap (лочит клавиши, оставляет громкость) |

### 2.7 🔊 Железные клавиши (одни и те же в обоих ригах)

Клавиши **идентичны**; инструмент разный по нужде OSD (см. §5).

| Клавиша | Действие |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` | Громкость ± (шаг 5%) |
| `XF86AudioMute` | Мьют выхода |
| `XF86AudioMicMute` | Мьют микрофона |
| `XF86MonBrightnessUp` / `Down` | Яркость ± (шаг 5%) |

---

## 3. Уникально для ilyamiro

| Комбо | Действие | Почему только тут |
|---|---|---|
| `SUPER+SHIFT+T` | **FocusTime** — Pomodoro-таймер с трекингом сессий | quickshell-виджет + демон, есть только в шелле ilyamiro |
| `SUPER+RETURN` | Терминал (foot) — доп. к `SUPER+TAB` | нативный дефолт ilyamiro, оставлен |
| `SUPER+SHIFT+TAB` | Фокус на след. монитор | мультимонитор-риг |
| 3 пальца горизонт. | Свайп воркспейсов | `gesture` ilyamiro |
| `XF86MonBrightness*` → swayosd | OSD яркости | в этом риге стартует `swayosd-server` |

---

## 4. Уникально для caelestia

| Комбо | Действие | Почему только тут |
|---|---|---|
| `SUPER+SHIFT+R` | `caelestia record` — запись экрана | нужен caelestia-шелл |
| `ALT+SHIFT+R` | `caelestia record -s` — запись + звук | -//- |
| `SUPER+O` | `caelestia resizer pip` — Picture-in-Picture | -//- |
| `SUPER+SHIFT+N` | `caelestia scheme set -r` — рандом цветосхема | -//- |
| `SUPER+ALT+N` | Toggle тёмная/светлая тема | -//- |
| `CTRL+SHIFT+Escape` | `caelestia toggle sysmon` — системный монитор | виджет caelestia |
| `SUPER+ALT+F12` | Тест-нотификация | dev/тест |

> `SUPER+O` занят PiP только в caelestia — в ilyamiro эта комбо **свободна**.

---

## 5. Громкость и яркость — почему тул разный

Клавиши одни и те же в обоих ригах. Команда под клавишей отличается, потому что
**OSD-путь у ригов разный**:

| | ilyamiro | caelestia |
|---|---|---|
| Vol/Mic/Mute | `swayosd-client` | `wpctl` |
| Brightness | `swayosd-client --brightness` | `brightnessctl` |
| Кто рисует OSD | `swayosd-server` (в autostart **только этого** рига) | нативный OSD caelestia-шелла |

Новый риг: если в нём нет `swayosd-server` — вешай `wpctl`/`brightnessctl` и полагайся на
свой OSD; если есть — `swayosd`. Клавиши держи те же (XF86-железные).

---

## 6. Known issues / проверить

- **`SHIFT` vs `SHIFT_L`.** Автоген ilyamiro использует `SUPER SHIFT, N` для переноса на
  воркспейс, а `binds-ilyamiro.conf` снимает их через `unbind = SUPER SHIFT_L, N`. Если
  Hyprland различает эти модмаски — старый бинд не снимется и `SUPER+SHIFT+цифра` сработает
  дважды (`wsaction move` + `qs_manager move`). Проверить: `hyprctl binds | grep -A2 ', 1$'`.
- **Два источника правды у caelestia.** Живой `keybinds.lua` и мёртвый `legacy-hyprlang/keybinds.conf`
  расходятся (в legacy нет IJKL, нет яркости). Legacy стоит удалить/пометить, чтобы больше
  никто не правил его по ошибке. См. `docs/tech-debt.md`.
- **Свитчер в двух файлах.** `SUPER+SHIFT+D` в `binds.conf` и `hypr-user.lua` — держать в синхроне.

---

## 7. Свободные слоты (для новых биндов)

Сетка `SUPER+<буква>` почти забита в обоих ригах. Реально свободно:

- **`SUPER+O`** — свободен в ilyamiro (в caelestia = PiP).
- **`SUPER+U`** — освобождён (был дубль лаунчера).
- **`SUPER+CTRL+стрелки`** — освобождены (был легаси movewindow).

Занятая сетка `SUPER+<буква>` (оба рига): A D E F G H I J K L M N P Q R S T V W Y Z + спец.
