-- lua/plugins/cmp.lua
return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		"saadparwaiz1/cmp_luasnip",
	},
	opts = function(_, opts)
		local cmp = require("cmp")

		-- 合并 mapping
		opts.mapping = cmp.mapping.preset.insert({
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-b>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<C-e>"] = cmp.mapping.abort(),
		})

		-- 合并 sources
		opts.sources = cmp.config.sources({
			{ name = "nvim_lsp" },
			{ name = "luasnip" },
			{ name = "buffer" },
			{ name = "path" },
		})

		return opts
	end,
}
