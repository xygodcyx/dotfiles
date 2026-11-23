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
			-- require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_lua").load({
				paths = { vim.fn.stdpath("config") .. "/luasnippets" },
			})
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
			local lsp_source = require("cmp_nvim_lsp.source")

			if not lsp_source._clangd_completion_cache_patch then
				lsp_source._clangd_completion_cache_patch = true
				local original_complete = lsp_source.complete

				lsp_source.complete = function(self, params, callback)
					return original_complete(self, params, function(response)
						if self.client.name == "clangd" and response and response.items then
							response.isIncomplete = false
						end
						callback(response)
					end)
				end
			end

			opts.preselect = cmp.PreselectMode.Item
			opts.completion = {
				completeopt = "menu,menuone,noinsert",
			}
			-- 合并 mapping
			opts.mapping = cmp.mapping.preset.insert({
				["<C-u>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						for _ = 1, 5 do
							cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
						end
					else
						fallback()
					end
				end, { "i", "s" }),

				["<C-d>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						for _ = 1, 5 do
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						end
					else
						fallback()
					end
				end, { "i", "s" }),

				["<C-g>"] = cmp.mapping(function(fallback)
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
				["<TAB>"] = cmp.mapping.confirm({ select = true }),
			})

			-- 合并 sources
			opts.sources = cmp.config.sources({
				{
					name = "nvim_lsp",
					priority = 1000,
				},
				{
					name = "luasnip",
					priority = 750,
				},
				{
					name = "path",
					priority = 500,
				},
				{
					name = "buffer",
					priority = 250,
				},
			})
			opts.matching = {
				disallow_fuzzy_matching = false,
				disallow_fullfuzzy_matching = false,
				disallow_partial_fuzzy_matching = false,
				disallow_partial_matching = false,
				disallow_prefix_unmatching = false,
			}
			opts.sorting = {
				priority_weight = 2,
				comparators = {
					require("cmp.config.compare").exact,
					require("cmp.config.compare").recently_used,
					require("cmp.config.compare").score,
					require("cmp.config.compare").offset,
					require("cmp.config.compare").locality,
					require("cmp.config.compare").kind,
					require("cmp.config.compare").sort_text,
					require("cmp.config.compare").length,
					require("cmp.config.compare").order,
				},
			}
			opts.performance = {
				debounce = 60, -- 默认 60ms，增加可减少频繁刷新
				throttle = 30, -- 默认 30ms，增加可减少频繁刷新
				fetching_timeout = 1000, -- 默认 500ms，适当减少可更快获得结果
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

			cmp.event:on("confirm_done", function(event)
				local entry = event.entry
				if not entry then
					return
				end

				local word = entry:get_word() or ""
				local kind = entry:get_kind()

				-- 1. 判断是否需要处理：
				-- 规则A: gl 开头的函数（要求 gl 后紧跟字母，排除 gl_ 和 GL_）
				local is_gl_func = word:match("^gl%a") ~= nil

				-- 规则B: 普通函数、方法
				local is_normal_func = (
					kind == cmp.lsp.CompletionItemKind.Function or kind == cmp.lsp.CompletionItemKind.Method
				)

				-- 规则C: 类、结构体（如果你希望它们也补全括号分号的话）
				-- local is_type = (kind == cmp.lsp.CompletionItemKind.Class or kind == cmp.lsp.CompletionItemKind.Struct)
				--
				-- 如果不是以上任何一种，直接退出
				if not (is_gl_func or is_normal_func) then
					return
				end

				-- 2. 延迟执行，确保 cmp 已经把文本完全插入
				vim.schedule(function()
					local line = vim.api.nvim_get_current_line()
					local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based 字节索引
					local before_cursor = line:sub(1, col)

					-- 条件一：如果是新行，或者光标前只有空白，不处理
					if before_cursor:match("^%s*$") then
						return
					end

					-- 条件二：在函数实参位置（已有未闭合的括号）不处理
					local open_parens = select(2, before_cursor:gsub("%(", ""))
					local close_parens = select(2, before_cursor:gsub("%)", ""))
					local char_before = before_cursor:match("%S$")

					if open_parens > close_parens and (char_before == "(" or char_before == ",") then
						return
					end

					-- 条件三：如果后面已经有括号或分号，不再重复插入
					local text_after = line:sub(col + 1)
					if text_after:match("^%s*%(+%)") or text_after:match("^%s*;") then
						return
					end

					-- 3. 执行插入 "();"
					if text_after:match("^%s*$") then
						-- 插入括号和分号
						vim.api.nvim_put({ "();" }, "c", true, true)
						-- 将光标移动到括号内
						vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + 1 })
					end
				end)
			end)
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
