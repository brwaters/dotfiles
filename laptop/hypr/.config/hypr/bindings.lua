-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- MacBook: toggle touchpad (ported from pre-Quattro bindings-mac.conf)
o.bind("SUPER + Z", "Toggle touchpad", "omarchy toggle touchpad")

-- About (stock omarchy-launch-about now auto-fits its own window size, so
-- the old fastfetch-tui + tag-based sizing rule isn't needed anymore).
o.bind("SUPER + A", "About", { omarchy = "about" })

-- Web apps via Firefox instead of stock's Chromium (own custom
-- omarchy-launch-webapp override never took effect -- ~/.local/bin is
-- deliberately lower PATH priority than /usr/share/omarchy/bin, so it always
-- lost to the stock script of the same name; rebinding directly here avoids
-- the naming collision instead of fighting PATH order).
local function firefox_webapp(url)
  return o.launch('firefox --no-remote -P "WebApps" --new-window --name WebApp ' .. url)
end

hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "ChatGPT", firefox_webapp("https://chatgpt.com"))

-- Calendar/Email: stock now points these at Hey.com instead of
-- iCloud/Gmail, so restoring the original destinations too, not just switching
-- the browser.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", firefox_webapp("https://www.icloud.com/calendar"))

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", firefox_webapp("https://mail.google.com/mail/u/0/"))

hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + SHIFT + Y", "YouTube", firefox_webapp("https://youtube.com/"))
