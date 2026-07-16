-- nvim-treesitter `main` branch (the supported one for Neovim 0.12; the old
-- `master` branch is frozen and its parsers clash with 0.12's bundled ones).
-- Neovim itself bundles parsers for lua / vim / vimdoc / markdown /
-- markdown_inline / c / query, so we only install the extras we use.
local ensure = {
  "rust",
  "python",
  "typescript",
  "tsx",
  "javascript",
  "json",
  "yaml",
  "toml",
  "bash",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(ensure)

    -- Turn on treesitter highlight + indent for any buffer with a parser
    vim.api.nvim_create_autocmd("FileType", {
      desc = "Enable treesitter highlight/indent",
      callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
