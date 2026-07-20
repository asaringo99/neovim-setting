-- Tree open/close goes through config/layout.lua so the tree/terminal
-- arrangement stays deterministic (see that file for the two layouts;
-- <leader>tl switches between them).

local function tree_toggle()
	if require("config.windows").win_with_ft("NvimTree") then
		vim.cmd("NvimTreeToggle") -- just closing; layout is unaffected
	else
		require("config.layout").open_tree("NvimTreeToggle")
	end
end

local function tree_focus()
	if require("config.windows").win_with_ft("NvimTree") then
		vim.cmd("NvimTreeFocus")
	else
		require("config.layout").open_tree("NvimTreeFocus")
	end
end

return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<leader>e", tree_toggle, desc = "Toggle file explorer" },
		{ "<C-b>", tree_toggle, desc = "Toggle file explorer (sidebar)" },
		{ "<leader>o", tree_focus, desc = "Focus file explorer" },
	},
	config = function()
		-- Custom paste: pasting a COPIED entry over an existing name creates
		-- "name.copy.ext" (then name.copy1.ext, ...) instead of prompting
		-- for a rename. Cut entries fall back to the default paste (= move).
		local function unique_copy_name(dir, name)
			local root, ext = name:match("^(.+)%.([^.]+)$")
			local base, suffix
			if root and root ~= "" then
				base, suffix = root, "." .. ext
			else
				base, suffix = name, ""
			end
			local n = 0
			while true do
				local tag = (n == 0) and ".copy" or (".copy" .. n)
				local candidate = base .. tag .. suffix
				if not vim.uv.fs_stat(dir .. "/" .. candidate) then
					return candidate
				end
				n = n + 1
			end
		end

		local function smart_paste()
			local api = require("nvim-tree.api")
			local explorer = require("nvim-tree.core").get_explorer()
			local clip = explorer and explorer.clipboard and explorer.clipboard.data
			if not clip or #clip.copy == 0 or #clip.cut > 0 then
				return api.fs.paste() -- cut (move) or empty: default behaviour
			end

			-- destination dir = folder under cursor, or the file's parent
			local node = api.tree.get_node_under_cursor()
			local dest_dir
			if node and node.type == "directory" then
				dest_dir = node.absolute_path
			elseif node and node.absolute_path then
				dest_dir = vim.fn.fnamemodify(node.absolute_path, ":h")
			else
				dest_dir = explorer.absolute_path
			end

			for _, src in ipairs(clip.copy) do
				local name = vim.fn.fnamemodify(src.absolute_path, ":t")
				local target = dest_dir .. "/" .. name
				if vim.uv.fs_stat(target) then
					target = dest_dir .. "/" .. unique_copy_name(dest_dir, name)
				end
				if src.type == "directory" then
					vim.fn.system({ "cp", "-r", src.absolute_path, target })
				else
					vim.uv.fs_copyfile(src.absolute_path, target)
				end
				vim.notify("Copied -> " .. vim.fn.fnamemodify(target, ":t"))
			end
			api.tree.reload()
		end

		require("nvim-tree").setup({
			on_attach = function(bufnr)
				local api = require("nvim-tree.api")
				api.config.mappings.default_on_attach(bufnr)
				vim.keymap.set("n", "p", smart_paste, { buffer = bufnr, desc = "Paste (auto .copy name)" })
			end,
			-- Reveal + highlight the current buffer's file in the tree
			-- (like VS Code's "explorer autoReveal")
			update_focused_file = {
				enable = true,
				update_root = false, -- keep the tree root where it is
			},
			git = {
				ignore = false, -- show .gitignore'd files too (secret.yaml etc.)
			},
			-- WSL2's inotify is unreliable, so the fs watcher often never fires
			-- and the tree wouldn't refresh after d / create / rename. Disabling
			-- it makes nvim-tree reload_explorer() itself right after each fs
			-- action (see actions/fs/remove-file.lua do_remove()).
			filesystem_watchers = {
				enable = false,
			},
			-- ...and, since the watcher is off, reload the tree whenever we
			-- re-enter it (only fires when filesystem_watchers.enable = false;
			-- see explorer/init.lua). Catches external changes made while the
			-- focus was in the editor / toggleterm. FocusGained below covers
			-- changes made in a separate OS terminal.
			reload_on_bufenter = true,
			actions = {
				open_file = {
					resize_window = false, -- keep the user's (mouse-)resized width
				},
				remove_file = {
					-- don't close the editor window when its file is deleted:
					-- closing it collapses the tree|editor|terminal layout and
					-- the next open lands in a stray split below the tree.
					close_window = false,
				},
			},
		})

		-- Third leg of the refresh strategy (see filesystem_watchers above):
		-- refresh when Neovim regains OS focus, catching changes made in a
		-- separate terminal (git checkout, build output) while nvim was in
		-- the background.
		vim.api.nvim_create_autocmd("FocusGained", {
			desc = "Refresh nvim-tree when Neovim regains focus",
			callback = function()
				if require("config.windows").win_with_ft("NvimTree") then
					pcall(require("nvim-tree.api").tree.reload)
				end
			end,
		})

		-- Preview-follow + promote-on-open (see that module's header)
		require("config.treepreview").setup()
	end,
}
