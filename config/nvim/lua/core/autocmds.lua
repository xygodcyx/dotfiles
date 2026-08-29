vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})

local commands = {
	W = "w",
	Q = "q",
	Wq = "wq",
	WQ = "wq",
	Wa = "wa",
	WA = "wa",
	Wqa = "wqa",
	WQA = "wqa",
	Qall = "qall",
	QALL = "qall",
}

for upper, lower in pairs(commands) do
	vim.api.nvim_create_user_command(upper, function(opts)
		local cmd = lower
		vim.cmd(cmd)
	end, {
		bang = true,
		nargs = "*",
		complete = "file",
		desc = "Auto lowercase command alias",
	})
end

-- 方法 A：只要 LSP 服务器支持，自动为缓冲区开启 inlay_hint
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- 直接全局/按缓冲区开启，内部会自动判断 LSP 能力
		vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
	end,
})

vim.api.nvim_create_user_command("MasonSearch", function()
	local ok, telescope = pcall(require, "telescope.pickers")
	if not ok then
		vim.notify("未安装 Telescope", vim.log.levels.ERROR)
		return
	end

	local registry = require("mason-registry")
	registry.refresh(function()
		local packages = registry.get_all_packages()
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		telescope
			.new({}, {
				prompt_title = "Search Mason Packages",
				finder = finders.new_table({
					results = packages,
					entry_maker = function(pkg)
						return {
							value = pkg,
							display = pkg.name .. " (" .. table.concat(pkg.spec.languages or {}, ", ") .. ")",
							ordinal = pkg.name .. " " .. table.concat(pkg.spec.languages or {}, " "),
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						vim.cmd("MasonInstall " .. selection.value.name)
					end)
					return true
				end,
			})
			:find()
	end)
end, {})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		vim.schedule(function()
			vim.cmd("normal! zx") -- zx 用于刷新并应用当前文件的折叠
		end)
	end,
})
