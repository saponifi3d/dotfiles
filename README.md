# My Configurations

- [Install Iterm 2](https://iterm2.com/downloads/stable/latest)
- Install Brew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- Export variables

```sh
CODE_PATH=~/Code
DOTFILES=$CODE_PATH/dotfiles
```

- Install Vim Plugins, by running `vim` and `:PlugInstall` - <https://github.com/junegunn/vim-plug>

## Pi coding agent

Install pi and this repository's portable configuration with:

```sh
make pi
```

The command is safe to run repeatedly. It installs the coding agent, maintains a
sparse checkout of [`earendil-works/pi`](https://github.com/earendil-works/pi)
at a pinned revision under `~/.pi/src/pi`, and links the selected upstream and
custom extensions into `~/.pi/agent/extensions/`.

Machine-local runtime state is not copied or linked by this repository. Complete
any required setup through pi itself after installation.

Useful checks and cleanup commands:

```sh
make pi_check   # validate the tracked configuration
make pi_verify  # verify the installed checkout and links
make pi_unlink  # remove only links managed by make pi
```

## Brew Packages

- ag
- bash-completion
- git
- tree
- wget

## Vim Plugins

- [vim-plug](https://github.com/junegunn/vim-plug)
- [ale](https://github.com/w0rp/ale)
- [ag](https://github.com/rking/ag.vim)
- [nerdtree](https://github.com/scrooloose/nerdtree)
- [fzf-vim](https://github.com/junegunn/fzf.vim)
- [vim-airline](https://github.com/vim-airline/vim-airline)
- [vim-fugitive](https://github.com/tpope/vim-fugitive)
- [vim-javascript](https://github.com/pangloss/vim-javascript)
- [vim-jsx](https://github.com/mxw/vim-jsx)
- [typescript-vim](https://github.com/leafgarland/typescript-vim)
- [vim-prettier](https://github.com/prettier/vim-prettier)
