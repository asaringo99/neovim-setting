-- Window discipline guard: on every relevant event, scan ALL windows and
-- fix every violation found:
--   * a FILE buffer sitting in the terminal strip -> moved to an editor
--     window, terminal buffer restored in the strip
--   * a TERMINAL buffer sitting in an editor window -> pushed back to a
--     file buffer
-- Because it sweeps every window (not just the current one), it also
-- catches plugins that swap buffers in non-focused windows or bypass
-- autocmds: the next event self-heals the layout.
local windows = require("config.windows")

local guarding = false

local function sweep()
	if guarding then
		return
	end
	guarding = true
	local cur = vim.api.nvim_get_current_win()

	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(w) and not windows.is_float(w) then
			local b = vim.api.nvim_win_get_buf(w)
			local bt, ft = vim.bo[b].buftype, vim.bo[b].filetype

			if windows.is_term_win(w) and bt == "" and ft ~= "NvimTree" then
				-- a file is sitting in the terminal strip
				local ewin = windows.editor_win(w)
				local tbuf = windows.term_buf()
				if ewin then
					if tbuf then
						vim.api.nvim_win_set_buf(w, tbuf)
					else
						pcall(vim.api.nvim_win_close, w, true)
					end
					vim.api.nvim_win_set_buf(ewin, b)
					if cur == w then
						-- the user was "in" that file: follow it to the editor
						vim.cmd("stopinsert")
						vim.api.nvim_set_current_win(ewin)
					end
				else
					vim.w[w].toggleterm_window = nil -- no editor window: adopt this one
				end
			elseif not windows.is_term_win(w) and ft == "toggleterm" then
				-- a terminal buffer is sitting in an editor window
				local fbuf = windows.file_buf(b)
				if fbuf then
					vim.api.nvim_win_set_buf(w, fbuf)
				else
					vim.api.nvim_win_call(w, function()
						vim.cmd("enew")
					end)
				end
			end
		end
	end

	-- geometry: the terminal strip must stay a full-width bottom row
	require("config.layout").reassert_strip()

	guarding = false
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "TermEnter", "TermLeave", "FocusGained" }, {
	desc = "Keep files in editor windows and terminals in the terminal strip",
	callback = function()
		-- run after whatever command triggered the event has fully finished
		vim.schedule(sweep)
	end,
})
