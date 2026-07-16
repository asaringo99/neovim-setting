return {
  -- Mason: LSP server installer (:Mason to manage)
  {
    "mason-org/mason.nvim",
    opts = {},
  },

  -- Bridge between mason and lspconfig (auto-installs & auto-enables servers)
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- Servers to auto-install. Add more names here (see :Mason for the list).
      ensure_installed = {
        "lua_ls",         -- Lua
        "rust_analyzer",  -- Rust
        "pyright",        -- Python
        "vtsls",          -- TypeScript / JavaScript (bundles its own tsserver)
        "postgres_lsp",   -- PostgreSQL (needs postgres-language-server.jsonc in project root)
      },
      -- Automatically run vim.lsp.enable() for installed servers (default: true)
      automatic_enable = true,
    },
  },

  -- LSP capabilities + keymaps
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      -- Advertise blink.cmp's completion capabilities to every LSP server
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Show errors inline while editing (virtual text is off by default
      -- since Neovim 0.11, and diagnostics normally wait for InsertLeave)
      vim.diagnostic.config({
        virtual_text = true,
        update_in_insert = true,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "󰌵",
          },
        },
      })

      -- Remove Neovim's built-in gr-prefix maps (grn/grr/gra/gri/grt) so our
      -- single-key `gr` (references) fires instantly instead of waiting on
      -- the ambiguous-prefix timeout. Their features stay reachable via the
      -- maps below (<leader>rn, <leader>ca, gi, gr).
      for _, lhs in ipairs({ "grn", "grr", "gri", "grt" }) do
        pcall(vim.keymap.del, "n", lhs)
      end
      pcall(vim.keymap.del, { "n", "x" }, "gra")

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP keymaps",
        callback = function(ev)
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          -- Capital F: <leader>f would clash with the <leader>f* telescope
          -- prefix and stall on the ambiguity timeout.
          map("<leader>F", function()
            vim.lsp.buf.format({ async = true })
          end, "Format buffer")
          -- [d / ]d (prev/next diagnostic) are Neovim defaults — no remap needed.
        end,
      })
    end,
  },
}
