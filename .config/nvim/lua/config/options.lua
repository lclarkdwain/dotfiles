-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.mapleader = " "

vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wildignore:append({ "*/node_modules/*" })

-- Set tab width to 2 spaces for better JSX/JS/Vue formatting
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
