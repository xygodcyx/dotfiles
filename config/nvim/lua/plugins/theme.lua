return {
	"rebelot/kanagawa.nvim",
	priority = 1000,
	config = function()
		require("kanagawa").setup({
			theme = "wave", -- 可选: wave, dragon, lotus
			transparent = false,
		})
		vim.cmd.colorscheme("kanagawa")
	end,
}
--
-- return {
-- 	"olimorris/onedarkpro.nvim",
-- 	priority = 1000, -- Ensure it loads first
-- 	config = function()
-- 		vim.cmd("colorscheme onedark")
-- 	end,
-- }
