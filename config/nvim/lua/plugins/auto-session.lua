return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      auto_restore = true,
      auto_save = true,
      purge_after_minutes = 1440,
      auto_session_use_git_branch = true,

      suppressed_dirs = {
        "~/",
        "~/Downloads",
        "~/Documents",
      },
    },
  },
}
