-- lua/plugins/cmp.lua
return {
	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {
			bind = true,
			handler_opts = {
				border = "rounded", -- 边框样式
			},
			floating_window = true, -- 是否使用浮动窗口
			hint_enable = true, -- 是否显示行内 inlay 提示
			hint_prefix = "󰏫 ",
			hi_parameter = "LspSignatureActiveParameter", -- 当前正在输入的参数高亮组
			handler_opts = {
				border = "rounded",
			},
			always_trigger = true, -- 只要在括号内就持续显示
		},
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
	},
	-- ===== 补全引擎 =====
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			-- LSP 补全源
			"hrsh7th/cmp-nvim-lsp",
			-- 缓冲区补全源（从已打开的文件中补全）
			"hrsh7th/cmp-buffer",
			-- 路径补全源
			"hrsh7th/cmp-path",
			{
				"tzachar/cmp-fuzzy-buffer",
				dependencies = {
					"tzachar/fuzzy.nvim",
				},
			}, -- 模糊搜索
			-- 代码片段引擎
			{
				"L3MON4D3/LuaSnip",
				dependencies = {
					"rafamadriz/friendly-snippets", -- 预置代码片段
				},
				config = function()
					require("luasnip").config.setup({
						history = true,
						update_events = "TextChanged,TextChangedI",
					})
					require("luasnip.loaders.from_vscode").lazy_load()
				end,
			},
			-- LuaSnip 补全源
			"saadparwaiz1/cmp_luasnip",
			-- 可选：命令行补全
			"hrsh7th/cmp-cmdline",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- 设置补全源
			cmp.setup({
				sorting = {
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.recently_used,
						cmp.config.compare.score,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				-- 1. 设置预选策略为 Always（强制总是选择 LSP 返回的默认首选项）
				-- preselect = cmp.PreselectMode.Item,

				-- 2. 调整 completeopt 行为
				completion = {
					-- remove 'noinsert' and 'noselect'
					-- 'select' 表示默认选中第一项，'menu,menuone' 表示有菜单时显示
					completeopt = "menu,menuone",
					autocomplete = { cmp.TriggerEvent.TextChanged },
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- 显示补全列表
					["<C-Space>"] = cmp.mapping.complete(),
					-- 确认补全
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					-- 上下选择
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					-- 滚动文档
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					-- 跳转到下一个占位符（LuaSnip）
					["<C-j>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-k>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						priority = 1000,
						entry_filter = function(entry, ctx)
							local cursor = vim.api.nvim_win_get_cursor(0)
							local line_text = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or ""
							local before_cursor = line_text:sub(1, cursor[2])

							-- 判断光标前是否紧跟 . 或 ::
							local is_member_access = before_cursor:match("%.%s*$") or before_cursor:match("::%s*$")

							if is_member_access then
								-- 核心修复：15 对应 LSP 标准的 Snippet 标记类型，不需要依赖 cmp.types
								if entry:get_kind() == 15 then
									return false
								end
							end
							return true
						end,
					},
					{
						name = "luasnip",
						priority = 750,
						entry_filter = function()
							local cursor = vim.api.nvim_win_get_cursor(0)
							local line_text = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or ""
							local before_cursor = line_text:sub(1, cursor[2])

							if before_cursor:match("%.%s*$") or before_cursor:match("::%s*$") then
								return false
							end
							return true
						end,
					},
					{ name = "path", priority = 500 },
					{ name = "buffer", priority = 250, keyword_length = 0 }, -- 限制仅当输入达到0个字符才从 buffer 提取，防止乱七八糟的干扰
					{ name = "fuzzy" }, -- 添加模糊搜索源
				}),
				-- 补全窗口样式

				window = {
					completion = cmp.config.window.bordered({
						border = "rounded", -- 边框可选: "single", "double", "rounded", "solid"
						winhighlight = "Normal:NormalFloat,CursorLine:PmenuSel,Search:None",
						-- 限制补全列表的最小和最大高度
						max_height = 15,
					}),
					documentation = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:NormalFloat,CursorLine:PmenuSel,Search:None",
						-- 限制文档窗口的尺寸范围，防止被挤压变狭长
					}),
				},
				performance = {
					debounce = 60, -- 防抖延迟（毫秒），避免频繁打字发请求
					throttle = 30, -- 节流，提高连续输入流畅度
					fetching_timeout = 500, -- 超时释放，防止单个死锁导致后续卡顿
				},
				-- 格式化补全项
				formatting = {
					fields = { "abbr", "kind", "menu" },
					format = function(entry, vim_item)
						-- 添加图标
						local kind_icons = {
							Text = "󰉿",
							Method = "󰆧",
							Function = "󰊕",
							Constructor = "",
							Field = "󰜢",
							Variable = "󰀫",
							Class = "󰠱",
							Interface = "",
							Module = "",
							Property = "󰜢",
							Unit = "󰑭",
							Value = "󰎠",
							Enum = "",
							Keyword = "󰌋",
							Snippet = "",
							Color = "󰏘",
							File = "󰈙",
							Reference = "",
							Folder = "󰉋",
							EnumMember = "",
							Constant = "󰏿",
							Struct = "󰙅",
							Event = "",
							Operator = "󰆕",
							TypeParameter = "󰊄",
						}
						vim_item.kind = (kind_icons[vim_item.kind] or "") .. " " .. vim_item.kind

						local item = entry:get_completion_item()
						if item.detail then
							local detail = item.detail
							vim_item.menu = detail
						end

						return vim_item
					end,
				},
				matching = {
					disallow_fuzzy_matching = false,
					disallow_fullfuzzy_matching = false,
					disallow_partial_fuzzy_matching = false,
					disallow_partial_matching = false,
					disallow_prefix_unmatching = false,
				},

				-- 确保不过滤已完全匹配的项
				matching = {
					disallow_symbol_nonprefix_matching = false,
				},

				-- 重点：调整 filter 规则，防止精确匹配时过滤掉同名 Snippet
				filtering = {
					-- 允许与当前输入完全相同的项继续留在列表中
					allow_exact_matches = true,
				},
			})

			-- 命令行补全（输入 `:` 命令时）
			cmp.setup.cmdline(":", {
				sorting = {
					comparators = {
						cmp.config.compare.recently_used,
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				sources = {
					{ name = "buffer" },
					{ name = "cmdline" },
					{ name = "fuzzy" }, -- 添加模糊搜索源
				},
				mapping = cmp.mapping.preset.cmdline({
					["<CR>"] = cmp.mapping({
						c = function(fallback)
							if cmp.visible() then
								local text = vim.fn.getcmdline()
								local selected = cmp.get_selected_entry()

								-- 1. 如果只输入了单字母（如 :w 或 :q），直接执行原命令，绝不强行补全为 :wq
								if #text == 1 then
									cmp.close()
									fallback()
									return
								end

								-- 2. 如果用户手动用 Tab / 方向键高亮选中了某一项，按回车直接确认并执行
								if selected then
									cmp.confirm({ select = false })
									vim.schedule(function()
										vim.api.nvim_feedkeys(
											vim.api.nvim_replace_termcodes("<CR>", true, false, true),
											"n",
											false
										)
									end)
									return
								end

								-- 3. 输入超过 1 个字符（如 :Telesc），且没有手动高亮项时，自动选中第一项补全并执行
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
								cmp.confirm({ select = true })
								vim.schedule(function()
									vim.api.nvim_feedkeys(
										vim.api.nvim_replace_termcodes("<CR>", true, false, true),
										"n",
										false
									)
								end)
							else
								fallback()
							end
						end,
					}),
				}),
			})

			-- 搜索补全（输入 `/` 或 `?` 时）
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})
		end,
	},
}
