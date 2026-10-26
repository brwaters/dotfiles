# Omarchy Quattro Migration Guide

Working notes from migrating the laptop (T2 MacBook, host `axiom`) from Omarchy
3.8.x to Quattro (4.0.0, RC channel). Keep this updated as work continues, and
use it to move faster when the desktop's turn comes.

**Status:**
- Laptop (`axiom`, T2 MacBook): migrated 2026-08-13, RC channel, `4.0.0rc4-1`;
  updated to `4.5.0rc1-1` on 2026-10-25 and plugin clones re-cloned against it
  (see "4.5 update" below)
- Desktop: not yet migrated. Plan: the desktop adapts itself from the
  `laptop/` packages as the reference, rather than restructuring `laptop/`
  into `base/` first. The Nautilus-script blocker (next section) is most
  likely resolved: confirm `pin-file-manager-icons` is the script.
- **Don't `git pull` on the desktop before migrating it.** `main` has deleted
  pre-Quattro files the desktop still uses live (`base/hypr/bindings.conf`,
  `looknfeel.conf`, `base/alacritty`, etc.). Pulling first would leave
  dangling stow symlinks on a 3.8.x system. Migrate, then pull.

---

## Untracked desktop state to check before migrating

- **Update 2026-10-25: probably found, already in the repo.** Commits
  `e2e617c`/`333c4c0` (Aug 9, pushed from the desktop but never pulled on the
  laptop until 2026-10-25) added
  `{desktop,laptop}/omarchy/.config/omarchy/hooks/theme-set.d/pin-file-manager-icons`.
  It's a theme-set hook, not a nautilus-python extension. On every theme
  switch it builds a "SimpleLines" icon theme from Adwaita's symbolic
  folder/mimetype SVGs, recolored to the theme's accent from `colors.toml`.
  Confirm this is the script on the desktop before treating the blocker as
  closed. Under Quattro, check that its `~/.config/omarchy/current/theme/colors.toml`
  path still resolves (theme state paths moved) and that `theme-set.d` hooks
  still fire. Original note below.
- **Nautilus accent-color icon script.** A script exists (desktop only, likely
  not yet committed to this repo) that watches the Omarchy theme's accent
  color and applies it to a set of SimpleIcons-derived SVGs, integrated with
  Nautilus — probably a `nautilus-python` extension following the same
  pattern as `localsend.py`/`transcode.py` in
  `~/.local/share/nautilus-python/extensions/` on the laptop, which are also
  untracked. Confirmed not present anywhere in this repo (`base/` or
  `desktop/`) or in laptop `.bash_history`/`nautilus-python` dirs as of
  2026-08-13 — it only lives on desktop's disk. **Before migrating desktop,
  locate it, move it into a stow package (`desktop/nautilus-python/...` or
  similar per this repo's "Adding a new file to the dotfiles" convention in
  `CLAUDE.md`), and commit it** — otherwise the migration's package
  removals/theme-state-path changes could silently break or lose it, the same
  way `laptop/waybar`'s `tailscale.sh` almost did.

## Pre-Quattro features still to port (from the Aug 7–9 desktop commits)

Ten desktop commits (Aug 7–9) were merged into `main` on 2026-10-25. Five
touched pre-Quattro files that `main` had already deleted. Those deletions
were kept, so the content only lives in history now. `git show <hash>` to
recover it.

- **Square window corners** (`19800b3`). The Hyprland part was
  `rounding = 0` in `base/hypr/looknfeel.conf`; port it to `looknfeel.lua`.
  The swayosd / walker "square" theme / `zero-mako-rounding` hook parts
  target retired apps (now dead on Quattro, still live on 3.8 desktop).
  Check whether Quickshell's bar/OSD/notifications need their own rounding
  override.
- **Super+Backspace transparency toggle** (`2e50d90`, corrected by
  `abde711`). The `base/bin/.local/bin/hypr-window-transparency-toggle`
  script came through. Still to port: the `unbind`/rebind of
  `SUPER + BACKSPACE` (was `bindings.conf`), `blur.ignore_opacity = true`
  (`abde711` reversed `2e50d90`'s `false`; `true` is right), and the
  terminal-tag opacity override (`windowrule = opacity 1.0 1.0, match:tag
  terminal`). First check whether stock 4.5's toggle works now. The
  alacritty opacity part is moot (foot is the terminal).
- **Pomodoro** (`4cd72d4`, `5e686d0`). The `base/bin` scripts
  (`pomodoro-primary/stop/status/advance`) came through. Still to port: the
  `SUPER + P` / `SUPER + SHIFT + P` bindings, and moving stock Pseudo window
  from `SUPER + P` to `SUPER + U`. The waybar module would need a Quickshell
  bar widget (or a plugin) to show status.
- **Mako on primary display** (`a767f11`, `pin-mako-output` hook). Mako is
  retired; check whether Quickshell notifications have an output setting.
- `base/bin` is a new stow package; it isn't stowed on the laptop yet.
- `base/swayosd`, `base/walker`, `base/waybar` modules, and the mako hooks
  are pre-Quattro only. Delete them once the desktop is migrated.

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
- **If you find a `~/.config/environment.d/*.conf` file trying to prepend
  `~/.local/bin` to `PATH`** (we had one, `local-bin-path.conf`) — it's
  likely dead. UWSM's `prepare-env.sh` re-sources `/etc/profile` (which
  chains into the same append-only PATH logic above) *after*
  `environment.d` runs, discarding any such prepend. Confirmed via
  `systemctl --user show-environment` showing the stock order despite the
  file being present and correctly symlinked. Check for this specifically
  before assuming an old `environment.d` PATH override still works under
  Quattro — it was probably a pre-Quattro workaround for the exact problem
  above, now silently ineffective rather than erroring.
- Any `~/.config/<app>/<file>` that's a stow symlink can get silently
  replaced by a disconnected regular file if some other tool does an atomic
  write (temp-file + rename) instead of writing through the symlink — this
  breaks the stow link without erroring. We hit this with `alacritty.toml`
  via the Quickshell display-scale/font-size panel. Check `ls -la` (look for
  `l` vs `-` in the permissions) on anything you suspect changed.

## Lost features (no Quattro replacement yet)

- **Websearch fallback in the app launcher.** Pre-Quattro used `walker` +
  `elephant` (a whole provider ecosystem: `elephant-all`, `elephant-calc`,
  `elephant-clipboard`, `elephant-websearch`, etc.), all explicitly retired
  in the migration script's package-removal list. The new Quickshell
  launcher's search (`shell/services/AppSearch.js`,
  `shell/Ui/SearchableDropdown.qml`) is local-app-only — checked both
  directly, zero references to web search, URLs, or a search-engine concept
  anywhere. Old config (`base/elephant/.config/elephant/websearch.toml`) set
  DuckDuckGo as the default fallback engine; removed from tracking since
  there's nothing to port it to, but documenting here in case Quattro adds
  an equivalent later (worth checking again on future RC releases, or
  filing an upstream feature request if this is wanted back).

## T2 Mac specific (won't apply to desktop)

- The T2-defaults migration step reverts custom sleep-mode fixes:
  `/etc/limine-entry-tool.d/t2-mac.conf` gets regenerated with stock
  `mem_sleep_default=deep`, silently overriding a prior `s2idle` fix in
  `/etc/default/limine` (last `mem_sleep_default=` occurrence in the merged
  kernel cmdline wins). **Closed as not applicable, not tested**: turns out
  suspend has been deliberately disabled on this machine since well before
  Quattro (`~/.local/state/omarchy/toggles/suspend-off`, dated back on
  3.8.x) — lid-close goes to hibernate, and there's no automatic path to
  suspend at all (`logind`'s `IdleAction` is unset/`ignore` by default, and
  the Quickshell idle service has no suspend concept in its code, only
  `lock`/`screensaver` timers). Since suspend isn't used day-to-day here,
  not worth spending effort verifying whether `deep` still hangs. Fallback
  stays staged at `/etc/limine-entry-tool.d/zz-t2-s2idle-fallback.conf.disabled`
  in case this ever changes — rename off `.disabled` + `sudo limine-mkinitcpio`
  to reapply `s2idle`. **On desktop**: check whether suspend is actually used
  there before assuming this doesn't matter — this machine's decision to
  skip it was specific to how *this* machine is used, not a general Quattro
  recommendation.
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

**Gotcha: "reset bar to defaults" menu actions silently revert plugin clones.**
Running a reset action (e.g. `omarchy bar defaults`, or an equivalent menu
item) disables all `bar-widget`-kind plugin clones and re-enables their
stock first-party equivalents in `shell.json` — happened to
`recon.monitor`, `recon.keyboard-layout`, and `recon.workspaces`
simultaneously from what looked like one action. Only `recon.idle`
survived, because it's plugin kind `service`, not `bar-widget` — the reset
appears scoped to bar widgets specifically. The clone's file content and
symlink are untouched by this (don't need to re-symlink anything) — it's
purely an enable/disable + `shell.json` reference flip. Fix: `omarchy
plugin enable recon.<name>` for each affected one, then `omarchy restart
shell`. Check `omarchy plugin list` for any `recon.*` entries showing
`disabled` after running any kind of bar/shell reset.

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
- Removed dead `laptop/environment-d/local-bin-path.conf` — see the PATH
  regression note above. `desktop/environment-d`'s copy intentionally left
  alone since it may still be effective under 3.8.x's session-startup flow

**Plugin clones** (re-cloned from 4.5.0rc1 on 2026-10-25, see "4.5 update"):
- `recon.monitor` — display-scale preset swapped `1.6` → `1.67`; text-size
  slider redirected to `recon-display-text-size` (see below) instead of the
  stock command, so it can never overwrite foot's font size
- `recon.workspaces` — global workspaces 1–10 on every bar (stock 4.5 shows
  per-monitor blocks), workspace 10 labeled "D" for Discord. Pairs with
  `hypr/workspaces.lua`
- `recon.idle` — redirects the idle service's screensaver launch to
  `recon-launch-screensaver` (see below) instead of trying to shadow the
  stock name
- *Retired in 4.5:* `recon.keyboard-layout` (upstream fixed #6833) and
  `recon.indicators` (upstream fixed clone service lookup, see the gotcha
  below)

**Gotcha (fixed upstream in 4.5, kept for history): cloning a service broke
any other widget that referenced it by literal id.** As of 4.5,
`shell.qml`'s `firstPartyServiceFor` goes through
`pluginRegistry.resolveEnabledId()`, which maps `"omarchy.idle"` to whichever
enabled clone has `clonedFrom: "omarchy.idle"`. Plugin facades also only
allow the *stock* ids, so referencing `"recon.idle"` directly now returns
`null`: the old `recon.indicators` fix broke Stay Awake again under 4.5. Keep
referencing stock ids. Original 4.0 notes: Service lookups (`shell.qml`'s `serviceFor`/`_syncServices`)
key strictly off the plugin's own id — `clonedFrom` in a clone's manifest is
only used for IPC target routing, it's never consulted by service lookups
despite `omarchy-plugin-clone`'s own comment claiming otherwise ("the shell
uses clonedFrom to route those calls"). So cloning `omarchy.idle` →
`recon.idle` silently broke `StayAwake.qml` (hardcoded
`firstPartyServiceFor("omarchy.idle")`, returned `null` once the original
was disabled) — found only when it stopped working days later, not at
clone time. Before cloning any `service`-kind plugin, `grep -rl
'"<plugin-id>"' ~/.local/share/omarchy/shell/` first to find every widget
that references it by literal id, and check each one still resolves
afterward. This is a personal-setup issue, not an upstream bug report —
it's specific to renaming the active service via a clone, not something
that affects stock installs.

**Personal bin scripts (`laptop/bin`):**
- `recon-screensaver` — fork of `omarchy-screensaver`, `ttfx` frame rate
  `120` → `30` (the only real performance lever; nothing else in the script
  is expensive)
- `recon-launch-screensaver` — fork of `omarchy-launch-screensaver`, same
  terminal-selection/multi-monitor logic, points at `recon-screensaver`
  instead of the stock name
- `recon-display-text-size` — fork of `omarchy-display-text-size`, identical
  except `set_terminal_size()` no longer touches `foot.ini` at all. That
  stock command does a blind regex overwrite of foot's `:size=` on every
  call — it would silently clobber a manually-set font size the next time
  the display panel's text-size slider (or the raw CLI command) is used for
  literally anything else. Called from `recon.monitor`'s slider instead of
  the stock name. **Residual gap**: the raw CLI typed directly still hits
  the stock script and would still overwrite `foot.ini` — no way to cover
  that without the same PATH-shadowing fight documented below. This covers
  the panel slider specifically, the normal way it's triggered.

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
- None currently. T2 sleep-mode test closed as not applicable — see the T2
  Mac section above.

## 4.5 update (laptop, 2026-10-25)

`4.0.0rc4-1` → `4.5.0rc1-1`. Plugin clones don't follow upstream, so they were
two months stale. To audit them, the stock version each clone was taken from
was extracted from `/var/cache/pacman/pkg/omarchy-4.0.0rc{3,4}-1-any.pkg.tar.zst`
(check clone dates against `pacman.log`, since some were taken on rc3). That
gives a three-way comparison: old stock → clone (my edits) and old stock →
new stock (upstream changes). Every clone's personal edit was 1–17 lines, so
the fix was re-cloning fresh and re-applying the edits, not merging.

**Re-clone without disturbing the live shell:** `omarchy plugin clone` refuses
when the target dir exists (it does, as a stow symlink) and also enables and
rescans. Instead, run its `copy_plugin` + `update_manifest` functions into a
scratch dir, apply the edits there, then `rsync -a --delete` into the dotfiles
package. The ids don't change, so there's no enable/disable step and the
shell hot-reloads.

What changed:
- `recon.monitor` — stock now enables/disables monitors via
  `hyprctl eval 'hl.monitor({...})'`, because `hyprctl keyword` is rejected
  under the Lua config. The 4.0 clone still used `keyword`, so its toggle was
  likely broken.
- `recon.idle` — timer fixes (a timeout of 0 actually disables; editing
  `shell.json` no longer restarts a pending timer).
- `recon.indicators` — retired (see gotcha above). Stock also gained
  PasswordlessSudo and RemoteSession indicators and dropped Dictation.
- `laptop/bin` forks (`recon-screensaver`, `recon-launch-screensaver`,
  `recon-display-text-size`): their stock originals are byte-identical
  between rc4 and 4.5.0rc1, so nothing to port.
- `recon.keyboard-layout` — retired. #6833 was fixed by switching the layout
  on *every* keyboard on click, so the phantom "Apple Headset" can't steal it.
- **Per-monitor workspaces (new in 4.5, opted out of).**
  `default/hypr/monitor-workspaces.lua` gives every monitor its own block of
  10 (laptop panel 1–10, next monitor 11–20, …), renumbers and moves
  workspaces on start/reload/hotplug, and rebinds SUPER+1–0 and
  SUPER+SHIFT+ALT+arrows to block-aware versions. `omarchy.lua` requires it
  unconditionally, with no flag. The opt-out is two parts:
  - `laptop/hypr/.config/hypr/workspaces.lua` (required from `hyprland.lua`
    after `hypr.bindings`) replaces `o.workspaces.reconcile` with a no-op.
    Its event handlers look it up at call time, so that disarms them all.
    It also replaces `o.workspaces.focus`/`move_window`/`move_to_monitor`
    with global versions and rebinds the keys, since stock binds captured
    the old functions.
  - `recon.workspaces` re-cloned from 4.5. It keeps the layout glyph,
    click-to-cycle layout and wheel scrolling, but shows a global 1–10 and
    marks the globally focused workspace instead of per-monitor slots.
  - **For the desktop:** copy both pieces. The old `workspace=N,monitor:DP-1`
    pins and Discord on 10 only make sense with global workspaces. Untested
    so far on multiple monitors (the laptop only had eDP-1 during the change).

## Upstream issues filed

- [basecamp/omarchy#6823](https://github.com/basecamp/omarchy/issues/6823) —
  dictation bar icon errors when voxtype isn't installed (still open; the
  Dictation indicator was dropped from the bar in 4.5)
- [basecamp/omarchy#6833](https://github.com/basecamp/omarchy/issues/6833) —
  keyboard-layout widget can target wrong device on T2 Macs (fixed in 4.5)
