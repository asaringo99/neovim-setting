-- "Which change am I on?" — hunk position info based on gitsigns.
local M = {}

---Returns "i/n" where n = total hunks in the buffer and i = hunks at or
---before the cursor (so it advances as you ]c through the file).
---Empty string when gitsigns isn't ready or the file has no changes.
function M.status(bufnr)
	local gs = package.loaded.gitsigns
	if not gs then
		return ""
	end
	local ok, hunks = pcall(gs.get_hunks, bufnr or 0)
	if not ok or not hunks or #hunks == 0 then
		return ""
	end
	local lnum = vim.fn.line(".")
	local idx = 0
	for i, h in ipairs(hunks) do
		local s = (h.added and h.added.start) or (h.removed and h.removed.start)
		if s and lnum >= math.max(s, 1) then
			idx = i
		end
	end
	return string.format("± %d/%d", idx, #hunks)
end

return M
