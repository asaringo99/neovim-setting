return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- Gutter marks: │ added / │ changed / _ deleted
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    -- GitLens-style inline blame on the current line
    -- (author, date • commit summary as dim virtual text)
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 400,
      virt_text_pos = "eol",
    },
    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      -- Jump between changed hunks (falls back to diff-mode ]c/[c)
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next git hunk")
      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev git hunk")

      -- Inspect / act on the hunk under the cursor
      map("n", "<leader>hp", gs.preview_hunk, "Preview hunk (popup diff)")
      map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gs.reset_hunk, "Reset hunk (discard change)")
      map("n", "<leader>hb", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle inline blame")
      map("n", "<leader>hd", gs.diffthis, "Diff current file")
    end,
  },
}
