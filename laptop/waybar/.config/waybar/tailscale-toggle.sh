#!/bin/bash
state=$(tailscale status --json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('BackendState',''))" 2>/dev/null)
if [ "$state" = "Running" ]; then
    tailscale down
else
    tailscale up
fi
