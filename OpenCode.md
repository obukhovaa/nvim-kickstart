# OpenCode Configuration for Neovim Kickstart

## Build/Test/Lint Commands
- **Install plugins**: `nvim --headless "+Lazy! sync" +qa`
- **Format code**: `<leader>cf` (in nvim) or `:Format` command
- **Check health**: `:checkhealth` (in nvim)
- **Update plugins**: `:Lazy update` (in nvim)
- **Install system deps**: `./install.sh` (installs tmux, zsh, nvim, ripgrep, fzf, etc.)

## Code Style Guidelines
- **Language**: Lua for Neovim configuration
- **Indentation**: 4 spaces (tabs disabled: `expandtab = false`, `tabstop = 4`, `shiftwidth = 4`)
- **Quotes**: Single quotes preferred for strings
- **Naming**: snake_case for variables/functions, PascalCase for plugins
- **Comments**: Use `--` for single line, avoid excessive commenting
- **Imports**: Use `require('module')` syntax, group related requires
- **Error handling**: Use `pcall()` for safe calls, check conditions before operations
- **Plugin structure**: Return table from plugin files, use `opts = {}` for simple configs
- **Keymaps**: Use descriptive `desc` field, group by leader key prefix
- **Conditionals**: Use `cond = is_complete_setup()` for optional features
- **Formatters**: stylua (Lua), gofumpt+goimports (Go), prettierd (JS/TS), shfmt (shell)