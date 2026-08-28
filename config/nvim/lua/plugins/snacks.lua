return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      -- 配置查找文件时的选项
      find = {
        hidden = true, -- 显示隐藏文件
        ignored = true, -- 显示被忽略的文件
      },
      -- 或者使用 explore 配置
      explore = {
        hidden = true,
        ignored = true,
      },
    },
    grep = { enabled = true, hidden = true, ignored = true },
    files = { enabled = true, hidden = true, ignored = true },
    notifier = {
      enabled = true,
      -- 忽略 inlayHint 错误
      filter = function(notification)
        if notification.msg and notification.msg:find("inlayHint") then
          return false -- 不显示这些通知
        end
        return true
      end,
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
}
