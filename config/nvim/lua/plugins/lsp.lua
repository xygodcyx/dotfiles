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

	-- {
	-- 	"mrcjkb/rustaceanvim",
	-- 	version = "^9",
	-- 	ft = { "rust" },
	-- 	lazy = false,
	-- 	config = function()
	-- 		local capabilities = require("cmp_nvim_lsp").default_capabilities()
	-- 		vim.g.rustaceanvim = {
	-- 			server = {
	-- 				capabilities = capabilities,
	-- 				default_settings = {
	-- 					["rust-analyzer"] = {
	-- 						cargo = { allFeatures = true },
	-- 						buildScripts = { enable = true },
	-- 						checkOnSave = true,
	-- 					},
	-- 				},
	-- 			},
	-- 		}
	-- 	end,
	-- },

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"williamboman/mason.nvim",
		},
		init = function()
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})
		end,

		opts = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- local capabilities = require("blink.cmp").get_lsp_capabilities()
			local mason_registry = require("mason-registry")
			-- 确保 vue-language-server 已经安装，否则 get_install_path 会报错

			local vue_lsp_path = mason_registry.get_package("vue-language-server"):get_install_path()
			local vue_typescript_plugin_path = vue_lsp_path .. "/node_modules/@vue/language-server"
			local customizations = {
				{ rule = "style/*", severity = "off", fixable = true },
				{ rule = "format/*", severity = "off", fixable = true },
				{ rule = "*-indent", severity = "off", fixable = true },
				{ rule = "*-spacing", severity = "off", fixable = true },
				{ rule = "*-spaces", severity = "off", fixable = true },
				{ rule = "*-order", severity = "off", fixable = true },
				{ rule = "*-dangle", severity = "off", fixable = true },
				{ rule = "*-newline", severity = "off", fixable = true },
				{ rule = "*quotes", severity = "off", fixable = true },
				{ rule = "*semi", severity = "off", fixable = true },
			}
			return {
				servers = {
					qmlls = {},
					dartls = {
						cmd = { "dart", "language-server", "--protocol=lsp" },
						filetypes = { "dart" },
						init_options = {
							closingLabels = true,
							flutterOutline = true,
						},
						settings = {
							dart = {
								completeFunctionCalls = true,
								showTodos = true,
							},
						},
					},
					nmocmake = {},
					bashls = {
						filetypes = {
							"sh",
							"bash",
						},
					},
					rust_analyzer = {
						settings = {
							["rust-analyzer"] = {
								imports = {
									granularity = {
										group = "module",
									},
									prefix = "self",
								},
								cargo = {
									buildScripts = {
										enable = true,
									},
								},
								procMacro = {
									enable = true,
								},
							},
						},
					},
					clangd = {
						capabilities = vim.tbl_deep_extend("force", capabilities, {
							textDocument = {
								completion = {
									completionItem = {
										snippetSupport = false, -- 关掉 snippet，clangd 就不会发内置模板了
									},
								},
							},
						}),
						cmd = {
							"clangd",
							"--background-index",
							"--clang-tidy",
							-- "--header-insertion=iwyu",
							"--header-insertion=never",
							"--completion-style=bundled",
							"--fallback-style=google",
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
									autoImportCompletions = true,
									typeCheckingMode = "basic", -- 可选: "off", "basic", "strict"
									diagnosticMode = "workspace",
									autoSearchPaths = true,
									useLibraryCodeForTypes = true,
								},
							},
						},
					},
					harperls = {},
					vtsls = {
						on_attach = function(client, bufnr)
							-- Disable formatting so it doesn't conflict with ESLint / Prettier
							client.server_capabilities.documentFormattingProvider = false
							client.server_capabilities.documentRangeFormattingProvider = false
						end,
						init_options = {

							plugins = {
								{
									name = "@vue/typescript-plugin",
									location = vue_typescript_plugin_path,
									languages = { "vue" },
								},
							},
							settings = {
								typescript = {

									diagnostics = {
										unusedLocals = false,
										unusedParameters = false,
									},
									inlayHints = {},
								},
								javascript = {
									diagnostics = {
										unusedLocals = false,
										unusedParameters = false,
									},
								},
							},
						},
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
	-- ,
	{
		"Mathijs-Bakker/godotdev.nvim",
		dependencies = { "nvim-dap", "nvim-dap-ui", "nvim-treesitter" },
		config = function(_, _)
			require("godotdev").setup({
				filetypes = {
					"gdscript",
					-- "cpp",
					-- "gdshader",
				},
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
						enabled = true, -- capture :GodotRun* output in Neovim; these runs are no longer detached
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
	{
		"esmuellert/nvim-eslint",
		config = function()
			require("nvim-eslint").setup({
				-- Toggle debug mode for ESLint language server, see debugging part
				debug = false,

				-- Command to launch language server. You might hardly want to change this setting
				-- cmd = M.create_cmd(),

				-- root_dir is used by Neovim LSP client API to determine if to attach or launch new LSP
				-- The default configuration uses the git root folder as the root_dir
				-- For monorepo it can have many projects, so launching too many LSP for one workspace is not efficient
				-- You can override it with passing function(bufnr)
				-- It should receive active buffer number and return root_dir
				-- root_dir = M.resolve_git_dir(args.buf),

				-- A table used to determine what filetypes trigger the start of LSP
				filetypes = {
					"json",
					"jsonc",
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
					"vue",
					"svelte",
					"astro",
				},

				-- The client capabilities for LSP Protocol. See Nvim LSP docs for details
				-- It uses the default Nvim LSP client capabilities. Adding the capability to dynamically change configs
				-- capabilities = M.make_client_capabilities(),

				handlers = {
					-- The handlers handles language server responses. See Nvim LSP docs for details
					-- The default handlers only has a rewrite of default "workspace/configuration" handler of Nvim LSP
					-- Basically, when you load a new buffer, ESLint LSP requests the settings with this request
					-- To make it work with monorepo, the workingDirectory setting needs to be calculated at runtime
					-- This is the main reaason for rewriting, and it also works if you have a simple structure repo
					-- You might add more custom handler with reference to LSP protocol spec and vscode-eslint code
				},

				-- The settings send to ESLint LSP. See below part for details.
				settings = {
					useESLintClass = false,
					experimental = { useFlatConfig = false },
					codeAction = {
						disableRuleComment = {
							enable = true,
							location = "separateLine",
						},
						showDocumentation = {
							enable = true,
						},
					},
					codeActionOnSave = { mode = "all" },
					format = true,
					quiet = true,
					onIgnoredFiles = "true",
					options = {},
					rulesCustomizations = {},
					run = "onType",
					problems = { shortenToSingleLine = true },
					-- nodePath = function(bufnr)
					-- 	return M.resolve_node_path()
					-- end,
					workingDirectory = { mode = "location" },
					-- nodePath = "node_modules/.bin/eslint",
					-- workspaceFolder = function(bufnr)
					-- 	local git_dir = M.resolve_git_dir(bufnr)
					-- 	return {
					-- 		uri = vim.uri_from_fname(git_dir),
					-- 		name = vim.fn.fnamemodify(git_dir, ":t"),
					-- 	}
					-- end,
				},
			})
		end,
	},
}
