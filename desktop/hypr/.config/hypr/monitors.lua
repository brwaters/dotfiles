-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Straight 1x setup: 1440p primary and two 1080p side monitors.
hl.env("GDK_SCALE", "1")

-- Primary, straight ahead.
hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })

-- Two side monitors stacked on the left, upper and lower.
hl.monitor({ output = "DP-2", mode = "1920x1080@144", position = "-1920x-360", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@144", position = "-1920x720", scale = 1 })

-- Fallback for anything else plugged in.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspace assignments: 1-8 on the primary, 9 (Firefox) on the upper side
-- monitor, 10 (Discord) on the lower one. Only meaningful with the global
-- workspaces from hypr/workspaces.lua, not 4.5's per-monitor blocks.
for workspace = 1, 8 do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-1" })
end
hl.workspace_rule({ workspace = "9", monitor = "DP-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })
