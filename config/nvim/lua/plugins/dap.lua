return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			-- 必须指定终端窗口打开方式，承载内置控制台
			dap.defaults.fallback.switchbuf = "noop-if-visible,usetab,uselast"
			dap.defaults.fallback.terminal_win_cmd = "tabnew | set filetype=dap-terminal"

			-- codelldb 适配器配置
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
				expressions = {
					native = true,
				},
				detached = false,
			}

			-- C 和 C++ 的调试配置
			local cpp_configs = {
				{
					name = "codelldb",
					type = "codelldb",
					request = "launch",
					program = function()
						local cwd = vim.fn.getcwd()
						local cache_file = vim.fn.stdpath("cache") .. "/dap_" .. vim.fn.sha256(cwd):sub(1, 8) .. ".txt"
						local last = ""
						local f = io.open(cache_file, "r")
						if f then
							last = f:read("*l") or ""
							f:close()
						end

						local default = last ~= "" and last or (vim.fn.getcwd() .. "/")
						local input = vim.fn.input("可执行文件路径: ", default, "file")
						if input == "" then
							return default
						end

						-- 写回缓存
						local w = io.open(cache_file, "w")
						if w then
							w:write(input)
							w:close()
						end

						return input
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					-- 1. 必须启用这一行，确保输出可被系统事件捕捉
					console = "integratedTerminal",
				},
			}
			dap.configurations.cpp = cpp_configs
			dap.configurations.c = cpp_configs

			-- Lua 调试配置
			local lua_configs = {
				{
					name = "启动 Lua 脚本 (local-lua-debugger)",
					type = "local-lua-debugger",
					request = "launch",
					program = function()
						return vim.fn.input("Lua 脚本路径: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			dap.adapters["local-lua-debugger"] = {
				type = "executable",
				command = "node",
				args = {
					vim.fn.stdpath("data")
						.. "/lazy/../mason/packages/local-lua-debugger-vscode/extension/extension/debugAdapter.js",
				},
			}
			dap.configurations.lua = lua_configs
		end,
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "断点切换",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("条件断点: "))
				end,
				desc = "条件断点",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "启动/继续调试",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "运行到光标",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "步入",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "步出",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "跳过",
			},
			{
				"<leader>dp",
				function()
					require("dap").pause()
				end,
				desc = "暂停",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "打开 REPL",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "终止调试",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "重新运行上次调试",
			},
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		lazy = false, -- 关键：不要因为 keys 而懒加载
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({
				layouts = {
					{
						elements = { "scopes", "breakpoints", "stacks", "watches", "repl" },
						size = 40,
						position = "left",
					},
					{
						elements = { "console" },
						size = 10,
						position = "bottom",
					},
				},
			})

			-- 把 listener 放到这里，setup 之后再注册
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
				vim.fn.jobstart("pkill -f mason/bin/codelldb")
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
				vim.fn.jobstart("pkill -f mason/bin/codelldb")
			end
			-- 在你的 nvim-dap-ui config 中，dapui.setup 之后添加
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dapui_console",
				callback = function(args)
					local buf = args.buf
					-- 延迟一小段时间，确保终端初始化完成
					vim.defer_fn(function()
						if not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
						-- 从顶部开始，删除连续的空行（只保留实际输出）
						local first_non_empty = 1
						for i, line in ipairs(lines) do
							if line:match("%S") then -- 找到第一个非空行
								first_non_empty = i
								break
							end
						end
						if first_non_empty > 1 then
							vim.api.nvim_buf_set_lines(buf, 0, first_non_empty - 1, false, {})
						end
					end, 50) -- 50ms 延迟，可根据机器速度微调
				end,
			})
			-- 在 nvim-dap-ui config 中，配合方案二的 autocmd
			vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
				pattern = "*",
				callback = function(args)
					if vim.bo[args.buf].filetype == "dapui_console" then
						-- 将光标钉在第一行，避免初始滚动位置产生空行错觉
						local wins = vim.fn.win_findbuf(args.buf)
						for _, win in ipairs(wins) do
							pcall(vim.api.nvim_win_set_cursor, win, { 1, 0 })
						end
					end
				end,
			})

			-- 自滚顶脚本
			-- local dap_scroll_group = vim.api.nvim_create_augroup("DapConsoleScroll", { clear = true })
			-- vim.api.nvim_create_autocmd({ "TextChangedT", "BufEnter", "BufWinEnter" }, {
			-- 	group = dap_scroll_group,
			-- 	pattern = "*",
			-- 	callback = function(args)
			-- 		if vim.bo[args.buf].filetype == "dapui_console" then
			-- 			local wins = vim.fn.win_findbuf(args.buf)
			-- 			for _, win in ipairs(wins) do
			-- 				pcall(vim.api.nvim_win_set_cursor, win, { 1, 0 })
			-- 			end
			-- 		end
			-- 	end,
			-- })
		end,
		keys = {
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "切换调试 UI",
			},
			{
				"<leader>de",
				function()
					require("dapui").eval()
				end,
				mode = { "n", "v" },
				desc = "求值表达式",
			},
		},
	},
}
