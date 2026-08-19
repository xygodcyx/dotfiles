-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.mouse = ""
vim.g.root_spec = { "cwd" }
vim.opt.scrolloff = 1
vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "help",
  "tabpages",
  "winsize",
  "winpos",
  "terminal",
  "localoptions",
}
-- 启用 Tree-sitter 折叠
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- 让 Neovim 在打开文件时尝试加载所有折叠（'99' 代表全部打开）
vim.opt.foldlevelstart = 99
-- 如果想在启动时完全禁用折叠，可以设置 'nofoldenable'，手动用 'zx' 来刷新[citation:7][citation:9]
-- vim.opt.foldenable = false

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
