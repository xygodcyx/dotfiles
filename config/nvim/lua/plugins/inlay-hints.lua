-- 在 init.lua 或 plugins 配置文件中添加
local api = vim.api
local orig_set_extmark = api.nvim_buf_set_extmark

api.nvim_buf_set_extmark = function(bufnr, ns_id, lnum, col, opts)
  -- 检查列是否越界
  local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
  if line and col and col > #line then
    -- 如果越界，则忽略此次调用
    return
  end
  return orig_set_extmark(bufnr, ns_id, lnum, col, opts)
end

return {
  "MysticalDevil/inlay-hints.nvim",
  event = "LspAttach",
  dependencies = { "neovim/nvim-lspconfig" }, -- optional
  config = function()
    require("inlay-hints").setup()
  end,
}
