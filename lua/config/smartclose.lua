-- Smart :q / :wq / :x so that closing a file never lets the terminal or
-- the tree take over the editor area.
--
--   other file tabs exist -> close just the tab, show the neighbour (VS Code)
--   last file tab         -> quit nvim entirely (tree/terminal included)
--   editor is split       -> plain :q (another editor window remains)
--   terminal / tree / etc -> plain :q
local windows = require("config.windows")

local function smart_close(write, bang)
	local buf = vim.api.nvim_get_current_buf()
	local suffix = bang and "!" or ""

	-- special windows (terminal, tree, help, ...): behave like plain :q
	if vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype == "NvimTree" then
		return vim.cmd("quit" .. suffix)
	end

	if write then
		vim.cmd("update") -- write only when modified
	end

	if #windows.editor_wins() > 1 then
		return vim.cmd("quit" .. suffix) -- another editor window remains
	end

	if #windows.listed_file_bufs() > 1 then
		-- other tabs exist: close only this tab, keep the editor window
		windows.switch_away(buf)
		vim.cmd("bdelete" .. suffix .. " " .. buf)
	else
		-- last file tab: take everything down cleanly
		vim.cmd("quitall" .. suffix)
	end
end

vim.api.nvim_create_user_command("SmartQuit", function(o)
	smart_close(false, o.bang)
end, { bang = true })
vim.api.nvim_create_user_command("SmartWq", function(o)
	smart_close(true, o.bang)
end, { bang = true })

-- Re-route the exact typed commands :q / :wq / :x (bang variants included —
-- the '!' lands after the expansion). :qa / :wqa stay untouched.
local function reroute(lhs, rhs)
	vim.cmd(
		("cnoreabbrev <expr> %s (getcmdtype() == ':' && getcmdline() ==# '%s') ? '%s' : '%s'"):format(lhs, lhs, rhs, lhs)
	)
end
reroute("q", "SmartQuit")
reroute("wq", "SmartWq")
reroute("x", "SmartWq")

-- Safety net for other quit paths (ZZ, :quit from a script, ...): when the
-- LAST editor window is about to quit, close the tree/terminal windows too
-- so nvim exits instead of leaving a full-screen terminal behind.
vim.api.nvim_create_autocmd("QuitPre", {
	desc = "Close aux windows when the last editor window quits",
	nested = true,
	callback = function()
		if vim.bo.buftype ~= "" or vim.bo.filetype == "NvimTree" then
			return
		end
		if #windows.editor_wins() > 1 then
			return
		end
		for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
			if ft == "NvimTree" or ft == "toggleterm" then
				pcall(vim.api.nvim_win_close, w, true)
			end
		end
	end,
})
