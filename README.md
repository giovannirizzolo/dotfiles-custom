# dotfiles-custom

Personal dotfiles. This repo is the source of truth; binding it into `~/.config` is left to the machine.

## What's Included

| Tool | Config |
|------|--------|
| **Neovim** | [LazyVim](https://www.lazyvim.org/)-based config with custom plugins (LSP, Treesitter, Go, colorscheme, etc.) |
| **Fish** | Shell config (macOS/Linux) with a [Tide](https://github.com/IlanCosman/tide) prompt themed from Ghostty |
| **Ghostty** | Terminal config with two full themes (Gotham Noir, GTA VI): colors, font, shaders, backdrop |
| **Tmux** | Statusline colored from the active Ghostty theme, utility configs |
| **Lazygit** | Custom `config.yml` |
| **Git** | Global ignore patterns |

### One theme everywhere

The active Ghostty theme drives the whole setup. Switch it and everything follows live, no restarts:

| Piece | What follows the theme | Where |
|-------|------------------------|-------|
| Ghostty | colors, font, cursor shader, background shaders/image, app icon | `.config/ghostty/themes/*` |
| Tmux | statusline, borders, menus, popups, copy-mode | `.config/tmux/ghostty-theme.sh` fills `statusline.tmpl.conf` |
| Neovim | solarized-osaka repainted with the theme's palette | `.config/nvim/lua/config/ghostty_theme.lua` |
| Fish prompt | Tide colors, logo pill (bold **VI** for GTA VI, moon for Gotham), rounded pills, prompt arrow | `.config/fish/functions/tide_ghostty_colors.fish` |

**Switching:** press <kbd>cmd</kbd>+<kbd>shift</kbd>+<kbd>y</kbd> (or "Switch Theme" in Ghostty's command palette). Ghostty sends F12, which opens an fzf picker with a color preview, in a tmux popup inside tmux or in fish outside it. You can also run `ghostty_theme` (`--all` adds Ghostty's built-in themes, `ghostty_theme "GTA VI"` skips the picker).

How it works:

- The pick is saved to `.config/ghostty/current-theme.ghostty` (gitignored, local), which overrides the default `theme` in `config.ghostty`.
- Ghostty reloads through AppleScript (`perform action "reload_config"`). If that fails it falls back to `SIGUSR2`.
- Tide colors are written once to `~/.cache/fish/tide_ghostty.fish`. Every fish sources that file, and a single universal variable (`tide_theme_stamp`) tells open shells to `tide reload`.
- Neovim watches the Ghostty directory and also re-checks on `FocusGained` (tmux has `focus-events on`).

Other Ghostty bits: <kbd>cmd</kbd>+<kbd>shift</kbd>+<kbd>b</kbd> toggles opaque "focus mode" (hides the shaders and backdrop), <kbd>cmd</kbd>+<kbd>`</kbd> opens a quake-style drop-down terminal, <kbd>cmd</kbd>+<kbd>d</kbd> / <kbd>cmd</kbd>+<kbd>shift</kbd>+<kbd>d</kbd> split the window.

**Adding a theme:** drop a Ghostty theme file in `.config/ghostty/themes/`. It needs `background`, `foreground` and `palette = 0..15`, and should set `cursor-color` and `selection-background`. A theme can also set `font-family`, `custom-shader` or `background-image`. Use `~/.config/ghostty/...` paths, never the checkout path. Tide picks a logo and separators by theme name in `tide_ghostty_colors.fish`; any other theme falls back to the OS icon.

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

## Requirements

macOS with [Homebrew](https://brew.sh). Some pieces work on Linux, but the theme sync assumes macOS (`/Applications/Ghostty.app`, AppleScript).

| What | Why | Install |
|------|-----|---------|
| [Ghostty](https://ghostty.org) ≥ 1.2 | terminal, shaders, AppleScript reload | `brew install --cask ghostty` |
| IBM Plex Mono | font used by both themes | `brew install --cask font-ibm-plex-mono` |
| fish ≥ 4 | shell | `brew install fish` |
| [fisher](https://github.com/jorgebucaran/fisher) | installs the plugins in `fish_plugins` (Tide v6, z, fzf.fish, nvm.fish) | see below |
| tmux ≥ 3.3 | multiplexer (`display-popup`, `terminal-features`) | `brew install tmux` |
| [TPM](https://github.com/tmux-plugins/tpm) | tmux plugins (resurrect, continuum) | `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`, then <kbd>prefix</kbd>+<kbd>I</kbd> |
| Neovim ≥ 0.10 | editor (LazyVim installs its plugins on first start) | `brew install neovim` |
| fzf | theme picker, fzf.fish | `brew install fzf` |
| git, ripgrep, fd | LazyVim pickers / grep | `brew install git ripgrep fd` |
| eza, peco | `ls` aliases, <kbd>ctrl</kbd>+<kbd>f</kbd> / <kbd>ctrl</kbd>+<kbd>r</kbd> pickers | `brew install eza peco` |
| lazygit | git UI | `brew install lazygit` |
| Node via nvm.fish | `nvm use lts` on shell start | `nvm install lts` (after fisher) |

Optional: Google Chrome (only to re-render the GTA VI backdrop PNG from `assets/gta-vi/render.html`, see the comment in `themes/GTA VI`). Icons need no Nerd Font: Ghostty ships the Nerd Font symbols built in.

## Setup

Clone the repo, then make each folder in `.config/` available at `~/.config/<tool>`. How you do that (symlinks, rcm, Stow, copies) is up to you and outside this repo. Every config refers to `~/.config/<tool>`, never to the checkout path. The one exception is `~/dotfiles-custom/.scripts`, which fish adds to `PATH`.

```sh
git clone git@github.com:giovannirizzolo/dotfiles-custom.git ~/dotfiles-custom

# Fish plugins (Tide, z, fzf.fish, nvm.fish), from fish_plugins
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update'

# Paint tide, tmux and nvim with the default theme (Gotham Noir)
fish -c "ghostty_theme 'Gotham Noir'"
```

Then restart Ghostty (<kbd>cmd</kbd>+<kbd>q</kbd>), start tmux and press <kbd>prefix</kbd>+<kbd>I</kbd> to install the tmux plugins. Open `nvim` once to let LazyVim install its plugins.

On first use of the theme switcher, macOS asks whether the terminal may control Ghostty (AppleScript). Allow it, or the reload falls back to a signal.

Troubleshooting:

- **Theme colors look grey or washed out inside tmux:** the shell started before truecolor was enabled. Run `exec fish`.
- **A shell still shows old prompt colors:** check for `set -g tide_*color` overrides in `conf.d`. Globals beat the theme's values.

