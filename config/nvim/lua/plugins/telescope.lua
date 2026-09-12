-- lua/plugins/telescope.lua

return {
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
		opts = {
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden", -- 搜索隐藏文件
				},
			},
			pickers = {
				find_files = {
					hidden = true, -- 关键：让 find_files 默认显示隐藏文件
				},
			},
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					file_ignore_patterns = {
						"node_modules",
						"%.lock",
						"%.jpg",
						"%.png",
						"%.uid",
						"%.tmp",
						"%.import",
						"__pycache__",
					},
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
						},
					},
				},
			})

			-- 快捷键映射
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
		end,
	},
}
