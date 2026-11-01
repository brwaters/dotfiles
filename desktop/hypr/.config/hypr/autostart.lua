-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Make DP-1 XWayland's primary output. Steam runs under XWayland and puts its
-- notifications on the primary output, which Hyprland's own config can't set.
o.exec_on_start("xrandr --output DP-1 --primary")

-- Firefox on workspace 9 (the upper side monitor), without switching there or
-- taking focus. Launch rules only apply to this first window, unlike a window
-- rule, which would send every Firefox window to 9. Launched directly rather
-- than through o.launch()'s uwsm-app wrapper so Hyprland can match the window
-- to the process it started.
hl.on("hyprland.start", function()
  hl.exec_cmd("firefox", { workspace = "9 silent", no_initial_focus = true })
end)

-- Discord. Workspace 10, silent placement, and no-initial-focus come from the
-- persistent window rule in hyprland.lua, so they also apply if Discord
-- restarts later, not just at login.
o.launch_on_start("discord")

-- OpenRGB: run the SDK server, then apply the color profile once it's up.
o.launch_on_start("openrgb --server")
o.exec_on_start("sleep 10 && ~/.local/bin/personal_openrgb_set_colors")
