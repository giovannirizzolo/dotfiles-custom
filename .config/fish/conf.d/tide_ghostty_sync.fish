# tide colors/style from the active Ghostty theme (written by
# tide_ghostty_colors). Sourced by every fish, including tide's background
# prompt job, so the globals here win over tide's universal defaults.
set -l __tgc_cache ~/.cache/fish/tide_ghostty.fish
test -f $__tgc_cache; and source $__tgc_cache

status is-interactive; or return

# `ghostty_theme` bumps the universal tide_theme_stamp: reload the cache,
# rebuild tide's cached prompt and redraw it right away.
function __tide_ghostty_sync --on-variable tide_theme_stamp
    source ~/.cache/fish/tide_ghostty.fish
    functions -q _tide_sub_reload; and tide reload
    commandline -f repaint
end
