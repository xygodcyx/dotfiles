-- vim.api.nvim_create_autocmd("BufWritePre", {
-- 	pattern = "*",
-- 	callback = function(args)
-- 		require("conform").format({ bufnr = args.buf })
-- 	end,
-- })


-- 在 LSP 配置的 on_attach 回调中绑定
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	callback = function(event)
-- 		local opts = { buffer = event.buf }
-- 		-- 格式化
-- 		vim.keymap.set(
-- 			"n",
-- 			"<leader>fm",
-- 			function()
-- 				vim.lsp.buf.format({ async = true })
-- 			end,
-- 			vim.tbl_extend("force", opts, {
-- 				desc = "Format Code",
-- 			})
-- 		)
-- 	end,
-- })

local commands = {
	W = "w",
	Q = "q",
	Wq = "wq",
	WQ = "wq",
	Wa = "wa",
	WA = "wa",
	Wqa = "wqa",
	WQA = "wqa",
	Qall = "qall",
	QALL = "qall",
}

for upper, lower in pairs(commands) do
	vim.api.nvim_create_user_command(upper, function(opts)
		local cmd = lower
		vim.cmd(cmd)
	end, {
		bang = true,
		nargs = "*",
		complete = "file",
		desc = "Auto lowercase command alias",
	})
end

-- 方法 A：只要 LSP 服务器支持，自动为缓冲区开启 inlay_hint
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- 直接全局/按缓冲区开启，内部会自动判断 LSP 能力
		vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		vim.schedule(function()
			vim.cmd("normal! zx") -- zx 用于刷新并应用当前文件的折叠
		end)
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		-- 获取当前文件的最后编辑位置
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		-- mark[1] 是行号，mark[2] 是列号
		-- 如果行号大于 0 且行号不超过文件总行数，则跳转
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})
