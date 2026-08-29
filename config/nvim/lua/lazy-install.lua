-- 安装 lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- 使用稳定版本
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 加载插件
require("lazy").setup({ { import = "plugins" } }, {
  checker = {
    enabled = true,
    frequency = 600,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
