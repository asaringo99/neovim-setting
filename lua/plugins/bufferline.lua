-- Close a buffer WITHOUT letting the terminal / tree buffer take over the
-- window: first switch every window showing it to a neighbouring file tab
-- (VS Code behaviour), then delete the buffer.
local function close_buffer(target)
	target = target or vim.api.nvim_get_current_buf()
	if vim.bo[target].buftype ~= "" then
		pcall(vim.cmd, "bdelete! " .. target)
		return
	end
	local windows = require("config.windows")
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == target then
			vim.api.nvim_win_call(win, function()
				windows.switch_away(target)
			end)
		end
	end
	pcall(vim.cmd, "bdelete " .. target)
end

return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- The tabline is a permanent UI element — load it at startup
	lazy = false,
	keys = {
		{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer tab" },
		{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer tab" },
		{ "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer tab (type its letter)" },
		{ "<leader>bd", close_buffer, desc = "Close current buffer" },
		{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
	},
	opts = {
		options = {
			-- Show LSP diagnostics (error/warn dots) on each tab
			diagnostics = "nvim_lsp",
			-- Keep tabs to the right of the file tree, with a header over it
			offsets = {
				{
					filetype = "NvimTree",
					text = "Files",
					text_align = "left",
					separator = true,
				},
			},
			-- Click a tab to focus it; close with the x / right-click
			-- (same terminal-safe close as <leader>bd)
			close_command = close_buffer,
			right_mouse_command = close_buffer,
		},
	},
}
