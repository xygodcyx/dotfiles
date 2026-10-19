-- {
-- 	"rebelot/kanagawa.nvim",
-- 	priority = 1000,
-- 	config = function()
-- 		require("kanagawa").setup({
-- 			theme = "wave", -- 可选: wave, dragon, lotus
-- 			transparent = false,
-- 		})
-- 		vim.cmd.colorscheme("kanagawa")
-- 	end,
-- }

-- return {
-- 	"olimorris/onedarkpro.nvim",
-- 	priority = 1000, -- Ensure it loads first
-- 	config = function()
-- 		vim.cmd("colorscheme onedark_dark")
--
-- 		vim.api.nvim_set_hl(0, "Visual", {
-- 			bg = "#3E4451", -- 你可以换成任何你喜欢的颜色
-- 			fg = "NONE",
-- 		})
-- 	end,
-- }

-- return {
-- 	"bluz71/vim-moonfly-colors",
-- 	name = "moonfly",
-- 	lazy = false,
-- 	priority = 1000,
-- 	config = function()
-- 		vim.cmd("colorscheme moonfly")
-- 	end,
-- }

return {
	"dgox16/oldworld.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("oldworld").setup({
			styles = {
				booleans = { italic = true, bold = true },
			},
			integrations = {
				hop = true,
				telescope = false,
				cmp = false,
			},
			highlight_overrides = {
				-- Comment = { bg = "#ff0000" },
			},
		})
		vim.cmd.colorscheme("oldworld")
	end,
}
