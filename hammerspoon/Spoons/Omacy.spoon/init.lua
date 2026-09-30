---@class omacy.Api
---@field version string
---@field HYPER string[] the modifier set the shortcuts use
---@field window omacy.Window
---@field focus omacy.Focus
---@field windowChooser table
---@field bookmarkChooser table
---@field micMute omacy.MicMute
---@field mouseScroll omacy.MouseScroll
---@field autostart omacy.Autostart
---@field audio omacy.Audio
---@field hotkeys omacy.Hotkey[] the shortcuts bound when Omacy starts
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
obj.bookmarkChooser = dofile(hs.spoons.resourcePath("bookmark_chooser.lua"))
obj.micMute = dofile(hs.spoons.resourcePath("mic_mute.lua"))
obj.mouseScroll = dofile(hs.spoons.resourcePath("mouse_scroll.lua"))
obj.autostart = dofile(hs.spoons.resourcePath("autostart.lua"))
obj.audio = dofile(hs.spoons.resourcePath("audio.lua"))

---@class omacy.Hotkey
---@field mods string[]
---@field key string
---@field desc string what the shortcut does, printed by showShortcuts
---@field fn function

-- Every shortcut bound when Omacy starts, in the order it was added. A user
-- config adds its own with map before Omacy starts.
obj.hotkeys = {
	{ mods = obj.HYPER, key = "a", desc = "snap left", fn = obj.window.left },
	{ mods = obj.HYPER, key = "d", desc = "snap right", fn = obj.window.right },
	{ mods = obj.HYPER, key = "w", desc = "snap top", fn = obj.window.top },
	{ mods = obj.HYPER, key = "s", desc = "snap bottom", fn = obj.window.bottom },
	{ mods = obj.HYPER, key = "c", desc = "center window", fn = obj.window.center },
	{ mods = obj.HYPER, key = "i", desc = "fill the screen", fn = obj.window.maximize },
	{ mods = obj.HYPER, key = "]", desc = "move to next screen", fn = obj.window.nextScreen },
	{ mods = obj.HYPER, key = "[", desc = "move to previous screen", fn = obj.window.previousScreen },
	{
		mods = obj.HYPER,
		key = "m",
		desc = "choose window",
		fn = function()
			obj.windowChooser:show()
		end,
	},
	{
		mods = obj.HYPER,
		key = "b",
		desc = "choose bookmark",
		fn = function()
			obj.bookmarkChooser:show()
		end,
	},
	{
		mods = obj.HYPER,
		key = "j",
		desc = "Brave Browser",
		fn = function()
			obj.focus.launchOrFocusOrRotate({ app = "com.brave.Browser" })
		end,
	},
	{
		mods = obj.HYPER,
		key = "k",
		desc = "WezTerm",
		fn = function()
			obj.focus.launchOrFocusOrRotate({ app = "com.github.wez.wezterm" })
		end,
	},
	{ mods = obj.HYPER, key = "t", desc = "toggle mic mute", fn = obj.micMute.toggle },
	{ mods = { "ctrl" }, key = "`", desc = "reload config", fn = hs.reload },
}

local function keysOf(mods, key)
	local parts = {}
	for _, mod in ipairs(mods) do
		table.insert(parts, mod:lower())
	end
	table.sort(parts)
	table.insert(parts, key:lower())
	return table.concat(parts, "+")
end

local function indexOf(hotkeys, mods, key)
	local wanted = keysOf(mods, key)
	for i, existing in ipairs(hotkeys) do
		if keysOf(existing.mods, existing.key) == wanted then
			return i
		end
	end
	return nil
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

-- Adds a shortcut to hotkeys. shortcut is the mods and the key separated by
-- spaces, such as "hyper u" or "cmd shift m", where hyper stands for the
-- HYPER mods. A shortcut on the same keys as an earlier one replaces it, so
-- a default can be given a new action. A nil fn removes the shortcut on
-- those keys, so a default can be turned off.
function obj:map(shortcut, fn, desc)
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

	local index = indexOf(self.hotkeys, mods, key)
	if not fn then
		if index then
			table.remove(self.hotkeys, index)
		end
		return self
	end

	local entry = { mods = mods, key = key, desc = desc, fn = fn }
	if index then
		self.hotkeys[index] = entry
		return self
	end
	table.insert(self.hotkeys, entry)

	return self
end

-- Prints every shortcut in hotkeys to the Hammerspoon console.
function obj:showShortcuts()
	print("=== Shortcuts ===")
	for _, entry in ipairs(self.hotkeys) do
		local keys = { table.unpack(entry.mods) }
		table.insert(keys, entry.key)
		print(string.format("  %-20s  %s", table.concat(keys, "+"), entry.desc or ""))
	end
	return self
end

function obj:start()
	for _, entry in ipairs(self.hotkeys) do
		enableWhenFree(entry.mods, entry.key, entry.fn)
	end
	self.mouseScroll.start()
	self.audio.start()

	return self
end

return obj
