local function path_with_modified(opts, path)
	local bufnr = vim.fn.bufnr(path)
	local suffix = ""

	if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
		if vim.bo[bufnr].modified then
			suffix = " [+]"
		end
	end

	return path .. suffix
end
return {
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		opts = {
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
			defaults = {
				path_display = path_with_modified,
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden", -- 让 live_grep 也搜索隐藏文件
				},
				file_ignore_patterns = {
					"temp",
					"library",
					"setting",
					"vendor",
					"static",
					"libs",
					"build",
					"dist",
					"install",
					".cache",
					"node_modules",
					"%.meta",
					"%.scene",
					"%.plist",
					"%.DS_Store",
					"%.lock",
					"%.jpg",
					"%.png",
					"%.uid",
					"%.tmp",
					"%.import",
					"__pycache__",
					"%.git/", -- 建议加上，避免 rg 扫 .git
				},
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true, -- find_files 显示隐藏文件
				},
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			-- 加载 fzf-native 扩展
			pcall(require("telescope").load_extension, "fzf")
			-- 快捷键映射
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
		end,
	},
}
