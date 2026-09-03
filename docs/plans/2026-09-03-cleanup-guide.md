# Гайд по уборке: пакеты и остатки end4

Задача для следующей сессии. Всё ниже — **проверено на машине 2026-09-03**,
не по памяти. Команды приведены, но решение по каждому пункту принимает
человек: удаление пакетов необратимо в том смысле, что переустановка требует
рабочих зеркал, а они сейчас лежат (см. «Блокер» ниже).

---

## Блокер — СНЯТ 2026-09-03 вечером

Зеркала и подписи починены: DNS резолвит `cdn77.cachyos.org`, базы
синхронизировались (`/var/lib/pacman/sync/*.db` от 21:33–21:43), предупреждений
pacman больше нет. Удалять пакеты теперь можно.

Исходная проблема была такой:

```
error: failed retrieving file 'cachyos-znver4.db' from cdn77.cachyos.org
       : Could not resolve host: cdn77.cachyos.org
error: failed to connect to ftp.icm.edu.pl:80
error: cachyos-znver4: signature from "CachyOS <admin@cachyos.org>" is invalid
```

Три отдельные вещи: DNS не резолвит зеркало CachyOS, запасное польское зеркало
недоступно, а скачанные базы не проходят проверку подписи.

Оставлено здесь как запись: если зеркала лягут снова, симптом будет тот же.

Порядок разбирательства:

```bash
getent hosts cdn77.cachyos.org           # резолвится ли имя вообще
cat /etc/pacman.d/mirrorlist | head      # какие зеркала выбраны
sudo pacman-key --refresh-keys           # если проблема только в подписях
sudo pacman -Syy                         # форс-пересинхронизация баз
```

Подписи CachyOS чинятся переустановкой связки:
`sudo pacman -S cachyos-keyring` — но она сама тянется из тех же зеркал, так
что сеть первична.

---

## NoExtract — ИСПРАВЛЕНО 2026-09-03

```bash
grep -n "NoExtract" /etc/pacman.conf
```

Строки теперь стоят в `[options]` (строки 10–11), предупреждений нет.
Раньше они лежали в конце файла, внутри секции репозитория `[g14]`, где
`NoExtract` не директива. Pacman на каждом запуске печатает
`directive 'NoExtract' in section 'g14' not recognized` и игнорирует их —
значит пакетные SDDM-записи `hyprland.desktop` и `hyprland-uwsm.desktop
вернутся при первом же обновлении hyprland.

Починка (правит системный файл, нужен sudo):

```bash
sudo sed -i '/^NoExtract   = usr\/share\/wayland-sessions\//d' /etc/pacman.conf
sudo sed -i '/^\[options\]/a NoExtract   = usr/share/wayland-sessions/hyprland.desktop\nNoExtract   = usr/share/wayland-sessions/hyprland-uwsm.desktop' /etc/pacman.conf
grep -n -A3 '^\[options\]' /etc/pacman.conf
```

`bootstrap.sh` уже исправлен и вставляет в `[options]`; правится только живой
файл.

---

## Остатки end4

Риг удалён из репозитория 2026-09-02, но на диске осталось. Всё это **вне
репозитория**, git о нём ничего не знает.

| Путь | Размер | Что это |
| :--- | :--- | :--- |
| `~/qs-test-prefix` | 13 МБ | локальная март-сборка quickshell под ii-шелл |
| `~/src/dots-hyprland` | 24 МБ | клон апстрима end-4 |
| `~/.config/illogical-impulse` | 24 КБ | конфиг его шелла |
| `~/.local/state/quickshell/user` | 52 КБ | его состояние (colors.json и пр.) |

```bash
rm -rf ~/qs-test-prefix ~/src/dots-hyprland ~/.config/illogical-impulse
rm -rf ~/.local/state/quickshell/user
```

**Проверить перед удалением**, что `~/.local/state/quickshell/user` не нужен
кому-то ещё: каталог `~/.local/state/quickshell/` общий для всех конфигов
quickshell, удалять надо только подкаталог `user`.

Кеш-сироты от обоих удалённых ригов:

```bash
rm -f ~/.cache/matugen/{discord,obsidian}-end4.* ~/.cache/matugen/{discord,obsidian}-ilyamiro.*
```

Ещё из хендоффа 2026-09-02, до сих пор не сделано — сироты старой раскладки
модулей caelestia в системном каталоге:

```bash
sudo rm -rf /usr/lib/qt6/qml/Caelestia/{caelestia.qmltypes,libcaelestiaplugin.so,Internal} \
            /usr/lib/qt6/qml/Caelestia/lib/libcaelestia.so
```

Они инертны (`qmldir` на них не ссылается), но собраны под Qt 6.10 и только
путаются под ногами.

---

## Пакеты

### Сироты

В системе **51 пакет-сирота** (`pacman -Qtdq` — установлены как зависимость,
но больше никем не требуются). Большинство к ригам отношения не имеет
(`dolphin`, `go`, `fontforge`, `bluedevil`…) — это следы других экспериментов,
и трогать их в рамках этой задачи не надо.

Похожие на риг-хлам:

| Пакет | Комментарий |
| :--- | :--- |
| `electron39`, `electron40-bin`, `electron40-bin-debug` | обсидиан сейчас требует `electron43`; эти три ничем не заняты |
| `swayosd-git-debug` | сам `swayosd-git` уже не стоит, остался только debug-пакет |
| `hyprkcs-git-debug` | debug-символы, сам `hyprkcs-git` нужен и стоит |
| `hyprlock`, `hyprshot` | проверить руками: locker'ом сейчас работает `caelestia lock` / `serpantinum lock` |

Прежде чем удалять **каждый**:

```bash
pacman -Qi <пакет> | grep -E "Required By|Optional For"
```

`-debug` пакеты безопасны к удалению всегда — это только символы.

```bash
sudo pacman -Rns electron39 electron40-bin electron40-bin-debug swayosd-git-debug hyprkcs-git-debug
```

`electron40-bin` стоит проверить отдельно: если какое-то AUR-приложение пинит
именно его, `-Rns` предупредит и откажется.

### Расхождение bootstrap с реальностью

`bootstrap.sh` перечисляет пять пакетов, которых в системе нет:

| Пакет | Что с ним |
| :--- | :--- |
| `matugen-bin` | заменён обычным `matugen 4.2.0` — **поправить в bootstrap**, иначе чистая установка поставит второй |
| `swayosd-git` | был OSD рига ilyamiro; рига нет — **убрать из bootstrap** |
| `gammastep` | ночной фильтр; у serpantinum эту роль играет `wl-gammarelay-rs` — **убрать** |
| `trash-cli` | не установлен, но полезен и упоминается в execs — решить: ставить или убрать из списка |
| `volantes_cursors` | тема курсора; файлы в `/usr/share/icons/volantes_cursors` ЕСТЬ, но **ни один пакет ими не владеет** — поставлены вручную. Работает, но не управляется: чистка `/usr/share/icons` унесёт их без возможности переустановить. Поставить пакетом поверх |

То есть правки в `bootstrap.sh`: `matugen-bin` → `matugen`, выкинуть
`swayosd-git` и `gammastep`, решить судьбу `trash-cli`, и либо поставить
`volantes_cursors`, либо убрать ссылки на него из тем ригов.

### Что НЕ трогать, хотя выглядит ненужным

Эти стоят, никем не требуются, но используются напрямую конфигами:

| Пакет | Кем используется |
| :--- | :--- |
| `awww`, `mpvpaper` | обои (`mpvpaper` — видео) |
| `cava` | matugen-шаблон `cava-colors.ini.template` рендерит ему тему |
| `foot` | терминал контракта, `SUPER+TAB` |
| `satty`, `zbar` | скриншот-конвейер |
| `easyeffects` | поднимается автостартом serpantinum |
| `geoclue` | геолокация для ночного фильтра |

`pacman -Qtdq` их не покажет как сирот только потому, что они установлены явно;
но и «required by: None» тут не значит «не нужен».

---

## Порядок работ

1. ~~Починить зеркала и подписи~~ — сделано.
2. ~~Поправить `NoExtract`~~ — сделано.
3. Удалить остатки end4 с диска и кеш-сироты.
4. Поправить список пакетов в `bootstrap.sh`.
5. Пакеты-сироты — по одному, с проверкой `Required By`, начиная с `-debug`.

После каждого шага: `bin/dotprofile doctor` и `tests/run.sh` должны оставаться
зелёными, а `SUPER+SHIFT+D` — открывать свитчер.
