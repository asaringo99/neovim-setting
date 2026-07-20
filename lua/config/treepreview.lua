-- Lightweight file preview for the nvim-tree sidebar.
--
-- Follow: moving with j/k in the tree shows the file under the cursor in the
-- editor window (focus stays in the tree) WITHOUT fully opening it: autocmds
-- are suppressed so no LSP / gitsigns machinery starts (~125ms per file
-- otherwise) and syntax colours are attached by hand — treesitter when a
-- parser exists (~ms), Vim's regex syntax otherwise (xml, html, ...).
--
-- Promote: when such a buffer is later REALLY entered (Enter in the tree,
-- picked from telescope, ...), the skipped setup runs once: the buffer gets
-- listed (bufferline tab) and filetype detection fires treesitter / LSP /
-- gitsigns as usual. The two halves are tied by the b:preview_plain flag.
local M = {}

---Attach syntax colours to a previewed buffer without firing FileType.
---@param buf integer
local function attach_colours(buf)
	local ft = vim.filetype.match({ buf = buf })
	local lang = ft and vim.treesitter.language.get_lang(ft)
	local hl = lang and pcall(vim.treesitter.start, buf, lang)
	if not hl and ft and ft ~= "" then
		-- No treesitter parser for this filetype: fall back to Vim's built-in
		-- regex syntax highlighting. Setting 'syntax' fires only the Syntax
		-- event (loads syntax/<ft>.vim), NOT FileType, so the preview stays
		-- lightweight.
		vim.bo[buf].syntax = ft
	end
end

local function preview_under_cursor()
	if vim.bo.filetype ~= "NvimTree" then
		return
	end
	local ok, node = pcall(require("nvim-tree.api").tree.get_node_under_cursor)
	if not ok or not node or node.type ~= "file" then
		return
	end
	local st = vim.uv.fs_stat(node.absolute_path)
	if not st or st.size > 1024 * 1024 then
		return -- skip huge files
	end
	local ewin = require("config.windows").editor_win()
	if not ewin then
		return
	end
	local buf = vim.fn.bufadd(node.absolute_path)
	if vim.api.nvim_win_get_buf(ewin) == buf then
		return -- already showing this file
	end
	local ei = vim.o.eventignore
	vim.o.eventignore = "all"
	local shown = pcall(function()
		vim.fn.bufload(buf)
		vim.api.nvim_win_set_buf(ewin, buf)
	end)
	vim.o.eventignore = ei
	if shown then
		attach_colours(buf)
		if vim.bo[buf].filetype == "" then
			vim.b[buf].preview_plain = true -- promote on real open
		end
	end
end

function M.setup()
	local timer = vim.uv.new_timer()
	vim.api.nvim_create_autocmd("CursorMoved", {
		desc = "nvim-tree preview follow",
		callback = function()
			if vim.bo.filetype ~= "NvimTree" then
				return
			end
			timer:stop()
			timer:start(120, 0, vim.schedule_wrap(preview_under_cursor))
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		desc = "Promote plain preview buffers to fully-loaded files",
		nested = true,
		callback = function(ev)
			if vim.b[ev.buf].preview_plain then
				vim.b[ev.buf].preview_plain = nil
				-- preview buffers are unlisted; a really-opened file must
				-- show up as a tab (bufferline) and in the S-h/S-l cycle
				vim.bo[ev.buf].buflisted = true
				vim.api.nvim_buf_call(ev.buf, function()
					vim.cmd("filetype detect")
					vim.cmd("doautocmd BufReadPost")
				end)
			end
		end,
	})
end

return M
