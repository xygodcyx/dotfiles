local map = vim.keymap.set

map("i", "jk", "<ESC>")

map("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })

vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, { desc = "显示当前行 diagnostic 报错" })
-- 跳到下一个报错/警告
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "下一个报错" })

-- 跳到上一个报错/警告
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "上一个报错" })
