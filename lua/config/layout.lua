-- Window-layout policy shared by the file tree (nvim-tree) and the
-- terminal strip (toggleterm).
--
--   tree_full_height = false (default)      tree_full_height = true
--   ┌────────┬──────────────┐               ┌────────┬──────────────┐
--   │ tree   │   editor     │               │ tree   │   editor     │
--   ├────────┴──────────────┤               │        ├──────────────┤
--   │ terminal (full width) │               │        │ terminal     │
--   └───────────────────────┘               └────────┴──────────────┘
--
-- Whichever should own the bottom-left corner must be (re)opened LAST.
local windows = require("config.windows")

local M = {}

M.tree_full_height = false

local function focus(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
	end
end

---Re-open the tree so it spans the full height, then restore focus.
---Used in tree_full_height mode after a terminal opened as a full strip.
function M.reassert_tree(keep_focus_win)
	if not windows.win_with_ft("NvimTree") then
		return
	end
	vim.cmd("NvimTreeClose")
	vim.cmd("NvimTreeOpen")
	focus(keep_focus_win)
end

---Open the tree while keeping the terminal a full-width bottom strip:
---hide the terminals, open the tree, then bring the terminals back.
local function open_tree_above_terms(open_cmd)
	if not windows.win_with_ft("toggleterm") then
		vim.cmd(open_cmd)
		return
	end
	vim.cmd("ToggleTermToggleAll")
	vim.cmd(open_cmd)
	local cur = vim.api.nvim_get_current_win()
	vim.cmd("ToggleTermToggleAll")
	local function restore()
		vim.cmd("stopinsert")
		focus(cur)
	end
	restore()
	vim.schedule(restore) -- in case the terminal enters insert mode late
end

---Open the tree according to the active layout mode.
function M.open_tree(open_cmd)
	if M.tree_full_height then
		vim.cmd(open_cmd) -- plain open -> tree spans full height
	else
		open_tree_above_terms(open_cmd)
	end
end

---Detect and repair a broken arrangement (terminal-priority mode only):
---with exactly one terminal strip visible it must be full-width at the very
---bottom. Whatever corrupted it (window moves, closes, plugins), re-placing
---the strip restores the canonical layout. Returns true when it repaired.
function M.reassert_strip()
	if M.tree_full_height then
		return false -- tree-priority mode has no strip invariant
	end
	local term_wins = {}
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "toggleterm" then
			table.insert(term_wins, w)
		end
	end
	if #term_wins ~= 1 then
		return false -- side-by-side terminals (2<C-j>) are legitimate
	end
	local tw = term_wins[1]
	local full_width = vim.api.nvim_win_get_width(tw) == vim.o.columns
	local bottom = true
	local trow = vim.api.nvim_win_get_position(tw)[1]
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if w ~= tw and vim.api.nvim_win_get_config(w).relative == "" then
			local r = vim.api.nvim_win_get_position(w)[1]
			if r > trow then
				bottom = false -- something sits BELOW the strip
			end
		end
	end
	if full_width and bottom then
		return false -- all good
	end
	local cur = vim.api.nvim_get_current_win()
	vim.cmd("ToggleTermToggleAll")
	vim.cmd("ToggleTermToggleAll")
	vim.cmd("stopinsert")
	-- the strip may have inherited a broken height; reset to the default
	local healed = windows.win_with_ft("toggleterm")
	if healed then
		vim.api.nvim_win_set_height(healed, 15)
	end
	focus(cur)
	return true
end

---Flip the layout priority; re-apply immediately when both are visible.
function M.switch()
	M.tree_full_height = not M.tree_full_height
	local tree = windows.win_with_ft("NvimTree")
	local term = windows.win_with_ft("toggleterm")
	if tree and term then
		local cur = vim.api.nvim_get_current_win()
		if M.tree_full_height then
			vim.cmd("NvimTreeClose")
			vim.cmd("NvimTreeOpen")
			focus(cur)
		else
			vim.cmd("ToggleTermToggleAll")
			vim.cmd("ToggleTermToggleAll")
			vim.cmd("stopinsert")
			focus(cur)
		end
	end
	vim.notify("Layout: " .. (M.tree_full_height and "フォルダ優先(全高)" or "ターミナル優先(全幅)"))
end

return M
