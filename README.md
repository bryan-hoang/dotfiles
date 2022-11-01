# Bryan's dotfiles

A [bare Git repository](https://www.atlassian.com/git/tutorials/dotfiles)
storing personal dotfiles.

## Installation

Running [`.local/bin/install-dotfiles`](.local/bin/install-dotfiles) is the
usual way of installing all the dot files. Otherwise, manually running the steps
in the `clone_repo` function also does the trick.

## Neovim

[NvChad](https://github.com/NvChad/NvChad) provides the base configuration,
because:

- It provides a solid base of reasonable defaults to reduce the cognitive load
  of writing the config from scratch.
- Makes it easier to discover certain configuration options.

`$XDG_CONFIG_HOME/nvim` is a symlink to a submodule of NvChad.
`$XDG_CONFIG_HOME/neovim` is the location of this dotfiles custom configuration,
which the developer needs to manually symlink to
`$XDG_CONFIG_HOME/nvim/lua/custom`.
