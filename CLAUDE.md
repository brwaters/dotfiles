# Dotfiles — Claude Instructions

## Omarchy Quattro migration (read first)

Both machines run Omarchy Quattro (4.x): the laptop since 2026-08-13, the
desktop since 2026-11-01. Before changing Hyprland, shell plugins or
anything else Omarchy-related, or before an Omarchy upgrade, read
`QUATTRO-MIGRATION.md`. Its "Desktop to-do" lists the open items, and
"Known regressions" lists the gotchas that have already cost time (theme
state path, stow folding, shell restarts, plugin clones, Secure Boot on the
desktop).

## Repo structure

Three top-level stow roots:

- `base/` — shared config that applies to every machine (desktop + laptop)
- `desktop/` — overrides/additions specific to the desktop
- `laptop/` — overrides/additions specific to the laptop

Each root contains stow packages (e.g. `base/hypr`, `desktop/hypr`). Inside each package the directory tree mirrors `$HOME`, so `base/hypr/.config/hypr/looknfeel.lua` stows to `~/.config/hypr/looknfeel.lua`.

## Where new config belongs

**Always prefer `base/` for changes that should exist on both machines.**

Only put a change in `desktop/` or `laptop/` (or duplicate it into both) when the application doesn't support layered/merged config from multiple sources. For example, an Omarchy shell plugin clone is a whole plugin directory that can't be layered, so the workspaces widget lives in both `desktop/omarchy` and `laptop/omarchy`.

If an app *does* support includes or imports (e.g. Hyprland's Lua `require`), keep shared config in `base/` and only put machine-specific overrides in the machine directory.

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
stow -t ~ hypr          # initial stow
stow -t ~ -R hypr       # restow (refresh symlinks after adding files)
stow -t ~ -D hypr       # unstow (remove symlinks)
stow -t ~ -nv -R hypr   # dry-run with verbose output
```

**Always pass `-t ~` (or `--target=~`) explicitly.** Stow's default target is the parent of the stow directory — when you `cd ~/.dotfiles/base` first, that parent is `~/.dotfiles`, not `$HOME`. Omitting `-t ~` silently creates stray symlinks inside the repo itself (e.g. `~/.dotfiles/.config/...`) instead of stowing into your home directory.

## Nerd Font glyphs in config files

Waybar (and other) configs embed Nerd Font icon glyphs — Private Use Area Unicode codepoints that look like normal icons but are easy to corrupt. When reading a file back and re-typing/re-composing a line that contains one instead of preserving it byte-for-byte, the glyph can silently drop or get replaced with blank/mangled output (this has happened before with waybar icons going blank after an edit).

Rules:
- Never retype or hand-compose a glyph. When editing a line that contains one, keep `old_string`/`new_string` scoped so the glyph itself is copied verbatim from the Read output, not reproduced from memory.
- If a glyph must actually change, verify after editing — e.g. `grep -c` for the expected codepoint, or reload the app and visually confirm the icon still renders — rather than assuming the edit was byte-exact.

## Checking symlink status

```bash
ls -la ~/.config/hypr/   # look for -> symlinks pointing into ~/.dotfiles
```

If a file is a regular file instead of a symlink, it hasn't been moved into the stow package yet and won't be updated when pulling changes on another machine.
