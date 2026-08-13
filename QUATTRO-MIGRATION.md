# Omarchy Quattro Migration Guide

Working notes from migrating the laptop (T2 MacBook, host `axiom`) from Omarchy
3.8.x to Quattro (4.0.0, RC channel). Keep this updated as work continues, and
use it to move faster when the desktop's turn comes.

**Status:**
- Laptop (`axiom`, T2 MacBook): migrated 2026-08-13, RC channel, `4.0.0rc4-1`
- Desktop: not yet migrated

---

## Before you start (any machine)

- **Check `/etc/pacman.conf` for `IgnorePkg` or other custom entries first.**
  Any channel switch (`omarchy-channel-set`, the Update ▸ Channel menu, or the
  manual `omarchy-refresh-pacman <channel>` flow) does a hard `cp -f` of a
  fresh stock `pacman.conf` template — it silently drops anything custom, then
  immediately runs `pacman -Syyuu --noconfirm` in the same breath, no pause to
  react. If you have a pinned package (e.g. a kernel), back up its cached
  `.pkg.tar.zst` from `/var/cache/pacman/pkg/` *before* switching channels, so
  you can roll back if the pin gets silently dropped and something upgrades
  out from under you.
- **Never point an already-Quattro-installed system at the `stable` channel.**
  Stable still serves the pre-Quattro 3.8.x package line. Attempting it tries
  to downgrade ~300+ core packages (glibc, systemd, gcc, hyprland, binutils,
  ...) while the filesystem is already in Quattro's migrated state — a
  dangerous mismatch. We hit this for real; only avoided actual damage
  because unrelated file conflicts (gexiv2, mbedtls) blocked the transaction
  before anything committed. If you need current Quattro package updates,
  stay on `rc` (or `edge`) until Quattro is promoted to stable.
- **Back up Wi-Fi credentials** from `/var/lib/iwd/` before upgrading — not
  migrated automatically. The network stack itself switches from `iwd` to
  NetworkManager; only the currently-connected network gets handed off across
  the reboot, everything else needs re-adding manually afterward.
- **Decide deliberately about kernel handling** if you're on anything
  hardware-specific (e.g. `linux-t2`) rather than letting it move as a side
  effect of a channel switch — see the pin-backup note above.

## Upgrade sequence that actually worked

1. `omarchy-channel-set rc` (or Update ▸ Channel in the menu). Expect the
   pacman.conf overwrite described above, plus a forced `pacman -Syyuu` that
   may hit package conflicts blocking the transaction — we hit
   `qemu-common` vs `qemu-block-gluster`, resolved by running
   `sudo pacman -Syu` directly (not through the Omarchy wrapper, which uses
   `--noconfirm` and auto-declines conflict prompts) and answering `y` to
   remove the conflicting package.
2. Re-run `omarchy-update` afterward to actually finish the pipeline
   (`keyring → system-pkgs → migrate → aur-pkgs → orphan-pkgs`). A plain
   manual `pacman -Syu` bypasses the `omarchy-migrate` step entirely — that's
   what fires the "Upgrade to Omarchy Quattro" notification and bumps
   version markers, so skipping it means Quattro's invite never appears.
3. Reboot when prompted.
4. Run the actual migration: `omarchy-upgrade-to-quattro` (Update ▸ Omarchy
   To Quattro in the menu, or the notification's click action). This is the
   real work — rewrites Hyprland config to Lua, retires
   waybar/walker/mako/hypridle/hyprlock in favor of Quickshell, moves theme
   state paths, etc. **It writes no log file** — only prints to the terminal
   it runs in — so verify results by checking live system state afterward,
   not by reviewing a log.
5. Reboot again to complete the Lua config cutover. The pre-reboot session
   runs off legacy `.conf` compat shims so it doesn't crash mid-upgrade, but
   the real cutover to Quickshell/Lua only happens after this reboot.

## Known regressions to check for after migrating (any machine)

- `IgnorePkg` (and anything else custom in `pacman.conf`) — gone, re-add if
  needed.
- Wi-Fi networks other than the one active during the upgrade — need
  re-adding in NetworkManager.
- `systemd-zram-setup@zram0.service` may show a transient "device busy"
  failure in the live pre-reboot session — resolved cleanly on the real
  reboot, not a real problem.
- **PATH ordering**: `/usr/share/omarchy/bin` comes before `~/.local/bin` in
  `$PATH`, so a personal script placed in `~/.local/bin` under the *same
  name* as a stock Omarchy script gets silently shadowed — confirmed
  affecting `omarchy-launch-webapp`, `omarchy-launch-about`, `fastfetch-tui`,
  `omarchy-screensaver` on the laptop. **Do not "fix" this by reordering
  PATH** — checked `default/bash/envs` directly: the append (not prepend) is
  deliberate, with an idempotency guard around it, real engineering care, not
  an oversight. There's no per-command override directory the way plugins
  get `~/.config/omarchy/plugins/` (`omarchy dev link` is a different, much
  heavier tool for developing Omarchy itself, not for shadowing one script).
  The actual fix is per call site, not global — see Open Items / the
  screensaver fix below for the pattern that actually works.
- Any `~/.config/<app>/<file>` that's a stow symlink can get silently
  replaced by a disconnected regular file if some other tool does an atomic
  write (temp-file + rename) instead of writing through the symlink — this
  breaks the stow link without erroring. We hit this with `alacritty.toml`
  via the Quickshell display-scale/font-size panel. Check `ls -la` (look for
  `l` vs `-` in the permissions) on anything you suspect changed.

## T2 Mac specific (won't apply to desktop)

- The T2-defaults migration step reverts custom sleep-mode fixes:
  `/etc/limine-entry-tool.d/t2-mac.conf` gets regenerated with stock
  `mem_sleep_default=deep`, silently overriding a prior `s2idle` fix in
  `/etc/default/limine` (last `mem_sleep_default=` occurrence in the merged
  kernel cmdline wins). We deliberately left it at Quattro's stock `deep` to
  test whether the underlying hang is actually fixed now. Fallback staged at
  `/etc/limine-entry-tool.d/zz-t2-s2idle-fallback.conf.disabled` — rename off
  `.disabled` + `sudo limine-mkinitcpio` to reapply `s2idle` if deep sleep
  still hangs. **Verify testing outcome before doing this on desktop** (N/A
  anyway, desktop presumably isn't a T2 Mac).
- Filed upstream: **basecamp/omarchy#6833** — keyboard-layout bar widget can
  switch the wrong device. T2's audio controller exposes the headphone
  jack's inline remote as a fake HID keyboard ("Apple Headset", via
  `apple-bce`/`bce-vhci`), which wasn't excluded from the widget's device
  selection. Fixed locally via plugin clone at
  `laptop/omarchy/.config/omarchy/plugins/recon.keyboard-layout/`.
- Filed upstream: **basecamp/omarchy#6823** — dictation bar icon (voxtype)
  throws a raw shell error when voxtype isn't installed, instead of
  prompting to install. Not T2-specific, but found during this migration.

## Dotfiles restructuring approach (applies to any machine moving to Quattro)

- Old `~/.config/hypr/*.conf` files become dead weight. Hyprland only reads 6
  Lua files now: `hyprland.lua`, `bindings.lua`, `input.lua`, `looknfeel.lua`,
  `monitors.lua`, `autostart.lua`. The migration seeds these fresh as **plain
  files, not stow symlinks** — move each into the right dotfiles package and
  restow, same as adding any new untracked file (see this repo's own
  `CLAUDE.md`).
- Window rules aren't one of those 6 auto-loaded personal files —
  `hyprland.lua`'s own trailing comment (`-- Add any other personal Hyprland
  configuration below.`) is the sanctioned spot for ad-hoc `o.window(...)`
  rules.
- Waybar/walker/mako/swayosd are retired outright, replaced by Quickshell
  (`~/.config/omarchy/shell.json`/`shell.toml`, untracked by default unless
  you customize it). **hyprlock and hypridle are also fully gone** — not
  obviously so, since referencing them doesn't error, they just silently
  stop being read — replaced by Quickshell's own lock/idle service plugins.
- For per-widget/panel customization, use `omarchy plugin clone <id>` rather
  than editing files under `/usr/share/omarchy/` directly (read-only,
  clobbered by updates). `omarchy plugin list` / `omarchy plugin list --json`
  to find ids. Clone lands in `~/.config/omarchy/plugins/<you>.<id>/` — move
  that into a dotfiles package (we use
  `laptop/omarchy/.config/omarchy/plugins/...`) and restow like anything
  else. `omarchy restart shell` to pick up changes.
- **Before writing any window-rule/Lua-config syntax, verify against real
  currently-loaded files** under `~/.local/share/omarchy/default/hypr/`
  rather than trusting cached knowledge or a web search — we caught one
  WebFetch summary hallucinating old `windowrulev2` string syntax dressed up
  as "Lua." `/usr/share/hypr/stubs/hl.meta.lua` is Hyprland's own official
  type-stub (useful for strictly-typed core fields), but real usage examples
  in `default/hypr/apps/*.lua` and `default/hypr/windows.lua` are more
  reliable for the full dynamic property surface (e.g. `float` vs `floating`
  as a match key, `no_initial_focus` vs `no_focus`).

## Config port status (laptop)

**Done:**
- `bindings.lua` — touchpad toggle (`SUPER+Z`), About (`SUPER+A` → stock
  `omarchy-launch-about`, replacing the obsolete `fastfetch-tui` +
  tag-based-sizing override chain), web app shortcuts
  (`SUPER+SHIFT+A/C/E/Y` → Firefox directly, replacing the shadowed
  `omarchy-launch-webapp` override; Calendar/Email also got their original
  destinations back, iCloud/Gmail instead of stock's Hey.com)
- `input.lua` — full port (keyboard layout, repeat rate, touchpad tuning,
  Magic Mouse 2 sensitivity, per-terminal scroll speeds)
- `monitors.lua` — pinned `eDP-1` @ scale `1.67` (macOS "More Space" parity)
  via the `omarchy_monitor_scale` variable (kept for display-scale panel
  compatibility), wildcard fallback at scale `1` for external monitors
- `looknfeel.lua` — nothing was active in the old config either, just
  brought under tracking
- `windows.conf` rules → ported into `hyprland.lua` (Discord workspace 10 +
  silent + no-initial-focus, floating-window rounding). TUI floating-size
  rule dropped: fastfetch-tui is now the self-sizing "About" window, satty
  isn't installed anymore (replaced by Tensaku), btop not worth a custom
  size for now.
- `autostart.lua` — Discord launch on login
- Removed all dead pre-Quattro `.conf` files from tracking (verified
  `hyprsunset.conf`/`xdph.conf` are still genuinely live before excluding
  them from the cleanup, rather than assuming based on the others' pattern)
- Removed dead `laptop/waybar` package — `~/.config/waybar/` no longer
  exists on disk at all, and the custom `tailscale.sh` status/toggle script
  is comprehensively superseded by a stock `omarchy.tailscale` bar widget
  (already enabled) with a full panel: machine browsing, Taildrop sending,
  IP/hostname/DNS copy, keyboard shortcuts. `desktop/waybar` intentionally
  left alone — that machine hasn't migrated yet

**Plugin clones:**
- `recon.keyboard-layout` — T2 "Apple Headset" device-selection fix
- `recon.monitor` — display-scale preset swapped `1.6` → `1.67`
- `recon.workspaces` — persistent workspaces 1–10 (was 1–5 + active only),
  workspace 10 labeled "D" for Discord
- `recon.idle` — redirects the idle service's screensaver launch to
  `recon-launch-screensaver` (see below) instead of trying to shadow the
  stock name

**Personal bin scripts (`laptop/bin`):**
- `recon-screensaver` — fork of `omarchy-screensaver`, `ttfx` frame rate
  `120` → `30` (the only real performance lever; nothing else in the script
  is expensive)
- `recon-launch-screensaver` — fork of `omarchy-launch-screensaver`, same
  terminal-selection/multi-monitor logic, points at `recon-screensaver`
  instead of the stock name

**Override pattern reference** (all three originally-flagged PATH-shadowed
items are now resolved — keeping this for the next time something similar
comes up):
Confirmed the "just fix PATH" instinct was wrong — see the PATH note above.
The actual fix is per call site:
- If a stock **keybinding** calls the shadowed command (e.g.
  `omarchy-launch-webapp`, baked in via `{ webapp = "..." }` in
  `applications.lua`): `hl.unbind` + `o.bind` with your own command directly
  in `bindings.lua`, following the pattern already documented in its own
  template comment. Used for the web app shortcuts.
- If the override target is now redundant with a stock feature (e.g.
  `fastfetch-tui`/`omarchy-launch-about`, superseded by the new
  self-sizing About window): just drop the override and rebind the key to
  the stock command directly. No shadowing fix needed at all.
- If a stock **plugin/service** calls it (e.g. the idle service calling
  `omarchy-launch-screensaver`): `omarchy plugin clone` the plugin and
  redirect the one line. Used for the screensaver fix.

**Open items:**
- Review `environment-d` packages (`base`/`laptop`/`desktop`) —
  `local-bin-path.conf` may be relevant to the PATH item above (systemd
  environment.d affects the graphical session's PATH, not just shell PATH) —
  though note the PATH ordering itself should NOT be changed, just worth
  understanding what this file actually does
- Confirm T2 sleep-mode test outcome (deep vs s2idle) and update the T2
  section above either way

## Upstream issues filed

- [basecamp/omarchy#6823](https://github.com/basecamp/omarchy/issues/6823) —
  dictation bar icon errors when voxtype isn't installed
- [basecamp/omarchy#6833](https://github.com/basecamp/omarchy/issues/6833) —
  keyboard-layout widget can target wrong device on T2 Macs
