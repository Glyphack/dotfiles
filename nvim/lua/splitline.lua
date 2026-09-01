--- Break a markdown line into one line per sentence.

local M = {}

--- Paired markup. A terminator inside a pair belongs to the markup rather than
--- to the prose, so the scan refuses to cut while a pair is open. Apostrophes
--- are deliberately absent: "don't" would open a pair that never closes.
--- @class Delimiter
--- @field [1] string Opening character
--- @field [2] string Closing character
local DELIMITERS = {
	{ "(", ")" },
	{ "[", "]" },
	{ "{", "}" },
	{ "`", "`" },
	{ '"', '"' },
}

local OPENS, CLOSES = {}, {}
for _, pair in ipairs(DELIMITERS) do
	OPENS[pair[1]] = pair
	CLOSES[pair[2]] = pair
end

local TERMINATORS = { ["."] = true, ["?"] = true, ["!"] = true }

--- Characters a word must reach before its terminator can cut the line. This
--- keeps initials and two letter abbreviations together, so "J. R. R. Tolkien.",
--- "e.g." and "Dr." stay on one line. Longer abbreviations such as "etc." are
--- indistinguishable from short words and do cut.
local MIN_WORD = 3

--- Walks a string one character at a time, tracking how deeply nested it is in
--- paired markup, and collects the offsets where the line may be cut.
--- @class Scan
--- @field text string
--- @field open Delimiter[] Pairs entered and not yet left; level is #open + 1
--- @field cuts integer[] Offsets to cut the line after
--- @field word integer Length of the word being walked through
local Scan = {}
Scan.__index = Scan

--- @param text string
--- @return Scan
function Scan.new(text)
	return setmetatable({ text = text, open = {}, cuts = {}, word = 0 }, Scan)
end

--- @return integer 1 outside all markup, higher inside it
function Scan:level()
	return #self.open + 1
end

--- @param offset integer Offset of a terminator
--- @return boolean
function Scan:cuts_here(offset)
	if self:level() > 1 or self.word < MIN_WORD then
		return false
	end
	local rest = self.text:sub(offset + 1)
	if TERMINATORS[rest:sub(1, 1)] then
		return false -- not the last mark of a run such as "..." or "?!"
	end
	return rest:match("^[ \t]") ~= nil and rest:match("%S") ~= nil
end

--- @param offset integer
function Scan:step(offset)
	local char = self.text:sub(offset, offset)

	local innermost = self.open[#self.open]
	if innermost and char == innermost[2] then
		table.remove(self.open)
	elseif OPENS[char] then
		table.insert(self.open, OPENS[char])
	elseif TERMINATORS[char] then
		if self:cuts_here(offset) then
			table.insert(self.cuts, offset)
		end
		self.word = 0
		return
	elseif char:match("%s") then
		self.word = 0
		return
	end

	self.word = self.word + 1
end

--- @param text string
--- @return integer[]|nil cuts, string|nil reason The reason is set when the
--- markup in `text` never closes, which makes every cut unsafe to guess at.
function M.cut_points(text)
	local scan = Scan.new(text)
	for offset = 1, #text do
		scan:step(offset)
	end
	local unclosed = scan.open[#scan.open]
	if unclosed then
		return nil, "unbalanced " .. unclosed[1]
	end
	return scan.cuts
end

--- Openers that a line can carry before its prose. The second field says whether
--- the marker keeps its shape on the lines that follow, or is blanked out so the
--- prose stays aligned under the first line.
local OPENERS = {
	{ "^[ \t]+", true },
	{ "^>[ \t]*", true },
	{ "^[-*+][ \t]+", false },
	{ "^%d+[.)][ \t]+", false },
}

--- @param line string
--- @return string prose, string continuation
local function peel(line)
	local continuation = {}
	local prose = line
	local peeled = true
	while peeled do
		peeled = false
		for _, opener in ipairs(OPENERS) do
			local marker = prose:match(opener[1])
			if marker then
				table.insert(continuation, opener[2] and marker or (marker:gsub("[^\t]", " ")))
				prose = prose:sub(#marker + 1)
				peeled = true
				break
			end
		end
	end
	return prose, table.concat(continuation)
end

--- @param line string
--- @return string[]|nil lines, string|nil reason
function M.split_line(line)
	local prose, continuation = peel(line)
	local cuts, reason = M.cut_points(prose)
	if not cuts then
		return nil, reason
	end
	if #cuts == 0 then
		return nil, nil
	end

	local lines, start = {}, 1
	for _, cut in ipairs(cuts) do
		table.insert(lines, prose:sub(start, cut))
		start = prose:find("%S", cut + 1)
	end
	table.insert(lines, prose:sub(start))

	lines[1] = line:sub(1, #line - #prose) .. lines[1]
	for index = 2, #lines do
		lines[index] = continuation .. lines[index]
	end
	return lines
end

--- Split the line under the cursor.
function M.split()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	if not line then
		return
	end

	local lines, reason = M.split_line(line)
	if reason then
		vim.notify("SplitLine: " .. reason, vim.log.levels.WARN)
		return
	end
	if not lines then
		vim.notify("SplitLine: no sentence break on this line", vim.log.levels.INFO)
		return
	end

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, lines)
	vim.api.nvim_win_set_cursor(0, { row, 0 })
end

function M.setup()
	vim.api.nvim_create_user_command("SplitLine", M.split, {
		desc = "Split the current line into one line per sentence",
	})
end

return M
