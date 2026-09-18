-- lua/plugins/editor.lua
return {
	{

		"nvimdev/lspsaga.nvim",

		config = function()
			-- 1. 配置 lspsaga
			require("lspsaga").setup({
				-- 边框样式
				border = "rounded",
				-- 关闭事件
				close_events = {
					"BufLeave",
					"InsertEnter",
					"CursorMoved",
				},
				-- 诊断配置
				diagnostic = {
					on_insert = false,
					show_source = true,
					jump_float = true,
				},
				-- 代码操作
				code_action = {
					num_shortcut = true,
					keys = {
						quit = "q",
						exec = "<CR>",
					},
				},
				-- 查找器
				finder = {
					keys = {
						tabe = "<CR>",
					},
				},
				-- 重命名
				rename = {
					keys = {
						quit = "q",
						exec = "<CR>",
					},
				},
				-- 定义预览
				definition = {
					keys = {
						tabe = "<CR>",
					},
					edit = "<C-c>o",
				},
				-- 面包屑
				breadcrumbs = {
					enable = true,
					icon = ">",
					separator = "▸",
				},
				-- 大纲
				outline = {
					keys = {
						jump = "<CR>",
						quit = "q",
					},
				},
				-- 调用层级
				call_hierarchy = {
					keys = {
						jump = "<CR>",
						quit = "q",
					},
				},
				-- 浮动终端
				floaterm = {
					height = 0.6,
					width = 0.6,
				},
			})

			-- Hover 文档
			vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Documentation" })

			-- 预览定义
			vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek Definition" })

			-- 预览类型定义
			vim.keymap.set("n", "gt", "<cmd>Lspsaga peek_type_definition<CR>", { desc = "Peek Type Definition" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP Code Action" })
			-- 查找引用（Finder）
			-- vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<CR>", { desc = "Find References" })

			-- 代码操作
			vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Code Action" })

			-- 重命名
			vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "Rename" })

			-- 诊断跳转
			vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc = "Previous Diagnostic" })

			vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next Diagnostic" })

			-- 显示行内诊断
			vim.keymap.set(
				"n",
				"<leader>ce",
				"<cmd>Lspsaga show_line_diagnostics<CR>",
				{ desc = "Show Line Diagnostics" }
			)

			-- 调用层级
			vim.keymap.set("n", "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", { desc = "Incoming Calls" })
			vim.keymap.set("n", "<leader>co", "<cmd>Lspsaga outgoing_calls<CR>", { desc = "Outgoing Calls" })

			-- 大纲
			vim.keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Outline" })

			-- 浮动终端
			vim.keymap.set("n", "<leader>t", "<cmd>Lspsaga term_toggle<CR>", { desc = "Float Terminal" })

			-- 面包屑切换
			vim.keymap.set("n", "<leader>bb", "<cmd>Lspsaga toggle_breadcrumbs<CR>", { desc = "Toggle Breadcrumbs" })
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- optional
			"nvim-tree/nvim-web-devicons", -- optional
		},
	},

	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"lewis6991/async.nvim", -- Required for recent versions/Neovim 0.12+
		},
		lazy = false,
		config = function()
			local refactoring = require("refactoring")

			refactoring.setup({
				-- Add any global prompt/prompt flavor overrides here
				prompt_func_param_type = {
					go = false,
					java = false,
					cpp = false,
					c = false,
					objc = false,
					php = false,
					ts = true,
					javascript = true,
				},
				prompt_func_return_type = {
					go = false,
					java = false,
					cpp = false,
					c = false,
					objc = false,
					php = false,
					ts = false,
					javascript = false,
				},
			})

			-- Remap to prompt the refactor menu in both normal and visual mode
			vim.keymap.set({ "n", "x" }, "<leader>rr", function()
				refactoring.select_refactor()
			end, { desc = "Refactor Menu", noremap = true, silent = true })
		end,
	},
	{
		"abecodes/tabout.nvim",
		dependencies = { -- These are optional
			"nvim-treesitter/nvim-treesitter",
			"L3MON4D3/LuaSnip",
			"hrsh7th/nvim-cmp",
		},
		event = "InsertEnter", -- 推荐改为 InsertEnter 确保进入插入模式即挂载成功
		priority = 1000,
		lazy = false,
		config = function()
			require("tabout").setup({
				tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
				backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
				act_as_tab = true, -- shift content if tab out is not possible
				act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
				default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
				default_shift_tab = "<C-d>", -- reverse shift default action,
				enable_backwards = true, -- well ...
				completion = true, -- if the tabkey is used in a completion pum
				tabouts = {
					{ open = "'", close = "'" },
					{ open = '"', close = '"' },
					{ open = "`", close = "`" },
					{ open = "(", close = ")" },
					{ open = "[", close = "]" },
					{ open = "{", close = "}" },
					{ open = "<", close = ">" },
				},
				ignore_beginning = false, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
				exclude = {}, -- tabout will ignore these filetypes
			})
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip").config.setup({
				history = true,
				update_events = "TextChanged,TextChangedI",
			})
			require("luasnip.loaders.from_vscode").lazy_load({})
		end,
		keys = function()
			-- Disable default tab keybinding in LuaSnip
			return {}
		end,
	},
	-- {
	-- 	"kevinhwang91/nvim-ufo",
	-- 	dependencies = {
	-- 		"kevinhwang91/promise-async",
	-- 	},
	-- 	event = "VeryLazy",
	-- 	opts = {
	-- 		-- 1. 显式关闭打开文件时的自动折叠（关键配置）
	-- 		close_fold_kinds_for_ft = {
	-- 			default = {}, -- 确保默认不关闭任何 kind（如 comment, region 等）
	-- 		},
	-- 		provider_selector = function(bufnr, filetype, buftype)
	-- 			-- 使用 indent 作为 fallback，避免 treesitter 解析延迟导致的全屏折叠
	-- 			return { "treesitter", "indent" }
	-- 		end,
	-- 	},
	-- 	config = function(_, opts)
	-- 		-- 2. 基础 Option 设置
	-- 		vim.o.foldcolumn = "1"
	-- 		vim.o.foldlevel = 99
	-- 		vim.o.foldlevelstart = 99
	-- 		vim.o.foldenable = true
	--
	-- 		local ufo = require("ufo")
	-- 		opts = opts == nil and {} or opts
	-- 		ufo.setup(opts)
	--
	-- 		-- 3. 等待 LSP Attach 完成后再解开折叠（解决 LSP 异步覆盖问题）
	-- 		vim.api.nvim_create_autocmd("LspAttach", {
	-- 			callback = function(args)
	-- 				local bufnr = args.buf
	-- 				vim.schedule(function()
	-- 					if vim.api.nvim_buf_is_valid(bufnr) then
	-- 						vim.wo.foldlevel = 99
	-- 						ufo.openAllFolds()
	-- 					end
	-- 				end)
	-- 			end,
	-- 		})
	--
	-- 		return opts
	-- 	end,
	-- },
	{
		"kylechui/nvim-surround",
		version = "^4.0.0", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		-- Optional: See `:h nvim-surround.configuration` and `:h nvim-surround.setup` for details
		-- config = function()
		--     require("nvim-surround").setup({
		--         -- Put your configuration here
		--     })
		-- end
	},
	-- 自动配对括号、引号
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},

	-- 注释快捷键
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- 显示 Git 信息
	{
		"f-person/git-blame.nvim",
		config = function()
			vim.keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { desc = "Toggle Git Blame" })
		end,
	},

	-- Git 操作界面
	{
		"NeogitOrg/neogit",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("neogit").setup()
			vim.keymap.set("n", "<leader>gg", ":Neogit<CR>", { desc = "Open Neogit" })
		end,
	},

	{
		"ray-x/lsp_signature.nvim",
		event = "LspAttach",
		opts = {},
	},
	{
		"mg979/vim-visual-multi",
		branch = "master",
		event = "VeryLazy",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-n>", -- 选中光标下的词，再按选中下一个
				["Find Subword Under"] = "<C-n>",
				["Add Cursor Down"] = "<C-Down>", -- 向下加光标
				["Add Cursor Up"] = "<C-Up>", -- 向上加光标
				["Select All"] = "<C-S-n>", -- 选中所有匹配
				["Visual Add"] = "<C-Down>", -- 可视模式下向下加光标
			}
		end,
	},
	{
		"SunnyTamang/select-undo.nvim",
		opts = {},
	},
	{
		"terryma/vim-expand-region",
		event = "VeryLazy", -- 延迟加载，不影响启动速度

		keys = {
			{ "-", "<Plug>(expand_region_shrink)", mode = { "n", "x" }, desc = "缩小选区" },
			{ "=", "<Plug>(expand_region_expand)", mode = { "n", "x" }, desc = "扩大选区" },
		},
		init = function()
			vim.g.expand_region_use_default_mappings = 0
			vim.g.expand_region_text_objects = {
				["iw"] = 0,
				["iW"] = 0,
				['i"'] = 0,
				["i'"] = 0,
				["i]"] = 1,
				["ib"] = 1,
				["iB"] = 1,
				["ii"] = 0, -- 缩进块内部
				["ai"] = 0, -- 缩进块周围
				["il"] = 0,
				["ip"] = 0,
			} -- 这里可以设置 g:expand_region_text_objects 等全局变量
			-- 具体配置见下方“自定义扩展层级”
		end,
	},
}
