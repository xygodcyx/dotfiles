-- lua/plugins/mini.lua
return {
	{
		"echasnovski/mini.nvim",
		version = false, -- 建议使用 main 分支以获取最新功能
		config = function()
			-- require("mini.comment").setup()

			require("mini.ai").setup()

			-- 启用缩进范围可视化
			require("mini.indentscope").setup()

			require("mini.move").setup()

			require("mini.splitjoin").setup()

			-- require("mini.surround").setup()
		end,
	},
}
