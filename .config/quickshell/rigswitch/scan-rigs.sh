#!/usr/bin/env bash
# Выводит по ригу: name<TAB>engine<TAB>абсолютный-путь-превью (или пусто).
set -u
PROFILES="$HOME/dotfiles/profiles"

wallpaper_for() {
    local rig="$1" p=""
    case "$rig" in
        caelestia)
            p="$(cat "$HOME/.local/state/caelestia/wallpaper/path.txt" 2>/dev/null)" ;;
        ilyamiro)
            # формат: type|/путь|monitor (например video|/…/x.mp4|all)
            p="$(cat "$HOME/.local/state/quickshell/wallpaper_picker/last_wallpaper" 2>/dev/null)"
            [[ "$p" == *"|"* ]] && p="$(cut -d'|' -f2 <<<"$p")"
            case "$p" in *.mp4|*.webm|*.mkv)
                p="$HOME/.cache/quickshell/wallpaper_picker/current_wallpaper.png" ;;
            esac ;;
        serpantinum)
            # WallpaperEngine.qml (shell/src/quickshell/wallpaper/) держит один
            # снапшот вне зависимости от монитора: для картинок — копия файла,
            # для видео — кадр через ffmpeg. Путь строит Caching.getCacheDir
            # ("wallpaper") = ~/.cache/serpantinum/wallpaper, мы его не переопределяем.
            p="$HOME/.cache/serpantinum/wallpaper/current_wallpaper.png" ;;
    esac
    [[ -f "$p" ]] && printf '%s' "$p"
}

for d in "$PROFILES"/*/; do
    name="$(basename "$d")"
    [[ "$name" == "active" ]] && continue
    engine=hyprlang
    [[ -f "$d/hypr/hyprland.lua" ]] && engine=lua
    printf '%s\t%s\t%s\n' "$name" "$engine" "$(wallpaper_for "$name")"
done
