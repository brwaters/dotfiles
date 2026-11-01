-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings. The ones still wanted are added back
-- in hypr/bindings.lua.
omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.workspaces")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.

-- Variable refresh rate on fullscreen apps only (games, video).
hl.config({ misc = { vrr = 2 } })

-- For the SUPER + BACKSPACE transparency toggle (hypr-window-transparency-toggle):
-- blur behind windows whose opacity is changed at runtime. false sounds right
-- but renders them flat see-through with no blur; some themes set it either
-- way, so force it.
hl.config({ decoration = { blur = { ignore_opacity = true } } })

-- Terminals fully opaque by default, instead of stock's barely-visible
-- 0.985/0.96, so the toggle is the only thing making them translucent.
o.window({ tag = "terminal" }, { opacity = "1.0 1.0" })

-- Discord: open on workspace 10 without switching your view there, and don't
-- steal focus when it does. Single unconditional match on class only --
-- splitting no_initial_focus into a second rule gated on workspace = "10"
-- raced against the first rule's own workspace assignment and let initial
-- focus slip through at startup.
o.window("^(discord)$", { workspace = "10 silent", no_initial_focus = true })

-- Round corners on all floating windows.
o.window({ float = true }, { rounding = 4 })

-- Steam's sign-in window: put it on workspace 1, centered. Its notifications
-- follow XWayland's primary output, set in autostart.lua.
o.window({ class = "^(steam)$", title = "^(Sign in to Steam)$" }, { workspace = "1", center = true })

-- Steam's main window, larger than stock's 1100x700 for the bigger font size.
o.window({ class = "steam", title = "Steam" }, { size = { 1800, 1000 } })

-- btop: larger than the standard 875x600 float. Drop the floating-window tag
-- so its size rule doesn't compete with this one.
o.window("^(org\\.omarchy\\.btop)$", { tag = "-floating-window", float = true, center = true, size = { 1450, 820 } })
