-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Do things without affecting the registers
vim.keymap.set("n", "x", '"_x')

-- Map Ctrl-z to do nothing
vim.keymap.set({ "n", "x", "i" }, "<C-z>", "<Nop>", {
  noremap = true,
  silent = true,
})

-- Map q to do nothing
vim.keymap.set("n", "q", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("x", "q", "<Nop>", { noremap = true, silent = true })

-- Map quit command to Ctrl-q
-- vim.keymap.set("n", "<C-q>", function()
--   vim.cmd("q")
-- end, {
--   desc = "Quit Neovim",
--   noremap = true,
--   silent = true,
-- })

-- Map quit all command to Ctrl+Alt+q
-- vim.keymap.set("n", "<C-A-q>", function()
--   vim.cmd("qa")
-- end, {
--   desc = "Quit all Neovim instances",
--   noremap = true,
--   silent = true,
-- })
