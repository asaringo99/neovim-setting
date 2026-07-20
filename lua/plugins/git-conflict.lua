-- Merge-conflict resolution, VS Code style: conflict blocks are highlighted
-- with "current / incoming" labels and resolved with one keystroke instead
-- of hand-editing the <<<<<<< ======= >>>>>>> markers.
--
-- Buffer-local mappings (active only in files that contain conflicts):
--   co  choose ours   (= VS Code "Accept Current Change")
--   ct  choose theirs (= VS Code "Accept Incoming Change")
--   cb  choose both   (= VS Code "Accept Both Changes")
--   c0  choose none   (drop both sides)
--   ]x / [x  jump to next / previous conflict
return {
	"akinsho/git-conflict.nvim",
	version = "*",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{ "<leader>gx", "<cmd>GitConflictListQf<cr>", desc = "List all conflicts (quickfix)" },
	},
	config = function()
		require("git-conflict").setup({
			default_mappings = true, -- co / ct / cb / c0, ]x / [x (see header)
			default_commands = true, -- :GitConflictChooseOurs etc.
			-- the plugin's own disable_diagnostics uses vim.diagnostic.disable(),
			-- removed in nvim 0.12 -> errors. Keep it off and do the same thing
			-- ourselves with the current API in the autocmds below.
			disable_diagnostics = false,
			list_opener = "copen",
		})

		-- On detection: mute LSP diagnostics in the buffer (conflict markers
		-- are all syntax errors to the LSP) and point out the resolve keys;
		-- easy to forget since conflicts are (hopefully) rare.
		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictDetected",
			callback = function()
				vim.diagnostic.enable(false, { bufnr = vim.api.nvim_get_current_buf() })
				vim.notify("コンフリクト検出: co=自分 / ct=相手 / cb=両方 / ]x=次へ", vim.log.levels.INFO)
			end,
		})
		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictResolved",
			callback = function()
				vim.diagnostic.enable(true, { bufnr = vim.api.nvim_get_current_buf() })
			end,
		})
	end,
}
