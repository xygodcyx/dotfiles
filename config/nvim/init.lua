require("core")
pcall(vim.keymap.del, { "i", "s" }, "<Tab>")
pcall(vim.keymap.del, { "i", "s" }, "<S-Tab>")
require("lazy-install")
