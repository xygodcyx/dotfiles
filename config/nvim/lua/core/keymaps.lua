local keymap = vim.keymap.set

keymap("i", "jk", "<ESC>")

keymap("n", "<ESC>", ":noh<CR>")

-- keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
-- keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })
-- keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
-- keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })

keymap("v", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- keymap("n", "<TAB>", ":BufferNext<CR>", { desc = "Next Buffer" })
-- keymap("n", "<S-TAB>", ":BufferPrevious<CR>", { desc = "Previous Buffer" })
-- keymap("n", "<S-W>", ":BufferClose<CR>", { desc = "Close Buffer" })
keymap("n", "<leader>ce", vim.diagnostic.open_float, { desc = "显示当前行 diagnostic 报错" })

-- 到下一个报错/警告
keymap("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "下一个报错" })

-- 跳到上一个报错/警告
keymap("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "上一个报错" })

vim.keymap.set({ "n", "v" }, "<leader>cm", function()
	require("conform").format({ async = false, lsp_format = "fallback" })
end, { desc = "Format Code" })

vim.keymap.set({ "n", "i" }, "<C-l>", function()
	require("lsp_signature").toggle_float_win()
end, { silent = true, noremap = true, desc = "切换签名帮助" })


vim.keymap.set({ "n"}, "<Leader>e", "<CMD>Oil<CR>", { desc = "打开文件管理器" })

