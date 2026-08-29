-- lua/plugins/session.lua
return {
	{
		"rmagatti/auto-session",
		lazy = false, -- 必须立即加载
		config = function()
			require("auto-session").setup({
				-- ===== 基础设置 =====
				enabled = true,
				auto_restore_enabled = true, -- 自动恢复会话
				auto_save_enabled = true, -- 自动保存会话
				auto_restore_after_session_restore = true,

				-- ===== 保存位置 =====
				session_lens_path = vim.fn.stdpath("data") .. "/sessions/",

				-- ===== 保存条件 =====
				-- 只在有修改或打开文件时保存
				save_condition = function()
					local bufnr = vim.api.nvim_get_current_buf()
					return vim.api.nvim_buf_get_name(bufnr) ~= "" or vim.api.nvim_buf_get_option(bufnr, "modified")
				end,

				-- ===== 排除的文件类型 =====
				excluded_filetypes = {
					"gitcommit",
					"gitrebase",
					"qf",
					"help",
					"terminal",
					"toggleterm",
					"NvimTree",
				},

				-- ===== 排除的目录 =====
				excluded_dirs = {
					"~/Downloads",
					"~/Desktop",
					"/tmp",
				},

				-- ===== 要保存的选项 =====
				session_options = {
					-- 保存全局变量
					globals = {
						"vim_global_variable_example",
					},
					-- 保存缓冲区的选项
					buffers = "all",
				},

				-- ===== 快捷键 =====
				keys = {
					-- 在 Telescope 中查找会话
					find_session = "<leader>sf",
					-- 删除当前会话
					delete_session = "<leader>sd",
				},
			})

			-- 覆盖默认快捷键（可选）
			vim.keymap.set("n", "<leader>ss", ":SessionSave<CR>", { desc = "Save Session" })
			vim.keymap.set("n", "<leader>sr", ":SessionRestore<CR>", { desc = "Restore Session" })
			vim.keymap.set("n", "<leader>sd", ":SessionDelete<CR>", { desc = "Delete Session" })
		end,
	},

	-- 可选：用 Telescope 搜索会话
	{
		"rmagatti/session-lens",
		dependencies = {
			"rmagatti/auto-session",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("session-lens").setup({
				theme = "dropdown",
				previewer = false,
				path_display = { "smart" },
			})

			-- 用 Telescope 查找会话
			vim.keymap.set("n", "<leader>sf", require("session-lens").search_session, { desc = "Find Sessions" })
		end,
	},
}
