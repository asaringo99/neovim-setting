return {
  "RRethy/vim-illuminate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("illuminate").configure({
      -- prefer semantic matches (LSP), fall back to treesitter / plain text
      providers = { "lsp", "treesitter", "regex" },
      delay = 120,
      filetypes_denylist = { "NvimTree", "toggleterm", "TelescopePrompt" },
    })
  end,
}
