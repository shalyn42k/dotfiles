# Спек: fastfetch — риг-зависимый конфиг + новый дизайн

Статус: одобрено пользователем (2026-07-14).

## Проблема

1. Строка «Dots» захардкожена: `echo 'caelestia dots'` — врёт на ilyamiro.
2. Дизайн устарел: хардкод-red второй секции, рамки кривые, нет иконок,
   нет инфы под роль рига.

## Дизайн (утверждён)

Компоновка: ASCII-баннер **SHALYN42K** (один на все риги) в цвет акцента
активного рига + плоский список без рамок под ним.

### Общий список (все риги)

| строка | источник |
|---|---|
| rig — `<имя> · <роль>` | command: `basename $(readlink -f ~/dotfiles/profiles/active)` + `profiles/<name>/role` |
| os · kernel | command: `/etc/os-release` PRETTY_NAME + `uname -r` |
| wm · shell | command: `$XDG_CURRENT_DESKTOP` + `basename $SHELL` |
| cpu | модуль `cpu` (Ryzen 9 7940HS) |
| gpu | модуль `gpu`, `"hideType": "integrated"` (показывать RTX 4070, скрыть 780M) |
| ram | модуль `memory` |
| disk / | модуль `disk`, folders `/` |
| disk /mnt/data | модуль `disk`, folders `/mnt/data` |
| pkgs · uptime | command: `pacman -Qq \| wc -l` + `uptime -p` |
| риг-блок | `{{RIG_MODULES}}` (см. ниже) |
| цветные точки | модуль `colors` |

Ключи — nerd-иконки + имя, цвет ключей и баннера `{{ACCENT}}`,
значения — дефолтный белый. Хардкод-red удаляется.

### Риг-специфичные модули

Сниппет `profiles/<name>/fastfetch.modules` (фрагмент JSON-массива modules,
с завершающими запятыми), вставляется в `{{RIG_MODULES}}` при рендере:

- **caelestia (work)**: `datetime`.
- **ilyamiro (daily)**: `media` (now playing), `battery`.
- end4 (будущий): получит `role` + сниппет при портировании.

### Роль рига

Файл `profiles/<name>/role`, одно слово: caelestia → `work`,
ilyamiro → `daily`.

## Механика рендера

`apply_rig_colors` в `bin/dotprofile` уже рендерит
`config.jsonc.template → config.jsonc` (sed `{{ACCENT}}`). Расширение:

```
sed -e "s/{{ACCENT}}/38;2;R;G;B/g" \
    -e "/{{RIG_MODULES}}/r $PROFILES/$name/fastfetch.modules" \
    -e "/{{RIG_MODULES}}/d" template > config.jsonc
```

**Важно**: писать через `>` в существующий файл (не mv) —
`~/.config/fastfetch/config.jsonc` захардлинкан на файл в dotfiles,
mv порвёт hardlink.

Строка rig — динамический command-модуль (не рендер): актуальна всегда,
даже без ре-рендера.

## Изменяемые файлы

- `.config/fastfetch/config.jsonc.template` — переписать (баннер + список).
- `bin/dotprofile` — рендер: вставка риг-сниппета.
- `profiles/caelestia/role`, `profiles/ilyamiro/role` — новые.
- `profiles/caelestia/fastfetch.modules`, `profiles/ilyamiro/fastfetch.modules` — новые.

## Проверка

1. `dotprofile switch ilyamiro` (текущий) → `fastfetch`: баннер в акценте
   ilyamiro, rig-строка `ilyamiro · daily`, media+battery, оба диска.
2. `dotprofile switch caelestia` → `fastfetch`: акцент caelestia,
   `caelestia · work`, datetime вместо media/battery.
3. Инод `~/.config/fastfetch/config.jsonc` == инод файла в dotfiles.
4. `fastfetch --config ...` без ошибок парсинга JSON.
