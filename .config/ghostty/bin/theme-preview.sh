#!/usr/bin/env bash
# fzf preview for ghostty_theme: draws a theme's colors in truecolor.
# Usage: theme-preview.sh <theme name> <themes dir>...
name=$1; shift
for d in "$@"; do [ -f "$d/$name" ] && { f="$d/$name"; break; }; done
[ -n "$f" ] || exit 0
hex() { grep -E "^$1 *=" "$f" | head -1 | sed -E 's/.*= *#?//; s/[[:space:]].*//'; }
pal() { grep -E "^palette *= *$1=" "$f" | head -1 | sed -E 's/.*=#?//; s/[[:space:]].*//'; }
rgb() { printf '%d;%d;%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
bg=$(hex background); fg=$(hex foreground); cur=$(hex cursor-color)
B=$(rgb "$bg"); F=$(rgb "$fg")
line() { printf '\e[48;2;%sm\e[38;2;%sm %-46s\e[0m\n' "$B" "$F" "$1"; }
line ""
printf '\e[48;2;%sm\e[38;2;%sm ~/vice-city \e[38;2;%sm❯\e[38;2;%sm git status%-24s\e[0m\n' \
  "$B" "$(rgb "$(pal 4)")" "$(rgb "$(pal 2)")" "$F" ""
printf '\e[48;2;%sm\e[38;2;%sm   modified: \e[38;2;%smheist.lua\e[38;2;%sm   # TODO%-17s\e[0m\n' \
  "$B" "$F" "$(rgb "$(pal 1)")" "$(rgb "$(pal 8)")" ""
line ""
for row in 0 8; do
  printf '\e[48;2;%sm ' "$B"
  for i in $(seq $row $((row + 7))); do
    c=$(pal "$i"); [ -n "$c" ] || continue
    printf '\e[48;2;%sm    \e[48;2;%sm ' "$(rgb "$c")" "$B"
  done
  printf '\e[0m\n'
done
line ""
[ -n "$cur" ] && printf '\ncursor \e[48;2;%sm  \e[0m  bg #%s  fg #%s\n' "$(rgb "$cur")" "$bg" "$fg"
