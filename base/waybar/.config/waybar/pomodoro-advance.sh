#!/bin/bash
set -euo pipefail

break_minutes=5

state_dir="${XDG_RUNTIME_DIR:-/tmp}/omarchy-pomodoro"
state_file="$state_dir/state"
phase=$1

if [[ $phase == work ]]; then
  end_epoch=$(($(date +%s) + break_minutes * 60))
  echo "break running $end_epoch" >"$state_file"
  omarchy-notification-send "🍅" "Work session complete" "Time for a ${break_minutes}-minute break" -u critical
  systemd-run --user --quiet --collect --on-active="${break_minutes}m" --unit=omarchy-pomodoro-break \
    bash "$HOME/.config/waybar/pomodoro-advance.sh" break
else
  rm -f "$state_file"
  omarchy-notification-send "🍅" "Break's over" "Ready for another pomodoro?" -u critical
fi

pkill -RTMIN+12 waybar 2>/dev/null || true
