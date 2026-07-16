-- Window picker: list every open window (tree / editor / terminal ...),
-- cycle with <C-n>/<C-p> (or arrows) and jump to it with <Enter>.
local function pick_window()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local items = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local name = vim.api.nvim_buf_get_name(buf)
    local label
    if ft == "NvimTree" then
      label = "[Tree] ファイルツリー"
    elseif ft == "toggleterm" then
      local n = name:match("#toggleterm#(%d+)") or "?"
      label = "[Term] ターミナル " .. n
    elseif name ~= "" then
      label = "[Edit] " .. vim.fn.fnamemodify(name, ":~:.")
    else
      label = "[Edit] (無題)"
    end
    table.insert(items, { win = win, label = label })
  end

  pickers
    .new({}, {
      prompt_title = "Windows (C-n/C-p で移動, Enter で選択)",
      finder = finders.new_table({
        results = items,
        entry_maker = function(e)
          return { value = e, display = e.label, ordinal = e.label }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          if entry and vim.api.nvim_win_is_valid(entry.value.win) then
            vim.api.nvim_set_current_win(entry.value.win)
            if vim.bo[vim.api.nvim_win_get_buf(entry.value.win)].buftype == "terminal" then
              vim.cmd("startinsert")
            end
          end
        end)
        return true
      end,
    })
    :find()
end

return {
  "nvim-telescope/telescope.nvim",
  -- master branch: the 0.1.x branch is frozen and calls the removed
  -- nvim-treesitter (master) API `ft_to_lang` from its previewer.
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    -- Lets you type ripgrep args (globs, paths) directly in the fg-style prompt
    "nvim-telescope/telescope-live-grep-args.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files (VS Code style)" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep (whole project)" },
    {
      -- Same fg UI, but you can type rg args inline: `foo -g!*.js apps/backend`
      "<leader>fh",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Live grep with args (globs / paths inline)",
    },
    { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<C-s>", pick_window, desc = "Pick window (tree/editor/terminal)" },
    {
      "<C-s>",
      function()
        vim.cmd("stopinsert")
        vim.schedule(pick_window)
      end,
      mode = "t",
      desc = "Pick window (from terminal)",
    },
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Changed files (git status)" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
    { "<leader>fH", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        -- Always open the picked file in a real editor window, never in
        -- the terminal / file-tree window the picker was launched from.
        get_selection_window = function()
          return require("config.windows").editor_win() or 0
        end,
      },
    })
    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "live_grep_args")
  end,
}
