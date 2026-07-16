return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- group labels for the popup that appears after pressing <Space>
    spec = {
      { "<leader>f", group = "find / search" },
      { "<leader>s", group = "search & replace" },
      { "<leader>b", group = "buffer tabs" },
      { "<leader>h", group = "git hunk" },
      { "<leader>g", group = "git" },
      { "<leader>t", group = "terminal / layout" },
    },
  },
}
