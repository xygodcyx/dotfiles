-- 在 init.lua 或 plugins 配置文件中添加
local api = vim.api
local orig_set_extmark = api.nvim_buf_set_extmark

api.nvim_buf_set_extmark = function(bufnr, ns_id, lnum, col, opts)
  -- 更健壮的检查
  if type(bufnr) ~= "number" or type(lnum) ~= "number" then
    return
  end

  -- 检查缓冲区是否有效
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- 获取行数
  local line_count = api.nvim_buf_line_count(bufnr)
  if lnum >= line_count or lnum < 0 then
    return
  end

  -- 检查列是否越界
  local lines = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
  if #lines == 0 then
    return
  end

  local line = lines[1]
  if col and (type(col) ~= "number" or col > #line) then
    -- 如果越界，修正列位置到行尾
    col = #line
  end

  -- 处理 opts 中的 end_col
  if opts and opts.end_col and type(opts.end_col) == "number" then
    local end_col = opts.end_col
    if end_col > #line then
      opts.end_col = #line
    end
    if end_col < (col or 0) then
      opts.end_col = (col or 0)
    end
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
