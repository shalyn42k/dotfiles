local vars = require("variables")

----------------------
---- Window rules ----
----------------------

-- General opacity (disabled in fullscreen)
hl.window_rule({ match = { fullscreen = false }, opacity = vars.windowOpacity .. " override" })

-- Opacity exceptions (apps with their own background / colour-critical)
hl.window_rule({ match = { class = "org\\.quickshell|imv|swappy|foot" }, opaque = true })
hl.window_rule({ match = { class = "krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot" }, opaque = true })

-- Center all floating windows (not xwayland, to avoid breaking context menus)
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- Discord (vencord/vesktop): float главного окна; прозрачность нативная
-- (vesktop transparencyOption=transparent + CSS-тема), множитель Hyprland
-- убран — он давал видимый переход при старте
hl.window_rule({ match = { title = "^(Discord)$" }, float = true })
hl.window_rule({ match = { class = "vesktop|discord|equibop" }, opacity = "1.0 override 1.0 override" })

-- Thunar: умеренная прозрачность
hl.window_rule({ match = { class = "(?i)thunar" }, opacity = "0.90 0.90" })

-- Obsidian/Feishin/AyuGram: без прозрачности Hyprland (переход при
-- старте раздражает; override освобождает и от общего правила 0.95)
hl.window_rule({ match = { class = "obsidian" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "feishin" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "com.ayugram.desktop" }, opacity = "1.0 override 1.0 override" })

-- Silent apps in special workspaces
hl.window_rule({ match = { class = "(?i)spotify" }, workspace = "special:music silent" })
hl.window_rule({ match = { class = "(?i)vesktop" }, workspace = "special:communication silent" })
hl.window_rule({ match = { class = "com.ayugram.desktop" }, workspace = "special:messanger silent" })
hl.window_rule({ match = { class = "obsidian" }, workspace = "special:todo silent", no_initial_focus = true })

-- Zen Browser
hl.window_rule({ match = { class = "^(zen-alpha)$" }, opacity = "0.85 0.85" })
hl.window_rule({ match = { class = "^(zen)$" }, opacity = "0.85 0.85" })

-- Float (utilities)
hl.window_rule({ match = { class = "guifetch|yad|zenity|wev|blueman-manager|feh|imv|system-config-printer|org\\.quickshell|nwg-look" }, float = true })
hl.window_rule({ match = { class = "org\\.gnome\\.FileRoller|file-roller" }, float = true })
hl.window_rule({ match = { class = "com\\.github\\.GradienceTeam\\.Gradience" }, float = true })

-- Float, resize and center (auto-size for system windows)
hl.window_rule({ match = { class = "foot", title = "nmtui" }, float = true })
hl.window_rule({ match = { class = "foot", title = "nmtui" }, size = "60% 70%" })
hl.window_rule({ match = { class = "foot", title = "nmtui" }, center = true })

hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, float = true })
hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, size = "70% 80%" })
hl.window_rule({ match = { class = "org\\.gnome\\.Settings" }, center = true })

hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, float = true })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, size = "60% 70%" })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser" }, center = true })

-- Special workspaces (workspace assignment)
hl.window_rule({ match = { class = "btop" }, workspace = "special:sysmon" })
hl.window_rule({ match = { class = "feishin|Spotify|Supersonic|Cider|com.github.th_ch.youtube_music|Plexamp" }, workspace = "special:music" })
hl.window_rule({ match = { initial_title = "Spotify( Free)?" }, workspace = "special:music" })
hl.window_rule({ match = { class = "discord|equibop|vesktop|whatsapp" }, workspace = "special:communication" })
hl.window_rule({ match = { class = "Todoist|obsidian" }, workspace = "special:todo" })

-- Dialogs (popups)
hl.window_rule({ match = { title = "(Select|Open)( a)? (File|Folder)(s)?" }, float = true })
hl.window_rule({ match = { title = "File (Operation|Upload)( Progress)?" }, float = true })
hl.window_rule({ match = { title = ".* Properties" }, float = true })
hl.window_rule({ match = { title = "Export Image as PNG" }, float = true })
hl.window_rule({ match = { title = "Save As" }, float = true })
hl.window_rule({ match = { title = "Library" }, float = true })

-- Picture in picture
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, float = true })
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, move = "100%-w-2% 100%-h-3%" })
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, pin = true })

-- Games (Steam, Gamescope, tearing)
hl.window_rule({ match = { class = "steam" }, rounding = 10 })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, float = true })
hl.window_rule({ match = { class = "(steam_app_(default|[0-9]+))|gamescope" }, immediate = true })
hl.window_rule({ match = { class = "(steam_app_(default|[0-9]+))|gamescope" }, idle_inhibit = "always" })
hl.window_rule({ match = { class = "(steam_app_(default|[0-9]+))|gamescope" }, opaque = true })

-- Fixes (Ueberzugpp & XWayland)
hl.window_rule({ match = { class = "^(ueberzugpp_.*)$" }, float = true })
hl.window_rule({ match = { class = "^(ueberzugpp_.*)$" }, no_initial_focus = true })

hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, no_dim = true })
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, no_shadow = true })
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, rounding = 10 })

-- Foot terminal specific
hl.window_rule({ match = { class = "foot" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ match = { class = "foot" }, no_blur = true })

-- Autodesk Fusion 360
hl.window_rule({ match = { class = "fusion360\\.exe", title = "Fusion360|(Marking Menu)" }, no_blur = true })

-------------------------
---- Workspace rules ----
-------------------------

hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })

---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "logout_dialog" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })

-- Fuzzel / launcher
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%" })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })

-- Caelestia shell
hl.layer_rule({ match = { namespace = "caelestia-(border-exclusion|area-picker)" }, no_anim = true })
hl.layer_rule({ match = { namespace = "caelestia-(drawers|background)" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "caelestia-drawers" }, blur = true })
hl.layer_rule({ match = { namespace = "caelestia-drawers" }, ignore_alpha = 0.57 })
