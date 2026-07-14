# Shalyn42k — dual-rig Hyprland dotfiles

![Preview](preview.png)

Два полных Hyprland-рига в одном репозитории с горячим переключением:

| Риг | База | Конфиг-движок | Шелл |
| :--- | :--- | :--- | :--- |
| **caelestia** | [caelestia-dots](https://github.com/caelestia-dots/caelestia) | lua (`hyprland.lua`) | caelestia shell (quickshell) |
| **ilyamiro** | [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots) | hyprlang (`hyprland.conf`) | кастомный quickshell |

Переключение — `SUPER+SHIFT+D` (меню fuzzel) или из SDDM (две отдельные сессии).

## Установка

```bash
git clone git@github.com:shalyn42k/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

`bootstrap.sh` идемпотентен: ставит пакеты (pacman → yay/paru), проверяет caelestia shell,
раскладывает симлинки (живые каталоги бэкапятся в `*.pre-bootstrap`), ставит matugen-шаблоны,
кладёт SDDM-сессии (подменяя захардкоженный `$HOME`) и рендерит генерируемые конфиги.

> Hyprland нужен с lua config provider (0.55+, сборка CachyOS или git) — риг caelestia живёт на `hyprland.lua`.

## Структура

```
bin/
  dotprofile   переключатель ригов (switch/menu/status/update/colors)
  rigdo        риг-зависимый диспетчер действий (лаунчер, скриншот, лок...)
  hypr-exec    запуск команды через Hyprland независимо от конфиг-движка
profiles/
  active -> caelestia|ilyamiro   симлинк активного рига
  caelestia/   снапшот рига: hypr, gtk-3.0/4.0, qt5ct/qt6ct + session.sh
  ilyamiro/    то же + скрипты quickshell-шелла + matugen-шаблоны
.config/
  hypr-shared/ общие бинды + порт-конфиги для ilyamiro (binds/rules/settings)
  caelestia/ fish/ foot/ fastfetch/   не-контестируемые конфиги (общие)
sddm/          .desktop-файлы двух wayland-сессий
docs/specs/    спеки на фичи
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
- **fastfetch** → `.config/fastfetch/config.jsonc` из `config.jsonc.template` (gitignored)

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
