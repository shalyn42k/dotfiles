# Keybinds — карта биндов ригов

Справка по горячим клавишам обоих риг-профилей: что работает, где работает и
какие комбы свободны под свои бинды.

> **Сверено 2026-09-04.** caelestia замерен живьём (`hyprctl binds` → 99 биндов,
> 94 уникальные комбы). serpantinum выведен из кода — живьём его замерить можно
> только изнутри его сессии. Метод вывода проверен на caelestia: список,
> собранный из `keybinds.lua` + `variables.lua` + контракта, совпал с живым
> замером **точно, 92 из 92** (расходятся только `Caps_Lock`/`Num_Lock` —
> индикаторные бинды шелла, не пользовательские).

---

## 1. Откуда бинды берутся

| Риг | Порядок загрузки |
| :--- | :--- |
| **caelestia** | 1) `.config/hypr-shared/rigbinds.lua` — реестр владения (первой строкой)<br>2) `profiles/caelestia/hypr/hyprland/keybinds.lua` — набор рига<br>3) `.config/hypr-shared/contract-binds.lua` — контракт, **последним** |
| **serpantinum** | 1) `.config/hypr-shared/rigbinds.lua`<br>2) `shell/compositors/hyprland/config/keybinds.lua` — дефолты апстрима (submodule, **не править**)<br>3) `profiles/serpantinum/hypr/overrides.lua` — наши бинды поверх апстрима<br>4) `.config/hypr-shared/contract-binds.lua` — контракт, **последним** |

Два правила, из которых следует всё остальное:

- **`hl.bind` добавляет, а не замещает.** Повторная загрузка набора даёт не тот
  же список, а вдвое длиннее (замерено 2026-09-02: 99 → 187). Поэтому и
  `overrides.lua`, и контракт снимают комбу через `hl.unbind` перед тем как
  повесить своё.
- **Кто грузится последним — тот и выигрывает.** Контракт идёт последним
  намеренно: в нём `SUPER+SHIFT+D`, то есть сам свитчер. Уедь он вместе с
  набором рига — упавшая загрузка нового набора оставила бы систему без способа
  переключиться обратно.

**Как одна комба означает разное в разных ригах:** контрактные бинды зовут
`~/dotfiles/bin/rigdo <действие>`, а тот в момент нажатия читает
`profiles/active`. Поэтому контракт не надо переставлять на свитче — меняется
только результат.

---

## 2. Контракт — работает в обоих ригах

Комба одна, действие «то же по смыслу», реализация у каждого рига своя.

⚠️ **Не всё из этого реально что-то делает.** Ниже — во что `rigdo`
разворачивается на самом деле. Где «hint» — комба только показывает
уведомление, что такого виджета в риге нет.

| Комба | Действие | caelestia | serpantinum |
| :--- | :--- | :--- | :--- |
| `SUPER+SHIFT+D` | **Свитчер ригов** | `dotprofile menu` | `dotprofile menu` |
| `SHIFT+TAB` | Лаунчер | `shell drawers toggle launcher` | `msg toggle launcher` |
| `SUPER+M` | Рестарт шелла | `qs -c caelestia kill; qs -c caelestia -d` | `serpantinum reload` |
| `SUPER+F1` | Локскрин | global `caelestia:lock` | `serpantinum lock` |
| `SUPER+SHIFT+S` | Скриншот | global `caelestia:screenshotFreeze` | `serpantinum screenshot` |
| `SUPER+grave` | Буфер обмена | `pkill fuzzel \|\| caelestia clipboard` | `msg toggle clipboard` |
| `SUPER+Y` | Обои | ⚠ hint → `SUPER+SHIFT+N` | `msg toggle wallpaper` |
| `SUPER+N` | Сеть | ⚠ hint (виджета нет) | `msg toggle network` |
| `SUPER+H` | Гайд | ⚠ hint → `SUPER+T` | `msg toggle guide` |
| `SUPER+ALT+M` | Музыка (виджет) | ⚠ hint → `SUPER+Z` | `msg toggle music` |
| `SUPER+ALT+S` | Календарь | ⚠ hint (виджета нет) | `msg toggle calendar` |
| `SUPER+SHIFT+O` | Настройки | ⚠ hint (панели нет) | ⚠ hint → `SUPER+H` |
| `SUPER+B` | Батарея | ⚠ hint (виджета нет) | ⚠ **сломано**, см. §7 |
| `SUPER+ALT+P` | Кино | ⚠ hint | ⚠ hint |

**Счёт:** из 13 действий `rigdo` по-настоящему реализованы 5 в caelestia и 10 в
serpantinum. `movies` — заглушка в обоих, то есть `SUPER+ALT+P` не делает
ничего нигде.

---

## 3. Одинаково в обоих ригах

Эти комбы забайнджены и там и там, на одно и то же действие. Мышечная память
переезжает между ригами без переучивания — ради этого всё и делалось.

### 3.1 Окна

| Комба | Действие |
| :--- | :--- |
| `SUPER+Q` | Закрыть окно |
| `SUPER+F` | Фуллскрин |
| `SUPER+ALT+F` | Maximized (фуллскрин с рамкой) |
| `SUPER+ALT+Space` | Toggle floating |
| `SUPER+SHIFT+F` | Toggle floating (мнемоника F) |
| `SUPER+P` | Pin |
| `SUPER+I/J/K/L` | Фокус ↑/←/↓/→ |
| `SUPER+SHIFT+I/J/K/L` | Двигать окно ↑/←/↓/→ |
| `SUPER+ALT+I/J/K/L` | Ресайз окна (−10%/+10% от текущего) |
| `ALT+Q` | Собрать окна в группу (вкладки) |
| `ALT+TAB` | Следующая вкладка в группе |

### 3.2 Воркспейсы

| Комба | Действие |
| :--- | :--- |
| `SUPER+A` / `SUPER+D` | Воркспейс −1 / +1 |
| `SUPER+scroll` | Воркспейс −1 / +1 |
| `SUPER+1..0` | На воркспейс N |
| `SUPER+SHIFT+1..0` | Перенести окно на воркспейс N |
| `SUPER+S` | Скретчпад |
| `SUPER+Z` | Музыка — feishin |
| `SUPER+X` | Общение — vesktop |
| `SUPER+C` | Todo — obsidian |
| `SUPER+V` | Мессенджер — AyuGram |
| `SUPER+SHIFT+X` | Вытащить окно из спец-воркспейса на текущий |
| `CTRL+J` / `CTRL+L` | Цикл спец-воркспейсов prev / next |

`SUPER+Z/X/C/V` — «тоггл, если запущено, иначе запустить». caelestia матчит
feishin и AyuGram по имени процесса (`pgrep -x`), остальные по классу окна;
serpantinum матчит по классу всё, кроме AyuGram. Разница исторична и на
поведение не влияет.

`SUPER+1..0` реализованы по-разному: caelestia гоняет их через `wsaction.fish`
(нужен для мультимонитора), serpantinum — прямым `hl.dsp.focus`.

### 3.3 Приложения

| Комба | Приложение |
| :--- | :--- |
| `SUPER+TAB` | Терминал — kitty |
| `SUPER+W` | Браузер — zen-browser |
| `SUPER+R` | Редактор — codium |
| `SUPER+E` | Файлы — thunar |
| `SUPER+T` | Раскладка — hyprkcs |

Все пять уезжают через `app2unit` в свой systemd-скоуп и не умирают вместе с
процессом, который их запустил.

В serpantinum три из них апстрим занимал под своё (`SUPER+E` → nautilus,
`SUPER+R` → reload шелла, `SUPER+W` → тоггл обоев) — перевешены на контрактное.
Функции рига не потеряны: обои на `SUPER+Y`, рестарт шелла на `SUPER+M`.

### 3.4 Мышь

| Комба | Действие |
| :--- | :--- |
| `SHIFT` + drag (btn 274) | Двигать окно |
| `CTRL` + drag (btn 274) | Ресайз окна |
| `SUPER+SHIFT` + btn 272 | Вытащить окно на текущий воркспейс |
| `SUPER+SHIFT` + btn 273 | Отправить на `special:secret` |

### 3.5 Питание и gamemode

| Комба | Действие |
| :--- | :--- |
| `SUPER+ALT+Escape` | Poweroff |
| `SUPER+G` | Gamemode submap — вход и выход одной клавишей |

Gamemode лочит все бинды сессии, чтобы случайный `SUPER+Q` не закрыл окно в
игре. Громкость внутри сабмапа переопределена явно: сабмап отменяет **все**
бинды, включая XF86, и без этого регулятор в игре умер бы.

### 3.6 Железные клавиши

Клавиши одни и те же, инструмент под ними разный — потому что OSD рисуют разные
шеллы.

| Клавиша | caelestia | serpantinum |
| :--- | :--- | :--- |
| `XF86AudioRaiseVolume` / `Lower` | `wpctl` (шаг 5%) | `serpantinum volume raise/lower` |
| `XF86AudioMute` | `wpctl set-mute` | `serpantinum volume mute-toggle` |
| `XF86AudioMicMute` | `wpctl set-mute` (source) | `serpantinum volume mic-toggle` |
| `XF86MonBrightnessUp` / `Down` | global `caelestia:brightnessUp/Down` | `serpantinum brightness raise/lower` |

Яркость в caelestia идёт через global шелла, а не прямым `brightnessctl`:
прямой вызов обходил хендлер шелла и OSD не рисовался.

### 3.7 Раскладка

`SUPER+SPACE` переключает pl ↔ ru в **обоих** ригах. Это xkb-опция
`grp:win_space_toggle` из `input.lua` каждого рига, а не бинд — **в
`hyprctl binds` её не видно**. Апстрим serpantinum вешал на ту же комбу
`playerctl play-pause`, и срабатывали оба: смена языка снимала плеер с паузы.
Мы её снимаем (`overrides.lua`), play-pause остаётся на `XF86AudioPlay/Pause`.

---

## 4. Только caelestia

Требуют `caelestia`-шелл, в serpantinum эти комбы **свободны**.

| Комба | Действие |
| :--- | :--- |
| `SUPER+O` | `caelestia resizer pip` — картинка в картинке |
| `SUPER+SHIFT+R` | `caelestia record` — запись экрана |
| `ALT+SHIFT+R` | `caelestia record -s` — запись со звуком |
| `SUPER+SHIFT+N` | `caelestia scheme set -r` — случайная цветосхема |
| `SUPER+ALT+N` | Toggle тёмная / светлая тема |
| `CTRL+SHIFT+Escape` | `caelestia toggle sysmon` — системный монитор |
| `SUPER+ALT+F12` | Тест-нотификация (dev) |

---

## 5. Только serpantinum

Дефолты апстрима, которые мы не трогали. В caelestia эти комбы **свободны**.

| Комба | Действие |
| :--- | :--- |
| `SUPER+←/→/↑/↓` | Фокус (дубль к `SUPER+IJKL`) |
| `SUPER+SHIFT+←/→/↑/↓` | Ресайз окна на ±50 px |
| `SUPER+CTRL+←/→/↑/↓` | Двигать окно |
| `SUPER+RETURN` | Терминал (дубль к `SUPER+TAB`) |
| `ALT+F4` | Закрыть окно (дубль к `SUPER+Q`) |
| `Print` | Скриншот региона |
| `SHIFT+Print` | Скриншот региона с редактором |
| `SUPER+Print` | Скриншот всего экрана |
| `SUPER+SHIFT+Print` | Весь экран с редактором |
| `XF86PowerOff` | Локскрин |
| `XF86AudioPlay` / `XF86AudioPause` | `playerctl play-pause` |
| `SUPER` + drag btn 272 / 273 | Двигать / ресайзить окно |

Апстримовый `SUPER+L` (локскрин) перекрыт нашим фокусом вправо — локскрин живёт
на контрактном `SUPER+F1` и на `XF86PowerOff`.

---

## 6. Свободные комбы

Посчитано вычитанием union обоих ригов (113 занятых комб) из сетки
`SUPER` × {—, SHIFT, CTRL, ALT} × {A–Z, спецклавиши}.

### 6.1 Свободно в обоих ригах — бери и вешай

| Префикс | Буквы | Спецклавиши |
| :--- | :--- | :--- |
| `SUPER+` | **U** | `space`\*, `Escape`, `F2`–`F12` |
| `SUPER+SHIFT+` | A B C E G H M P Q T U V W Y Z | `grave` `TAB` `RETURN` `space` `Escape` `F1`–`F12` |
| `SUPER+CTRL+` | **вся сетка A–Z** | `grave` `TAB` `RETURN` `space` `Escape` `Print` `F1`–`F12` |
| `SUPER+ALT+` | A B C D E G H O Q R T U V W X Y Z | `grave` `TAB` `RETURN` `Print` `←→↑↓` `F1`–`F11` |

\* `SUPER+space` занят xkb-раскладкой (§3.7) — в `hyprctl binds` не виден, но
трогать его нельзя.

**`SUPER+CTRL+` — самый большой запас: свободен целиком.** Единственное
исключение — стрелки, их занимает serpantinum (§5).

**`SUPER+U`** — единственная свободная голая `SUPER+<буква>`. Была дублем
лаунчера, освобождена.

### 6.2 Свободно только в одном риге

Годится для риг-специфичной кнопки, но не для контракта — «одна клавиша значит
в ригах разное» это ровно то, что контракт запрещает.

- **Свободно в serpantinum:** `SUPER+O`, `SUPER+SHIFT+R`, `SUPER+SHIFT+N`,
  `SUPER+ALT+N`, `SUPER+ALT+F12`, `ALT+SHIFT+R`, `CTRL+SHIFT+Escape`
- **Свободно в caelestia:** `SUPER+RETURN`, `ALT+F4`, `Print` (все варианты),
  `SUPER+←→↑↓`, `SUPER+SHIFT+←→↑↓`, `SUPER+CTRL+←→↑↓`, `XF86PowerOff`,
  `XF86AudioPlay/Pause`

### 6.3 Как добавить бинд

Кросс-риг (обязан работать в любом риге) → `.config/hypr-shared/contract-binds.lua`
через `rigdo`, плюс ветка в `bin/rigdo`. Риг-нативный → `keybinds.lua` рига
(caelestia) или `overrides.lua` (serpantinum, через `rebind`, не `hl.bind`).

Апстрим serpantinum (`profiles/serpantinum/shell/`) — submodule, править нельзя:
перезапишется при `rig-update`. Всё поверх него идёт в `overrides.lua`.

---

## 7. Известные проблемы

**`SUPER+B` в serpantinum — тупик.** Апстрим вешал на неё `msg toggle system`
(системная панель, там же заряд батареи). Контракт грузится последним и
перебивает её на `rigdo battery`, а ветка `serpantinum` в `rigdo` только
показывает подсказку «battery lives in the system panel (SUPER+B)» — то есть
отсылает к самой себе. Системная панель с клавиатуры недостижима.
Чинится одной строкой в `bin/rigdo`: `"$SERP" msg toggle system` вместо hint.

**Бинды не переключаются на горячем свитче.** `dotprofile switch` меняет
симлинки, цвета, правила окон и шелл, но стадию `binds` намеренно отключена
(`bin/dotprofile:405`) — снос набора через хендлы ронял композитор (два SIGSEGV
2026-09-02, оба в `CLuaKeybind::push`). Следствие: до релогина на комбах висят
бинды **обоих** ригов сразу. Замерено 2026-09-04 в сессии, где
`profiles/active` уже был `serpantinum`, а `profiles/.last-lua` — ещё
`caelestia`: 113 биндов вместо 99, включая живые `SUPER+O` (PiP caelestia) и
`CTRL+SHIFT+Escape` (sysmon caelestia).

Контрактные комбы это переживают — они ходят через `rigdo`, который читает
`profiles/active` в момент нажатия, поэтому делают правильное сразу. Ломаются
именно риг-нативные: на одной комбе стреляют оба бинда.

Путь к починке — `docs/tech-debt.md` п.8: снимать через `hl.unbind(комба)`
вместо хендлов и проверять в отдельном headless-инстансе Hyprland, а не в
рабочей сессии.

**require-кэш lua.** `hyprctl reload` может не подхватить правки `*.lua`
из-за кэша модулей — часть биндов «не работает» до полного свитча рига
(`dotprofile menu`) или релогина.

---

## 8. Проверка

`tests/rig_contract_parity_test.lua` не даёт наборам разойтись молча: держит
список `RIG_ONLY` (§4 и §5) и падает, если риг-нативная комба просочилась в
контракт или контрактная потерялась.

```bash
tests/run.sh
```
