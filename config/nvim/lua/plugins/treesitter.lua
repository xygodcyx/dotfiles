-- lua/plugins/treesitter.lua
return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.config").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- 自动查找光标后的匹配项
						keymaps = {
							-- 选中函数体 / 包含函数声明
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							-- 选中条件判断 (if/else 块，适合 Python/Lua)
							["ai"] = "@conditional.outer",
							["ii"] = "@conditional.inner",
							-- 选中循环 (for/while 块)
							["al"] = "@loop.outer",
							["il"] = "@loop.inner",
							-- 选中表达式 (如表达式 `a + b * c`)
							["ae"] = "@assignment.outer",
							["ie"] = "@assignment.rhs", -- 仅选中赋值符号右侧的表达式
						},
					},
				},
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
