# Dotfiles — Claude Instructions

## Repo structure

Three top-level stow roots:

- `base/` — shared config that applies to every machine (desktop + laptop)
- `desktop/` — overrides/additions specific to the desktop
- `laptop/` — overrides/additions specific to the laptop

Each root contains stow packages (e.g. `base/waybar`, `desktop/waybar`). Inside each package the directory tree mirrors `$HOME`, so `base/waybar/.config/waybar/config.jsonc` stows to `~/.config/waybar/config.jsonc`.

## Where new config belongs

**Always prefer `base/` for changes that should exist on both machines.**

Only put a change in `desktop/` or `laptop/` (or duplicate it into both) when the application doesn't support layered/merged config from multiple sources. For example, waybar loads a single `config.jsonc`, so there's no way to have a `base/` file that both machines extend — it must live in each machine's package.

If an app *does* support includes or imports (e.g. hyprland `source =`), keep shared config in `base/` and only put machine-specific overrides in the machine directory.

## Adding a new file to the dotfiles

When a config file exists on disk but isn't tracked in the repo yet:

1. **Move** the file into the correct stow package directory (preserving the path structure):
   ```
   mv ~/.config/foo/bar.conf ~/.dotfiles/base/foo/.config/foo/bar.conf
   ```
2. **Re-stow** the package so the file is symlinked back to its original location:
   ```
   cd ~/.dotfiles/base   # or desktop/ or laptop/
   stow -t ~ -R foo
   ```
   Use `-R` (restow) to remove any existing symlinks and recreate them cleanly.
   Use `-n` to dry-run first if unsure: `stow -t ~ -nv -R foo`

3. **Commit** the new file.

Never copy a file into the stow package and leave the original in place — stow will refuse to create the symlink if the target already exists as a regular file.

## Stow invocation reference

All stow commands should be run from inside the root that contains the package (`base/`, `desktop/`, or `laptop/`), **not** from `~/.dotfiles` itself.

```bash
cd ~/.dotfiles/base
stow -t ~ waybar          # initial stow
stow -t ~ -R waybar       # restow (refresh symlinks after adding files)
stow -t ~ -D waybar       # unstow (remove symlinks)
stow -t ~ -nv -R waybar   # dry-run with verbose output
```

**Always pass `-t ~` (or `--target=~`) explicitly.** Stow's default target is the parent of the stow directory — when you `cd ~/.dotfiles/base` first, that parent is `~/.dotfiles`, not `$HOME`. Omitting `-t ~` silently creates stray symlinks inside the repo itself (e.g. `~/.dotfiles/.config/...`) instead of stowing into your home directory.

## Checking symlink status

```bash
ls -la ~/.config/waybar/   # look for -> symlinks pointing into ~/.dotfiles
```

If a file is a regular file instead of a symlink, it hasn't been moved into the stow package yet and won't be updated when pulling changes on another machine.
