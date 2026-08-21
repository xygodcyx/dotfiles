return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "eslint_d", "prettier" },
      javascriptreact = { "eslint_d", "prettier" },
      typescript = { "eslint_d", "prettier" },
      typescriptreact = { "eslint_d", "prettier" },
      vue = { "eslint_d", "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },
      sh = { "shfmt" },
    },
    formatters = {
      eslint_d = {
        -- ✅ 修复 cwd 函数
        cwd = function(ctx)
          -- 安全处理 ctx
          if not ctx or not ctx.filename then
            return vim.fn.getcwd()
          end
          local root = vim.fs.root(ctx.filename, {
            "package.json",
            "eslint.config.js",
            ".eslintrc.js",
            ".eslintrc.json",
            "pnpm-workspace.yaml",
          })
          return root or vim.fn.getcwd()
        end,
        prepend_args = { "--fix" },
        condition = function(ctx)
          if not ctx or not ctx.filename then
            return false
          end
          return vim.fs.find({ "eslint.config.js", ".eslintrc.js", ".eslintrc.json" }, {
            path = ctx.filename,
            upward = true,
          })[1] ~= nil
        end,
      },
      prettier = {
        cwd = function(ctx)
          if not ctx or not ctx.filename then
            return vim.fn.getcwd()
          end
          local root = vim.fs.root(ctx.filename, {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            "package.json",
          })
          return root or vim.fn.getcwd()
        end,
        condition = function(ctx)
          if not ctx or not ctx.filename then
            return false
          end
          return vim.fs.find({ ".prettierrc", ".prettierrc.json", ".prettierrc.js" }, {
            path = ctx.filename,
            upward = true,
          })[1] ~= nil
        end,
      },
    },
  },
}
