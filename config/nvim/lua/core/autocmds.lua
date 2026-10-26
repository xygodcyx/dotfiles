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
		local ft = vim.bo.filetype
		if vim.tbl_contains({ "sagafinder", "sagaoutline" }, ft) then
			return false
		end
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

vim.api.nvim_create_user_command("SnipList", function()
	local res = vim.inspect(require("luasnip").available())
	vim.api.nvim_command("botright vnew")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(buf, "SnipList")
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "filetype", "lua")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(res, "\n"))
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end, {})

-- 在 dapui.setup 后面加上这段：
-- 强行让 dap-ui 所有的终端/控制台面板自动滚动到底部
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = "*",
	callback = function()
		-- 如果当前缓冲区的类型是终端（dap-ui 的 console 本质上是 terminal）
		if vim.bo.buftype == "dapui_console" then
			-- 延迟 10 毫秒执行，确保文本已经渲染完毕，然后滚动到最后一行
			vim.cmd("normal! gg")
		end
	end,
})

-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	callback = function(args)
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		if client and client.name == "ts_ls" then
-- 			-- 关闭 ts_ls 的诊断，让 eslint 接管
-- 			client.server_capabilities.diagnosticProvider = nil
-- 		end
-- 	end,
-- })

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "ts_ls" then
			-- 过滤掉 code 为 6133 的诊断

			if vim.b[args.buf]._ts_ls_diag_patched then
				return
			end
			vim.b[args.buf]._ts_ls_diag_patched = true
			local orig = vim.lsp.handlers["textDocument/publishDiagnostics"]
			client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
				if result and result.diagnostics then
					result.diagnostics = vim.tbl_filter(function(d)
						return d.code ~= 6133 and d.code ~= 6196
					end, result.diagnostics)
				end
				if orig then
					orig(err, result, ctx, config)
				end
			end
		end
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(ev)
		---@type string
		local path = ev.file
		if path:match("dap-") == nil then
			-- local file = vim.secure.read(path)
			-- print(file)
			-- for key, value in pairs(file) do
			-- 	print(key)
			-- end
		end
	end,
})

vim.api.nvim_create_autocmd("WinLeave", {
	callback = function()
		-- 检查当前是否打开了 code action 相关的窗口
		-- Neovim 0.10+ 的 code action 窗口通常包含 "code_action" 的 filetype 或特定的 buftype
		local bufnr = vim.api.nvim_get_current_buf()
		local ft = vim.bo[bufnr].filetype
		local buftype = vim.bo[bufnr].buftype

		-- 匹配 code action 窗口的特征，或者如果你用的是 Lspsaga，可能是 "saga_code_action"
		if ft:match("code_action") or ft:match("saga") or buftype == "prompt" then
			vim.cmd("close")
		end
	end,
	desc = "离开窗口时自动关闭 Code Action 浮窗",
})
