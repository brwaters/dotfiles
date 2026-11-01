-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Bindings for Omarchy's preinstalled apps and web apps are switched off in
-- hyprland.lua (omarchy_preinstalled_bindings = false). The ones still wanted
-- are added back below; the rest (Herdr, Calculator, Signal, Omawrite,
-- Passwords, Grok, WhatsApp, Google Messages/Photos/Maps, X) stay off, which
-- frees SUPER + SHIFT + P and S.

o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
if o.cmd_present("lazydocker") then
  o.bind("SUPER + SHIFT + D", "Docker", { tui = "omarchy-launch-docker-tui" })
end
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })

-- Web apps via Firefox's WebApps profile instead of stock's Chromium, with the
-- original iCloud/Gmail destinations rather than stock's Hey.com.
local function firefox_webapp(url)
  return o.launch('firefox --no-remote -P "WebApps" --new-window --name WebApp ' .. url)
end

o.bind("SUPER + SHIFT + A", "ChatGPT", firefox_webapp("https://chatgpt.com"))
o.bind("SUPER + SHIFT + C", "Calendar", firefox_webapp("https://www.icloud.com/calendar"))
o.bind("SUPER + SHIFT + E", "Email", firefox_webapp("https://mail.google.com/mail/u/0/"))
o.bind("SUPER + SHIFT + Y", "YouTube", firefox_webapp("https://youtube.com/"))

-- Screenshot (was Google Maps).
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy capture screenshot")

-- About (was select all).
o.rebind("SUPER + A", "About", { omarchy = "about" })

-- Pomodoro on P (was pseudo window), stop on SHIFT + P (was Google Photos).
-- Pseudo window moves to U.
o.rebind("SUPER + P", "Pomodoro start/pause", "pomodoro-primary")
o.bind("SUPER + SHIFT + P", "Pomodoro stop", "pomodoro-stop")
o.bind("SUPER + U", "Pseudo window", hl.dsp.window.pseudo())

-- Transparency toggle between opaque and 0.65 with blur (stock only reaches
-- a terminal's 0.985 default). See ~/.local/bin/hypr-window-transparency-toggle.
o.rebind("SUPER + BACKSPACE", "Toggle window transparency", "hypr-window-transparency-toggle")
