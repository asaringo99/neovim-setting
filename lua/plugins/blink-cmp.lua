return {
  "saghen/blink.cmp",
  -- Use a release tag so lazy.nvim downloads the prebuilt fuzzy-matcher binary
  -- (building from source would require a Rust *nightly* toolchain).
  version = "1.*",
  event = "InsertEnter",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      -- VS Code style: Enter / Tab accept the highlighted item.
      -- <C-n>/<C-p> move, <C-e> closes the menu (then Enter = plain newline),
      -- <C-space> shows docs.
      preset = "enter",
      ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
    },
    appearance = {
      -- We installed a Mono Nerd Font, so icons line up correctly
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = true },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
