---@class omacy.Api
---@field version string
---@field HYPER string[] the modifier set the shortcuts use
---@field window omacy.Window
---@field focus omacy.Focus
---@field windowChooser table
---@field fuzzyQuery table
---@field micMute omacy.MicMute
---@field mouseScroll omacy.MouseScroll
---@field configWatcher table|nil the hs.pathwatcher object
local obj = {}
obj.__index = obj

obj.name = "Omacy"
obj.version = "0.1.0"
obj.author = "Glyphack"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.HYPER = { "cmd", "ctrl", "alt" }

obj.window = dofile(hs.spoons.resourcePath("window.lua"))
obj.focus = dofile(hs.spoons.resourcePath("focus.lua"))
obj.windowChooser = dofile(hs.spoons.resourcePath("window_chooser.lua"))
obj.fuzzyQuery = dofile(hs.spoons.resourcePath("fuzzy_query.lua"))
obj.micMute = dofile(hs.spoons.resourcePath("mic_mute.lua"))
obj.mouseScroll = dofile(hs.spoons.resourcePath("mouse_scroll.lua"))

obj.defaultHotkeys = {
	left = { obj.HYPER, "a" },
	right = { obj.HYPER, "d" },
	top = { obj.HYPER, "w" },
	bottom = { obj.HYPER, "s" },
	center = { obj.HYPER, "c" },
	maximize = { obj.HYPER, "i" },
	nextScreen = { obj.HYPER, "]" },
	previousScreen = { obj.HYPER, "[" },
	chooseWindow = { obj.HYPER, "m" },
	toggleMute = { obj.HYPER, "t" },
	reload = { { "ctrl" }, "`" },
}

local function actionsOf(spoon)
	local window = spoon.window

	return {
		left = window.left,
		right = window.right,
		top = window.top,
		bottom = window.bottom,
		center = window.center,
		maximize = window.maximize,
		nextScreen = window.nextScreen,
		previousScreen = window.previousScreen,
		chooseWindow = function()
			spoon.windowChooser:show()
		end,
		toggleMute = spoon.micMute.toggle,
		reload = hs.reload,
	}
end

local function enableWhenFree(mods, key, fn)
	local hotkey = hs.hotkey.new(mods, key, fn)
	if not hotkey then
		return false
	end

	for _, taken in ipairs(hs.hotkey.getHotkeys()) do
		if taken.idx == hotkey.idx then
			hotkey:delete()
			return false
		end
	end

	hotkey:enable()
	return true
end

function obj:bindHotkeys(mapping)
	local actions = actionsOf(self)

	for name, combination in pairs(mapping or self.defaultHotkeys) do
		local action = actions[name]
		if action then
			enableWhenFree(combination[1], combination[2], action)
		end
	end

	return self
end

function obj:map(shortcut, fn)
	local words = {}
	for word in shortcut:gmatch("%S+") do
		table.insert(words, word)
	end

	local key = table.remove(words)
	if not key then
		return self
	end

	local mods = {}
	for _, word in ipairs(words) do
		if word == "hyper" then
			for _, hyperMod in ipairs(self.HYPER) do
				table.insert(mods, hyperMod)
			end
		else
			table.insert(mods, word)
		end
	end

	hs.hotkey.bind(mods, key, fn)

	return self
end

local function watchConfig(files)
	for _, file in ipairs(files) do
		if file:sub(-4) == ".lua" then
			hs.reload()
			return
		end
	end
end

function obj:start()
	self:bindHotkeys(self.defaultHotkeys)
	self.mouseScroll.start()

	self.configWatcher = hs.pathwatcher.new(hs.configdir, watchConfig)
	self.configWatcher:start()

	return self
end

return obj
