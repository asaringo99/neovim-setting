-- Core editor options. Loaded before plugins (init.lua requires this first).

-- Disable netrw at the very start (required by nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- UI
vim.opt.termguicolors = true -- 24-bit colour
vim.opt.number = true -- line numbers
vim.opt.cursorline = true -- highlight the current line
vim.opt.signcolumn = "yes" -- gutter always visible (no layout jumping)
vim.opt.scrolloff = 8 -- keep context lines above/below the cursor

-- Editing
vim.opt.undofile = true -- persistent undo across restarts
vim.opt.confirm = true -- ask instead of erroring on :q with changes

-- Search
vim.opt.ignorecase = true -- case-insensitive search ...
vim.opt.smartcase = true -- ... unless the query has capitals

-- Windows
vim.opt.splitright = true -- vsplit opens to the right
vim.opt.splitbelow = true -- split opens below

-- Snappier CursorHold / gitsigns / illuminate
vim.opt.updatetime = 300

-- Reopen a file at the last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
	desc = "Restore last cursor position",
	callback = function(ev)
		if vim.bo[ev.buf].filetype:match("^git") then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
