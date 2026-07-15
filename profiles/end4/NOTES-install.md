# end-4 (illogical-impulse) — журнал установки

> Артефакт Задач 1–2. Потребители: Задачи 3,5,6,9,10,11.
> Заполняется по мере установки. НЕ плейсхолдеры — явная зависимость от клона.

## Task 1 — prep

- Ветка: `end4-rig` (от `main`).
- Дата старта: 2026-07-15.

### quickshell-версия (мина №1)

```
quickshell-git 0.3.0.r3.g7d1c9a9-1
Quickshell 0.3.0 (revision 7d1c9a9c6721606b129829134d6f614f015621e2, AUR quickshell-git)
```

- Шелл ilyamiro использует `quickshell-git`. end4 (ii) тоже требует quickshell-git.
- **TODO (Task 2):** сверить точное требование ii к тегу/ревизии из его `setup`/README.
  Если ii требует тег, несовместимый с текущим `quickshell-git` — СТОП до установки.

### Бэкап общих конфигов

- `~/end4-preinstall-backup/` ← fish, foot, fuzzel, matugen (до прогона installer).

---

## Task 2 — clone / install / факты

> Заполнить после клона `~/src/dots-hyprland`.

### setup: что пишет в ~/.config

- TODO

### Список пакетов (`illogical-impulse-*`)

- TODO

### Требование ii к quickshell

- TODO (см. мину №1 выше)

### Diff — перезаписанные общие конфиги (fish/foot/fuzzel/matugen)

- TODO

### IPC-вокабуляр end4 (`quickshell:*`)

Из `~/.config/hypr/hyprland/keybinds.lua` (`hl.dsp.global` / `ipc call`):

- launcher (search): TODO
- wallpaperSelector: TODO
- sidebarRight / sidebarLeft: TODO
- mediaControls: TODO
- overviewClipboard: TODO
- regionScreenshot: TODO
- cheatsheet: TODO
- session: TODO
- regionRecord: TODO
- toggleLightDark: TODO
- regionOcr / regionSearch: TODO
- oskToggle: TODO
- overlay: TODO
- panelFamily: TODO
- overviewEmoji: TODO
- battery / network / calendar: отдельный IPC или только сайдбар? TODO

### Файл итоговой палитры end4

- Путь (для Task 10): TODO
- Откуда accent/border: TODO

### matugen-конфиг end4

- Путь: TODO
