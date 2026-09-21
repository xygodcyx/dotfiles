return {
	-- 1. 自动安装 LSP 服务器
	{
		"williamboman/mason.nvim",
		dependencies = {},
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"vtsls",
				"vue-language-server",
				"lua-language-server",
				"pyright",
			})
			return opts
		end,
	},

	-- 2. Rust 专用增强插件
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		ft = { "rust" },
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.g.rustaceanvim = {
				server = {
					capabilities = capabilities,
					default_settings = {
						["rust-analyzer"] = {
							cargo = { allFeatures = true },
							buildScripts = { enable = true },
							checkOnSave = true,
						},
					},
				},
			}
		end,
	},

	-- 3. nvim-lspconfig 配置
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"williamboman/mason.nvim",
		},
		opts = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local mason_registry = require("mason-registry")
			-- 确保 vue-language-server 已经安装，否则 get_install_path 会报错

			local vue_lsp_path = mason_registry.get_package("vue-language-server"):get_install_path()
			local vue_typescript_plugin_path = vue_lsp_path .. "/node_modules/@vue/language-server"

			return {
				servers = {
                    bashIde = {},
					clangd = {
						capabilities = capabilities, -- 关键！把 cmp 的能力声明传给 clangd
						cmd = {
							"clangd",
							"--background-index",
							"--clang-tidy",
							"--header-insertion=iwyu",
							"--completion-style=detailed",
							"--function-arg-placeholders",
							"--fallback-style=llvm",
						},
						init_options = {
							fallbackFlags = { "-std=c++17" },
						},
					},
					cssls = {
						filetypes = { "css", "scss", "less" }, -- ⭐ 添加 tcss
						validate = false,
					},
					lua_ls = {
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT", -- 如果你用 Neovim/OpenResty，用 LuaJIT；纯 Lua 改成 "Lua 5.4"
								},
								diagnostics = {
									globals = { "vim" }, -- Neovim 配置必备，避免把 vim 当成未定义全局变量
									enable = true, -- 打开所有诊断
									unusedLocalExclude = { "_*" }, -- 排除下划线开头的未使用变量
								},
								workspace = {
									checkThirdParty = false,
									library = {
										os.getenv("HOME") .. "/.local/share/LuaAddons",
										vim.env.VIMRUNTIME,
									},
								},
								telemetry = { enable = false },
							},
						},
					},
					pyright = {
						settings = {
							python = {
								analysis = {
									-- ⭐ 关键：开启自动导入补全
									autoImportCompletions = true,
									-- ⭐ 开启类型检查（提供更多 code action）
									typeCheckingMode = "basic", -- 可选: "off", "basic", "strict"
									-- ⭐ 使用 Pylance 的完整功能
									diagnosticMode = "workspace",
									-- ⭐ 自动搜索路径
									autoSearchPaths = true,
									-- ⭐ 使用库类型信息
									useLibraryCodeForTypes = true,
								},
							},
						},
					},
					ts_ls = {
						init_options = {
							plugins = {
								{
									-- 核心：将 Vue 的 TypeScript 插件挂载到 ts_ls 上
									name = "@vue/typescript-plugin",
									location = vue_typescript_plugin_path,
									languages = { "vue" },
								},
							},
							settings = {
								typescript = {
									inlayHints = {},
								},
							},
						},
						-- 让 ts_ls 同时也处理 .vue 文件
						filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
					},
					vue_ls = {
						filetypes = { "vue" }, -- 混合模式下 Volar 只监听 vue
						init_options = {
							vue = { hybridMode = true },
							typescript = {
								-- Path to typescript/lib inside your global mason installation or local project
								tsdk = vim.fn.expand(
									"$HOME/.local/share/nvim/mason/packages/vue-language-server/node_modules/typescript/lib"
								),
							},
						},
					},
				},
				setup = {
					["*"] = function(server, opts)
						if vim.lsp.config then
							vim.lsp.config(server, opts)
							vim.lsp.enable(server)
							return true
						end
					end,
				},
			}
		end,
		config = function(_, opts)
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			for server, config in pairs(opts.servers) do
				config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})

				local has_setup = opts.setup and (opts.setup[server] or opts.setup["*"])
				if not has_setup or not has_setup(server, config) then
					lspconfig[server].setup(config)
				end
			end
		end,
	},
	-- {
	-- 	"lommix/godot.nvim",
	-- 	lazy = false,
	-- 	cmd = { "GodotDebug", "GodotBreakAtCursor", "GodotStep", "GodotQuit", "GodotContinue" },
	-- 	config = {
	-- 		-- Path to your Godot executable
	-- 		bin = "godot",
	--
	-- 		-- DAP configuration
	-- 		dap = {
	-- 			host = "127.0.0.1",
	-- 			port = 6006,
	-- 		},
	--
	-- 		-- GUI settings for console (passed to nvim_open_win)
	-- 		gui = {
	-- 			console_config = {
	-- 				anchor = "SW",
	-- 				border = "double",
	-- 				col = 1,
	-- 				height = 10,
	-- 				relative = "editor",
	-- 				row = 99999,
	-- 				style = "minimal",
	-- 				width = 99999,
	-- 			},
	-- 		},
	--
	-- 		-- Expose user commands automatically (optional)
	-- 		expose_commands = true,
	-- 	},
	-- },
	{
		"Mathijs-Bakker/godotdev.nvim",
		dependencies = { "nvim-dap", "nvim-dap-ui", "nvim-treesitter" },
		config = function(_, _)
			require("godotdev").setup({
				editor_host = "127.0.0.1", -- Godot editor host
				editor_port = 6005, -- Godot LSP port
				debug_port = 6006, -- Godot debugger port
				godot_path = "godot", -- executable used by :GodotRun* and health checks
				csharp = true, -- Enable C# Installation Support
				autostart_editor_server = false, -- opt-in: start a Neovim server automatically on setup
				formatter = "gdscript-formatter", -- "gdscript-formatter" | "gdformat" | false
				formatter_cmd = nil, -- string or argv list; default gdscript-formatter adds "--reorder-code"
				inline_hints = {
					enabled = false, -- enable Neovim inlay hints when the attached server supports them
				},
				run = {
					console = {
						enabled = false, -- capture :GodotRun* output in Neovim; these runs are no longer detached
						renderer = "buffer", -- "buffer" | "float"
						buffer = {
							position = "bottom", -- "right" | "bottom" | "current"
							size = 0.3,
						},
						float = {
							width = 0.8,
							height = 0.25,
							border = "rounded",
						},
					},
				},
				scene_tree = {
					buffer = {
						position = "left", -- "left" | "right"
						size = 0.35,
					},
					icons = "nerdfont", -- "nerdfont" | "ascii" | false | { generic = "...", script_suffix = "...", types = { Node2D = "..." } }
					icon_colors = {
						generic = { fg = "white" },
						groups = {
							White = { fg = "white" },
							Grey = { fg = "grey" },
							Blue = { fg = "blue" },
							Red = { fg = "red" },
							Green = { fg = "green" },
							Purple = { fg = "magenta" },
							Yellow = { fg = "gold" },
						},
					},
				},
				editor_server = {
					address = nil, -- nil uses the current server or the platform default
					remove_stale_socket = true,
				},
				treesitter = {
					auto_setup = true, -- convenience default; disable if you manage nvim-treesitter yourself
					ensure_installed = { "gdscript" },
				},
				docs = {
					renderer = "float", -- default: open docs in a floating window
					fallback_renderer = "browser", -- nil | "browser" | "buffer"; browser is the only fetch-recovery fallback
					missing_symbol_feedback = "message", -- "message" | "notify"
					version = "stable", -- e.g. "stable", "latest", "4.5"
					language = "en",
					source_ref = "master", -- godot-docs git ref used for floating docs
					source_base_url = nil, -- optional override for raw docs source
					timeout_ms = 10000,
					cache = {
						enabled = true,
						max_entries = 64,
					},
					float = {
						width = 0.8,
						height = 0.8,
						border = "rounded",
					},
					buffer = {
						position = "right", -- "right" | "bottom" | "current"
						size = 0.4,
					},
				},
			})
		end,
	},
	{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
}
