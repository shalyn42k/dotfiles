# Дизайн: rig-switcher overlay (утверждён)

Статус: **утверждён 2026-07-15**, готов к плану.
Отдельная фича от end4-рига; улучшает флоу переключения для всех ригов.

## Проблема

1. **Меню `SUPER+SHIFT+D`** сейчас — голый `fuzzel --dmenu` текст-список
   (`bin/dotprofile` → `cmd_menu`). Хочется красиво.
2. **Голый Hyprland при свитче.** В `cmd_switch` между `session.sh stop` (старый
   шелл умирает → обои/бар/виджеты пропадают) и полным рендером нового шелла
   (~2с старта `qs`) экран пустой (`misc.background_color`/дефолт). Свитч по
   времени ~2с — эту дыру надо замаскировать.

## Ключевая идея

Один **standalone quickshell-процесс** `qs -c rigswitch` решает обе задачи:
не привязан к ригам (три рига = три разных шелла: `qs -c caelestia`, `qs -c ii`,
Shell.qml ilyamiro — рисовать в каждом = 3 копии), на layer-shell **overlay**
(поверх всего, включая голый Hyprland). Две фазы в одном процессе:
пикер → transition-сплэш.

## Решения (с пользователем)

- Вид меню — богатый overlay с карточками (обои-thumbnail + имя + активный).
- Transition — минимал: blur-backdrop + имя целевого рига, fade in/out.
- Тайминг — **фиксированные ~2с** (свитч занимает 2с) + guard: не гасить пока
  не появился процесс нового шелла (`pgrep`), кап ~2.5с.
- Живёт **в dotfiles** (`dotfiles/.config/quickshell/rigswitch/`, симлинк в
  `~/.config/quickshell/rigswitch`), не отдельно. Не контестируемый — свитчер
  один на все риги.
- Фолбэк на старый fuzzel если quickshell/конфиг недоступен.

## Архитектура

```
SUPER+SHIFT+D → dotprofile menu → qs -c rigswitch (overlay-процесс)
   ├─ Фаза 1: пикер-карточки (навигация, Enter=выбор, Esc=отмена)
   ├─ на выборе: exec `dotprofile switch <name>` (фоном), процесс ОСТАЁТСЯ наверху
   ├─ Фаза 2: морф в blur+имя, fade-in, держит ~2с (+guard pgrep нового шелла)
   └─ fade-out когда новый шелл поднят → процесс выходит
```

Overlay-слой рисуется поверх всего → голого Hyprland не видно всё время свитча.
`cmd_switch` НЕ трогаем — под overlay'ем делает stop/reload/start как сейчас.

## Компоненты

### 1. `dotfiles/.config/quickshell/rigswitch/` — quickshell-конфиг

- `shell.qml` (или `rigswitch.qml`) — точка входа, PanelWindow на
  `WlrLayershell.layer = Overlay`, полноэкранный, exclusionMode Ignore.
- Модель ригов: список из `dotprofile` (`list_profiles`) + текущий активный +
  путь обоев каждого (wallpaper-state рига).
- Состояние: `phase ∈ {picker, transition}`; `target` (выбранный риг).

### 2. Фаза 1 — пикер

- Центрированный ряд карточек: thumbnail обоев, имя рига, маркер активного.
- Навигация: стрелки ←/→ + мышь-hover; `Enter`/клик = выбрать; `Esc` = закрыть
  без свитча (процесс выходит).
- Источники thumbnail'ов (wallpaper-state per rig):
  - caelestia: `~/.local/state/caelestia/wallpaper/path.txt`
  - ilyamiro: `~/.local/state/quickshell/wallpaper_picker/last_wallpaper`
    (кадр видео: `~/.cache/quickshell/wallpaper_picker/current_wallpaper.png`)
  - end4: путь из `profiles/end4/NOTES-install.md` (уточняется при интеграции
    end4; до этого — плейсхолдер-обои)
  - если путь недоступен/видео — заглушка (иконка рига).

### 3. Фаза 2 — transition

- На выборе: `Quickshell.execDetached(["dotprofile","switch",target])` +
  переход `phase = transition`.
- Визуал: полупрозрачный тёмный/blur backdrop (blur через слой quickshell или
  затемнённая заглушка-обои цели), по центру имя целевого рига. Fade-in ~200мс.
- Держит минимум ~2с. Guard: не начинать fade-out пока
  `pgrep -f "<шелл целевого рига>"` не вернул процесс (иначе экран ещё голый);
  кап-таймаут ~2.5с (гасим в любом случае, чтоб не зависнуть).
- Fade-out ~300мс → `Qt.quit()` (процесс выходит).
- Имя шелла для guard per rig: caelestia `qs -c caelestia`, ilyamiro
  `quickshell -p .*Shell.qml`, end4 `qs -c ii`.

### 4. Интеграция в `bin/dotprofile`

- `cmd_menu`: вместо fuzzel — запуск overlay. Проверка доступности:
  ```
  if command -v qs && [ -d ~/.config/quickshell/rigswitch ]; then
      qs -c rigswitch
  else
      <старый fuzzel-путь>   # фолбэк
  fi
  ```
- Overlay сам зовёт `dotprofile switch <name>` — `cmd_switch` без изменений.
- Старый fuzzel-код `cmd_menu` сохранить как fallback-ветку (не удалять).

### 5. Установка

- `bootstrap.sh`: симлинк `~/.config/quickshell/rigswitch` →
  `dotfiles/.config/quickshell/rigswitch`.

## Риски

| Риск | Митигация |
|---|---|
| overlay-слой не перекрывает новый шелл (тот тоже overlay) | z-order: держать rigswitch на `Overlay`, новый шелл рисует обои на `Background`/`Bottom` — rigswitch поверх; проверить на месте |
| guard-`pgrep` ложно-срабатывает (шелл есть, но обои ещё не отрисованы) | кап-таймаут + fixed-минимум 2с гарантируют что не мигнёт рано |
| quickshell-версия rigswitch vs ригов | конфиг простой (базовый Quickshell/Layershell API), совместим с любой; проверить с даунгрейд-версией ii (см. end4-мину) |
| end4 wallpaper-state путь пока неизвестен | до интеграции end4 — заглушка-обои; уточнить из NOTES при end4-работе |

## Оценка

Небольшая фича: один quickshell-конфиг (~150-250 строк qml) + правка `cmd_menu`
+ симлинк в bootstrap. Половина работы — вылизать z-order/guard на живом свитче.
Зависимость на end4 только в одной точке (его wallpaper-путь) — до end4 работает
на двух ригах.
