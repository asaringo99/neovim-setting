-- Smart <C-j> (VS Code Ctrl+J feel):
--   no terminal visible -> open it and enter insert mode
--   focus in the editor -> jump into the terminal (insert mode)
--   focus in terminal   -> hide it
-- Prefix a count for extra terminals: 2<C-j>, 3<C-j> ... (<leader>ts to pick)

local function enter_insert()
  vim.schedule(function()
    vim.cmd("startinsert")
  end)
end

-- After a terminal opens (always a full-width bottom strip), re-assert the
-- tree when the layout mode wants it full height instead.
local function after_term_open()
  local layout = require("config.layout")
  if layout.tree_full_height then
    layout.reassert_tree(vim.api.nvim_get_current_win())
  end
  enter_insert()
end

local function smart_toggle_term()
  if vim.v.count > 0 then
    vim.cmd(vim.v.count .. "ToggleTerm direction=horizontal")
    after_term_open()
    return
  end

  local term_win = require("config.windows").win_with_ft("toggleterm")
  if not term_win then
    vim.cmd("ToggleTerm") -- open
    after_term_open()
  elseif vim.api.nvim_get_current_win() == term_win then
    vim.cmd("ToggleTerm") -- hide
  else
    vim.api.nvim_set_current_win(term_win) -- jump back in
    enter_insert()
  end
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-j>", smart_toggle_term, mode = { "n", "t" }, desc = "Toggle / focus terminal" },
    { "<leader>ts", "<cmd>TermSelect<cr>", desc = "Select / switch terminal" },
  },
  opts = {
    direction = "horizontal",
    size = 15,
    start_in_insert = true,
    terminal_mappings = true,
    -- Mark every window toggleterm opens as a "terminal window" so the
    -- window guard (config/winguard.lua) can police what shows where.
    on_open = function(term)
      if term.window and vim.api.nvim_win_is_valid(term.window) then
        vim.w[term.window].toggleterm_window = true
      end
    end,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- Terminal-buffer-local maps. Kept to a minimum so the shell keeps its
    -- own readline keys (e.g. Ctrl-L clear screen).
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = function()
        -- keep terminals out of the buffer tabline / :bnext cycle
        vim.bo.buflisted = false
        local o = { buffer = 0, silent = true }
        -- Esc ALWAYS enters terminal-normal mode (scroll / select text),
        -- even while a program is running. To send a real Esc to the
        -- program (fzf cancel, claude interrupt, ...): Ctrl+\ then Esc.
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], o)
        vim.keymap.set("t", "<C-\\><Esc>", "<Esc>", o)
        -- Jump up to the editor window; terminal stays visible
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], o)
      end,
    })
  end,
}
