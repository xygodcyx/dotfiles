local keymap = vim.keymap.set

keymap("i", "jk", "<ESC>")

keymap("n", "<ESC>", ":noh<CR>", {
	silent = true,
})

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
	-- 延迟等浮窗创建完，再找它并聚焦
	vim.defer_fn(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local cfg = vim.api.nvim_win_get_config(win)
			-- 浮动窗口 + nofile + 无 filetype，基本就是 lsp_signature 的
			if cfg.relative ~= "" then
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].buftype == "nofile" and vim.bo[buf].filetype == "" then
					vim.api.nvim_set_current_win(win)
					return
				end
			end
		end
	end, 30)
end, { silent = true, noremap = true, desc = "切换签名帮助" })

vim.keymap.set({ "n" }, "<Leader>e", "<CMD>Oil<CR>", { desc = "打开文件管理器" })

-- H 跳到行首，L 跳到行尾
vim.keymap.set({ "n", "x" }, "H", "^", { desc = "行首" })
vim.keymap.set({ "n", "x" }, "L", "$", { desc = "行尾" })

vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "保存文件" })

vim.keymap.set("n", "<leader>ro", "<cmd>restart<CR>", { desc = "保存文件" })
