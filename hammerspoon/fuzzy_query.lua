-- Ranks texts against a typed query with fzy. Every word of the query must
-- appear in a text for it to match. Texts that contain every word as an
-- exact substring rank above texts that only match letter by letter, and
-- inside each group the fzy score decides.

local fzy = require("fzy")

local EXACT = 0
local FUZZY = 1

local FuzzyQuery = {}
FuzzyQuery.__index = FuzzyQuery

-- Splits the query into lowercase words.
function FuzzyQuery.new(text)
	local words = {}
	for word in text:lower():gmatch("%S+") do
		table.insert(words, word)
	end
	return setmetatable({ words = words }, FuzzyQuery)
end

-- Matches every word against the text. Returns nil when a word is missing,
-- otherwise the tier (EXACT or FUZZY) and the summed fzy score.
function FuzzyQuery:match(text)
	local lowerText = text:lower()
	local tier = EXACT
	local score = 0
	for _, word in ipairs(self.words) do
		if not fzy.has_match(word, lowerText) then
			return nil
		end
		if not lowerText:find(word, 1, true) then
			tier = FUZZY
		end
		score = score + fzy.score(word, text)
	end
	return { tier = tier, score = score }
end

-- Returns the indices of the texts that match, best first. Ties keep the
-- original order.
function FuzzyQuery:rank(texts)
	local matches = {}
	for index, text in ipairs(texts) do
		local match = self:match(text)
		if match then
			match.index = index
			table.insert(matches, match)
		end
	end
	table.sort(matches, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.index < b.index
	end)
	local indices = {}
	for _, match in ipairs(matches) do
		table.insert(indices, match.index)
	end
	return indices
end

return FuzzyQuery
