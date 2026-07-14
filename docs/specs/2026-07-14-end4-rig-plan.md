# План: третий риг — end-4/dots-hyprland (illogical-impulse)

Статус: **не начато** (план на будущее).
Источник: https://github.com/end-4/dots-hyprland

## Что это

Третий профиль `profiles/end4` в dual-rig систему (caelestia + ilyamiro).
Ключевой факт: end-4 сейчас на **hyprland.lua** (lua config provider, как
caelestia) и на **Quickshell** (конфиг `quickshell/ii`, запуск `qs -c ii`).

Следствия:
- caelestia ↔ end4 — **однодвижковый** горячий свитч (оба lua): полный
  `hyprctl reload` работает; остаётся оговорка про require-кэш lua-модулей.
- end4 ↔ ilyamiro — кросс-движковый, как сейчас (бинды/правила WM после
  relogin, autoreload глушится dotprofile'ом).

## Требования (от пользователя)

1. Мои бинды сохранить, новые от разраба добавить, часть его — перезаписать.
2. Схемы (Material You из обоев) и обои — интегрировать в наш пайплайн
   (рамки/группы/fastfetch/Discord/Obsidian следуют активному ригу).

## Шаги

### 1. Установка и снапшот (интерактивно, с пользователем)
- `dotprofile update end4` не подойдёт для ПЕРВОЙ установки (профиля ещё
  нет) — сначала `git clone`, `./setup install` (у них каждый шаг
  показывается перед выполнением; sudo — через `!` пользователя).
- Installer агрессивно пишет в `~/.config` — прогонять на материализованных
  каталогах (как update-flow), потом снапшот в `profiles/end4/`
  (hypr, gtk-3.0/4.0, qt5ct/qt6ct + его специфичные: quickshell/ii,
  Kvantum, kde-material-you-colors, fontconfig).
- Пакеты: AUR-метапакеты illogical-impulse-* — добавить в bootstrap.sh
  после установки (взять фактический список из setup).

### 2. Каркас профиля (по шаблону ilyamiro)
- `profiles/end4/session.sh` — start/stop его шелла (`qs -c ii`);
  не забыть остановку шелла предыдущего рига в cmd_switch.
- `sddm/hyprland-end4.desktop` + запись в bootstrap.
- `profiles/end4/post-update.sh` — вернуть source-строки, которые затирает
  его installer (аналог ilyamiro).

### 3. Бинды
- У end-4 есть официальный механизм оверрайдов: `~/.config/hypr/custom/`
  (сорсится после дефолтов) — наши бинды класть туда, НЕ в его файлы:
  переживает их апдейты.
- Содержимое: общий binds.conf (U/Y, SUPER+SHIFT+D меню), unbind
  конфликтных его биндов, rigdo-бинды (launcher/screenshot/lock/shell/
  battery/network/guide + новые действия его шелла).
- rigdo: ветка `end4` в каждом action — его шелл имеет свои IPC-команды
  (`qs -c ii ipc ...`), изучить при установке.

### 4. Схемы и обои
- Его пайплайн: switchwall → matugen + kde-material-you-colors →
  палитра в state/generated-файлах. Найти файл с итоговой палитрой.
- `apply_rig_colors`: третья ветка парсинга (end4-палитра → active/inactive
  border, группы, fastfetch {{ACCENT}}, Discord rig.theme.css,
  Obsidian rig-theme.css). Генерить его вариант тем через его же matugen
  (шаблоны discord/obsidian уже есть — переиспользовать).
- Хук на смену обоев: его switchwall дёргает `dotprofile colors`
  (как matugen_reload.sh у ilyamiro).
- **КОНФЛИКТ**: `~/.config/matugen` сейчас не-контестируемый и живёт под
  ilyamiro (наши шаблоны + config.toml). end-4 несёт свой matugen-конфиг.
  Решение: сделать `matugen` контестируемым каталогом (в CONTESTED у
  dotprofile + перенести в profiles/*/matugen) ЛИБО смержить config.toml.
  Контестируемый — чище.

### 5. Горячий свитч
- `profiles/end4/animations-runtime.{lua,keywords}` — перевод его
  анимаций (для применения при свитче в чужую сессию).
- Проверить fadeIn-политику (у нас: fadeIn 1,2 — быстрая маска первого
  кадра электронов) — применить и в его конфиге.
- Прозрачность: наши правила (дс/Obsidian/AyuGram/Feishin opacity
  1.0 override, Thunar 0.90) добавить в его custom/rules.

### 6. Риски
| Риск | Митигация |
|---|---|
| Quickshell-версия: ii может требовать конкретный тег, ilyamiro-шелл живёт на quickshell-git | проверить перед установкой; при конфликте — собрать ii-совместимую и прогнать шелл ilyamiro на ней |
| matugen-конфиг конфликт | см. шаг 4 |
| Его installer перепишет fish/foot/fuzzel (у нас общие, не-контестируемые) | на время установки бэкапить; решить, чьи оставить |
| GTK/Kvantum/Qt темы end4 глобальны | qt5ct/qt6ct/gtk уже контестируемые — его варианты лягут в profiles/end4 |

### 7. Финализация
- e2e: relogin во все 3 сессии + 6 направлений горячего свитча.
- bootstrap.sh: пакеты, симлинки новых контестируемых каталогов, SDDM.
- README: таблица ригов + новые оговорки.

## Оценка

Сопоставимо с портом ilyamiro: один длинный заход (~вечер) + участие
пользователя на установке (sudo, выборы installer'а) и e2e-тестах.
