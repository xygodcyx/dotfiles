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
			["<C-d>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					require("cmp").open_docs()
				else
					fallback()
				end
			end, { "i", "s" }),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-b>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping.abort(),
			["<C-j>"] = cmp.mapping(function()
				if require("luasnip").jumpable(1) then
					require("luasnip").jump(1)
				end
			end, { "i", "s" }),

			["<C-k>"] = cmp.mapping(function()
				if require("luasnip").jumpable(-1) then
					require("luasnip").jump(-1)
				end
			end, { "i", "s" }),
			["<CR>"] = cmp.mapping.confirm({ select = true }),
		})

		-- 合并 sources
		opts.sources = cmp.config.sources({
			{
				name = "nvim_lsp",
				option = {
					-- 将 :: 识别为关键词的一部分
					keyword_pattern = [[\%(\k\|\:\)\+]],
				},
				trigger_characters = { "::", "." },
			},
			{
				name = "luasnip",
			},
			{ name = "buffer" },
			{ name = "path" },
		})

		-- 补全菜单和文档窗口的边框
		opts.window = {
			completion = cmp.config.window.bordered({
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
				scrollbar = false,
				max_height = 12,
				max_width = 60,
			}),
			documentation = cmp.config.window.bordered({
				border = "rounded",
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				max_height = 15,
				max_width = 60,
			}),
		}

		opts.view = {
			docs = { auto_open = false },
		}
		opts.formatting = {
			fields = { "kind", "abbr", "menu" },
			format = function(entry, vim_item)
				local ELLIPSIS_CHAR = "…"
				local MAX_LABEL_WIDTH = 50 -- abbr 字段最大宽度
				local MAX_MENU_WIDTH = 30 -- menu 字段最大宽度

				-- 截断 abbr（补全项名称）
				local label = vim_item.abbr
				if #label > MAX_LABEL_WIDTH then
					vim_item.abbr = vim.fn.strcharpart(label, 0, MAX_LABEL_WIDTH) .. ELLIPSIS_CHAR
				end

				-- 截断 menu（来源/详情）
				local menu = vim_item.menu
				if menu and #menu > MAX_MENU_WIDTH then
					vim_item.menu = vim.fn.strcharpart(menu, 0, MAX_MENU_WIDTH) .. ELLIPSIS_CHAR
				end

				return vim_item
			end,
		}

		return opts
	end,
}
