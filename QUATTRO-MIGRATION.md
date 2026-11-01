# Omarchy Quattro Migration Guide

Working notes from migrating both machines from Omarchy 3.8.x to Quattro
(4.x): the laptop (T2 MacBook, host `axiom`) first, then the desktop (host
`void`). Keep this updated as work continues; the next Omarchy release or a
reinstall will hit the same gotchas.

**Status:**
- Laptop (`axiom`, T2 MacBook): migrated 2026-08-13, RC channel, `4.0.0rc4-1`;
  updated to `4.5.0rc1-1` on 2026-10-25 and plugin clones re-cloned against it
  (see "4.5 update" below). Stays on RC until stable reaches 4.5 (switching
  to stable earlier would downgrade it).
- Desktop (`void`): migrated 2026-11-01. 3.8.4 → stable `4.0.6-1` (see
  "Upgrade from 3.8.4 on the stable channel") → RC `4.5.0rc2-1` to match the
  laptop. Secure Boot (own sbctl keys + Microsoft) survived untouched (see
  "Secure Boot"). Config port done apart from the to-do items below.

## Desktop to-do

Done so far: Hyprland Lua port (monitors, global workspaces, window rules,
autostart, input), `recon.workspaces` widget (U/L labels, per-monitor
highlight), file-manager icon hook fixed, key bindings.

- [x] **Key bindings:** tried, all fine.
- [ ] **Check autostart at next login:** Firefox on U (9), Discord on L (10)
      without stealing focus, OpenRGB colors, Steam notifications on DP-1
      (`xrandr --output DP-1 --primary`).
- [x] **Pomodoro bar display:** own bar-widget plugin `brendon.pomodoro`
      (`base/omarchy/.config/omarchy/plugins/brendon.pomodoro/`; not a clone,
      so updates don't touch it), placed after the workspaces. The old
      waybar glyphs: hourglass when idle, timer-sand (work) or coffee mug
      (break) with `m:ss` in the theme's red/green when running, sideways
      hourglass dimmed when paused. (A colour-emoji tomato clashed with the
      line glyphs; no installed font has a monochrome one, though AUR
      `ttf-noto-emoji-monochrome` does.)
      click = start/pause, right-click = stop. Reads the scripts' state file
      directly (no process per second). Also fixed the scripts for 4.5's
      `omarchy-notification-send` (glyph now goes in `-g`; the old call
      errored out under `set -e`). For the laptop: stow `base/bin` and
      `base/omarchy` (`--no-folding`), then `omarchy plugin enable
      brendon.pomodoro` and `omarchy bar move brendon.pomodoro --after
      recon.workspaces`.
- [ ] **Stock app shortcuts left off** (`omarchy_preinstalled_bindings =
      false`): Herdr, Calculator, Omawrite are new since 3.8 and were never
      enabled; add any back in `desktop/hypr/bindings.lua` if wanted.
- [x] **Notifications on DP-1:** `brendon.notifications` clone prefers DP-1
      over the focused monitor (replaces the retired mako hook). Re-clone at
      each release. Gotcha: after swapping a *service* plugin for a clone,
      check `pgrep -x quickshell` changes on `omarchy restart shell`; a
      reload leaves the stock service owning the `notifications` IPC and
      D-Bus names, so the clone looks enabled but does nothing.
- [x] **Idle and lock:** `idle.screensaver = 450`, `idle.lock = 901` in
      `~/.config/omarchy/shell.json` (untracked; the shell rewrites it, so
      re-set these on a reinstall). Screens and keyboard backlight go off 5s
      after the lock engages (lock plugin), replacing the old 930s DPMS step.
      Screensaver: `brendon.idle` clone calls `brendon-launch-screensaver`
      (`desktop/bin`): waves on DP-1, black on the side monitors, exits on
      key press or mouse movement.
      Not ported: the old hyprlock showed the password field and wallpaper
      only on DP-1; the Quickshell lock draws both on every monitor, with no
      setting for it (would need a clone of the security-critical lock
      plugin).
      Gotchas: idle timeouts in `shell.json` only apply after `omarchy
      restart shell`. When testing, never put the literal
      `org.omarchy.screensaver` in your own command line: the launcher's
      `pgrep -f` "already running" check matches your shell and silently
      exits, and a `pkill -f` cleanup kills your shell.
- [x] **Square corners:** `rounding = 0` in `base/hypr/looknfeel.lua`
      (both machines). Wins over themes because the theme's `hyprland.lua`
      loads before `hypr.looknfeel`; the shell's corner radius follows the
      same option, so this replaces the old swayosd/walker/mako overrides.
- [x] **Suspend/resume:** fine, and `openrgb-resume.service` re-applies the
      colors. It's `WantedBy=sleep.target`, so it actually starts on the way
      *into* sleep and only finishes after waking (its `sleep 5` is frozen
      across the suspend). Works, but `suspend.target`-based ordering would be
      the proper fix.
- [ ] **OpenRGB ARGB strip (header 3) stuck on rainbow.** The 2026-11-01
      update moved `openrgb-git` from 0.9 to 1.1.42 (AUR step of `omarchy
      update`). Rolled back to 0.9 from `~/.cache/yay/openrgb-git/` and
      pinned (`IgnorePkg = openrgb-git`, re-added after channel switches by
      `desktop/omarchy/.../pre-refresh-pacman.d/pin-openrgb`). But 1.x wasn't
      the cause: the GPU and the board's own LEDs respond on both versions,
      while the strip ignores even the controller's hardware Static mode, so
      the Aura controller's signal isn't reaching it. Next: full cold power
      cycle (PSU off ~30s; the Aura controller and ARGB hubs keep standby
      power across reboots), then BIOS lighting settings, Armoury Crate (if
      Windows was booted), the cable/hub. Ruled out: header numbering (all
      three ARGB zones sized to 90 and painted, strip still rainbow), access
      (hidraw and raw USB nodes writable via `uaccess`), the kernel (same USB
      enumeration as before). The user confirmed the strip worked on 0.9 at
      boot that morning, before the update, and sees the same version split
      on Windows (0.9 and 1.x each drive a different subset of this
      hardware), so the likeliest cause is OpenRGB 1.x rewriting the Aura
      controller's stored ARGB configuration, which survives reboots on
      standby power. Don't run 1.x on Windows either until it's sorted.
      **Parked 2026-11-01 (second pass), to pick up another time.** The
      installed build (`0.9.1849.g880dc14`) is the exact one that worked
      that morning; its startup logs from 10:33 (working) and 15:49 (broken)
      detect the same devices. The SDK server confirms header 3 is set to
      90 blue LEDs in Direct mode. The controller (firmware
      `AULA3-AR32-0309`, `0b05:19af`, `/dev/hidraw5`) answers commands, and
      its config table (`0xEC 0xB0`) reports 3 ARGB channels of up to 120
      LEDs. Nothing looks corrupt, but there's no earlier dump to compare
      against. Nothing else holds the device. The only remaining software
      difference from the morning is the kernel: Arch `linux 7.2.11` →
      `linux-omarchy 7.2.8` (same ASUS modules load on both). Not the GPU:
      the 5070 Ti registers under its own name and responds; `Main.orp`
      still names the 3070 Ti, which the profile loader just skips (re-save
      it sometime). To do, in order: (1) boot the `7.2.11-arch1-1` Limine
      entry. If the strip goes blue, pin that kernel. (2) Power off at the
      PSU for at least 30s (not done yet; the last "reboot" had about a
      minute between shutdown and boot). (3) Look for an ARGB hub or a
      case LED button in its own effects mode; reseat the header 3 cable.
      If 0.9 turns out not to be needed,
      drop the hook and the `IgnorePkg` line. Device indices didn't change
      between versions (0 = GPU, 1 = X670E board), but zone names did
      ("Aura Addressable 3" in 0.9, "Addressable RGB Header 3" in 1.x).
- [x] **Cleanup:** removed `desktop/hypr/*.conf`, `desktop/waybar`,
      `desktop/environment-d/local-bin-path.conf`, the old screensaver
      scripts in `desktop/bin`, and `base/{walker,swayosd,waybar}` (e81f292),
      plus the stow links inside Omarchy's `*.omarchy-upgrade-to-quattro.*.bak`
      backups. Dropped the `git stash` of the upgrade's dead path edits.
- [ ] **Patch-based plugin clones:** keep each clone's edit as a `.patch`
      plus a `reclone` script (`omarchy plugin clone` → apply patch → move
      into the stow package), so re-syncing after an Omarchy release is one
      command and a failed patch flags that stock changed where it matters.
      Covers both machines' clones.
- [ ] **Upstream requests** that would retire clones entirely: a
      notifications output setting (`brendon.notifications`), a configurable
      screensaver command for the idle service (`brendon.idle`,
      `recon.idle`), and a global-workspaces mode (`*.workspaces`,
      `workspaces.lua`). Draft them for the user to post; add to "Upstream
      issues filed".
- [x] **`system-backups/README.md`:** desktop section added. Only
      `openrgb-resume.service`, `50-qmk.rules` and the swappiness line are
      still needed; the OpenRGB hidraw/i2c rules and `i2c-dev.conf` are
      covered by packaged rules (`uaccess`) now. Quattro removed the user
      from `input` and `docker` on purpose (security); nothing here needs them.
- [x] **Update this guide** with the desktop migration: stable-channel
      upgrade path, Secure Boot, and the new gotchas (see "Known
      regressions").
---

## Desktop runbook (completed 2026-11-01)

Kept as a record of what the desktop needed, and where it differs from the
laptop. Desktop changes live in `desktop/`, shared ones in `base/`.

**Desktop facts:** user `brendon` (laptop is `recon`, so a fresh `omarchy
plugin clone` here makes `brendon.*` ids; the copied `recon.workspaces`
keeps its id, which lives in `manifest.json`). NVIDIA RTX 5070 Ti (driver
via `nvidia-open-dkms`; built for both `linux` and `linux-omarchy`). Three
monitors: `DP-1` 2560x1440@165 primary at `0x0`, `DP-2` 1920x1080@144 at
`-1920x-360` (was `HDMI-A-1` until the cable changed), `HDMI-A-2`
1920x1080@144 at `-1920x720`, all scale 1.

**Before upgrading (done on 3.8.4):** committed untracked state (OpenRGB
config → `desktop/openrgb`, root-owned files → `system-backups/`), backed up
`/var/lib/sbctl` and `/var/lib/iwd` to an encrypted USB archive, took a
manual snapper snapshot with no cleanup policy (the channel switch upgrades
packages before anything else snapshots), didn't `git pull`.

**After upgrading:** rebased the local commits onto `origin/main` (the
3.8-only mako-hook fix `61ff6d3` was dropped), then:

- **Hyprland Lua** (`desktop/hypr`): `monitors.lua` (monitors +
  `hl.workspace_rule` pins 1–8 → DP-1, 9 → DP-2, 10 → HDMI-A-2),
  `workspaces.lua` copied from the laptop, `autostart.lua` (Firefox on 9 via
  `hl.exec_cmd(cmd, { workspace = "9 silent", no_initial_focus = true })`
  launched directly, not through `o.launch()`'s `uwsm-app`, so the launch
  rules can match the window; Discord; OpenRGB; `xrandr --output DP-1
  --primary` so Steam's XWayland notifications land on DP-1), `input.lua`,
  window rules + `misc.vrr = 2` at the bottom of `hyprland.lua`. NVIDIA env
  vars needed nothing: `default/hypr/nvidia.lua` sets them.
- **Bar:** the Quickshell bar draws on every monitor and can't be limited to
  DP-1 like the old waybar without cloning the whole bar plugin. The
  desktop's `recon.workspaces` copy labels 9/10 as U/L and marks the
  workspace each bar's own monitor shows (the laptop's marks the focused
  one).
- **Clones:** `recon.workspaces` (above), `brendon.notifications` (DP-1),
  `brendon.idle` (desktop screensaver). Not needed here: `recon.monitor`
  (laptop scale preset), indicators / keyboard-layout (fixed in 4.5).
- **Bindings:** `omarchy_preinstalled_bindings = false` plus the kept apps
  re-added (`desktop/hypr/bindings.lua`); SUPER+L stays stock (cycle
  layout; lock is SUPER+CTRL+L).
- **Transparency:** `hypr-window-transparency-toggle` (`base/bin`) rewritten
  for Lua `set_prop`; stock's toggle only reaches a terminal's 0.985.
- **Corners:** `rounding = 0` in `base/hypr/looknfeel.lua`.
- **Stowed here for the first time:** `base/bin`, `base/foot` (merged with
  4.5's stock `foot.ini`, which adds Ctrl+Shift+C/V).
- **Removed:** the old `.conf` files, waybar/walker/swayosd, the dead
  `local-bin-path.conf`, the old screensaver scripts.

## Resolved before/while migrating the desktop

- **The "Nautilus accent-color icon script"** was the
  `pin-file-manager-icons` theme-set hook (`e2e617c`/`333c4c0`), already
  in the repo for both machines. Quattro broke it silently: it read
  `~/.config/omarchy/current/theme/colors.toml`, which moved to
  `~/.local/state/omarchy/current/theme/` (fixed in `cde7037`). Adwaita's
  newer `folder-projects` icon also needed its GTK "grappa" attributes
  stripped to take the accent (`3c231e1`).
- **The Aug 7–9 desktop features** whose pre-Quattro files `main` had
  deleted (square corners `19800b3`, transparency toggle `2e50d90`/`abde711`,
  pomodoro `4cd72d4`/`5e686d0`, mako on DP-1 `a767f11`) are all ported, as
  above. Only the pomodoro countdown display is left (to-do list).

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
- **Never move a Quattro system to a channel that's behind it.** In August,
  stable still served 3.8.x, and pointing an already-migrated laptop at it
  tried to downgrade ~300 core packages (glibc, systemd, gcc, hyprland, ...)
  under a Quattro filesystem; unrelated file conflicts (gexiv2, mbedtls)
  blocked it before anything committed. Stable has served Quattro since
  (`4.0.6` on 2026-11-01), but the same rule applies: an RC machine on 4.5
  must stay on RC until stable reaches 4.5. Check what a channel serves
  first: `curl -s https://pkgs.omarchy.org/<channel>/x86_64/omarchy.db |
  bsdtar -tf - | grep '^omarchy-[0-9][^/]*/$'`.
- **Back up the Secure Boot signing keys** (`/var/lib/sbctl`) if the machine
  uses its own (see "Secure Boot"). Losing them is the one thing that forces
  setup mode and a re-enroll.
- **Back up Wi-Fi credentials** from `/var/lib/iwd/` before upgrading — not
  migrated automatically. The network stack itself switches from `iwd` to
  NetworkManager; only the currently-connected network gets handed off across
  the reboot, everything else needs re-adding manually afterward.
- **Decide deliberately about kernel handling** if you're on anything
  hardware-specific (e.g. `linux-t2`) rather than letting it move as a side
  effect of a channel switch — see the pin-backup note above.

## Upgrade sequence that actually worked (laptop, RC channel, August)

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

## Upgrade from 3.8.4 on the stable channel (desktop, 2026-11-01)

Once Quattro was on stable, the RC detour wasn't needed, but 3.8.4's git
`master` (frozen since 2026-07-29) has neither the Quattro menu entry nor the
upgrade invite; both only exist on the `rc` git branch (3.8.5). Its
`omarchy-upgrade-to-quattro` reads the channel from
`/etc/pacman.d/mirrorlist` and keeps a stable machine on stable.

1. `omarchy-branch-set rc`: switches only `~/.local/share/omarchy`'s git
   branch. Unlike `omarchy-channel-set`, no `pacman.conf` rewrite and no
   forced `pacman -Syyuu`.
2. `omarchy-update`: pulls 3.8.5 (its migrations include the invite and a
   Plymouth fix that adds `initramfs_async=0` and rebuilds the UKI). Reboot.
3. Update ▸ Omarchy To Quattro. Installed `omarchy 4.0.6-1` plus the
   `linux-omarchy` kernel alongside `linux`; `limine.conf`'s default entry
   becomes `linux-omarchy`. Before the reboot, check signatures (see
   "Secure Boot") and that the NVIDIA DKMS module exists for both kernels
   (`find /usr/lib/modules/*/ -name 'nvidia.ko*'`). Reboot.
4. Optional, to match the laptop: snapshot, then `omarchy-channel-set rc`
   (pulled `4.5.0rc2-1`; same kernels, so nothing to re-sign).

The 3.8 bar's "update available" indicator compares against the newest git
tag, RCs included, so it shows `v4.5.0-rc2` on a 3.8.4 machine; it's not a
3.8 update.

## Secure Boot (desktop)

The desktop boots Limine with Secure Boot on, using sbctl's own keys plus
Microsoft's (for dual-booting Windows from its own ESP). Upgrading the OS
never touches the enrolled keys (PK/KEK/db), so no setup mode or re-enroll is
needed, and Windows (BitLocker / Hello PIN, which watch PCR7) is unaffected.
What can break boot is an unsigned EFI binary.

- Signing is automatic: `limine-entry-tool` (via `limine-mkinitcpio`) and
  `limine-snapper-sync` sign `limine_x64.efi` and the UKIs with sbctl every
  time they regenerate them; sbctl's own `zz-sbctl.hook` re-signs what's in
  its database (`BOOTX64.EFI`, `BOOTIA32.EFI`). None of these packages are
  on Quattro's removal lists.
- Limine config enrollment is off here (`ENABLE_ENROLL_LIMINE_CONFIG` unset),
  so the upgrade script's `sed` edits to `/boot/limine.conf` can't break boot.
- Pre-reboot check, no root needed (`/boot` and the efivars are
  world-readable): extract the `CN=Database Key` certificate from
  `/sys/firmware/efi/efivars/db-d719b2cb-*` (an EFI_SIGNATURE_LIST) and run
  `sbverify --cert db.pem` on every file in `/boot/EFI/{Linux,limine,BOOT}/`.
  With root: `sudo sbctl verify`.
- If it ever fails to boot: pick a snapshot or the other kernel in the Limine
  menu. If the firmware rejects Limine itself, disable *only* Secure Boot in
  the BIOS (don't clear keys or load defaults, which wipes the custom PK),
  boot, `sudo limine-mkinitcpio && sudo sbctl verify`, re-enable. Don't boot
  Windows in between.

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

- **Group memberships are removed on purpose.** Quattro migrations take the
  user out of `input` (raw keyboard access allows keylogging; kept only if
  `xpadneo-dkms` or `ydotool` is installed; migration `1787865477`) and
  `docker` (root-equivalent; opt back in with Setup ▸ Security ▸ Sudoless
  Docker; `1787580187`). Check udev rules that grant devices via
  `GROUP="input"`; on the desktop, OpenRGB's packaged rules use
  `TAG+="uaccess"` instead, so nothing broke (see `system-backups/README.md`).
- **Theme state moved** from `~/.config/omarchy/current/` to
  `~/.local/state/omarchy/current/`. Personal hooks reading the old path
  fail silently if they guard with `[[ -f ... ]] || exit 0`
  (`pin-file-manager-icons` did). `theme-set.d` hooks themselves still run.
- **The upgrade edits tracked files through stow links.** It rewrote the old
  theme path in `base/alacritty/alacritty.toml` and
  `desktop/hypr/hyprland.conf` inside the repo. Check `git status` after
  upgrading before pulling or rebasing.
- **Folded stow directories catch Omarchy's own files.** `theme-set.d` was a
  single directory link into `desktop/omarchy`, so Quattro's `10-owe-sync`
  hook was written into the repo. Stow `desktop/omarchy` with
  `--no-folding` (`cd desktop && stow -t ~ --no-folding -R omarchy`) so the
  directories are real and only tracked files are links.
- **Quattro seeds some configs as plain files** where a stow link used to be
  expected (`~/.config/foot/foot.ini`, the `hypr/*.lua` files), so a later
  `stow` of that package conflicts. A conflict in one package aborts the
  whole stow run, including the other packages named on the command line;
  stow packages one at a time when unsure.
- **Shell plugin changes need a real restart.** Edits to a stowed clone go
  into the repo file, which the shell's watcher doesn't always see; run
  `omarchy restart shell`. After swapping a *service* plugin for a clone,
  also check that `pgrep -x quickshell` changed: a restart that only reloads
  leaves the stock service owning its IPC and D-Bus names, so the clone shows
  as enabled but does nothing. `idle.*` timeouts in `shell.json` likewise
  only apply after a restart.
- **`pgrep -f` / `pkill -f` match your own command line.** The screensaver
  launcher exits early if anything's command line contains
  `org.omarchy.screensaver`, including the shell running your test, and a
  `pkill -f` cleanup with that string kills the test shell itself. Build the
  string from pieces in test commands.
- **Quattro's shell aliases** replace `ls`, `grep` and `find` with other
  tools in interactive bash, so their usual flags fail. Use `/usr/bin/ls`
  etc. in one-liners.

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
