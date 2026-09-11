-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.omni_sql_no_default_maps = 1
vim.g.snacks_animate = false

vim.opt.title = true
vim.opt.scrolloff = 10
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.inccommand = "split"
vim.opt.shell = "zsh"
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }

if vim.fn.has("win32") == 1 then
  LazyVim.terminal.setup("pwsh")
end
