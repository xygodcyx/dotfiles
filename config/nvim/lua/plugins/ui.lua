-- lua/plugins/ui.lua
return {
	-- lua/plugins/ui.lua
	{
		"stevearc/dressing.nvim",
		opts = {},
	},
	{ "folke/which-key.nvim", event = "VeryLazy", opts = {
		preset = "helix",
	} },
	-- 状态栏
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
			})
		end,
	},

	-- 文件树
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				sort_by = "case_sensitive",
				view = {
					width = 30,
					side = "left",
				},
				renderer = {
					group_empty = true,
				},
				hijack_directories = {
					enable = true, -- 启用目录劫持
					auto_open = false,
				},
			})
			vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Tree" })
		end,
	},

	-- 标签栏
	{
		"romgrk/barbar.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.keymap.set("n", "<S-L>", ":BufferNext<CR>", { desc = "Next Buffer" })
			vim.keymap.set("n", "<S-H>", ":BufferPrevious<CR>", { desc = "Previous Buffer" })
			vim.keymap.set("n", "<S-W>", ":BufferClose<CR>", { desc = "Close Buffer" })
		end,
	},
	{
		"sphamba/smear-cursor.nvim",
		opts = {
			smear_between_buffers = false,
			legacy_computing_symbols_support = true,
			stiffness = 0.8,
			trailing_stiffness = 0.4,
			damping = 0.9,
		},
	},
}
