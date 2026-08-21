return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- 获取 Mason 安装的 vue-language-server 的真实动态路径
      local mason_registry = require("mason-registry")
      -- 确保 vue-language-server 已经安装，否则 get_install_path 会报错
      if not mason_registry.is_installed("vue-language-server") then
        return opts
      end

      local vue_lsp_path = mason_registry.get_package("vue-language-server"):get_install_path()
      local vue_typescript_plugin_path = vue_lsp_path .. "/node_modules/@vue/language-server"

      opts.inlay_hints = { enabled = true }

      -- 修改 opts.servers 配置
      opts.servers = opts.servers or {}

      -- 1. 启用 ts_ls (TypeScript 语言服务器)
      opts.servers.ts_ls = {
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
      }
      opts.servers.tailwindcss = {}

      -- 2. 启用 Vue 语言服务器 (volar)
      opts.servers.volar = {}

      -- 3. 其他你需要的服务器 (例如 Python)
      opts.servers.pyright = {}

      opts.servers.rust_analyzer = {
        checkOnSave = {
          command = "clippy",
        },
        inlayHints = {
          -- 禁用可能导致问题的 inlay hints
          bindingModeHints = { enable = true },
          chainingHints = { enable = true },
          closingBraceHints = { enable = true },
          parameterHints = { enable = true },
          typeHints = { enable = true },
        },
      }
      return opts
    end,
  },
}
