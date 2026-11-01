# System backups (not stow-managed)

Reference/backup copies of root-owned system files that live outside `$HOME`
and can't go through the normal stow packages (`base/`, `desktop/`, `laptop/`),
which only mirror paths under `~`.

These are **not automatically deployed**. If restoring on a fresh install,
copy manually to the real path (shown by each subdirectory's name, with `/`
replaced by `-`) and fix ownership/permissions.

## laptop, T2 Mac (axiom)

- `usr-lib-systemd-system-sleep/apple-bce-reload` → `/usr/lib/systemd/system-sleep/apple-bce-reload`
  (root:root, 755). Hibernate fix hook for the T2 apple-bce/aaudio driver.
  See [[project_t2mac_sleep]] in Claude memory for the full debugging history.
- `etc-systemd-system/systemd-hibernate.service.d/disable-user-freeze.conf` → `/etc/systemd/system/systemd-hibernate.service.d/disable-user-freeze.conf`
  (root:root, 644). Disables systemd's user-session freeze during hibernate —
  fixes a deadlock against the hook above. Explanatory comment inline in the
  file itself.

## desktop (void)

All root:root, 644. Mostly the OpenRGB setup; its user-side config is the
`desktop/openrgb` stow package (`~/.config/OpenRGB/{Main.orp,OpenRGB.json}`),
and `personal_openrgb_set_colors` is in `desktop/bin`.

Needed:

- `etc-systemd-system/openrgb-resume.service` → `/etc/systemd/system/openrgb-resume.service`.
  Re-applies the RGB colors (`~/.local/bin/personal_openrgb_set_colors`) 5s
  after resuming from sleep. Enable with
  `sudo systemctl enable openrgb-resume.service`. Hardcodes user `brendon`
  and UID 1000.
- `etc-udev-rules.d/50-qmk.rules` → `/etc/udev/rules.d/50-qmk.rules`. QMK's
  udev rules, so QMK keyboards (the Keychron K2 Pro) can be flashed without
  root. No package provides them. Flashing firmware built locally also needs
  the ARM toolchain (`arm-none-eabi-newlib` etc.), removed as orphans during
  the Quattro migration.
- `etc-sysctl.d/99-sysctl.conf` → `/etc/sysctl.d/99-sysctl.conf`. Only
  `vm.swappiness = 10` is ours; `net.ipv4.tcp_mtu_probing=1` was added by the
  Omarchy installer.

Redundant on the current packages (as of 2026-11-01), kept in case that
changes:

- `etc-udev-rules.d/60-openrgb-asus-aura-hidraw.rules` (ASUS Aura LED
  controller, `0b05:19af`, `GROUP="input"`) and
  `etc-udev-rules.d/99-i2c.rules` (`/dev/i2c-*`, `GROUP="i2c"`):
  `openrgb-git`'s own `/usr/lib/udev/rules.d/60-openrgb.rules` grants both
  to the logged-in user with `TAG+="uaccess"`, which is what actually gives
  access now. Check with `getfacl /dev/hidraw*` / `getfacl /dev/i2c-0`
  (expect `user:brendon:rw-`).
- `etc-modules-load.d/i2c-dev.conf`: `i2c-tools`, `ddcutil` and `openrgb`
  each ship a `/usr/lib/modules-load.d/` file loading `i2c-dev`.

Groups: the user doesn't need to be in `input` or `i2c` for any of this.
Quattro removes users from `input` (raw keyboard access allows keylogging;
migration `1787865477`) and from `docker` (root-equivalent; opt back in with
Setup › Security › Sudoless Docker; migration `1787580187`). The `i2c` group
is created by `i2c-tools`; this machine's was created by hand earlier, hence
GID 1003.
