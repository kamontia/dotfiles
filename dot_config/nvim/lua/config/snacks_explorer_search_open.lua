local M = {}

local explorer_actions = require("snacks.explorer.actions")
local picker_actions = require("snacks.picker.actions")

function M.direct_open(picker, item, action)
  item = item or picker:selected({ fallback = true })[1]
  if not item then
    return
  end

  local searching = picker.input.filter.meta.searching
  if searching and not item.dir then
    return picker_actions.jump(picker, item, action)
  end

  return explorer_actions.actions.confirm(picker, item, action)
end

function M.explorer_opts()
  return {
    actions = {
      explorer_direct_open = M.direct_open,
    },
    win = {
      input = {
        keys = {
          ["<C-o>"] = { "explorer_direct_open", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-o>"] = "explorer_direct_open",
        },
      },
    },
  }
end

return M
