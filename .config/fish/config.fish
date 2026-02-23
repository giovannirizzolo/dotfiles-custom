# ~/.config/fish/config.fish

# Only run for interactive sessions
if status is-interactive
    set -g fish_prompt_pwd_dir_length 0 # show full paths in prompt
end

# Add your custom scripts
fish_add_path $HOME/dotfiles-custom/.scripts

# Ensure the data directory for 'z' lives under your home directory
set -gx _Z_DATA $HOME/.local/share/z/data
mkdir -p $_Z_DATA

# Load Homebrew’s environment, but only if brew is installed
if type -q brew
    # If brew is already in PATH, this works for both macOS and Linuxbrew
    eval (brew shellenv)
else
    # Otherwise fall back to known locations; only run if the file exists
    if test -x /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
    else if test -x /usr/local/bin/brew
        eval (/usr/local/bin/brew shellenv)
    else if test -x ~/.linuxbrew/bin/brew
        eval (~/.linuxbrew/bin/brew shellenv)
    end
end

if test -f $HOME/dotfiles-custom/.config/fish/config-local.fish
    source $HOME/dotfiles-custom/.config/fish/config-local.fish
end

set -g fish_function_path $HOME/dotfiles-custom/.config/fish/functions $fish_function_path

# OS‑specific path tweaks
switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
        fish_add_path /usr/local/bin
        fish_add_path ~/.local/bin
end

# Initialise pyenv in a fish‑compatible way, if it’s installed
if type -q pyenv
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    status --is-interactive; and source (pyenv init - | psub)
end

#Setup git alias
if type -q git
    alias gc 'git c'
    alias gd 'git wdiff'
    alias gl 'git l5'
    alias gs 'git s'
    alias gws 'git sw'
    alias gb 'git br --list'
end

if type -q lazygit
    alias lg lazygit
end

#Setup FZF to use ripgrep
if type rg &>/dev/null
    export FZF_DEFAULT_COMMAND='rg --files'
    export FZF_DEFAULT_OPTS='-m'
end
export PATH="$HOME/.local/bin:$PATH"

# nvm.fish - use latest installed LTS on shell start
nvm use lts
