-- Scoped grep: live_grep with an adjustable scope. INSIDE the picker:
--   <C-o> -> pick the directory to search in (fuzzy: type "backend" etc.)
--   <C-e> -> set ignored extensions / globs (e.g. "js, json" or "*.test.ts")
-- Both persist for the session, are shown in the picker title, and the
-- half-typed query survives the adjustment.
local grep_scope = { dir = nil, exclude = {} }

local scoped_grep -- forward declaration (pick_scope_dir reopens it)

-- Fuzzy directory chooser: lists project directories, "backend" finds
-- "apps/backend". Selecting "." resets to the whole project.
local function pick_scope_dir(query)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers
    .new({}, {
      prompt_title = "検索ディレクトリ (スペース区切りでAND絞り込み: backend src / . = 全体)",
      finder = finders.new_oneshot_job({
        "find", ".", "-maxdepth", "8",
        "(", "-name", "node_modules", "-o", "-name", ".git", "-o", "-name", "cdk.out", ")",
        "-prune", "-o", "-type", "d", "-print",
      }, {}),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          local dir = (entry and entry[1] or "."):gsub("^%./", "")
          grep_scope.dir = (dir ~= "" and dir ~= ".") and dir or nil
          vim.schedule(function()
            scoped_grep(query)
          end)
        end)
        return true
      end,
    })
    :find()
end

function scoped_grep(default_text)
  local title = "Live Grep"
  if grep_scope.dir then
    title = title .. "  " .. grep_scope.dir
  end
  if #grep_scope.exclude > 0 then
    title = title .. "  !" .. table.concat(grep_scope.exclude, ",")
  end
  require("telescope.builtin").live_grep({
    prompt_title = title .. "  (C-o:dir C-e:除外)",
    search_dirs = grep_scope.dir and { grep_scope.dir } or nil,
    additional_args = function()
      local args = {}
      for _, g in ipairs(grep_scope.exclude) do
        args[#args + 1] = "--glob=!" .. g
      end
      return args
    end,
    default_text = default_text,
    attach_mappings = function(bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local function adjust(key, input_opts, apply)
        map({ "i", "n" }, key, function()
          local query = action_state.get_current_line()
          actions.close(bufnr)
          vim.ui.input(input_opts, function(v)
            if v ~= nil then
              apply(v)
            end
            vim.schedule(function()
              scoped_grep(query)
            end)
          end)
        end)
      end
      map({ "i", "n" }, "<C-o>", function()
        local query = action_state.get_current_line()
        actions.close(bufnr)
        vim.schedule(function()
          pick_scope_dir(query)
        end)
      end)
      adjust("<C-e>", {
        prompt = "無視する拡張子/グロブ (例: js, json / 空=解除): ",
        default = table.concat(grep_scope.exclude, ", "),
      }, function(v)
        grep_scope.exclude = {}
        for token in v:gmatch("[^,%s]+") do
          -- bare extension -> *.ext, anything with * or / is used as-is
          grep_scope.exclude[#grep_scope.exclude + 1] = token:find("[*/]") and token or ("*." .. token)
        end
      end)
      return true
    end,
  })
end

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
    { "<leader>fg", scoped_grep, desc = "Live grep (C-o: dir / C-e: exclude)" },
    {
      -- Same fg UI, but you can type rg args inline: `foo -g!*.js apps/backend`
      "<leader>fh",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Live grep with args (globs / paths inline)",
    },
    { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>w", pick_window, desc = "Pick window (tree/editor/terminal)" },
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
