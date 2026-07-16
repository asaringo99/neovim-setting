return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- Statusline is a permanent UI element — load at startup
  lazy = false,
  opts = {
    options = {
      -- One statusline for the whole screen instead of one per window;
      -- much cleaner with the tree / terminal splits
      globalstatus = true,
      theme = "onedark",
    },
    sections = {
      -- relative path + "which hunk am I on / total hunks" (± 2/5)
      lualine_c = {
        { "filename", path = 1 },
        function()
          return require("config.hunkinfo").status(0)
        end,
      },
    },
  },
}
