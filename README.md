# dotfiles-custom

Personal dotfiles managed with [rcm](https://github.com/thoughtbot/rcm) or symlinks.

## What's Included

| Tool | Config |
|------|--------|
| **Neovim** | [LazyVim](https://www.lazyvim.org/)-based config with custom plugins (LSP, Treesitter, Go, colorscheme, etc.) |
| **Fish** | Shell config with platform-specific files for macOS and Linux |
| **Tmux** | Theme, statusline, and utility configs |
| **Lazygit** | Custom `config.yml` |
| **Git** | Global ignore patterns |

### Scripts

- **`ide`** — Creates a tmux 4-pane layout (`ide h` for horizontal, `ide v` for vertical)

## Setup

Clone into your home directory and symlink the configs:

```sh
git clone git@github.com:giovannirizzolo/dotfiles-custom.git ~/dotfiles-custom

# Example: symlink nvim config
ln -sf ~/dotfiles-custom/.config/nvim ~/.config/nvim
```

Or use a dotfile manager like [rcm](https://github.com/thoughtbot/rcm) or [GNU Stow](https://www.gnu.org/software/stow/).
