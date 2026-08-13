-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

hl.config({
  input = {
    kb_layout = "us,gr",
    kb_options = "compose:caps,grp:alts_toggle",

    repeat_rate = 40,
    repeat_delay = 250,

    numlock_by_default = true,

    accel_profile = "flat",

    touchpad = {
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = true,
    },
  },
})

-- Magic Mouse 2
hl.device({
  name = "brendon's-magic-mouse-2",
  sensitivity = -0.5,
})

-- App-specific touchpad scroll speeds.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
