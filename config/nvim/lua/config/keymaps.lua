-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", ",,", "<ESC>")

-- 使用 <leader>xx 触发完整的悬浮诊断错误
vim.keymap.set("n", "<leader>cx", vim.diagnostic.open_float, { desc = "Line Diagnostics (Full)" })
