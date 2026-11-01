-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

hl.config({
  input = {
    -- US and Greek, switched with Left Alt + Right Alt. Caps Lock is Compose.
    kb_layout = "us,gr",
    kb_options = "compose:caps,grp:alts_toggle",

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    -- Raw mouse movement: no sensitivity boost, no acceleration.
    sensitivity = 0,
    accel_profile = "flat",
  },
})
