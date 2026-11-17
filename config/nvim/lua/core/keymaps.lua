local keymap = vim.keymap.set

local opt = { noremap = true, silent = true }

-- keymap("n", "q", "q") -- close record mode

-- keymap("n", "<leader>qq", function()
-- 	vim.keymap_local.set("n", "q")
-- end)

keymap("i", "<C-h>", "<ESC>I", opt)
keymap("i", "<C-l>", "<ESC>A", opt)

-- 不要用 kk/jj/jk 退出插入模式：输入 k/j 开头的单词（如 key、json）时，
-- Neovim 会等待 timeoutlen（默认 1000ms）判断是否是映射，导致明显卡顿。
-- 使用 <Esc> 或 <C-[> 退出插入模式。如需快捷退出，请改用非字母组合（如 ;;）。
-- keymap("i", "kk", "<ESC>")
-- keymap("i", "jj", "<ESC>")
-- keymap("i", "jk", "<ESC>")
keymap("i", "<C-n>", "<ESC>")

keymap("n", "<C-v>", "V")
keymap("n", "V", "<C-v>")

keymap("n", "<ESC>", ":noh<CR>", {
	silent = true,
})

keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })
keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })

keymap("t", "<C-n>", "<C-\\><C-n>", { desc = "在终端中切换回Normal模式" })

keymap("n", "<C-=>", "<C-w>+", { desc = "增加上下宽度" })
keymap("n", "<C-->", "<C-w>-", { desc = "减小上下宽度" })
keymap("n", "<C-,>", "<C-w><", { desc = "增加左右宽度" })
keymap("n", "<C-.>", "<C-w>>", { desc = "减小左右宽度" })

keymap("v", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

keymap("n", "<leader>ce", vim.diagnostic.open_float, { desc = "显示当前行 diagnostic 报错" })

-- 跳到上一个报错/警告
keymap("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "上一个报错" })

-- 到下一个报错/警告
keymap("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "下一个报错" })

keymap({ "n", "v" }, "<leader>fm", function()
	require("conform").format({ async = false, lsp_format = "fallback" })
end, { desc = "Format Code" })

-- 普通模式：光标在函数名上即可
vim.keymap.set("n", "<leader>hh", "<cmd>TSCppDefineClassFunc<cr>", { desc = "Generate C++ implementation" })

-- 可视模式：必须用 ":" 开头，才能自动补全成 '<,'> 范围
vim.keymap.set("v", "<leader>hh", ":TSCppDefineClassFunc<cr>", { desc = "Generate C++ implementation" })

keymap({ "n" }, "L", function()
	require("lsp_signature").toggle_float_win()
	-- 延迟等浮窗创建完，再找它并聚焦
	vim.defer_fn(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local cfg = vim.api.nvim_win_get_config(win)
			-- 浮动窗口 + nofile + 无 filetype，基本就是 lsp_signature 的
			if cfg.relative ~= "" then
				local buf = vim.api.nvim_win_get_buf(win)
				if
					(vim.bo[buf].buftype == "nofile" and vim.bo[buf].filetype == "")
					or vim.bo[buf].filetype == "markdown"
				then
					vim.api.nvim_set_current_win(win)
					return
				end
			end
		end
	end, 30)
end, { silent = true, noremap = true, desc = "切换签名帮助" })

-- keymap({ "n" }, "<Leader>e", "<CMD>Oil<CR>", { desc = "打开文件管理器" })

-- H 跳到行首，L 跳到行尾
-- keymap({ "n", "x", "o" }, "<C-h>", "^")
-- keymap({ "n", "x", "o" }, "<C-l>", "$")

keymap("n", "<leader>w", "<cmd>wa<CR>", { desc = "保存文件" })
-- keymap("n", "<leader>q", "<cmd>q<CR>", { desc = "退出文件" })

keymap("n", "<leader>rlo", "<cmd>restart<CR>", { desc = "重新加载文件" })

keymap("n", "j", function()
	return vim.v.count == 0 and vim.wo.wrap and "gj" or "j"
end, { expr = true, desc = "屏幕行下移" })

keymap("n", "k", function()
	return vim.v.count == 0 and vim.wo.wrap and "gk" or "k"
end, { expr = true, desc = "屏幕行上移" })

keymap("x", "j", "gj", { desc = "屏幕行下移" })
keymap("x", "k", "gk", { desc = "屏幕行上移" })

-- keymap({ "n", "x", "o" }, "<c-space>", function()
-- 	require("flash").treesitter({
-- 		actions = {
-- 			["<c-space>"] = "next",
-- 			["<BS>"] = "prev",
-- 		},
-- 	})
-- end, { desc = "Treesitter incremental selection" })
--
-- fix logic line and visual line bug

local prefix_char = ""
vim.on_key(function(key)
	local k = vim.fn.keytrans(key)
	if k == "d" or k == "y" then
		prefix_char = k
	end
end)

local modes = { "n", "x", "o" }
local function hasNoPrefix()
	local prefix = vim.v.count == 0 and prefix_char == ""
	prefix_char = ""
	return prefix
end

for _, m in ipairs(modes) do
	keymap(m, "j", function()
		return hasNoPrefix() and vim.wo.wrap and "gj" or "j"
	end, { expr = true, desc = "屏幕行下移" })
	keymap(m, "k", function()
		return hasNoPrefix() and vim.wo.wrap and "gk" or "k"
	end, { expr = true, desc = "屏幕行上移" })
end

keymap({ "n", "x" }, "<Down>", function()
	return hasNoPrefix() and vim.wo.wrap and "gj" or "j"
end, { expr = true })
keymap({ "n", "x" }, "<Up>", function()
	return hasNoPrefix() and vim.wo.wrap and "gk" or "k"
end, { expr = true })

vim.keymap.set("n", "gl", "<esc>:URLOpenUnderCursor<cr>")
