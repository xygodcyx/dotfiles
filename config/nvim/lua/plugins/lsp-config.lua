local vtsls = require("lazyvim.plugins.extras.lang.typescript.vtsls")
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- 全局启用 inlay hints
      inlay_hints = { enabled = true },
      servers = {
        vtsls = {},
      },
    },
  },
}
