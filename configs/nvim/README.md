# Neovim 0.11+ Configuration

Clean migration from your vim config.

## Installation (CLEAN INSTALL REQUIRED)

```bash
# 1. Remove ALL old nvim data
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# 2. Copy config
mkdir -p ~/.config/nvim
cp init.lua ~/.config/nvim/
cp -r lua ~/.config/nvim/

# 3. Start nvim (plugins auto-install)
nvim

# 4. Install language servers
:Mason
# Then press 'i' on these:
#   - typescript-language-server
#   - pyright
```

## Install Formatters

```bash
# For JavaScript/TypeScript formatting
npm install -g prettier

# For Python formatting  
pip install black isort

# Optional: faster eslint
npm install -g eslint_d
```

## Verify LSP Works

Open a `.ts` or `.tsx` file in a project with `package.json`, then:

```vim
:LspCheck
```

Should say "LSP attached: ts_ls". If not, the language server isn't installed or the file isn't in a project.

## Your Keymaps

| Key | Action |
|-----|--------|
| `<F2>` | Toggle file explorer (NERDTree) |
| `<F3>` | Open quickfix |
| `\t` | Find files (git or all) |
| `\p` | Find all files |
| `\y` | Git status |
| `\k` | List buffers |
| `\s` | Search in files (Ag/grep) |
| `\d` | Go to definition |
| `\r` | Find references |
| `\g` | Definition in vsplit |
| `\f` | Format file |
| `\a` | Toggle diagnostics |
| `\n` | Toggle line numbers |
| `\S` | Toggle spell |
| `\z` | Toggle fold |
| `\c` | Open quickfix |
| `\q` | Close quickfix |
| `K` | Hover documentation |
| `\rn` | Rename symbol |
| `\ca` | Code actions |
| `[d` / `]d` | Prev/next diagnostic |
| `:Ag <text>` | Search files |

## Commands

| Command | Description |
|---------|-------------|
| `:Mason` | Install/manage language servers |
| `:LspCheck` | Check if LSP is attached |
| `:Lazy` | Plugin manager |
| `:DiagnosticsToQf` | Send diagnostics to quickfix |
| `:checkhealth` | Verify installation |

## Troubleshooting

**"LSP not attached" when using `\d` or `\r`?**
1. Run `:LspCheck` to see status
2. Make sure you're in a project (has `package.json` or `pyproject.toml`)
3. Make sure language server is installed via `:Mason`

**Icons showing as `?` characters?**
Install a Nerd Font: https://www.nerdfonts.com/font-downloads
Or the current config uses ASCII fallbacks which should work.

**Treesitter errors?**
Run `:TSUpdate` to update parsers.

**Telescope errors about git?**
`\t` tries git_files first. Use `\p` for non-git directories.
