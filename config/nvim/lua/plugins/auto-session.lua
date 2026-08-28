return {
  {
    "rmagatti/auto-session",
    lazy = false,
    priority = 1000,
    -- 让插件在 LazyVim 初始化时立即加载
    init = function()
      vim.g.auto_session_enabled = true
    end,
    opts = {
      auto_restore = true,
      auto_save = true,
      auto_restore_last_session = true,
      auto_session_suppress_dirs = {
        "~/",
        "~/Downloads",
        "~/Documents",
      },
      -- 使用 git 分支作为 session 名
      auto_session_use_git_branch = true,
      -- 保存延迟
      save_delay = 500,
    },
    config = function(_, opts)
      require("auto-session").setup(opts)

      -- 额外的确保
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.g.auto_session_enabled = true
        end,
      })
    end,
  },
}
