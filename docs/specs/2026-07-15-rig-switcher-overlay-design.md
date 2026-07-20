# Дизайн: rig-switcher overlay (утверждён)

Статус: **Revision 2, обновлён 2026-07-18 под движковый v2-свитч**
(исходно утверждён 2026-07-15). Отдельная фича от end4-рига; улучшает флоу
переключения для всех ригов.

**Зависимость:** реализация — ПОСЛЕ мержа ветки `rig-switch-engine-split` в
main (v2-свитч уже реализован там в `bin/dotprofile`: движок-детект,
`trigger_relogin`, хот-свитч без reload). Перед исполнением ребейзнуть
`rig-switcher-overlay` на актуальный main.

## Проблема

1. **Меню `SUPER+SHIFT+D`** сейчас — голый `fuzzel --dmenu` текст-список
   (`bin/dotprofile` → `cmd_menu`). Хочется красиво.
2. **Голый Hyprland при lua↔lua хот-свитче.** В `cmd_switch` между
   `session.sh stop` (старый шелл умирает → обои/бар/виджеты пропадают) и
   полным рендером нового шелла (~2с старта `qs`) экран пустой. Дыру надо
   замаскировать.
3. **(v2) Кросс-движковый свитч — релогин.** При цели с другим движком
   (`любой ↔ ilyamiro`) `cmd_switch` зовёт `trigger_relogin`: Hyprland
   выходит → SDDM-грайтер. Замаскировать это overlay **не может** — вместе с
   компоновщиком умирает и wayland-поверхность overlay'я. Маскировка
   SDDM-грайтера — вне скоупа (решение v2-спеки engine-split). Overlay лишь
   показывает короткий сплэш «выход в SDDM…» до смерти компоновщика.

## Контекст: как работает свитч после v2

`dotprofile switch <name>` (см. `bin/dotprofile` на ветке
`rig-switch-engine-split`):

```
движок цели == движок сессии (lua↔lua: caelestia↔end4)
  → ГОРЯЧИЙ СВИТЧ: active-свап, ensure_links, session.sh stop/start,
    apply_rig_colors/animations/rules (hyprctl eval, БЕЗ reload), .last-lua
движок цели != движок сессии (любой ↔ ilyamiro)
  → РЕЛОГИН: active-свап, .last-lua, ~/.dmrc Session=, stop
    graphical-session.target, hyprctl dispatch exit → SDDM
```

Движок рига: `profiles/<name>/hypr/hyprland.lua` существует → lua, иначе
hyprlang. Движок сессии: `hyprctl systeminfo` → `configProvider`.

## Ключевая идея

Один **standalone quickshell-процесс** `qs -c rigswitch` решает задачи 1–2:
не привязан к ригам (три рига = три разных шелла: `qs -c caelestia`, `qs -c ii`,
Shell.qml ilyamiro — рисовать в каждом = 3 копии), на layer-shell **overlay**
(поверх всего, включая голый Hyprland). Две фазы в одном процессе:
пикер → transition-сплэш. Transition двухрежимный (hot / relogin) — режим
определяется тем же движок-детектом, что в `dotprofile`.

## Решения (с пользователем, Revision 1 + уточнения Revision 2)

- Вид меню — богатый overlay с карточками (обои-thumbnail + имя + активный).
- Кросс-движковые цели помечаются на карточке бейджем «релогин» (Revision 2):
  выбор честно предупреждает, что будет выход в SDDM.
- Transition (hot) — минимал: затемнённый backdrop + имя целевого рига,
  fade in/out. Тайминг — **фиксированные ~2с** + guard: не гасить пока не
  появился процесс нового шелла (`pgrep`), кап ~2.5с.
- Transition (relogin) — тот же визуал с подписью «выход в SDDM…», без
  guard/таймеров на выход: процесс умирает вместе с Hyprland.
- Живёт **в dotfiles** (`dotfiles/.config/quickshell/rigswitch/`, симлинк в
  `~/.config/quickshell/rigswitch`), не отдельно. Не контестируемый — свитчер
  один на все риги.
- Фолбэк на старый fuzzel если quickshell/конфиг недоступен.

## Архитектура

```
SUPER+SHIFT+D → dotprofile menu → qs -c rigswitch (overlay-процесс)
   ├─ Фаза 1: пикер-карточки (навигация, Enter=выбор, Esc=отмена)
   ├─ на выборе: exec `dotprofile switch <name>` (фоном), overlay ОСТАЁТСЯ наверху
   ├─ Фаза 2а (hot): морф в backdrop+имя, fade-in, ~2с + guard pgrep, кап 2.5с
   │    └─ fade-out когда новый шелл поднят → Qt.quit()
   └─ Фаза 2б (relogin): backdrop + «<имя> · выход в SDDM…»;
        компоновщик выходит → процесс умирает сам (не маскируем SDDM)
```

Overlay-слой рисуется поверх всего → при hot-свитче голого Hyprland не видно.
`cmd_switch` НЕ трогаем — под overlay'ем работает как в v2.

## Компоненты

### 1. `dotfiles/.config/quickshell/rigswitch/` — quickshell-конфиг

- `shell.qml` — точка входа, PanelWindow на `WlrLayershell.layer = Overlay`,
  полноэкранный, exclusionMode Ignore, keyboardFocus Exclusive.
- `Rigs.qml` — модель ригов: список из `profiles/` + активный + движок рига +
  движок сессии + путь обоев каждого.
- `RigCard.qml` — карточка.
- Состояние: `phase ∈ {picker, transition}`; `target`; `targetMode ∈ {hot, relogin}`.

### 2. Фаза 1 — пикер

- Центрированный ряд карточек: thumbnail обоев, имя рига, маркер активного,
  бейдж «релогин» на кросс-движковых.
- Навигация: стрелки ←/→ + мышь-hover; `Enter`/клик = выбрать; `Esc` = закрыть
  без свитча (процесс выходит).
- Источники thumbnail'ов (wallpaper-state per rig):
  - caelestia: путь в `~/.local/state/caelestia/wallpaper/path.txt`
  - ilyamiro: путь в `~/.local/state/quickshell/wallpaper_picker/last_wallpaper`
    (если видео — кадр `~/.cache/quickshell/wallpaper_picker/current_wallpaper.png`)
  - end4 (Revision 2, риг интегрирован): `~/.config/illogical-impulse/config.json`
    → `.background.wallpaperPath` (jq). Если путь — видео (`.mp4`/`.webm`),
    превью: `~/dotfiles/profiles/end4/hypr/custom/scripts/mpvpaper_thumbnails/<basename>.jpg`.
  - путь недоступен / превью нет — заглушка (имя рига на градиенте).

### 3. Фаза 2 — transition

- На выборе: `Quickshell.execDetached(["dotprofile","switch",target])` +
  `phase = transition`.
- Общий визуал: полупрозрачный тёмный backdrop, по центру имя целевого рига,
  fade-in ~200мс.
- **hot** (движок цели == движок сессии): держит минимум ~2с; guard — fade-out
  не раньше, чем `pgrep -f "<шелл цели>"` вернул процесс; кап-таймаут ~2.5с
  (гасим в любом случае). Fade-out ~300мс → `Qt.quit()`.
- **relogin** (движки разошлись): подпись «выход в SDDM…»; никаких guard/кап —
  Hyprland выйдет через <1с и заберёт overlay с собой. Страховочный
  `Qt.quit()` по таймеру 5с на случай, если релогин не сработал.
- pgrep-паттерны для guard (только lua-пара — relogin guard не нужен):
  caelestia → `pgrep -f 'qs -c caelestia'`; end4 → `pgrep -f 'qs -c ii'`
  (март-quickshell живёт в `~/qs-test-prefix/usr/bin`, но бинарь зовётся `qs`
  — паттерн матчится; проверить на месте).

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
| движок-детект overlay разошёлся с dotprofile | оба читают одни источники (`hyprland.lua` существует / `hyprctl systeminfo` configProvider); детект в одном месте (Rigs.qml), логика скопирована 1:1 из `rig_engine`/`hypr_provider` |
| quickshell-версия rigswitch vs ригов | конфиг простой (базовый Quickshell/Layershell API); дефолтный `qs` в PATH — caelestia-версия; проверить, что март-qs end4 не перехватывает |
| relogin-сплэш мигнёт и пропадёт (<1с) | это ок: цель — не «красиво держать», а не дать голому кадру мелькнуть до exit; SDDM дальше штатный |
| `~/.dmrc`-подсветка не работает (риск v2-спеки) | вне скоупа overlay; наследуется от engine-split |

## Оценка

Небольшая фича: один quickshell-конфиг (~200–300 строк qml) + правка `cmd_menu`
+ симлинк в bootstrap. Половина работы — вылизать z-order/guard на живом
hot-свитче. end4-обои теперь реальные (риг интегрирован), плейсхолдер не нужен.
