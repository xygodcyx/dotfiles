local g = vim.g
local opt = vim.opt

vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
g.mapleader = " "

opt.undofile = false -- 开启文件持久化撤销（保存退出后依然能 u 撤销）
opt.undodir = vim.fn.stdpath("data") .. "/undo" -- 撤销历史文件保存目录
opt.undolevels = 10000 -- 最大可撤销步数（默认 1000，调大到 10000）
opt.undoreload = 10000 -- 文件被外部修改重载时保留的最大撤销行数

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.encoding = "utf-8"
opt.title = true
vim.api.nvim_create_autocmd("User", {
	pattern = "*",
	callback = function()
		vim.opt.signcolumn = "yes" -- 完全关闭 sign 列
		-- vim.opt_local.signcolumn = "yes:2"
	end,
})

opt.hidden = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.autowrite = true
vim.o.autoread = true
vim.bo.autoread = true
vim.o.whichwrap = "<,>,[,]"
-- vim.opt.guicursor = "n-v-c:block-blinkwait0-blinkon0-blinkoff0"

opt.ignorecase = true
opt.smartcase = true
opt.smartindent = true
opt.hlsearch = false
opt.cursorline = true
opt.scrolloff = 999
opt.wrap = true

opt.softtabstop = 2
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.colorcolumn = "80"
opt.clipboard = "unnamedplus"

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldcolumn = "1"

vim.diagnostic.config({
	virtual_text = {
		spacing = 4, -- 与代码的间隔
	},
	underline = true,
	update_in_insert = true, -- 在插入模式时不频繁刷新报错，避免卡顿
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "",
		},
	},
})

vim.filetype.add({
	extension = {
		gdshader = "cpp",
		tcss = "css", -- .tcss 文件类型识别为 css
	},
})
