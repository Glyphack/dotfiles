local windowFilter = require("hs.window.filter")
local FuzzyChooser = dofile(hs.spoons.resourcePath("fuzzy_chooser.lua"))

local function appIcon(app)
	local bundleId = app:bundleID()
	if not bundleId then
		return nil
	end
	return hs.image.imageFromAppBundle(bundleId)
end

local WindowChooser = {
	filter = windowFilter.new():setDefaultFilter({}):keepActive(),
	windowsById = {},
	chooser = nil,
}

function WindowChooser:load()
	self.windowsById = {}
	local choices = {}
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
			table.insert(choices, {
				text = title,
				subText = appName,
				image = appIcon(app),
				windowId = id,
			})
		end
	end
	return choices
end

function WindowChooser:focus(choice)
	local win = self.windowsById[choice.windowId]
	if not win then
		return
	end
	if win:isMinimized() then
		win:unminimize()
	end
	win:focus()
end

function WindowChooser:show()
	self.chooser:show()
end

WindowChooser.chooser = FuzzyChooser.new("Window", function()
	return WindowChooser:load()
end, function(choice)
	WindowChooser:focus(choice)
end)

return WindowChooser
