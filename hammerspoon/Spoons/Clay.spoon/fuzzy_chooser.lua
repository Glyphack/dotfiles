local chooser = require("hs.chooser")
local fzy = dofile(hs.spoons.resourcePath("fzy.lua"))
local onShutdown = dofile(hs.spoons.resourcePath("on_shutdown.lua"))

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

-- Ranks entries, each a { text, group } table. Exact matches come before fuzzy ones.
-- Among matches that are equally exact, lower groups come first, then better scores.
function FuzzyQuery:rank(entries)
	local matches = {}
	for index, entry in ipairs(entries) do
		local match = self:match(entry.text)
		if match then
			match.index = index
			match.group = entry.group
			table.insert(matches, match)
		end
	end
	table.sort(matches, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		if a.group ~= b.group then
			return a.group < b.group
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

-- group is optional. It returns a number for a choice, and among matches that are
-- equally exact, choices in lower groups are listed first.
function FuzzyChooser.new(placeholder, load, pick, group)
	local self = setmetatable({
		load = load,
		group = group or function()
			return 0
		end,
		choices = {},
	}, FuzzyChooser)
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
	onShutdown(function()
		self.chooser:delete()
	end)
	return self
end

function FuzzyChooser:filter(query)
	if query == "" then
		return self.choices
	end
	local entries = {}
	for _, choice in ipairs(self.choices) do
		table.insert(entries, { text = choice.text .. " " .. choice.subText, group = self.group(choice) })
	end
	local result = {}
	for _, index in ipairs(FuzzyQuery.new(query):rank(entries)) do
		table.insert(result, self.choices[index])
	end
	return result
end

-- Replaces the choices, refreshing the open list with the current query.
function FuzzyChooser:setChoices(choices)
	self.choices = choices
	if not self.chooser:isVisible() then
		return
	end
	self.chooser:choices(self:filter(self.chooser:query()))
end

function FuzzyChooser:show()
	self.choices = self.load()
	self.chooser:query("")
	self.chooser:choices(self.choices)
	self.chooser:show()
end

function FuzzyChooser:toggle()
	if self.chooser:isVisible() then
		self.chooser:hide()
		return
	end
	self:show()
end

return FuzzyChooser
