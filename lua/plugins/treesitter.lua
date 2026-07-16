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

    -- Pre-warm treesitter for common languages in the background: start a
    -- highlighter once on a scratch buffer, which pays every one-time cost
    -- (parser load, query compilation ~30-120ms per language) at startup
    -- instead of on the first preview/open.
    vim.defer_fn(function()
      for _, lang in ipairs({ "typescript", "tsx", "javascript", "python", "lua", "json", "yaml", "markdown" }) do
        pcall(function()
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "x" })
          vim.treesitter.start(buf, lang)
          vim.api.nvim_buf_delete(buf, { force = true })
        end)
      end
    end, 1500)
  end,
}
