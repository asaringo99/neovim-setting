-- Plugin-independent keymaps and editing options.

-- Quickly leave insert mode by typing "jk"
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Ctrl+S saves (VS Code style; works in insert mode without leaving it)
vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>update<cr>", { desc = "Save file" })

-- ---------------------------------------------------------------------------
-- VS Code-style selection
-- ---------------------------------------------------------------------------
-- NOTE: normal yank/delete/paste registers are left untouched; only the
-- explicit Ctrl+C below talks to the Windows clipboard (via win32yank).

-- Shift+Arrow starts/extends a selection, a plain arrow cancels it,
-- and typing replaces the selection (Select mode) — like VS Code.
vim.opt.keymodel = { "startsel", "stopsel" }
vim.opt.selectmode = { "key" }

-- Ctrl+Left / Ctrl+Right: word-wise cursor movement, stopping at the END
-- of each word (VS Code style).
-- (Ctrl+Shift+Left/Right then selects word-wise via 'keymodel'.)
vim.keymap.set({ "n", "x" }, "<C-Right>", "e", { desc = "Move to word end" })
vim.keymap.set({ "n", "x" }, "<C-Left>", "b", { desc = "Move one word left" })
-- in insert mode land AFTER the word's last character
vim.keymap.set("i", "<C-Right>", "<C-o>e<Right>", { desc = "Move to word end" })
vim.keymap.set("i", "<C-Left>", "<C-o>b", { desc = "Move one word left" })

-- Ctrl+F: incremental in-file search (type -> highlights & jumps live,
-- Enter to confirm, then n / N for next / previous match, Ctrl+L to
-- clear the highlight)
vim.keymap.set("n", "<C-f>", "/", { desc = "Search in file" })
vim.keymap.set("i", "<C-f>", "<Esc>/", { desc = "Search in file" })

-- Ctrl+H: replace every match of the last Ctrl+F search (VS Code style).
-- Type the replacement and press Enter; type 'c' before Enter to confirm
-- each match one by one. In visual mode it only replaces inside the
-- selection.
vim.keymap.set("n", "<C-h>", ":%s///g<Left><Left>", { desc = "Replace all matches of last search" })
vim.keymap.set("x", "<C-h>", ":s///g<Left><Left>", { desc = "Replace matches in selection" })

-- Ctrl+C copies the selection to the Windows clipboard ("+ register).
-- This is the ONLY key that touches the clipboard; y/d/p stay vim-internal.
vim.keymap.set("x", "<C-c>", '"+y', { desc = "Copy selection to clipboard" })
vim.keymap.set("s", "<C-c>", '<C-o>"+y', { desc = "Copy selection to clipboard" })

-- ---------------------------------------------------------------------------
-- Windows / layout
-- ---------------------------------------------------------------------------
-- Resize the current window with Alt + arrow keys
-- (Ctrl+arrows are used for word-wise movement above)
vim.keymap.set("n", "<A-Up>", "<cmd>resize +2<cr>", { desc = "Grow window height" })
vim.keymap.set("n", "<A-Down>", "<cmd>resize -2<cr>", { desc = "Shrink window height" })
vim.keymap.set("n", "<A-Left>", "<cmd>vertical resize -2<cr>", { desc = "Shrink window width" })
vim.keymap.set("n", "<A-Right>", "<cmd>vertical resize +2<cr>", { desc = "Grow window width" })

-- Switch which of the tree / terminal wins the shared corner
-- (tree full-height <-> terminal full-width). See lua/config/layout.lua.
vim.keymap.set("n", "<leader>tl", function()
	require("config.layout").switch()
end, { desc = "Switch tree/terminal layout priority" })
