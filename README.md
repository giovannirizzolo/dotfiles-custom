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

### Next Trip Countdown

Because nothing makes you productive like a constant reminder that you could be on a beach right now.

The tmux statusline replaces the hostname (who cares about the hostname) with a live countdown to the next trip:

```
972980d left to Wonderland
```

When the trip is over and you're back at your desk with mild post-vacation depression, it switches to:

```
Add next trip to next_trip.fish
```

**To update the destination**, edit `.config/tmux/next_trip/next_trip.fish`:

```fish
set TRIP_NAME Wonderland
set TRIP_DATE 2999-01-01  # YYYY-MM-DD
```

Then reload tmux config. The countdown resumes. Hope returns.

## Setup

Clone into your home directory and symlink the configs:

```sh
git clone git@github.com:giovannirizzolo/dotfiles-custom.git ~/dotfiles-custom

# Example: symlink nvim config
ln -sf ~/dotfiles-custom/.config/nvim ~/.config/nvim
```

Or use a dotfile manager like [rcm](https://github.com/thoughtbot/rcm) or [GNU Stow](https://www.gnu.org/software/stow/).
