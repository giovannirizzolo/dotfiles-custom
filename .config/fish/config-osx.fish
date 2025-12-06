fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin

if type -q eza
    alias ll "eza -l -g --icons"
    alias la "ll -a"
    alias lt "ll --tree --level=2 -a ."
    alias md "mkdir -p"
    alias tt tmux
end

#FZF
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0
