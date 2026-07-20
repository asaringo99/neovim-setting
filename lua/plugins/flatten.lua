-- No nested editors inside the toggleterm: `git commit` / `git rebase -i`
-- (and any plain `nvim file` typed in the terminal) open their file as a
-- buffer of THIS Neovim instance instead of nano / a nested nvim that can't
-- be driven with normal vim habits.
--
-- Flow: GIT_EDITOR=nvim makes git start nvim; flatten detects it's running
-- inside our :terminal (via $NVIM), forwards the file to this instance and
-- blocks git until the buffer is closed here (:wq — smartclose.lua keeps the
-- layout intact and hands focus back to the terminal via block_end below).
return {
	"willothy/flatten.nvim",
	lazy = false,
	priority = 1001, -- must initialize before anything else (guest side)
	config = function()
		vim.env.GIT_EDITOR = "nvim"
		require("flatten").setup({
			-- default block_for = { gitcommit, gitrebase }: git waits until
			-- the handed-over buffer is closed (QuitPre / BufDelete).
			window = {
				-- always show the file in the editor window, never in the
				-- tree / terminal strip (mirrors config/windows.lua roles)
				open = function(ctx)
					local focus = ctx.stdin_buf or ctx.files[1]
					local win = require("config.windows").editor_win()
					if win then
						vim.api.nvim_win_set_buf(win, focus.bufnr)
						vim.api.nvim_set_current_win(win)
					else
						win = vim.api.nvim_open_win(focus.bufnr, true, { vertical = false, win = 0 })
					end
					return focus.bufnr, win
				end,
			},
			hooks = {
				-- done editing -> git resumes in the terminal; follow it
				block_end = function()
					vim.schedule(function()
						local twin = require("config.windows").win_with_ft("toggleterm")
						if twin then
							vim.api.nvim_set_current_win(twin)
							vim.cmd("startinsert")
						end
					end)
				end,
			},
		})
	end,
}
