-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.67

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- MacBook Air 13" 2560x1600 — "More Space" equivalent (macOS parity)
hl.monitor({ output = "eDP-1", mode = "2560x1600@60", position = "0x0", scale = omarchy_monitor_scale })

-- Fallback for anything else you plug in (most external monitors want scale 1,
-- not the internal panel's density — adjust per-monitor below if needed).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°)
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Example for Framework 13 w/ 6K XDR Apple display
-- hl.monitor({ output = "DP-5", mode = "6016x3384@60", position = "auto", scale = 2 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })

-- Disable the second ghost monitor on an Apple 6K XDR over Thunderbolt
-- hl.monitor({ output = "DP-2", disable = true })
