-- Window chooser: lists the visible windows, most recently focused first,
-- and focuses the one picked. Typing filters the list on the window title
-- and the app name: windows containing the typed words come first, then
-- windows that only match letter by letter.

local windowFilter = require("hs.window.filter")
local chooser = require("hs.chooser")
local FuzzyQuery = require("fuzzy_query")

local function appIcon(app)
	local bundleId = app:bundleID()
	if not bundleId then
		return nil
	end
	return hs.image.imageFromAppBundle(bundleId)
end

local WindowChooser = {
	filter = windowFilter.new():keepActive(),
	windowsById = {},
	choices = {},
	chooser = nil,
}

function WindowChooser:refresh()
	self.windowsById = {}
	self.choices = {}
	for _, win in ipairs(self.filter:getWindows(windowFilter.sortByFocusedLast)) do
		local id = win:id()
		local app = win:application()
		if id and app then
			local appName = app:name()
			local title = win:title()
			if title == "" then
				title = appName
			end
			self.windowsById[id] = win
			table.insert(self.choices, {
				text = title,
				subText = appName,
				image = appIcon(app),
				windowId = id,
			})
		end
	end
end

function WindowChooser:filterChoices(query)
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

function WindowChooser:focus(choice)
	if not choice then
		return
	end
	local win = self.windowsById[choice.windowId]
	if not win then
		return
	end
	win:focus()
end

function WindowChooser:show()
	self:refresh()
	self.chooser:query("")
	self.chooser:choices(self.choices)
	self.chooser:show()
end

WindowChooser.chooser = chooser
	.new(function(choice)
		WindowChooser:focus(choice)
	end)
	:placeholderText("Window")
	:queryChangedCallback(function(query)
		WindowChooser.chooser:choices(WindowChooser:filterChoices(query))
	end)

return WindowChooser
