return {
	"stevearc/conform.nvim",
	opts = {
		format_on_save = {
			-- These options will be passed to conform.format()
			timeout_ms = 500,
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			json = { "eslint", "prettierd", stop_after_first = true },
			jsonc = { "eslint", "prettierd", stop_after_first = true },
			typescript = { "eslint", "prettierd", stop_after_first = true },
			javascript = { "eslint", "prettierd", stop_after_first = true },
			html = { "prettierd" },
			lua = { "stylua" },
			python = { "ruff_fix", "ruff_format" },
			rust = { "rustfmt", lsp_format = "fallback" },
			cpp = { "clang_format" },
			c = { "clang_format" },
			gdscript = { "gdscript-formatter" },
		},
		formatters = {
			clang_format = {
				prepend_args = { "--style=file" },
			},
		},
		default_format_opts = {
			lsp_format = "never",
		},
	},
}
