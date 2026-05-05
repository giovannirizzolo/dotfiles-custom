#!/usr/bin/env fish

set conf "$HOME/.config/tmux/next_trip/next_trip.fish"

if test -f "$conf"
    source "$conf"
end

if not set -q TRIP_NAME; or test -z "$TRIP_NAME"
    echo "Add next trip destination to next_trip.fish"
    exit 0
end

if not set -q TRIP_DATE; or test -z "$TRIP_DATE"
    echo "Add next trip date to next_trip.fish in format YYYY-MM-DD"
    exit 0
end

if test (uname) = Darwin
    set t (date -j -f %Y-%m-%d "$TRIP_DATE" +%s 2>/dev/null)
else
    set t (date -d "$TRIP_DATE" +%s 2>/dev/null)
end
set n (date +%s)
set r (math "$t - $n")

if test "$r" -le 0
    echo "Add next trip to next_trip.fish"
    exit 0
end

echo (math --scale=0 "$r / 86400")d left to $TRIP_NAME
