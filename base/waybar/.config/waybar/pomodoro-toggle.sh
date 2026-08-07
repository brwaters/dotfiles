#!/bin/bash
set -euo pipefail

work_minutes=25

state_dir="${XDG_RUNTIME_DIR:-/tmp}/omarchy-pomodoro"
state_file="$state_dir/state"
mkdir -p "$state_dir"

if [[ -f $state_file ]]; then
  systemctl --user stop omarchy-pomodoro-work.timer omarchy-pomodoro-break.timer \
    omarchy-pomodoro-work.service omarchy-pomodoro-break.service 2>/dev/null || true
  rm -f "$state_file"
  omarchy-notification-send "🍅" "Pomodoro cancelled" -u low
else
  end_epoch=$(($(date +%s) + work_minutes * 60))
  echo "work running $end_epoch" >"$state_file"
  systemd-run --user --quiet --collect --on-active="${work_minutes}m" --unit=omarchy-pomodoro-work \
    bash "$HOME/.config/waybar/pomodoro-advance.sh" work
  omarchy-notification-send "🍅" "Pomodoro started" "${work_minutes} minute work session" -u low
fi

pkill -RTMIN+12 waybar 2>/dev/null || true
