fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin

if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

#FZF
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0
