return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")

			-- codelldb 适配器
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- C 和 C++ 的调试配置
			local cpp_configs = {
				{
					name = "启动 (codelldb)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("可执行文件路径: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					console = "internalConsole",
				},
			}
			dap.configurations.cpp = cpp_configs
			dap.configurations.c = cpp_configs

			-- 调试 UI
			local dapui = require("dapui")
			dapui.setup()
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
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
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "步出",
			},
			{
				"<leader>dO",
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
		config = function()
			require("dapui").setup()
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
