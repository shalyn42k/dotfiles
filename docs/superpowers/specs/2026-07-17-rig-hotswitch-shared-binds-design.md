# Быстрый хот-свитч lua-пары через общий источник биндов (без reload)

Дата: 2026-07-17
Статус: спека на ревью (Revision 2)
Заменяет lua-часть `2026-07-17-rig-switch-engine-split-design.md`. Релогин для
ilyamiro (кросс-движок) из той спеки — в силе. Меняется только пара
caelestia↔end4: вместо «reload + частично» — настоящий чистый хот-свитч.

## Проблема (что показал E2E)

`dotprofile switch` на lua-паре звал `hyprctl reload`. Reload перечитывает
конфиг ДРУГОЙ кодбазы (end4=illogical-impulse ↔ caelestia=свой) в тот же
процесс: `require()` кеширует модули, старые бинды/правила/env не сбрасываются →
наслоение, «свитч не происходит». Причина — не «lua vs hyprlang», а «один
процесс держит состояние двух чужих конфигов». Полное лечение кросс-движка —
релогин (см. предыдущую спеку). Но для lua-пары релогин избыточен, если убрать
источник грязи.

**Ключевой инсайт:** грязь идёт от `hyprctl reload`. Если бинды/правила —
общие/идентичные и загружены ОДИН раз при старте, их не надо переприменять на
свитче → **reload не нужен** → грязи нет. Слои, которые реально различаются
(бар, тема, анимации, правила), применяются точечно через `hyprctl eval`, а не
через reload.

## Решение

Хот-свитч lua↔lua (caelestia↔end4) **без `hyprctl reload`**:
- **Бинды** — один общий источник правды (lua-модуль), оба рига `require()` при
  старте. На свитче НЕ трогаются. Риг-зависимые действия маршрутизирует `rigdo`
  по `profiles/active` в рантайме — та же комба, разное меню.
- **Тема/анимации/правила** — у каждого рига свои, применяются точечно на свитче
  (`hyprctl eval`), без reload.
- **Шелл (бар)** — свап через `session.sh` stop/start (уже работает).
- **env** (end4 PATH под март-quickshell) — единственная мина, отдельный шаг.

Кросс-движок (ilyamiro) — по-прежнему релогин.

## Таксономия биндов (что где и как)

### A. Контракт §2.1 — общие комбо, rigdo-маршрутизация (РАЗНОЕ поведение)

Одна комба во всех ригах, `rigdo <action>` диспатчит в шелл активного рига.
**Это и есть «SHIFT+TAB вызывает разные меню».** `rigdo` читает
`profiles/active` → выбирает команду:

| Комба | Действие | caelestia | end4 |
| :--- | :--- | :--- | :--- |
| `SHIFT+TAB` | Лаунчер | `caelestia shell drawers toggle launcher` | `hl.dsp.global quickshell:searchToggleRelease` |
| `SUPER+Y` | Обои | (hint) | `quickshell:wallpaperSelectorToggle` |
| `SUPER+SHIFT+O` | Настройки | (hint) | `quickshell:sidebarRightToggle` |
| `SUPER+M` | Рестарт шелла | `qs -c caelestia kill; -d` | `pkill ii; $QS_II -c ii` |
| `SUPER+F1` | Локскрин | `caelestia:lock` | `loginctl lock-session` |
| `SUPER+SHIFT+S` | Скриншот | `caelestia:screenshotFreeze` | `quickshell:regionScreenshot` |
| `SUPER+grave` | Буфер | `caelestia clipboard` | `quickshell:overviewClipboardToggle` |
| `SUPER+H` | Гайд | (hint) | `quickshell:cheatsheetToggle` |
| `SUPER+ALT+M/S/P` | Музыка/календарь/кино | (hint) | mediaControls/sidebar/(нет) |

На свитче эти бинды **не меняются** — меняется только результат `rigdo`, потому
что `profiles/active` уже указывает на новый риг. Работает мгновенно.

### B. Контракт §2.2–2.6 — общие WM-бинды (ОДИНАКОВОЕ поведение)

Окна (`SUPER+Q/F/IJKL/...`), воркспейсы (`SUPER+A/D/1..0/S/Z/X/C/V`),
приложения (`SUPER+TAB/W/R/E/T`), мышь. Прямой `hyprctl dispatch`, риг-независимы.
Идентичны в обоих ригах → в общем источнике, на свитче не трогаются.

### C. Уникальные бинды рига (работают ТОЛЬКО в своём риге)

- **caelestia (§4):** `SUPER+SHIFT+R` запись, `SUPER+O` PiP, `SUPER+SHIFT+N`
  рандом-схема, `SUPER+ALT+N` тёмная/светлая, `CTRL+SHIFT+Esc` sysmon,
  `SUPER+SHIFT+R` — все зовут `caelestia <cmd>`, нужен caelestia-шелл.
- **end4:** свои ii-виджет-комбо (через `hl.dsp.global quickshell:*`).
- **ilyamiro (§3):** FocusTime и пр. — риг relogin-only, вне пары.

**Поведение при хот-свитче:** уникальные бинды загружены при старте (в общем
источнике для пары), но их команда осмысленна только при своём шелле. Нажатие
caelestia-уникального бинда в end4 → команда `caelestia ...` не находит своего
шелла → тихо ничего/ошибка. Приемлемо: уникальные фичи используешь в своём риге.
Опционально можно завернуть через `rigdo` с `hint`, но не обязательно.

### D. Громкость/яркость (§5) — общие клавиши, разный тул

XF86-клавиши одинаковы, но тул различается (caelestia: `wpctl`/`brightnessctl`;
end4: свой путь). **Решение:** в общем источнике вешаем универсальные
`wpctl`/`brightnessctl` — они меняют громкость/яркость на системном уровне в
обоих ригах. OSD-визуал может отличаться (свой у каждого шелла) — не критично.
Клавиши держим железные (XF86).

## Слои конфига при свитче — полный лог

`dotprofile switch <target>` (lua↔lua), пошагово:

```
1. ln -sfn <target> profiles/active ; ensure_links
      → symlinks gtk-3.0/gtk-4.0/qt5ct/qt6ct/matugen следуют за active
2. <old>/session.sh stop
      → убить старый бар (caelestia: qs -c caelestia kill / end4: pkill ii)
3. <target>/session.sh start
      → поднять новый бар (свежий процесс шелла)
4. apply_rig_colors <target>
      → бордюры (hyprctl eval hl.config) + gtk/qt тема + fastfetch/discord/obsidian
5. apply_rig_animations <target>
      → hyprctl eval dofile(<target>/animations-runtime.lua)
6. apply_rig_rules <target>            [НОВОЕ]
      → hyprctl eval dofile(<target> rules) — правила целевого рига
7. write profiles/.last-lua = <target>
      НЕТ hyprctl reload
      БИНДЫ не трогаются (общий источник, загружен при старте; rigdo роутит)
      ENV не трогается (см. мину №1)
```

### Результат по слоям

| Слой | У каждого рига свой? | Как на свитче | Чисто? |
| :--- | :--- | :--- | :--- |
| Бар/шелл | да | session.sh stop/start (шаг 2–3) | ✅ свежий процесс |
| Тема (цвета/gtk/qt) | да | apply_rig_colors (шаг 4) | ✅ (после фиксов тем, ниже) |
| Бордюры/гапсы | да | apply_rig_colors eval | ✅ |
| Анимации | да | apply_rig_animations dofile (шаг 5) | ✅ чисто |
| Window-rules | да | apply_rig_rules dofile (шаг 6) | ⚠ целевой выигрывает (добавлен последним); старые не снимаются, но целят классы закрытого шелла или перебиты; идеально — на релогине |
| Бинды §2.1 | общие, rigdo-роут | не трогаются; rigdo читает active | ✅ авто по ригу |
| Бинды §2.2–2.6 WM | общие идентичны | не трогаются | ✅ |
| Бинды §D vol/bright | общие клавиши, унив. тул | не трогаются | ✅ |
| Бинды §C уникальные | загружены при старте | не трогаются | ⚠ работают только в своём риге |
| env (PATH март-qs) | end4 | НЕ перезапускается на свитче | ⚠ мина №1 |

### Почему правила — «⚠», а не «✅»

Hyprland-правила накапливаются в живом компоновщике; нет чистого рантайм-«сбросить
все правила». `apply_rig_rules` добавляет правила целевого рига поверх — для
конфликтных общих классов (напр. `thunar` opacity 0.90 у end4 vs общая у caelestia)
**целевой выигрывает** (добавлен последним, оценивается последним). Правила старого
рига целят в основном классы уже закрытого чужого шелла → безвредны. Абсолютно
чисто правила только на релогине (свежий процесс). Для хот-свитча —
«достаточно правильно».

## Изменения по файлам (обзор; детали — в плане)

**Консолидация биндов (один источник правды):**
- Создать общий lua-модуль биндов (контракт §2.A/B + §D), напр.
  `.config/hypr-shared/binds-lua/contract.lua` (или `profiles/_shared/binds.lua`).
- caelestia (`.config/caelestia/hypr-user.lua` / `hypr/hyprland/keybinds.lua`) —
  `require()` общий модуль вместо своей копии контракта; оставить §4-уникальные.
- end4 (`profiles/end4/hypr/custom/keybinds.lua`) — `require()` общий модуль
  (после `unbind` ii-дефолтов); убрать ручной порт контракта.
- Итог: контракт — в ОДНОМ файле; правки не расходятся (уходит tech-debt #1 для
  lua-пары).

**Свитч без reload + правила:**
- `bin/dotprofile` `cmd_switch` (lua↔lua ветка): убрать `hyprctl reload`; добавить
  вызов `apply_rig_rules "$name"`.
- Добавить `apply_rig_rules()` (mirror `apply_rig_animations`): `hyprctl eval
  dofile(<rig>/rules-runtime.lua)`.
- Создать `rules-runtime.lua` на риг (standalone-обёртка над его rules, как
  `animations-runtime.lua`).

**env мина №1 (хот-свитч В end4):**
- `profiles/end4/session.sh` start — экспортить `PATH` с
  `~/qs-test-prefix/usr/bin` ПЕРЕД стартом ii-шелла и его ipc-вотчеров (сейчас
  это делает `custom/env.lua` только при старте рига). Или абсолютные пути для
  всех end4-процессов. Чтобы хот-свитч-внутрь-end4 давал рабочий ii-шелл без
  релогина.

**Отдельные баги тем (иначе «тема не применяется» останется):**
- `~/.config/matugen` — реальный каталог, `ensure_links` кладёт симлинк ВНУТРЬ
  (`matugen/matugen`) вместо замены. matugen не переключается по ригу. Починить
  ensure_links (снести реальный каталог/сделать корректный симлинк как у gtk).
- `profiles/end4/gtk-3.0/` пуст → свитч в end4 роняет gtk.css. Наполнить.
- gsettings gtk-theme глобальный — apply_rig_colors уже дёргает Adwaita-туда-сюда;
  проверить, что end4 имеет `gtk-theme-name` (иначе хак скипается).

## Что НЕ входит

- Конвертация ilyamiro в lua / v2 — ждём upstream.
- Уникальные бинды §C через rigdo-hint — опционально, не обязательно.
- Идеально-чистые правила на хот-свитче — принят компромисс (⚠), релогин даёт
  идеал.

## Проверка (E2E)

1. Логин hyprland-lua→caelestia. Бар caelestia, тема caelestia, анимации caelestia,
   SHIFT+TAB → caelestia-лаунчер.
2. `SUPER+SHIFT+D`→end4: бар→ii, тема→end4, анимации→end4, SHIFT+TAB→end4-поиск,
   `SUPER+Q/IJKL/1..0` работают идентично, БЕЗ наслоения. Быстро, без релогина.
3. Назад→caelestia: то же зеркально; SHIFT+TAB снова caelestia-лаунчер.
4. `SUPER+SHIFT+D`→ilyamiro: релогин (кросс-движок) — как в предыдущей спеке.
5. Правила: thunar-прозрачность соответствует активному ригу для нового окна.
6. Уникальный caelestia-бинд (`SUPER+O` PiP) в end4: тихо не срабатывает (ок).
