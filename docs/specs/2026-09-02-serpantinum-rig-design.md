# Дизайн: ilyamiro → serpantinum, сведение всех ригов на lua

Заведён 2026-09-02, в день архивации апстрима.

## Что случилось

`ilyamiro/imperative-dots` **архивирован** 2026-09-02. Последний коммит —
`archive notice`, финальный `DOTS_VERSION="2.0.0"`. Проект переехал в
`ilyamiro/serpantinum` и сменил природу: из дотфайлов стал шеллом.

Из README про миграцию с v1:

> All previous configuration will be backed up and unused. Configuration of
> compositor settings such as monitors, keybinds, and autostart is now up to
> you, as the project migrated from being dotfiles to being a shell.

Это ровно тот не-инвазивный v2, которого ждали с мая (см. память
`ilyamiro-v2-unlock`). Ждали ~4 месяца.

## Почему это важно сейчас

`docs/tech-debt.md` п.1 и п.2 держатся на одном факте: ilyamiro — единственный
риг на hyprlang, caelestia и end4 на lua. Отсюда два источника правды, ручные
порты правил/анимаций/биндов, `rigdo`, `hypr-exec`, `animations-runtime.*`,
сломанный `hyprctl reload` и хот-свитч, который всё равно требует релогина.

**У serpantinum конфиг композитора написан на lua:**

```
compositors/hyprland/hyprland.lua
compositors/hyprland/config/{variables,env,autostart,monitors,settings,keybinds}.lua
```

И это не «похожий диалект», а тот же `hl`-API, что у нас:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("serpantinumd start")
end)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
```

То есть hyprlang-ветка исчезает **у источника**. Не мост, не генератор — просто
её больше нет. Все три рига становятся однодвижковыми, одна сессия хостит
любой, хот-свитч перестаёт быть обходом ограничения Hyprland.

## Разведка (проверено на 2026-09-02)

| Факт | Значение |
| :--- | :--- |
| Версия | 2.0.6, коммиты в день проверки |
| Природа | quickshell-конфиг: `src/quickshell/Shell.qml` + `bin/serpantinum`, `bin/serpantinumd` |
| Композиторы | `compositors/{hyprland,niri,sway}` |
| Вендорится? | Да — `serpantinumd` уважает `$SERPANTINUM_DIR`, ищет `Shell.qml` под ним |
| Недостающие зависимости | **одна**: `wl-gammarelay-rs`. Остальные 59 уже стоят с v1 |
| Nix | есть flake + NixOS/HM модули (нам не нужно) |

## Красная линия: не запускать их install.sh

`install/modules/deps.sh` делает `sudo pacman -Syyu --noconfirm` — неинтерактивное
обновление всей системы — и ставит пакеты через `pacman -S --noconfirm`.
Плюс README прямо обещает, что предыдущая конфигурация будет отложена и не
использована.

В нашей схеме это недопустимо: репозиторий **и есть** живой конфиг
(`~/.config/hypr` — симлинк в `profiles/active/hypr`), их инсталлер снёс бы риг.

Поэтому 2026-09-02 обе кнопки «обновить» в старом профиле были разоружены
(коммит `d09578a`): они пайпили `install.sh` архивной репы прямо в `eval`.

**Ставим только вендорингом:** клон в репу + `$SERPANTINUM_DIR` + одна
зависимость руками.

## Требования

1. Рабочий ilyamiro не трогать, пока serpantinum не проверен. Откат бесплатный.
2. Никакого системного `install.sh`.
3. Профиль соблюдает существующий контракт рига: `role`, `session.sh`, `hypr/`,
   тема-каталоги (`gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct`, `matugen`).
4. Строки в виджетах — только английские (память `ui-text-english-only`).

## Шаги

### 1. Вендоринг

Клон serpantinum в `profiles/serpantinum/shell/` (pinned на тег/коммит, не
плавающий master). `session.sh` экспортирует `SERPANTINUM_DIR` на него.
Зависимость: `wl-gammarelay-rs`.

### 2. Каркас профиля

По шаблону `profiles/end4` (тоже lua-риг). `role` — пока пустой, `daily`
остаётся за ilyamiro до проверки.

### 3. Hypr-конфиг

`compositors/hyprland/config/*.lua` — не копировать вслепую: `monitors.lua`,
`env.lua` и `variables.lua` у нас свои. Взять `autostart.lua` (нужен
`serpantinumd start`) и свериться по `keybinds.lua`/`settings.lua` с нашими
общими биндами.

### 4. Проверка однодвижковости

Главный критерий приёмки: свитч caelestia ↔ end4 ↔ serpantinum **без релогина**.
Если работает — п.2 tech-debt закрыт, и следом можно сносить `rigdo`-кросс-ветки,
`hypr-exec`, `animations-runtime.keywords`, `disable_autoreload`.

### 5. Вывод ilyamiro из эксплуатации

Только после того как serpantinum отработал как daily. Удаление
`profiles/ilyamiro` закрывает п.1 tech-debt целиком: порты
`rules-ilyamiro.conf`, `settings-ilyamiro.conf`, `binds-ilyamiro.conf` уходят
вместе с ним.

### 6. Риски

- Наши бинды и его бинды могут конфликтовать — v1 «умно мержил» keybinds, v2
  этим не занимается, теперь это наша забота.
- Виджеты v1 (FocusTime, movies, таймер) в v2 могли переехать или исчезнуть;
  сверить по `CHANGELOG.md` перед тем как обещать паритет.
- Pin на коммит обязателен: апстрим коммитит по несколько раз в день.

## Оценка

Меньше, чем казалось: зависимостей не хватает одной, движок уже наш, инсталлер
не нужен. Основная работа — шаг 3 (свести его lua-конфиг с нашим) и шаг 4
(доказать хот-свитч).

## Что уже сделано

- `d09578a` — разоружён путь обновления старого профиля, версии смотрят на
  serpantinum информационно, ссылки перенацелены.
