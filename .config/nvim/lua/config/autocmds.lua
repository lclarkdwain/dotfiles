-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

---@diagnostic disable: param-type-mismatch
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc", "markdown" },
  callback = function()
    vim.opt.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "javascript" },
  callback = function()
    vim.opt_local.commentstring = "// %s"
  end,
})
local dotfiles_dir = vim.env.DOTFILES_DIR or vim.fn.expand("~/.dotfiles")
vim.api.nvim_create_autocmd("BufRead", {
  pattern = dotfiles_dir .. "/.config/bash/*",
  callback = function()
    vim.bo.filetype = "bash"
  end,
})
local au_filetypes = vim.api.nvim_create_augroup("ConfigFileType", { clear = true })
vim.api.nvim_create_autocmd(
  { "BufRead", "BufNewFile" },
  -- See https://github.com/LazyVim/LazyVim/issues/80
  { group = au_filetypes, pattern = { "*" }, command = "set fo-=o" }
)
vim.api.nvim_create_autocmd(
  { "BufRead", "BufNewFile" },
  { group = au_filetypes, pattern = { "*.conf", "*.ini" }, command = "setl filetype=dosini" }
)
vim.api.nvim_create_autocmd(
  { "BufRead", "BufNewFile" },
  { group = au_filetypes, pattern = { "*.zsh" }, command = "setl filetype=sh" }
)

local au_on_save = vim.api.nvim_create_augroup("ConfigOnSave", { clear = true })
vim.api.nvim_create_autocmd(
  { "BufWritePost" },
  { group = au_on_save, pattern = { "*bspwrc" }, command = "!./%; notify-send -i reload 'Running bspwmrc'" }
)
vim.api.nvim_create_autocmd(
  { "BufWritePost" },
  { group = au_on_save, pattern = { "*dunstrc" }, command = "!killall dunst; notify-send -i reload 'Restarting dunst'" }
)
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = au_on_save,
  pattern = { "*sxhkdrc" },
  command = "!pkill -USR1 sxhkd; notify-send -i reload 'Reloading sxhkd'",
})
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = au_on_save,
  pattern = { "*polybar/config.ini" },
  command = "!polybar-msg cmd restart; notify-send -i reload 'Restarting polybar'",
})
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = au_on_save,
  pattern = { "*waybar/config" },
  command = "!killall -SIGUSR2 waybar; notify-send -i reload 'Reloading waybar'",
})
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = au_on_save,
  pattern = { "*Xresources", "*Xdefaults" },
  command = "!xrdb %; notify-send -i reload 'Setting xrdb'",
})
local au_resize_propor = vim.api.nvim_create_augroup("ResizePropor", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = au_resize_propor,
  command = "tabdo wincmd =",
})
