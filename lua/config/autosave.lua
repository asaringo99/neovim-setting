-- Saving policy: explicit Ctrl+S (see keymaps.lua), VS Code style.
-- Optional mild auto-save (write when focus leaves the buffer / app) can be
-- turned on with :AutoSaveToggle — it never saves on Esc / while typing.

vim.g.autosave_enabled = false

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
	desc = "Auto-save (opt-in)",
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
	vim.notify("AutoSave: " .. (vim.g.autosave_enabled and "ON (フォーカスが外れた時に保存)" or "OFF"))
end, {})
