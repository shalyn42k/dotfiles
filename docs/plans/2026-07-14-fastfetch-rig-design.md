# Fastfetch Rig Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Риг-зависимый fastfetch: баннер SHALYN42K в акценте активного рига, динамичная rig-строка, риг-специфичные модули, оба диска.

**Architecture:** Шаблон `config.jsonc.template` рендерится существующей функцией `apply_rig_colors` в `bin/dotprofile` при каждом свитче. Рендер расширяется двухпроходным sed: (1) вставка риг-сниппета `profiles/<name>/fastfetch.modules` в `{{RIG_MODULES}}`, (2) подстановка `{{ACCENT}}`. Rig-строка — command-модуль (readlink на лету), рендера не требует.

**Tech Stack:** fastfetch (jsonc), bash (sed), nerd font icons.

**Spec:** `docs/specs/2026-07-14-fastfetch-rig-design.md`

## Global Constraints

- Рендер пишет через `>` в существующий `config.jsonc` (НЕ mv): файл захардлинкан на `~/.config/fastfetch/config.jsonc`, mv порвёт hardlink.
- Порядок sed-проходов обязателен: сначала вставка сниппета, потом `{{ACCENT}}` — иначе `{{ACCENT}}` внутри сниппета останется несубституированным (sed `r` вставляет текст после выполнения s-команд).
- Отсутствие `fastfetch.modules` у профиля не должно ломать рендер (end4 в будущем): GNU sed молча игнорирует `r` с несуществующим файлом, блок просто пустой.
- Коммит — только после подтверждения пользователем (правило репо).

---

### Task 1: Файлы профилей (role + fastfetch.modules)

**Files:**
- Create: `profiles/caelestia/role`
- Create: `profiles/ilyamiro/role`
- Create: `profiles/caelestia/fastfetch.modules`
- Create: `profiles/ilyamiro/fastfetch.modules`

**Interfaces:**
- Produces: `profiles/<name>/role` — одно слово, читается command-модулем rig-строки (Task 2). `profiles/<name>/fastfetch.modules` — фрагмент JSON-массива modules (каждый объект с завершающей запятой), вставляется рендером (Task 3).

- [x] **Step 1: role-файлы**

`profiles/caelestia/role`:
```
work
```

`profiles/ilyamiro/role`:
```
daily
```

- [x] **Step 2: сниппет caelestia (work: дата/время)**

`profiles/caelestia/fastfetch.modules`:
```jsonc
        {
            "type": "command",
            "key": "   󰃰 date",
            "keyColor": "{{ACCENT}}",
            "text": "date '+%a %d %b · %H:%M'"
        },
```

- [x] **Step 3: сниппет ilyamiro (daily: media + battery)**

`profiles/ilyamiro/fastfetch.modules`:
```jsonc
        {
            "type": "media",
            "key": "   󰂪 media",
            "keyColor": "{{ACCENT}}"
        },
        {
            "type": "battery",
            "key": "   󰁹 bat",
            "keyColor": "{{ACCENT}}"
        },
```

### Task 2: Новый шаблон config.jsonc.template

**Files:**
- Modify: `.config/fastfetch/config.jsonc.template` (полная замена содержимого)

**Interfaces:**
- Consumes: `profiles/<name>/role` (Task 1) — через command-модуль rig.
- Produces: плейсхолдеры `{{ACCENT}}` (много мест) и `{{RIG_MODULES}}` (отдельная строка, ровно один раз) для рендера (Task 3).

- [x] **Step 1: записать шаблон**

Полное содержимое `.config/fastfetch/config.jsonc.template`:

```jsonc
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": null,
    "display": {
        "separator": "  ",
        "color": "{{ACCENT}}"
    },
    "modules": [
        "break",
        {
            "type": "custom",
            "format": " ███████╗██╗  ██╗ █████╗ ██╗     ██╗   ██╗███╗   ██╗██╗  ██╗██████╗ ██╗  ██╗",
            "outputColor": "{{ACCENT}}"
        },
        {
            "type": "custom",
            "format": " ██╔════╝██║  ██║██╔══██╗██║     ╚██╗ ██╔╝████╗  ██║██║  ██║╚════██╗██║ ██╔╝",
            "outputColor": "{{ACCENT}}"
        },
        {
            "type": "custom",
            "format": " ███████╗███████║███████║██║      ╚████╔╝ ██╔██╗ ██║███████║ █████╔╝█████╔╝ ",
            "outputColor": "{{ACCENT}}"
        },
        {
            "type": "custom",
            "format": " ╚════██║██╔══██║██╔══██║██║       ╚██╔╝  ██║╚██╗██║╚════██║██╔═══╝ ██╔═██╗ ",
            "outputColor": "{{ACCENT}}"
        },
        {
            "type": "custom",
            "format": " ███████║██║  ██║██║  ██║███████╗   ██║   ██║ ╚████║     ██║███████╗██║  ██╗",
            "outputColor": "{{ACCENT}}"
        },
        {
            "type": "custom",
            "format": " ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝     ╚═╝╚══════╝╚═╝  ╚═╝",
            "outputColor": "{{ACCENT}}"
        },
        "break",
        {
            "type": "command",
            "key": "   󰜗 rig",
            "keyColor": "{{ACCENT}}",
            "text": "n=$(basename $(readlink -f ~/dotfiles/profiles/active)); r=$(cat ~/dotfiles/profiles/$n/role 2>/dev/null); echo \"$n${r:+ · $r}\""
        },
        {
            "type": "command",
            "key": "    os",
            "keyColor": "{{ACCENT}}",
            "text": ". /etc/os-release; echo \"$PRETTY_NAME · $(uname -r)\""
        },
        {
            "type": "command",
            "key": "   󰊠 wm",
            "keyColor": "{{ACCENT}}",
            "text": "echo \"$XDG_CURRENT_DESKTOP · $(basename $SHELL)\""
        },
        {
            "type": "cpu",
            "key": "   󰍛 cpu",
            "keyColor": "{{ACCENT}}"
        },
        {
            "type": "gpu",
            "key": "   󰢮 gpu",
            "keyColor": "{{ACCENT}}",
            "hideType": "integrated"
        },
        {
            "type": "memory",
            "key": "   󰑭 ram",
            "keyColor": "{{ACCENT}}"
        },
        {
            "type": "disk",
            "key": "   󰋊 root",
            "keyColor": "{{ACCENT}}",
            "folders": "/"
        },
        {
            "type": "disk",
            "key": "   󰋊 data",
            "keyColor": "{{ACCENT}}",
            "folders": "/mnt/data"
        },
        {
            "type": "command",
            "key": "   󰏗 pkgs",
            "keyColor": "{{ACCENT}}",
            "text": "echo \"$(pacman -Qq | wc -l) pkgs · up $(uptime -p | sed 's/^up //')\""
        },
{{RIG_MODULES}}
        "break",
        {
            "type": "colors",
            "symbol": "circle",
            "paddingLeft": 5
        }
    ]
}
```

Примечания:
- Баннер — 6 custom-модулей (ansi-shadow, 76 колонок), НЕ logo: custom проще красить в `{{ACCENT}}`.
- `{{RIG_MODULES}}` — строка без отступа, ровно одна, между pkgs и финальным break.
- `hideType: "integrated"` прячет Radeon 780M, остаётся RTX 4070.
- Старые `constants` и хардкод-red удалены.

### Task 3: Рендер в dotprofile

**Files:**
- Modify: `bin/dotprofile` (функция `apply_rig_colors`, строки ~62-68)

**Interfaces:**
- Consumes: `{{RIG_MODULES}}`/`{{ACCENT}}` из шаблона (Task 2), сниппеты (Task 1), переменная `$name` (аргумент функции, уже есть).

- [x] **Step 1: заменить sed-строку**

Было (строка ~67):
```bash
        sed "s/{{ACCENT}}/38;2;$r;$g;$b/g" "$tmpl" > "$DOTFILES/.config/fastfetch/config.jsonc"
```

Стало:
```bash
        sed -e "/{{RIG_MODULES}}/r $PROFILES/$name/fastfetch.modules" \
            -e "/{{RIG_MODULES}}/d" "$tmpl" \
            | sed "s/{{ACCENT}}/38;2;$r;$g;$b/g" \
            > "$DOTFILES/.config/fastfetch/config.jsonc"
```

Два прохода: вставка сниппета первым (текст из `r`-файла не проходит через s-команды того же sed), акцент — вторым, чтобы покрасить и сниппет.

### Task 4: Верификация

**Files:** нет изменений (только проверки).

- [x] **Step 1: рендер активного рига**

Run: `~/dotfiles/bin/dotprofile colors && fastfetch`
Expected: баннер SHALYN42K в акценте ilyamiro; строки rig `ilyamiro · daily`, os·kernel, wm·shell, cpu (7940HS), gpu (RTX 4070, без 780M), ram, root, data, pkgs·uptime, media, battery, точки. Без JSON-ошибок.

- [x] **Step 2: рендер caelestia без свитча (не дёргаем сессию)**

Run:
```bash
sed -e "/{{RIG_MODULES}}/r $HOME/dotfiles/profiles/caelestia/fastfetch.modules" \
    -e "/{{RIG_MODULES}}/d" ~/dotfiles/.config/fastfetch/config.jsonc.template \
    | sed "s/{{ACCENT}}/38;2;237;192;108/g" \
    > /tmp/claude-1000/-home-shalyn42k/1a48ba1d-d24c-4f8d-8020-8848f7a9f882/scratchpad/ff-caelestia.jsonc
fastfetch --config /tmp/claude-1000/-home-shalyn42k/1a48ba1d-d24c-4f8d-8020-8848f7a9f882/scratchpad/ff-caelestia.jsonc
```
Expected: тот же макет, но date-строка вместо media/battery. (rig-строка покажет ilyamiro — она динамическая, это корректно.)

- [x] **Step 3: hardlink цел**

Run: `stat -c %i ~/.config/fastfetch/config.jsonc ~/dotfiles/.config/fastfetch/config.jsonc`
Expected: одинаковый inode.

- [ ] **Step 4: коммит — спросить пользователя**

После визуального ок от пользователя:
```bash
git -C ~/dotfiles add .config/fastfetch/config.jsonc.template .config/fastfetch/config.jsonc bin/dotprofile profiles/*/role profiles/*/fastfetch.modules docs/specs/2026-07-14-fastfetch-rig-design.md docs/plans/2026-07-14-fastfetch-rig-design.md
git -C ~/dotfiles commit -m "feat(fastfetch): rig-aware config — SHALYN42K banner, per-rig modules"
```
