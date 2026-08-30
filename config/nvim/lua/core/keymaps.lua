local keymap = vim.keymap.set

keymap("i", "jk", "<ESC>")

keymap("n", "<ESC>", ":noh<CR>")

keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })
keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })

keymap("n", "<TAB>", ":BufferNext<CR>", { desc = "Next Buffer" })
keymap("n", "<S-TAB>", ":BufferPrevious<CR>", { desc = "Previous Buffer" })
keymap("n", "<S-W>", ":BufferClose<CR>", { desc = "Close Buffer" })
keymap("n", "<leader>ce", vim.diagnostic.open_float, { desc = "显示当前行 diagnostic 报错" })
-- 跳到下一个报错/警告
keymap("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "下一个报错" })

-- 跳到上一个报错/警告
keymap("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "上一个报错" })

keymap({ "n", "x" }, "<leader>re", function()
	return require("refactoring").extract_func()
end, { desc = "Extract Function", expr = true })

-- cmp占位符跳转
vim.keymap.set("i", "<Tab>", function()
	if require("luasnip").jumpable(1) then
		require("luasnip").jump(1)
	else
		return "<Tab>"
	end
end, { expr = true })

-- 反向
vim.keymap.set("i", "<S-Tab>", function()
	if require("luasnip").jumpable(-1) then
		require("luasnip").jump(-1)
	else
		return "<S-Tab>"
	end
end, { expr = true })
