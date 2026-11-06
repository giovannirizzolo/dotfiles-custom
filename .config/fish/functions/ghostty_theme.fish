function ghostty_theme --description 'Pick a Ghostty theme with fzf and live-reload Ghostty'
    # Usage: ghostty_theme            pick from my themes (dotfiles)
    #        ghostty_theme --all      also list Ghostty's built-in themes
    #        ghostty_theme <name>     switch directly, no picker
    set -l dir ~/.config/ghostty
    set -l mine $dir/themes
    set -l builtin /Applications/Ghostty.app/Contents/Resources/ghostty/themes
    set -l state $dir/current-theme.ghostty

    set -l choice
    if test (count $argv) -gt 0; and test "$argv[1]" != --all
        set choice "$argv"
    else
        set -l dirs $mine
        test "$argv[1]" = --all; and set -a dirs $builtin

        set choice (begin
                command ls $mine
                test "$argv[1]" = --all; and command ls $builtin
            end | awk '!seen[$0]++' | fzf --height=40% --reverse --prompt='theme ❯ ' \
            --preview="$dir/bin/theme-preview.sh {} $dirs" --preview-window=right,55%)
        or return 1
    end

    set -l path
    for d in $mine $builtin
        if test -f "$d/$choice"
            set path "$d/$choice"
            break
        end
    end
    if test -z "$path"
        echo "ghostty_theme: no theme named '$choice'" >&2
        return 1
    end

    # Store it home-relative (~/...) so the file stays valid on other machines.
    set -l portable (string replace -r "^$HOME/" '~/' -- $path)
    printf '# Written by ghostty_theme — overrides `theme` in config.ghostty.\ntheme = "%s"\n' $portable >$state
    # Reload Ghostty's config via its AppleScript API (SIGUSR2 alone didn't
    # repaint open windows); the signal stays as a fallback.
    # Runs in the background: the call blocks while Ghostty recompiles the
    # theme's shaders (several seconds), which kept the picker popup open.
    command sh -c 'osascript -e "tell application \"Ghostty\" to perform action \"reload_config\" on focused terminal of selected tab of front window" >/dev/null 2>&1 || pkill -USR2 -x ghostty' </dev/null >/dev/null 2>&1 &
    disown
    # Repaint the tmux statusline and the tide prompt too (nvim follows on its own).
    ~/.config/tmux/ghostty-theme.sh
    tide_ghostty_colors
    echo "ghostty: theme → $choice"
end
