-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Discord. Workspace assignment, silent placement, and no-initial-focus are
-- handled by the persistent window rules in hyprland.lua so they also apply
-- if Discord restarts later, not just at login.
o.launch_on_start("discord")
