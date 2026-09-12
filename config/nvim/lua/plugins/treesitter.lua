-- lua/plugins/treesitter.lua
return {
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		init = function()
			-- 禁用 Vim 原生内置的 ftplugin 按键映射，解决 Python 下 f 被映射成括号的冲突问题
			vim.g.no_plugin_maps = true
		end,
		config = function()
			-- 1. 基础配置
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true, -- 自动跳到光标后面的目标
				},
				move = {
					set_jumps = true, -- 将跳转记录写入 jumplist (可以用 Ctrl+O/Ctrl+I 跳回)
				},
			})

			-- 2. 绑定选中快捷键 (Visual / Operator-pending 模式)
			local select = require("nvim-treesitter-textobjects.select")

			-- 选中整个函数 (af) 和 函数体内部 (if)
			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end)

			-- 选中整个类 (ac) 和 类内部 (ic)
			vim.keymap.set({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end)

			-- 3. 绑定跳转快捷键 (Normal / Visual / Operator-pending 模式)
			local move = require("nvim-treesitter-textobjects.move")

			-- 跳转到函数开头/结尾
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.config").setup({
				ensure_installed = {
					"vue",
					"lua",
					"vim",
					"vimdoc",
					"python",
					"javascript",
					"typescript",
					"c",
					"cpp",
					"go",
					"rust",
					"json",
					"yaml",
					"toml",
					"markdown",
				},
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
			})
		end,
	},
}
