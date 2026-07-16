return {
  "MagicDuck/grug-far.nvim",
  opts = {},
  keys = {
    -- VS Code-like project search & replace panel
    {
      "<leader>sr",
      function()
        require("grug-far").open()
      end,
      desc = "Search / replace (project)",
    },
    -- Open pre-filled with the word under the cursor
    {
      "<leader>sw",
      function()
        require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
      end,
      desc = "Search word under cursor (grug-far)",
    },
    -- Open scoped to the current file only
    {
      "<leader>sf",
      function()
        require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
      end,
      desc = "Search / replace in current file",
    },
  },
}
