# Разделение свитчера по движку: hot-switch для lua-ригов, релогин для ilyamiro

Дата: 2026-07-17
Статус: спека на ревью

## Проблема

Hyprland выбирает конфиг-движок (lua или hyprlang) один раз при старте и на лету
не меняет. Сейчас все три рига — caelestia (lua), end4 (lua), ilyamiro (hyprlang)
— под одним горячим свитчером `dotprofile`, который пытается переключать риги
внутри живой сессии независимо от движка.

Наблюдаемые баги (из отчёта пользователя):

1. **Свитч в кросс-движковый риг не меняет WM.** Вход в SDDM в ilyamiro
   (hyprlang) → `SUPER+SHIFT+D` → caelestia (lua): меняются только userspace-слои
   (quickshell-бар, цвета рамок через `hyprctl keyword`), а бинды/правила/настройки
   WM остаются ilyamiro — они загружены при старте, движок сменить нельзя.
   Выглядит как «профиль не меняется».
2. **Наслоение.** Дальнейший свитч в end4 меняет shell+тему, но WM-слой заморожен
   на ilyamiro → «end4 наслаивается на ilyamiro».
3. **Рассинхрон GTK-тем** — вторичный симптом того же (частичное применение при
   кросс-движковом свитче + путь логина не зовёт `apply_rig_colors`).

Корень — tech-debt #2/#3: горячий свитч через симлинк `active` физически не может
двигать WM-слой, пока движок сессии ≠ движок цели.

## Решение (принято при брейншторме)

Свитч получает **два режима, режим выбирается автоматически по движку цели**:

```
цель.движок == запущенный.движок  →  ГОРЯЧИЙ СВИТЧ  (hyprctl reload, как сейчас)
цель.движок != запущенный.движок  →  РЕЛОГИН        (exit → SDDM greeter)
```

Движковая карта фиксирована:

| Риг       | Движок   |
| :-------- | :------- |
| caelestia | lua      |
| end4      | lua      |
| ilyamiro  | hyprlang |

Следствия:

- **caelestia ↔ end4** (lua ↔ lua): горячий свитч, `hyprctl reload` реально
  ребиндит WM. Работает по-настоящему.
- **любой ↔ ilyamiro** (пересечение lua/hyprlang): релогин.

ilyamiro в lua-порт **не** конвертируется: его shell (Quickshell settings-панель)
hardwired на hyprlang — `settings_watcher.sh` генерит из шаблонов чистый hyprlang
(`bind =`, `exec-once =`, `monitor =`) и делает `hyprctl reload`. Чистый lua-порт
требует форк генератора настроек — ровно то, что upstream v2 (non-invasive
quickshell) сделает сам. Ждём v2 (следить за master `DOTS_VERSION`); до v2
ilyamiro остаётся hyprlang и достаётся только релогином.

## Архитектура

### Режим-детект в `dotprofile switch`

`cmd_switch <name>` определяет движок цели (`profiles/<name>/hypr/hyprland.lua`
существует → lua, иначе hyprlang) и запущенный движок
(`hyprctl systeminfo` → `configProvider`):

- **Совпали** → текущая логика горячего свитча: свап `active`, `ensure_links`,
  stop старой `session.sh`, `hyprctl reload`, start новой `session.sh`,
  `apply_rig_colors`, `apply_rig_animations`.
- **Не совпали** → релогин-флоу (ниже). Живой свитч НЕ выполняется.

Меню (`cmd_menu`) не меняется по составу — всегда 3 рига с пометкой `(active)`.
Кросс-движковый выбор тихо уходит в релогин вместо печати
«note: … применятся после relogin».

### Релогин-флоу

При кросс-движковом `switch <name>`:

1. Свап симлинка `active` → `<name>` и `ensure_links` (чтобы следующая сессия
   стартовала с корректными симлинками; путь `--links-only` это уже делает).
2. Записать `~/.dmrc` `Session=<целевая .desktop>` — SDDM подсветит целевую
   сессию в грайтере.
3. Записать `profiles/.last-lua`, если цель — lua-риг (см. ниже).
4. Вызвать `exit.sh` (уже двухдвижковый: `hl.dsp.exit()` под lua,
   `dispatch exit` под hyprlang).
5. Hyprland выходит → SDDM грайтер с подсвеченной целью → пользователь вводит
   пароль → вход в целевую сессию, `session.sh` стартует темы с нуля.

Пароль сохраняется — это НЕ autologin.

### SDDM: 3 сессии → 2

| Было (`.desktop`)          | Стало (`.desktop`)         | Exec                                             |
| :------------------------- | :------------------------- | :----------------------------------------------- |
| `hyprland-caelestia`       | `hyprland-lua`             | `start-hyprland-profile <last-lua>` (деф. caelestia) |
| `hyprland-end4`            | (слит в `hyprland-lua`)    | —                                                |
| `hyprland-ilyamiro`        | `hyprland-ilyamiro`        | `start-hyprland-profile ilyamiro`                |

Один вход для lua-ригов; по дефолту caelestia; внутри `SUPER+SHIFT+D` горячо
свитчит на end4.

### `.last-lua` — правильный lua-риг после релогина

Кейс: из ilyamiro пользователь выбрал end4 → релогин должен привести в end4,
а не всегда в caelestia.

- `dotprofile` пишет имя рига в `profiles/.last-lua` при каждом свитче на
  lua-риг (и в горячем, и в релогин-режиме).
- `start-hyprland-profile` без явного аргумента (или сессия `hyprland-lua`)
  читает `profiles/.last-lua`; нет файла / битый → caelestia.
- `hyprland-ilyamiro.desktop` передаёт `ilyamiro` явно — `.last-lua` не трогает.

## Изменения по файлам

### Удалить (мёртвый кросс-движковый hot-switch)

- `profiles/caelestia/animations-runtime.keywords`,
  `profiles/end4/animations-runtime.keywords`,
  `profiles/ilyamiro/animations-runtime.keywords`,
  `profiles/active/animations-runtime.keywords` — hyprlang-переводы анимаций,
  применялись в живую hyprlang-сессию при хот-свитче. Свитч теперь lua-only
  (юзает `animations-runtime.lua`), ilyamiro не свитчится живьём. Единственный
  реальный читатель кода — `bin/dotprofile`.
- В `bin/dotprofile`, `cmd_switch`: ветка кросс-движка целиком
  (`disable_autoreload` true/false по провайдеру + печать
  «note: … применятся после relogin»). Заменяется релогин-триггером.
- В `bin/dotprofile`, `apply_rig_colors` и `apply_rig_animations`:
  hyprlang-ветки (`hyprctl keyword …`, чтение `animations-runtime.keywords`).
  Срабатывали только под hyprlang при хот-свитче → мертвы (свитч lua-only).
  Упростить до lua-веток.

### Оставить (нужны, не трогаем)

- `bin/rigdo` — риг-диспетчер действий (launcher/wallpaper/settings/shell/lock).
  Нужен для lua↔lua свитча (active меняется живьём) И внутри ilyamiro-сессии
  (её бинды зовут `rigdo`). Его провайдер-детект (`hypr_global`) остаётся: под
  ilyamiro сессия hyprlang.
- `bin/hypr-exec` — обход `dispatch exec` под lua. Зовут ilyamiro
  `appLauncher.qml` и `rigdo`.
- `.config/hypr-shared/binds-ilyamiro.conf`, `rules-ilyamiro.conf`,
  `settings-ilyamiro.conf` — порты caelestia→hyprlang, ilyamiro=caelestia-like.
  Решение пользователя: оставить (tech-debt #1 живёт до v2).
- `profiles/ilyamiro/hypr/scripts/exit.sh` — двухдвижковый, нужен для
  релогин-триггера.

### Изменить

- `bin/dotprofile`:
  - `cmd_switch`: детект движка цели vs запущенного → ветвление hot-switch /
    релогин.
  - Релогин-ветка: `active` swap + `~/.dmrc Session=` + `.last-lua` + `exit.sh`.
  - Писать `profiles/.last-lua` при свитче на lua-риг.
  - Упростить `apply_rig_colors`/`apply_rig_animations` до lua-only.
- `bin/start-hyprland-profile`: без аргумента / для lua-сессии читать
  `profiles/.last-lua` (дефолт caelestia); аргумент имеет приоритет.
- `sddm/`: `hyprland-caelestia.desktop` + `hyprland-end4.desktop` →
  один `hyprland-lua.desktop`; `hyprland-ilyamiro.desktop` без изменений по сути
  (проверить Exec).

## Что НЕ входит (вне скоупа)

- Конвертация ilyamiro в lua — ждём upstream v2.
- Форк генератора настроек ilyamiro.
- Overlay-маскировка чёрного экрана при релогине (память `rig-switcher-overlay`)
  — отдельная задача; здесь релогин через штатный SDDM-грайтер.
- Устранение tech-debt #1 (порты caelestia→hyprlang) — сознательно оставлено.
- Рассинхрон GTK как отдельные баг-фиксы (end4 пустой gtk-3.0, matugen не
  симлинкуется) — вторичны; частично снимаются тем, что релогин всегда зовёт
  `session.sh`/`apply_rig_colors`. Если останутся после этой работы — отдельный
  проход.

## Риски / открытые вопросы для реализации

- **`.dmrc` подсветка сессии**: проверить, что SDDM реально читает
  `~/.dmrc` `Session=` и подсвечивает соответствующую `.desktop` в грайтере на
  этой машине (тема sddm-silent). Если нет — цель просто не подсвечена, вход всё
  равно рабочий (ручной выбор).
- **`.last-lua` гонки**: файл пишется на свитче, читается на старте сессии —
  последовательно, гонки маловероятны. Битый/пустой → caelestia.
- **Проверить оставшиеся `disable_autoreload` в других местах** (README, доки —
  не код) не мешают.

## Проверка (как убедиться, что работает)

1. Вход в `hyprland-lua` → caelestia. `SUPER+SHIFT+D` → end4: WM ребиндится,
   темы end4, без наслоения. Назад в caelestia — так же.
2. Из lua-сессии `SUPER+SHIFT+D` → ilyamiro: exit → SDDM, ilyamiro подсвечен →
   вход → чистый ilyamiro, темы применены.
3. Из ilyamiro `SUPER+SHIFT+D` → end4: exit → SDDM, `hyprland-lua` подсвечен →
   вход → сессия стартует в end4 (через `.last-lua`), не caelestia.
4. `dotprofile status` корректен после каждого перехода.
