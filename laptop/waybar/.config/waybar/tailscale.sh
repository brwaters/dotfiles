#!/bin/bash
tailscale status --json 2>/dev/null | python3 -c "
import json, sys

d = json.load(sys.stdin)
state = d.get('BackendState', '')
s = d.get('Self', {})

if state == 'Running':
    tooltip = '\n'.join([
        'State: ' + d.get('BackendState', '?'),
        'Host:  ' + str(s.get('HostName', '?')),
        'IP:    ' + str(s.get('TailscaleIPs', ['?'])[0]),
        'Relay: ' + str(s.get('Relay', 'direct')),
    ])
    print(json.dumps({'text': '󰒃', 'class': 'connected', 'tooltip': tooltip}))
else:
    print(json.dumps({'text': '󰒃', 'class': 'disconnected', 'tooltip': 'Tailscale: ' + state}))
"
