#!/bin/bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/omarchy-pomodoro"
state_file="$state_dir/state"

idle() {
  echo '{"alt": "idle", "class": "idle", "text": "", "tooltip": "Pomodoro: click to start a 25m session"}'
}

[[ -f $state_file ]] || { idle; exit 0; }

read -r phase status value <"$state_file"

if [[ $status == paused ]]; then
  remaining=$value
else
  remaining=$((value - $(date +%s)))
fi

if ((remaining <= 0)); then
  idle
  exit 0
fi

time_str=$(printf "%d:%02d" $((remaining / 60)) $((remaining % 60)))

if [[ $status == paused ]]; then
  echo "{\"alt\": \"${phase}\", \"class\": \"${phase}-paused\", \"text\": \" ${time_str}\", \"tooltip\": \"Pomodoro: ${time_str} left in ${phase} (paused, right-click to resume)\"}"
else
  echo "{\"alt\": \"${phase}\", \"class\": \"${phase}\", \"text\": \" ${time_str}\", \"tooltip\": \"Pomodoro: ${time_str} left in ${phase} (right-click to pause)\"}"
fi
