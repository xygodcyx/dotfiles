-- lua/plugins/cmp.lua
return {
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = "InsertEnter",
		config = function()
			require("luasnip").config.setup({
				history = true,
				update_events = "TextChanged,TextChangedI",
			})
			require("luasnip.loaders.from_vscode").lazy_load()
			-- require("luasnip.loaders.from_lua").load({
			-- 	paths = { vim.fn.stdpath("config") .. "/luasnippets" },
			-- })
		end,
		keys = function()
			-- Disable default tab keybinding in LuaSnip
			return {}
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
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
				["<C-i>"] = cmp.mapping.confirm({ select = true }),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
			})

			-- 合并 sources
			opts.sources = cmp.config.sources({
				{
					name = "nvim_lsp",
				},
				{
					name = "luasnip",
				},
				{ name = "path" },
				{ name = "buffer" },
			})
			opts.matching = {
				disallow_prefix_unmatching = false,
				-- disallow_fuzzy_matching = true, -- 完全禁用模糊匹配（不推荐）
				-- disallow_partial_matching = true, -- 要求输入更完整
			}
			opts.sorting = {
				priority_weight = 2,
				comparators = {
					require("cmp.config.compare").exact, -- 精确匹配优先
					require("cmp.config.compare").offset, -- 靠近光标的前缀匹配优先
					require("cmp.config.compare").score, -- 使用默认的评分
					-- require("cmp-under-comparator").under, -- 下划线排序优化
					require("cmp.config.compare").recently_used, -- 最近使用优先
					require("cmp.config.compare").order, -- 保持源顺序
				},
			}
			opts.performance = {
				debounce = 100, -- 默认 60ms，增加可减少频繁刷新
				throttle = 50, -- 默认 30ms，增加可减少频繁刷新
				fetching_timeout = 300, -- 默认 500ms，适当减少可更快获得结果
			}

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
					-- 如果是 LSP 来源，优先显示 detail（通常包含路径）
					--
					local labelDetails = entry.completion_item.labelDetails
					if labelDetails and labelDetails.description then
						vim_item.menu = labelDetails.description
					end
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
	},
	-- {
	-- 	-- 使用 blink.cmp 替代 nvim-cmp
	-- 	"saghen/blink.cmp",
	-- 	-- 可选：提供 snippet 来源
	-- 	-- dependencies = { "rafamadriz/friendly-snippets" },
	-- 	-- 推荐使用 release tag 以下载预编译的二进制文件（Rust 模糊匹配器）
	-- 	version = "1.*",
	-- 	---@module 'blink.cmp'
	-- 	---@type blink.cmf.Config
	-- 	opts = {
	-- 		-- 键位映射预设：'default' 类似内置补全，'super-tab' 类似 VSCode
	-- 		keymap = {
	-- 			-- preset = "enter",
	-- 			["<C-j>"] = { "snippet_forward", "fallback" },
	-- 			["<C-k>"] = { "snippet_backward", "fallback" },
	-- 			-- ["<Tab>"] = false,
	-- 			["<S-Tab>"] = false,
	-- 			["<C-i>"] = {
	-- 				function(cmp)
	-- 					cmp.accept({ index = 1 })
	-- 				end,
	-- 			},
	-- 			-- ["<CR>"] = {
	-- 			-- 	function(cmp)
	-- 			-- 		cmp.accept({ index = 1 })
	-- 			-- 	end,
	-- 			-- 	"fallback",
	-- 			-- },
	-- 			--
	-- 			-- ["<Tab>"] = { "fallback" },
	-- 			["<C-d>"] = { "show_documentation", "fallback" },
	-- 			-- ["<C-j>"] = { "snippet_forward" },
	-- 			-- ["<C-k>"] = { "snippet_backward" },
	-- 			["<C-b>"] = { "scroll_documentation_up", "fallback" },
	-- 			["<C-f>"] = { "scroll_documentation_down", "fallback" },
	-- 		},
	--
	-- 		appearance = {
	-- 			-- 'mono' 用于 Nerd Font Mono，'normal' 用于 Nerd Font
	-- 			nerd_font_variant = "mono",
	-- 		},
	-- 		completion = {
	-- 			-- 不自动显示文档弹窗，仅在手动触发时显示
	-- 			documentation = { auto_show = false },
	-- 			keyword = {
	-- 				range = "full", -- 关键配置
	-- 			},
	-- 			trigger = {
	-- 				show_on_keyword = true, -- 输入关键字时自动触发
	-- 				show_on_trigger_character = true,
	-- 				-- show_on_insert = true,
	-- 			},
	-- 			-- 默认选中的行为，保持和 nvim-cmp 类似的手感
	-- 			list = {
	-- 				selection = {
	-- 					preselect = true,
	-- 					auto_insert = true,
	-- 				},
	-- 			},
	-- 		},
	-- 		-- 默认启用的源，可在此处扩展
	-- 		sources = {
	-- 			default = { "lsp", "path", "snippets", "buffer" },
	--
	-- 			providers = {
	--
	-- 				buffer = {
	-- 					opts = {
	-- 						-- get all buffers, even ones like neo-tree
	-- 						-- get_bufnrs = vim.api.nvim_list_bufs
	-- 						-- or (recommended) filter to only "normal" buffers
	-- 						get_bufnrs = function()
	-- 							return vim.tbl_filter(function(bufnr)
	-- 								return false
	-- 								-- return vim.bo[bufnr].buftype == ""
	-- 							end, vim.api.nvim_list_bufs())
	-- 						end,
	-- 					},
	-- 				},
	-- 				lsp = {
	-- 					name = "LSP",
	-- 					module = "blink.cmp.sources.lsp",
	-- 					-- transform_items = function(_, items)
	-- 					-- 	return vim.tbl_filter(function(item)
	-- 					-- 		return item.kind ~= require("blink.cmp.types").CompletionItemKind.Keyword
	-- 					-- 	end, items)
	-- 					-- end,
	-- 				},
	-- 			},
	-- 		},
	-- 		-- 使用 Rust 实现的模糊匹配器（如果可用），性能更好，具备拼写容错能力
	-- 		fuzzy = {
	-- 			-- sorts = {
	-- 			-- 	-- 优先按字符长度排序（短的在前）
	-- 			-- 	function(a, b)
	-- 			-- 		local len_a = #(a.label or "")
	-- 			-- 		local len_b = #(b.label or "")
	-- 			-- 		if len_a == len_b then
	-- 			-- 			return nil -- 长度相同，交给后面的排序规则处理
	-- 			-- 		end
	-- 			-- 		return len_a < len_b
	-- 			-- 	end,
	-- 			-- 	-- 保留默认的排序规则作为后备
	-- 			-- 	"score",
	-- 			-- 	"sort_text",
	-- 			-- },
	-- 			implementation = "rust",
	-- 			prebuilt_binaries = { download = true },
	-- 		},
	-- 	},
	-- 	opts_extend = { "sources.default" },
	-- },
}
