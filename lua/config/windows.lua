-- Shared window / buffer helpers for the tree | editor | terminal layout.
-- Every module that needs to reason about "which window is what" uses these,
-- so the definition of editor / terminal / tree lives in exactly one place.
local M = {}

---@param win integer
function M.is_float(win)
	return vim.api.nvim_win_get_config(win).relative ~= ""
end

---A window opened by toggleterm (marked in plugins/toggleterm.lua on_open).
---@param win integer
function M.is_term_win(win)
	return vim.w[win].toggleterm_window == true
end

---An ordinary editing window: not floating, not the tree, not the terminal.
---@param win integer
function M.is_editor_win(win)
	if M.is_float(win) or M.is_term_win(win) then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "NvimTree"
end

---First window in this tab whose buffer has the given filetype.
---@param ft string
function M.win_with_ft(ft)
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft then
			return w
		end
	end
end

---First editor window (optionally skipping one window).
---@param except integer|nil
function M.editor_win(except)
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if w ~= except and M.is_editor_win(w) then
			return w
		end
	end
end

---All editor windows in this tab.
function M.editor_wins()
	return vim.tbl_filter(M.is_editor_win, vim.api.nvim_tabpage_list_wins(0))
end

---Any loaded toggleterm buffer (visible or hidden).
function M.term_buf()
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "toggleterm" then
			return b
		end
	end
end

---All listed normal-file buffers (the "tabs").
function M.listed_file_bufs()
	return vim.tbl_filter(function(b)
		return vim.bo[b].buflisted and vim.bo[b].buftype == ""
	end, vim.api.nvim_list_bufs())
end

---A listed file buffer to display instead of `except` (alternate buffer
---first, then any other tab).
---@param except integer|nil
function M.file_buf(except)
	local alt = vim.fn.bufnr("#")
	if
		alt > 0
		and alt ~= except
		and vim.api.nvim_buf_is_valid(alt)
		and vim.bo[alt].buflisted
		and vim.bo[alt].buftype == ""
	then
		return alt
	end
	for _, b in ipairs(M.listed_file_bufs()) do
		if b ~= except then
			return b
		end
	end
end

---In the CURRENT window, move off `from_buf` to a neighbouring tab
---(bufferline order), falling back to an empty buffer. Used before :bdelete
---so the window never falls back to the terminal / tree buffer.
---@param from_buf integer
function M.switch_away(from_buf)
	local ok = pcall(vim.cmd, "BufferLineCyclePrev")
	if not ok or vim.api.nvim_get_current_buf() == from_buf then
		vim.cmd("enew")
	end
end

return M
