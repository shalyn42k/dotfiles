# dotprofile — переключатель риг-профилей (caelestia ⇄ ilyamiro)

Дата: 2026-07-13
Статус: дизайн утверждён, ждёт implementation-план

## Цель

Жить на двух ригах (caelestia и ilyamiro/imperative-dots) на одной системе
(Arch + Hyprland + SDDM) и переключаться между ними:

- чисто — выбором сессии на экране входа SDDM;
- горячо — биндом `Super+Shift+D` → меню (fuzzel/rofi) без relogin.

Кастомные бинды и настройки пользователя работают в обоих ригах из одного файла.
Весь сетап воспроизводим с нуля одной командой (`bootstrap.sh`).

## Не-цели

- Не патчим код caelestia или ilyamiro (ни shell, ни cli).
- Не коммитим чужие дотсы целиком в репо (кроме рабочего снапшота
  hypr-профиля ilyamiro — см. «Владение файлами»).
- Не добиваемся 100% чистоты горячего переключения: env-переменные и темы
  уже открытых окон обновляются только после relogin. Принято.

## Структура репо `~/dotfiles`

```
~/dotfiles/
├── .config/
│   ├── caelestia/               # user-конфиг caelestia (как сейчас)
│   ├── fish/ foot/ fastfetch/   # профиленезависимые (как сейчас)
│   └── hypr-shared/
│       └── binds.conf           # кастомные бинды, общие для обоих ригов
├── profiles/
│   ├── caelestia/
│   │   ├── hypr/                # текущий .config/hypr (hyprkcs: hyprland.lua и др.)
│   │   ├── gtk-3.0/ gtk-4.0/ qt5ct/ qt6ct/
│   │   └── session.sh           # start/stop демонов рига
│   ├── ilyamiro/
│   │   ├── hypr/                # снапшот после install.sh
│   │   ├── gtk-3.0/ gtk-4.0/ qt5ct/ qt6ct/
│   │   └── session.sh
│   └── active                   # симлинк на активный профиль; в .gitignore
├── bin/
│   └── dotprofile               # скрипт свитчера
├── sddm/
│   ├── sddm-silent/             # тема (уже есть)
│   ├── hyprland-caelestia.desktop
│   └── hyprland-ilyamiro.desktop
├── bootstrap.sh
└── docs/specs/                  # этот документ
```

## Симлинки

```
~/.config/hypr     → ~/dotfiles/profiles/active/hypr
~/.config/gtk-3.0  → ~/dotfiles/profiles/active/gtk-3.0
~/.config/gtk-4.0  → ~/dotfiles/profiles/active/gtk-4.0
~/.config/qt5ct    → ~/dotfiles/profiles/active/qt5ct
~/.config/qt6ct    → ~/dotfiles/profiles/active/qt6ct
~/dotfiles/profiles/active → profiles/<имя>     # единственная точка переключения
```

Переключение профиля = один атомарный `ln -sfn` на `active`.
Остальные симлинки (`fish`, `foot`, `caelestia`, …) не меняются.

## Компоненты

### 1. `bin/dotprofile` (bash)

- `dotprofile switch <name> [--links-only]`
  1. проверka: профиль существует;
  2. `ln -sfn profiles/<name> profiles/active`;
  3. без `--links-only`: `profiles/<старый>/session.sh stop` →
     `hyprctl reload` → `profiles/<name>/session.sh start`.
- `dotprofile menu` — fuzzel/rofi со списком профилей (активный помечен),
  выбор → `switch`.
- `dotprofile update ilyamiro` — `switch ilyamiro --links-only` → распаковка
  симлинков в реальные каталоги (installer пишет в `~/.config/hypr` напрямую)
  → запуск его `install.sh` → снапшот спорных каталогов обратно в
  `profiles/ilyamiro/` → восстановление симлинков.
- `dotprofile status` — какой профиль активен, целы ли симлинки.

### 2. `session.sh` (по одному на профиль)

Контракт: `session.sh start|stop`.

- caelestia: start = запуск caelestia shell (как в её exec-once);
  stop = `pkill quickshell`, погасить её демоны.
- ilyamiro: start = его quickshell + `swww-daemon`; stop = `pkill quickshell`,
  `pkill mpvpaper`, `pkill swww-daemon`.

Точные списки фиксируются при установке по факту (из exec-once обоих ригов).
Это единственный файл, который правится вручную при изменениях у авторов.

### 3. SDDM-сессии

`sddm/hyprland-{caelestia,ilyamiro}.desktop` → копируются в
`/usr/share/wayland-sessions/` (sudo, при bootstrap). Exec каждой:
обёртка `dotprofile switch <name> --links-only && <штатный запуск Hyprland>`.
SDDM запоминает последний выбор пользователя.

### 4. Общие бинды

`.config/hypr-shared/binds.conf` (hyprlang). Подключение:

- caelestia-профиль: через существующий механизм user-конфига
  (`~/.config/caelestia/hypr-user.lua` / include в hyprkcs-конфиге);
- ilyamiro-профиль: `source = ~/dotfiles/.config/hypr-shared/binds.conf`
  в его пользовательском include.

Бинд свитчера `Super+Shift+D → dotprofile menu` живёт в этом файле.

### 5. `bootstrap.sh` (новая машина)

1. пакеты pacman/AUR по списку (включая зависимости обоих ригов);
2. caelestia апстримом: `caelestia-cli install`;
3. ilyamiro апстримом: его `install.sh` (опции SDDM / zsh / nvidia — отказ);
4. разложить спорные каталоги по `profiles/`, поставить симлинки;
5. скопировать sddm-файлы (sudo), активировать профиль по умолчанию.

Идемпотентен: повторный запуск ничего не ломает.

## Владение файлами

| Что                        | Владелец      | Обновляется как             |
|----------------------------|---------------|------------------------------|
| caelestia shell/cli        | апстрим/pacman| как сейчас, без изменений    |
| user-конфиг caelestia      | твой репо     | руками, git                  |
| hypr-профиль ilyamiro      | твой репо (снапшот) | `dotprofile update ilyamiro` |
| gtk/qt обоих профилей      | твой репо (снапшот) | вместе с профилем      |
| dotprofile, session.sh, sddm, bootstrap | твой репо | руками, git       |

## Порядок внедрения (миграция без потерь)

1. Бэкап: tar спорных каталогов (`~/.config/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct}`).
2. Переезд текущего `~/dotfiles/.config/hypr` → `profiles/caelestia/hypr`;
   снапшот текущих gtk/qt туда же; симлинки; `active → caelestia`.
   Проверка: relogin, caelestia работает как раньше. Точка отката №1.
3. Скрипт `dotprofile` + sddm-сессии + общие бинды. Проверка на одном профиле.
4. Установка ilyamiro (`install.sh`, отказ от SDDM/zsh/nvidia),
   снапшот в `profiles/ilyamiro`, его `session.sh`.
5. Тест: переключение через SDDM в обе стороны → горячий бинд в обе стороны.
6. Коммит + push.

## Риски и компромиссы (приняты)

- Горячий switch не меняет env/темы открытых окон — до relogin.
- Установщик ilyamiro содержит телеметрию (заявлена анонимной).
- Качество рига ilyamiro на данном железе неизвестно до установки;
  откат = удалить профиль, `active → caelestia`.
- v2 ilyamiro (~2-3 мес): структура его конфигов изменится → пересмотр
  `session.sh` и снапшота. Архитектура свитчера не меняется.
- Известное ограничение по памяти сессии: у caelestia есть локальный патч
  (Thunar animation fix) — при обновлениях caelestia он живёт по своим
  правилам, свитчер его не трогает и не чинит.
