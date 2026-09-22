-- lua/plugins/ui.lua
return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup()
		end,
	},
	{
		"mei28/luminate.nvim",
		event = "VeryLazy",
		config = function()
			require("luminate").setup({
				duration = 130, -- 高亮持续毫秒数
			})
		end,
	},
	{
		"stevearc/dressing.nvim",
		opts = {},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			spec = {
				{ "<leader>d", group = "调试" }, -- 把 +debug 改成 +调试
				{ "<leader>f", group = "文件" },
				{ "<leader>g", group = "Git" },
				{ "<leader>s", group = "搜索" },
				{ "<leader>u", group = "界面" },
				{ "<leader>x", group = "诊断" },
				{ "<leader>c", group = "代码操作" },
			},
		},
	},
	-- 状态栏
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local icons = require("nvim-web-devicons")

			-- ⭐ 添加 tcss 文件图标
			icons.set_icon({
				tcss = {
					icon = "", -- CSS 图标（或  也行）
					color = "#38b2ac",
					cterm_color = "80",
					name = "TailwindCSS",
				},
			})
			require("lualine").setup({
				options = {
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
			})
		end,
	},
	{
		"sphamba/smear-cursor.nvim",

		opts = {
			-- Smear cursor when switching buffers or windows.
			smear_between_buffers = true,

			-- Smear cursor when moving within line or to neighbor lines.
			-- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
			smear_between_neighbor_lines = true,

			-- Draw the smear in buffer space instead of screen space when scrolling
			scroll_buffer_space = true,

			-- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
			-- Smears and particles will look a lot less blocky.
			legacy_computing_symbols_support = false,

			-- Smear cursor in insert mode.
			-- See also `vertical_bar_cursor_insert_mode` and `distance_stop_animating_vertical_bar`.
			smear_insert_mode = true,
		},
	},

	-- 文件树
	-- {
	-- 	"nvim-tree/nvim-tree.lua",
	-- 	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- 	config = function()
	-- 		require("nvim-tree").setup({
	-- 			sort_by = "case_sensitive",
	-- 			view = {
	-- 				width = 30,
	-- 				side = "left",
	-- 			},
	-- 			renderer = {
	-- 				group_empty = true,
	-- 			},
	-- 			hijack_directories = {
	-- 				enable = true, -- 启用目录劫持
	-- 				auto_open = false,
	-- 			},
	-- 		})
	-- 		vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Tree" })
	-- 	end,
	-- },

	-- 标签栏
	-- {
	-- 	"romgrk/barbar.nvim",
	-- 	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- },
	-- {
	-- 	"sphamba/smear-cursor.nvim",
	-- 	opts = {},
	-- },
}
