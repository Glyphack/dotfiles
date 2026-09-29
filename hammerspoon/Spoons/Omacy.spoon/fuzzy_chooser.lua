local chooser = require("hs.chooser")
local fzy = dofile(hs.spoons.resourcePath("fzy.lua"))

local EXACT = 0
local FUZZY = 1

local FuzzyQuery = {}
FuzzyQuery.__index = FuzzyQuery

function FuzzyQuery.new(text)
	local words = {}
	for word in text:lower():gmatch("%S+") do
		table.insert(words, word)
	end
	return setmetatable({ words = words }, FuzzyQuery)
end

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

local FuzzyChooser = {}
FuzzyChooser.__index = FuzzyChooser

function FuzzyChooser.new(placeholder, load, pick)
	local self = setmetatable({ load = load, choices = {} }, FuzzyChooser)
	self.chooser = chooser
		.new(function(choice)
			if choice then
				pick(choice)
			end
		end)
		:placeholderText(placeholder)
		:queryChangedCallback(function(query)
			self.chooser:choices(self:filter(query))
		end)
	return self
end

function FuzzyChooser:filter(query)
	if query == "" then
		return self.choices
	end
	local texts = {}
	for _, choice in ipairs(self.choices) do
		table.insert(texts, choice.text .. " " .. choice.subText)
	end
	local result = {}
	for _, index in ipairs(FuzzyQuery.new(query):rank(texts)) do
		table.insert(result, self.choices[index])
	end
	return result
end

function FuzzyChooser:show()
	self.choices = self.load()
	self.chooser:query("")
	self.chooser:choices(self.choices)
	self.chooser:show()
end

return FuzzyChooser
