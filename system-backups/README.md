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
