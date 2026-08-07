#!/bin/bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/omarchy-pomodoro"
state_file="$state_dir/state"

[[ -f $state_file ]] || exit 0

read -r phase status value <"$state_file"

if [[ $status == running ]]; then
  remaining=$((value - $(date +%s)))
  ((remaining > 0)) || exit 0
  systemctl --user stop "omarchy-pomodoro-${phase}.timer" "omarchy-pomodoro-${phase}.service" 2>/dev/null || true
  echo "$phase paused $remaining" >"$state_file"
  omarchy-notification-send "🍅" "Pomodoro paused" -u low
else
  end_epoch=$(($(date +%s) + value))
  echo "$phase running $end_epoch" >"$state_file"
  systemd-run --user --quiet --collect --on-active="${value}s" --unit="omarchy-pomodoro-${phase}" \
    bash "$HOME/.config/waybar/pomodoro-advance.sh" "$phase"
  omarchy-notification-send "🍅" "Pomodoro resumed" -u low
fi

pkill -RTMIN+12 waybar 2>/dev/null || true
