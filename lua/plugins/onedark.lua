return {
  "navarasu/onedark.nvim",
  -- theme must load before every other UI plugin
  lazy = false,
  priority = 1000,
  config = function()
    local onedark = require("onedark")
    onedark.setup({
      style = "dark", -- matches VS Code "One Dark Pro"
    })
    onedark.load()
  end,
}
