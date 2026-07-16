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

    -- ----- file paths inside terminal output (git status etc.) -----
    -- In terminal-normal mode the path under the cursor is underlined and
    -- <CR> opens it in the editor ("path:12" also jumps to the line).
    local path_ns = vim.api.nvim_create_namespace("toggleterm_path")

    local function term_cwd()
      local pid = vim.b.terminal_job_pid
      return (pid and vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")) or vim.fn.getcwd()
    end

    local function path_under_cursor()
      local cfile = vim.fn.expand("<cfile>")
      if cfile == "" then
        return
      end
      local name = cfile:gsub("^[ab]/", "") -- strip git-diff prefixes
      for _, base in ipairs({ term_cwd(), vim.fn.getcwd() }) do
        local p = name:sub(1, 1) == "/" and name or (base .. "/" .. name)
        if vim.fn.filereadable(p) == 1 then
          return p, cfile
        end
      end
    end

    local function highlight_path()
      vim.api.nvim_buf_clear_namespace(0, path_ns, 0, -1)
      local path, cfile = path_under_cursor()
      if not path then
        return
      end
      -- underline the token the cursor is on
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()
      local init = 1
      while true do
        local s, e = line:find(cfile, init, true)
        if not s then
          return
        end
        if col + 1 >= s and col + 1 <= e then
          vim.api.nvim_buf_set_extmark(0, path_ns, row - 1, s - 1, { end_col = e, hl_group = "Underlined" })
          return
        end
        init = e + 1
      end
    end

    local function open_path()
      local path, cfile = path_under_cursor()
      if not path then
        return
      end
      local lnum = vim.api.nvim_get_current_line():match(vim.pesc(cfile) .. ":(%d+)")
      local ewin = require("config.windows").editor_win()
      if ewin then
        vim.api.nvim_set_current_win(ewin)
      end
      vim.cmd("edit " .. vim.fn.fnameescape(path))
      if lnum then
        pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(lnum), 0 })
      end
    end

    -- Terminal-buffer-local maps. Kept to a minimum so the shell keeps its
    -- own readline keys (e.g. Ctrl-L clear screen).
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = function(ev)
        -- keep terminals out of the buffer tabline / :bnext cycle
        vim.bo[ev.buf].buflisted = false
        local o = { buffer = ev.buf, silent = true }
        -- Esc ALWAYS enters terminal-normal mode (scroll / select text),
        -- even while a program is running. To send a real Esc to the
        -- program (fzf cancel, claude interrupt, ...): Ctrl+\ then Esc.
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], o)
        vim.keymap.set("t", "<C-\\><Esc>", "<Esc>", o)
        -- Jump up to the editor window; terminal stays visible
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], o)
        -- Open the file path under the cursor (terminal-normal mode)
        vim.keymap.set("n", "<CR>", open_path, { buffer = ev.buf, desc = "Open file path under cursor" })
        vim.api.nvim_create_autocmd("CursorMoved", {
          buffer = ev.buf,
          desc = "Underline openable file paths",
          callback = highlight_path,
        })
      end,
    })
  end,
}
