if status is-interactive
    # 1. Прячем Hardware блок, если мы в Codium
    # Проверяем и нашу переменную, и стандартную переменную VS Code
    if not set -q IS_CODIUM; and test "$TERM_PROGRAM" != "vscode"
        cat ~/.local/state/caelestia/sequences.txt 2>/dev/null
    end

    # 2. Активация venv
    if test -f .venv/bin/activate.fish
        source .venv/bin/activate.fish
    end

    # 3. Инструменты
    starship init fish | source
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish --cmd cd | source

    # Алиасы и аббревиатуры
    alias ls='eza --icons --group-directories-first -1'
    abbr lg lazygit
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr l ls
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # 4. Функции
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    function yy
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end

# 5. Переменные окружения (вне блока interactive)
set -gx PATH $PATH /home/shalyn42k/.local/bin
fish_add_path /usr/lib/qt6/bin
set -gx QT_QPA_PLATFORM "wayland;xcb"
set -gx QT_QPA_PLATFORMTHEME qt6ct

# Убираем стандартное приветствие (на всякий случай)
set -g fish_greeting ""
