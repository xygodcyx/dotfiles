return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform will run multiple formatters sequentially
			python = { "ruff_fix", "ruff_format" },
			-- You can customize some of the format options for the filetype (:help conform.format)
			rust = { "rustfmt", lsp_format = "fallback" },
			-- Conform will run the first available formatter
			javascript = { "prettierd", "prettier", stop_after_first = true },
			cpp = { "clang_format" },
			c = { "clang_format" },
		},
		formatters = {
			clang_format = {
				-- 关键：告诉 conform 去项目目录找 .clang-format 文件
				prepend_args = { "--style=file" },
			},
		},
		default_format_opts = {
			lsp_format = "never", -- 只使用 conform 的格式化器
		},
	},
}
