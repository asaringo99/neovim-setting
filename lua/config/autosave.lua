-- Auto-save (VS Code style): write the file whenever editing pauses.
-- `update` only writes when the buffer is actually modified.
-- Toggle at runtime with :AutoSaveToggle.

vim.g.autosave_enabled = true

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufLeave", "FocusLost" }, {
	desc = "Auto-save",
	-- nested: the :update below must fire BufWritePre/Post so that plugins
	-- (gitsigns refresh, future format-on-save, ...) see the write
	nested = true,
	callback = function(ev)
		if not vim.g.autosave_enabled then
			return
		end
		local buf = ev.buf
		if
			vim.api.nvim_buf_is_valid(buf)
			and vim.bo[buf].buftype == "" -- real file buffers only
			and vim.bo[buf].modifiable
			and not vim.bo[buf].readonly
			and vim.api.nvim_buf_get_name(buf) ~= "" -- skip unnamed scratch
		then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("silent! update")
			end)
		end
	end,
})

vim.api.nvim_create_user_command("AutoSaveToggle", function()
	vim.g.autosave_enabled = not vim.g.autosave_enabled
	vim.notify("AutoSave: " .. (vim.g.autosave_enabled and "ON" or "OFF"))
end, {})
