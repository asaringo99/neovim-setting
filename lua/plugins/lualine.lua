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
      -- relative path instead of bare filename (useful in the monorepo)
      lualine_c = { { "filename", path = 1 } },
    },
  },
}
