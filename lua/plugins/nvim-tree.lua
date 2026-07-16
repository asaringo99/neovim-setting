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
			actions = {
				open_file = {
					resize_window = false, -- keep the user's (mouse-)resized width
				},
			},
		})

		-- Preview-follow: moving with j/k in the tree shows the file under
		-- the cursor in the editor window (focus stays in the tree).
		local api = require("nvim-tree.api")
		local timer = vim.uv.new_timer()
		local function preview_under_cursor()
			if vim.bo.filetype ~= "NvimTree" then
				return
			end
			local ok, node = pcall(api.tree.get_node_under_cursor)
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
			-- LIGHTWEIGHT preview: suppress autocmds so no LSP / gitsigns
			-- machinery starts (~125ms per file otherwise), then start ONLY
			-- the treesitter highlighter by hand for syntax colours (~ms).
			-- The full experience kicks in when the file is really opened.
			local ei = vim.o.eventignore
			vim.o.eventignore = "all"
			local ok = pcall(function()
				vim.fn.bufload(buf)
				vim.api.nvim_win_set_buf(ewin, buf)
			end)
			vim.o.eventignore = ei
			if ok then
				local ft = vim.filetype.match({ buf = buf })
				local lang = ft and vim.treesitter.language.get_lang(ft)
				if lang then
					pcall(vim.treesitter.start, buf, lang)
				end
				if vim.bo[buf].filetype == "" then
					vim.b[buf].preview_plain = true -- finish setup on real open
				end
			end
		end
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

		-- When a lightweight-previewed buffer is REALLY entered (Enter in the
		-- tree, picked from telescope, ...), run the skipped setup once:
		-- filetype detection fires treesitter / LSP / gitsigns as usual.
		vim.api.nvim_create_autocmd("BufEnter", {
			desc = "Promote plain preview buffers to fully-loaded files",
			nested = true,
			callback = function(ev)
				if vim.b[ev.buf].preview_plain then
					vim.b[ev.buf].preview_plain = nil
					vim.api.nvim_buf_call(ev.buf, function()
						vim.cmd("filetype detect")
						vim.cmd("doautocmd BufReadPost")
					end)
				end
			end,
		})
	end,
}
