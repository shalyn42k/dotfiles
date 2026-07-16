-- custom/env.lua — end4 риг.
--
-- СОСУЩЕСТВОВАНИЕ (мина №1, NOTES): ii-шелл должен крутиться на ЛОКАЛЬНОМ
-- март-quickshell (7511545), НЕ системном (май, для caelestia/ilyamiro).
-- ii-дефолт `hyprland/execs.lua` стартует шелл через `qs -c $qsConfig` (системный).
-- Префиксуем PATH локальным bin → `qs`/`quickshell` резолвятся в март-бинарь
-- ВЕЗДЕ (execs shell-start, cliphist ipc-вотчеры). custom/env.lua грузится ДО
-- hyprland.execs (см. hyprland.lua) — PATH готов к старту шелла.
--
-- bootstrap формализует префикс (сейчас ~/qs-test-prefix из test-first сборки).

local home     = os.getenv("HOME")
local path_old = os.getenv("PATH") or ""
hl.env("PATH", home .. "/qs-test-prefix/usr/bin:" .. path_old)
