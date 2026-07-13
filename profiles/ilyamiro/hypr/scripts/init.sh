#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "wallpaper_picker"

FLAG="$QS_STATE_WALLPAPER_PICKER/wallpaper_initialized"
CACHE_IMG="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper.png"

RELOAD_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/quickshell/wallpaper/matugen_reload.sh"

# If the flag exists, restore the last chosen wallpaper, then run matugen
# and the reload script, then exit
if [ -f "$FLAG" ]; then
    LAST="$QS_STATE_WALLPAPER_PICKER/last_wallpaper"
    if [ -f "$LAST" ]; then
        IFS='|' read -r wtype wpath wmons < "$LAST"
        if [ -f "$wpath" ]; then
            if [ "$wtype" = "video" ]; then
                pkill -x mpvpaper 2>/dev/null
                MPV_OPTS='loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample'
                if [ -z "$wmons" ] || [ "$wmons" = "all" ]; then
                    mpvpaper -o "$MPV_OPTS" '*' "$wpath" &
                else
                    IFS=',' read -ra MON_ARR <<< "$wmons"
                    for mon in "${MON_ARR[@]}"; do
                        mpvpaper -o "$MPV_OPTS" "$mon" "$wpath" &
                    done
                fi
            else
                # Wait for awww-daemon to be ready (started in parallel)
                for _ in $(seq 1 20); do
                    awww query >/dev/null 2>&1 && break
                    sleep 0.25
                done
                if [ -z "$wmons" ] || [ "$wmons" = "all" ]; then
                    awww img "$wpath" --transition-type none &
                else
                    awww img -o "$wmons" "$wpath" --transition-type none &
                fi
            fi
        fi
    fi

    # Use the cached wallpaper image for matugen
    if [ -f "$CACHE_IMG" ]; then
        matugen image "$CACHE_IMG" --source-color-index 0
    fi

    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi

    exit 0
fi

# If no wallpaper dir is set, default to a common one to prevent find from failing
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

sleep 0.5

# Find a random file
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    # Copy to our persistent cache location instead of /tmp
    cp "$file" "$CACHE_IMG"
    printf '%s|%s|%s\n' img "$file" all > "$QS_STATE_WALLPAPER_PICKER/last_wallpaper"
    
    awww img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    
    matugen image "$file" --source-color-index 0
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
