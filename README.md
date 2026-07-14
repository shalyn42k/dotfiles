# Shalyn42k — dual-rig Hyprland dotfiles

![Preview](preview.png)

Два полных Hyprland-рига в одном репозитории с горячим переключением:

| Риг | База | Роль | Конфиг-движок | Шелл |
| :--- | :--- | :--- | :--- | :--- |
| **caelestia** | [caelestia-dots](https://github.com/caelestia-dots/caelestia) | work | lua (`hyprland.lua`) | caelestia shell (quickshell) |
| **ilyamiro** | [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots) | daily | hyprlang (`hyprland.conf`) | кастомный quickshell |

Переключение — `SUPER+SHIFT+D` (меню fuzzel) или из SDDM (две отдельные сессии).

## Установка с нуля

Нужно: Arch-подобная система, `git`, AUR-хелпер (`yay`/`paru`), sudo.

```bash
git clone git@github.com:shalyn42k/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

**Чужие dotfiles качать не надо** — репозиторий содержит полные снапшоты обоих
ригов в `profiles/`. Скрипт ничего не клонирует со стороны, он только
раскладывает то, что уже есть:

1. **Пакеты** — ставит недостающие (pacman → yay/paru): Hyprland-стек, шеллы,
   foot/fish/fuzzel, matugen, утилиты. Список — в `PKGS` внутри скрипта.
2. **Caelestia shell** — единственный внешний компонент; если не найден,
   скрипт печатает варианты установки:
   `yay -S caelestia-shell-git` или сборка из
   [caelestia-dots/shell](https://github.com/caelestia-dots/shell).
3. **Симлинки** — контестируемые каталоги `~/.config/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct}`
   → `profiles/active/*`, общие `~/.config/{caelestia,fish,foot,fastfetch}` →
   `.config/*` репозитория. Живые каталоги не затираются — бэкап в
   `*.pre-bootstrap`.
4. **Matugen-шаблоны** — темы Discord/Obsidian рига ilyamiro в
   `~/.config/matugen/`.
5. **SDDM-сессии** — два `.desktop` в `/usr/share/wayland-sessions/`
   (с подстановкой твоего `$HOME`).
6. **Первичный рендер** — генерируемые конфиги (fastfetch) + статус.

Скрипт идемпотентен — повторный запуск ничего не ломает.

После установки:

1. Положи обои (jpg/png/mp4) в `~/Pictures/Wallpapers`.
2. Relogin через SDDM → сессия «Hyprland (caelestia)» или «Hyprland (ilyamiro)».
3. Переключение на лету: `SUPER+SHIFT+D`.

> Hyprland нужен с lua config provider (0.55+, сборка CachyOS или git) —
> риг caelestia живёт на `hyprland.lua`.

## Что в системе и за что отвечает

| Компонент | Зачем |
| :--- | :--- |
| `bin/dotprofile` | Ядро: переключение ригов (симлинк `profiles/active`), рендер цветов/тем, снапшоты после чужих installer'ов |
| `bin/rigdo` | Диспетчер действий по активному ригу: один бинд — разные команды (launcher, screenshot, lock…) |
| `bin/hypr-exec` | Запуск команд через Hyprland независимо от конфиг-движка (`dispatch exec` сломан под lua) |
| `profiles/<rig>/` | Полный снапшот рига: hypr, gtk, qt5ct/qt6ct, `session.sh` (старт/стоп шелла), `role`, `fastfetch.modules` |
| `.config/hypr-shared/` | Общие бинды и порт-конфиги, сорсятся обоими ригами |
| `.config/{fish,foot,fastfetch,caelestia}/` | Не-контестируемые конфиги — общие для всех ригов |
| Тем-пайплайн | Рамки, Discord, Obsidian, fastfetch следуют акценту активного рига |

## Структура

```
bin/
  dotprofile   переключатель ригов (switch/menu/status/update/colors)
  rigdo        риг-зависимый диспетчер действий (лаунчер, скриншот, лок...)
  hypr-exec    запуск команды через Hyprland независимо от конфиг-движка
profiles/
  active -> caelestia|ilyamiro   симлинк активного рига
  caelestia/   снапшот рига: hypr, gtk-3.0/4.0, qt5ct/qt6ct + session.sh
               + role (work) + fastfetch.modules (дата/время)
  ilyamiro/    то же + скрипты quickshell-шелла + matugen-шаблоны
               + role (daily) + fastfetch.modules (media, battery)
.config/
  hypr-shared/ общие бинды + порт-конфиги для ilyamiro (binds/rules/settings)
  caelestia/ fish/ foot/ fastfetch/   не-контестируемые конфиги (общие)
sddm/          .desktop-файлы двух wayland-сессий
docs/specs/    спеки на фичи
docs/plans/    планы реализации
```

`~/.config/{hypr,gtk-3.0,gtk-4.0,qt5ct,qt6ct}` — симлинки на `profiles/active/*`,
поэтому свитч рига = перекинуть один симлинк.

## dotprofile

```
dotprofile switch <name>   переключить риг (симлинки + цвета + анимации + шелл)
dotprofile menu            fuzzel-меню (SUPER+SHIFT+D)
dotprofile status          активный риг + состояние симлинков
dotprofile update <name>   материализовать конфиги, прогнать installer рига, снять снапшот
dotprofile colors          переприменить цвета активного рига (зовёт matugen-хук)
```

При горячем свитче runtime-командами применяются: цвета рамок и групп, анимации,
акцент fastfetch, тема Discord (Vencord) и CSS-сниппет Obsidian.

## rigdo

Бинды обоих ригов зовут `rigdo <action>` — команда выбирается по **активному** ригу
в момент нажатия, а не по тому, с чем стартовала сессия:
`launcher wallpaper settings music calendar movies clipboard screenshot lock shell battery network guide`.

## Тем-пайплайн

Один целевой файл на приложение, контент подменяется по ригу (`dotprofile colors`):

- **Discord** → `~/.config/{vesktop,equibop,Vencord}/themes/rig.theme.css`
- **Obsidian** → `<vault>/.obsidian/snippets/rig-theme.css`
- **fastfetch** → `.config/fastfetch/config.jsonc` из `config.jsonc.template`
  (gitignored): баннер и ключи красятся в акцент рига, в `{{RIG_MODULES}}`
  вставляется `profiles/<rig>/fastfetch.modules`. Строка `rig` динамическая —
  читает `profiles/active` + `profiles/<rig>/role` на каждом запуске.

Вариант ilyamiro генерит matugen из обоев (шаблоны в `profiles/ilyamiro/matugen/`,
хук `dotprofile colors` дёргается при смене обоев); вариант caelestia — статические
файлы в `profiles/caelestia/`.

## Известные особенности

- **Конфиг-движок фиксируется при старте сессии.** Горячий свитч на «чужой» движок
  меняет шелл/цвета/анимации, но бинды и правила WM полностью применятся после relogin.
- При кросс-движковом свитче dotprofile глушит auto-reload (`misc:disable_autoreload`) —
  иначе правка файлов загруженного рига триггерит reload и ошибку `cannot open hyprland.lua`.
- `hyprctl reload` не перечитывает закешированные `require()`-модули lua — изменения
  биндов caelestia требуют relogin.
- `hyprctl dispatch exec` не работает под lua-провайдером — используйте `bin/hypr-exec`.
- Анимации при свитче применяются из заранее переведённых файлов
  `profiles/*/animations-runtime.{lua,keywords}` (статическая трансляция).
- `profiles/*/hypr/scripts/quickshell/calendar/.env` (API-ключ погоды) — только локально,
  в gitignore.
