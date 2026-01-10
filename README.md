# Rquirements

* gnu stow
* git

Create a directory under `$HOME` called `/.dotfiles` or whatever you like.

Clone this repo (specifying `./dotfiles` or the file will be named `~/dotfiles` by default.

NOTE: Using `~/.dotfiles` ensures the directory is hidden which provides a cleaner `$HOME` directory.

Stow uses a naming convention that dictates the output of the files relative to the `$HOME` directory.

e.g. `alacritty/.config/alacritty` ensures that the dotfiles for alacritty end up in `~/.config/alacritty/` when running the command `stow alacritty`

NOTE: Can use `-n` flag to do a try run and test the outcome and `-v` for increased verbosity, e.g. `stow -nv alacritty`

More to follow.
