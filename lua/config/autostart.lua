-- Open the file tree and the terminal automatically when nvim starts.
vim.api.nvim_create_autocmd("VimEnter", {
	desc = "Open tree + terminal on startup",
	-- nested: without this, the TermOpen event fired by ToggleTerm below
	-- would be suppressed and the terminal would get NO buffer-local
	-- keymaps (Esc, Ctrl+K, ...)
	nested = true,
	callback = function()
		-- Skip headless runs (scripts / tests) …
		if #vim.api.nvim_list_uis() == 0 then
			return
		end
		-- … and commit/rebase message editing (nvim spawned by git)
		local ft = vim.bo.filetype
		if ft == "gitcommit" or ft == "gitrebase" or vim.fn.bufname():match("COMMIT_EDITMSG") then
			return
		end

		local editor_win = vim.api.nvim_get_current_win()
		local layout = require("config.layout")
		require("toggleterm") -- lazy-loaded; make :ToggleTerm available

		-- Whichever should own the bottom-left corner must open LAST
		-- (see lua/config/layout.lua for the two layouts)
		if layout.tree_full_height then
			vim.cmd("ToggleTerm")
			vim.cmd("NvimTreeOpen")
		else
			vim.cmd("NvimTreeOpen")
			vim.cmd("ToggleTerm")
		end

		local function back_to_editor()
			vim.cmd("stopinsert")
			if vim.api.nvim_win_is_valid(editor_win) then
				vim.api.nvim_set_current_win(editor_win)
			end
		end
		back_to_editor()
		vim.schedule(back_to_editor) -- the terminal may enter insert mode late
	end,
})
