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

# OS‑specific path tweaks
switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
    case Linux
        fish_add_path /usr/local/bin
        fish_add_path ~/.local/bin
end

# Initialise pyenv in a fish‑compatible way, if it’s installed
if type -q pyenv
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    status --is-interactive; and source (pyenv init - | psub)
end

# Note: Don’t source bash scripts like nvm.sh here. For Node version management in fish,
# install a fish‑native solution later (e.g. fisher install jorgebucaran/nvm.fish).
