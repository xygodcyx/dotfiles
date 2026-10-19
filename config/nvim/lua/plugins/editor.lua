-- lua/plugins/editor.lua
return {
	{

		"nvimdev/lspsaga.nvim",

		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- optional
			"nvim-tree/nvim-web-devicons", -- optional
		},

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
				-- -- 诊断配置
				-- diagnostic = {
				-- 	on_insert = false,
				-- 	show_source = true,
				-- 	jump_float = true,
				-- },
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
				-- -- 面包屑
				-- breadcrumbs = {
				-- 	enable = true,
				-- 	icon = ">",
				-- 	separator = "▸",
				-- },
				-- 大纲
				outline = {
					keys = {
						jump = "<CR>",
						quit = "q",
					},
					auto_close = true,
					close_after_jump = true,
					layout = "float",
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
			vim.keymap.set("n", "K", function()
				vim.cmd("Lspsaga hover_doc")
				-- 延迟等浮动窗口创建完，再聚焦
				vim.defer_fn(function()
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.bo[buf].filetype
						local cfg = vim.api.nvim_win_get_config(win)
						-- 只找浮动窗口 + markdown filetype
						if cfg.relative ~= "" and ft == "markdown" then
							vim.api.nvim_set_current_win(win)
							return
						end
					end
				end, 30)
			end, { desc = "Hover Documentation (聚焦窗口)" })
			-- 预览定义
			vim.keymap.set("n", "gD", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek Definition" })

			vim.keymap.set("n", "gd", function()
				vim.lsp.buf.definition()
			end, { desc = "Peek Definition" })

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
			"hrsh7th/nvim-cmp",
			"nvim-treesitter/nvim-treesitter",
			"L3MON4D3/LuaSnip",
		},

		opt = true, -- Set this to true if the plugin is optional
		event = "InsertEnter", -- Set the event to 'InsertCharPre' for better compatibility
		priority = 1,
		config = function()
			require("tabout").setup({
				tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
				backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
				act_as_tab = true, -- shift content if tab out is not possible
				act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
				default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
				default_shift_tab = "<C-d>", -- reverse shift default action,
				enable_backwards = false, -- well ...
				completion = false, -- if the tabkey is used in a completion pum
				tabouts = {
					{ open = "'", close = "'" },
					{ open = '"', close = '"' },
					{ open = "`", close = "`" },
					{ open = "(", close = ")" },
					{ open = "[", close = "]" },
					{ open = "{", close = "}" },
					{ open = "<", close = ">" },
				},
				ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
			})
		end,
	},

	{
		"L3MON4D3/LuaSnip",
		keys = function()
			-- Disable default tab keybinding in LuaSnip
			return {}
		end,
	},
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
	-- {
	-- 	"f-person/git-blame.nvim",
	-- 	config = function()
	-- 		vim.keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { desc = "Toggle Git Blame" })
	-- 	end,
	-- },

	-- Git 操作界面
	-- {
	-- 	"NeogitOrg/neogit",
	-- 	dependencies = { "nvim-lua/plenary.nvim" },
	-- 	config = function()
	-- 		require("neogit").setup()
	-- 		vim.keymap.set("n", "<leader>gg", ":Neogit<CR>", { desc = "Open Neogit" })
	-- 	end,
	-- },

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
			vim.g.expand_region_use_default_mappings = 1
			-- vim.g.expand_region_text_objects = {
			-- 	["iw"] = 0,
			-- 	["iW"] = 0,
			-- 	['i"'] = 1,
			-- 	["i'"] = 1,
			-- 	["i]"] = 1,
			-- 	["i<"] = 1,
			-- 	["ib"] = 1,
			-- 	["iB"] = 1,
			-- 	["ii"] = 1, -- 缩进块内部
			-- 	["ai"] = 1, -- 缩进块周围
			-- 	["il"] = 1,
			-- 	["ip"] = 1,
			-- } -- 这里可以设置 g:expand_region_text_objects 等全局变量
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		opts = {
			filetypes = {
				"html",
				"javascript",
				"typescript",
				"javascriptreact",
				"typescriptreact",
				"vue",
				"svelte",
				"xml",
			},
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		},
	},
	{
		"nvim-lua/plenary.nvim",
	},
	{
		"antosha417/nvim-lsp-file-operations",
		cmd = "LFO",
		-- Uncomment whichever supported plugin(s) you use
		dependencies = {
			-- "nvim-tree/nvim-tree.lua",
			-- "nvim-neo-tree/neo-tree.nvim",
			"simonmclean/triptych.nvim",
		},
		config = function()
			require("lsp-file-operations").setup()
		end,
	},
	{
		"simonmclean/triptych.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- optional for icons
			"antosha417/nvim-lsp-file-operations", -- optional LSP integration
		},
		opts = {}, -- config options here
		keys = {
			{ "<leader>e", ":Triptych<CR>" },
		},
	},
	-- {
	-- 	"chaoren/vim-wordmotion",
	-- 	event = "VeryLazy",
	-- 	init = function()
	-- 		-- vim.g.wordmotion_prefix = "<leader>" -- 可选：给 wordmotion 加前缀键
	-- 		-- 不加前缀直接覆盖 w/e/b 也可以：
	-- 		-- vim.g.wordmotion_nomap = 0
	-- 	end,
	-- },

	-- {
	-- 	"folke/flash.nvim",
	-- 	event = "VeryLazy",
	-- 	opts = {
	-- 		modes = {
	-- 			char = {
	-- 				jump_labels = true,
	-- 			},
	-- 		},
	-- 	},
	-- 	keys = {
	-- 		{
	-- 			"s",
	-- 			mode = { "n", "x", "o" },
	--
	-- 			function()
	-- 				require("flash").jump({
	-- 					search = { mode = "search" },
	-- 				})
	-- 			end,
	-- 			desc = "Flash",
	-- 		},
	-- 	},
	-- },
	-- {
	-- "nvim-focus/focus.nvim",
	-- enable = false,
	-- config = function()
	-- 	require("focus").setup({
	-- 		autoresize = {
	-- 			enable = true,
	-- 			width = 0,
	-- 			height = 0,
	-- 			minwidth = 0,
	-- 			minheight = 0,
	-- 			focusedwindow_minwidth = 0,
	-- 			focusedwindow_minheight = 0,
	-- 			height_quickfix = 10,
	-- 			equalise_min_cols = 0,
	-- 			equalise_min_rows = 0,
	-- 		},
	-- 		commands = true,
	-- 		enable = true,
	-- 		split = { bufnew = false, tmux = false },
	-- 		ui = {
	-- 			absolutenumber_unfocussed = false,
	-- 			colorcolumn = { enable = false, list = "+1" },
	-- 			cursorcolumn = false,
	-- 			cursorline = true,
	-- 			hybridnumber = false,
	-- 			number = false,
	-- 			relativenumber = false,
	-- 			signcolumn = false,
	-- 			winhighlight = false,
	-- 		},
	-- 	})
	-- 	local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })
	--
	-- 	local function should_disable_focus()
	-- 		local name = vim.api.nvim_buf_get_name(0)
	-- 		local buftype = vim.bo.buftype
	--
	-- 		-- dap-ui 左侧面板：DAP Watches / Stacks / Breakpoints / Scopes
	-- 		if name:match("/DAP ") then
	-- 			return true
	-- 		end
	-- 		-- dap-terminal / dap-repl
	-- 		if name:match("%[dap%-terminal%]") then
	-- 			return true
	-- 		end
	-- 		if name:match("%[dap%-repl") then
	-- 			return true
	-- 		end
	--
	-- 		-- 兜底：nofile / prompt / terminal 类型的浮动/工具窗口
	-- 		if vim.tbl_contains({ "nofile", "prompt", "terminal", "popup" }, buftype) then
	-- 			return true
	-- 		end
	--
	-- 		return false
	-- 	end
	--
	-- 	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
	-- 		group = augroup,
	-- 		callback = function()
	-- 			if should_disable_focus() then
	-- 				vim.w.focus_disable = true
	-- 				vim.b.focus_disable = true
	-- 			end
	-- 		end,
	-- 		desc = "Disable focus autoresize for dap-ui and utility windows",
	-- 	})
	-- end,
}
