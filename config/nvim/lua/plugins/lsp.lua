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
			local mason_registry = require("mason-registry")
			-- 确保 vue-language-server 已经安装，否则 get_install_path 会报错
			if not mason_registry.is_installed("vue-language-server") then
				return opts
			end

			local vue_lsp_path = mason_registry.get_package("vue-language-server"):get_install_path()
			local vue_typescript_plugin_path = vue_lsp_path .. "/node_modules/@vue/language-server"

			return {
				servers = {
					lua_ls = {
						settings = {
							Lua = {
								diagnostics = { globals = { "vim" } },
								workspace = { checkThirdParty = false },
								telemetry = { enable = false },
							},
						},
					},
					pyright = {},
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
}
