-- ~/.config/nvim/lua/plugins/bufferline.lua
return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        -- 在当前 buffer 关闭后，选择哪个 buffer
        -- "left" 表示选择左边的 buffer
        -- "right" 表示选择右边的 buffer
        -- "closest" 表示选择最近的
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "|",
          style = "icon",
        },
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 18,
        max_prefix_length = 15,
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        -- 当打开新文件时，将 buffer 移到最左边
        enforce_regular_tabs = true,
        always_show_bufferline = true,
        -- 排序方式：默认是 "insert_after_end"
        -- 或者使用自定义排序
        sort_by = function(buffer_a, buffer_b)
          return buffer_a.id > buffer_b.id
        end,
      },
    },
  },
}
