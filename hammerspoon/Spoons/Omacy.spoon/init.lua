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
---@field translate omacy.Translate
---@field mappings omacy.Hotkey[] the shortcuts added with map, applied over the defaults when Omacy starts
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
obj.translate = dofile(hs.spoons.resourcePath("translate.lua"))

---@class omacy.Hotkey
---@field mods string[]
---@field key string
---@field desc string what the shortcut does, printed by showShortcuts
---@field fn function? nil turns off the default on the same keys

obj.mappings = {}

local function defaultHotkeys(self)
	local hyper = self.HYPER
	return {
		{ mods = hyper, key = "a", desc = "snap left", fn = self.window.left },
		{ mods = hyper, key = "d", desc = "snap right", fn = self.window.right },
		{ mods = hyper, key = "w", desc = "snap top", fn = self.window.top },
		{ mods = hyper, key = "s", desc = "snap bottom", fn = self.window.bottom },
		{ mods = hyper, key = "c", desc = "center window", fn = self.window.center },
		{ mods = hyper, key = "i", desc = "fill the screen", fn = self.window.maximize },
		{ mods = hyper, key = "g", desc = "show grid", fn = self.window.grid },
		{ mods = hyper, key = "]", desc = "move to next screen", fn = self.window.nextScreen },
		{ mods = hyper, key = "[", desc = "move to previous screen", fn = self.window.previousScreen },
		{
			mods = hyper,
			key = "m",
			desc = "choose window",
			fn = function()
				self.windowChooser:show()
			end,
		},
		{
			mods = hyper,
			key = "b",
			desc = "choose bookmark",
			fn = function()
				self.bookmarkChooser:show()
			end,
		},
		{
			mods = hyper,
			key = "j",
			desc = "Brave Browser",
			fn = function()
				self.focus.launchOrFocusOrRotate({ app = "com.brave.Browser" })
			end,
		},
		{
			mods = hyper,
			key = "k",
			desc = "WezTerm",
			fn = function()
				self.focus.launchOrFocusOrRotate({ app = "com.github.wez.wezterm" })
			end,
		},
		{ mods = hyper, key = "t", desc = "toggle mic mute", fn = self.micMute.toggle },
		{
			mods = hyper,
			key = "\\",
			desc = "translate selection",
			fn = function()
				self.translate:translateSelectionPopup()
			end,
		},
		{ mods = { "ctrl" }, key = "#50", desc = "reload config", fn = hs.reload },
	}
end

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

local function hotkeysOf(self)
	local hotkeys = defaultHotkeys(self)
	for _, mapping in ipairs(self.mappings) do
		local index = indexOf(hotkeys, mapping.mods, mapping.key)
		if not mapping.fn then
			if index then
				table.remove(hotkeys, index)
			end
		elseif index then
			hotkeys[index] = mapping
		else
			table.insert(hotkeys, mapping)
		end
	end
	return hotkeys
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

-- Adds a shortcut. mods is the list of modifier keys the way hs.hotkey takes
-- them, such as omacy.HYPER or { "cmd", "shift" }, and key is the key, such
-- as "u". A shortcut on the same keys as an earlier one replaces it, so a
-- default can be given a new action. A nil fn removes the shortcut on those
-- keys, so a default can be turned off.
function obj:map(mods, key, fn, desc)
	table.insert(self.mappings, { mods = mods, key = key, desc = desc, fn = fn })
	return self
end

-- Prints every shortcut bound when Omacy starts to the Hammerspoon console.
function obj:showShortcuts()
	print("=== Shortcuts ===")
	for _, entry in ipairs(hotkeysOf(self)) do
		local keys = { table.unpack(entry.mods) }
		table.insert(keys, entry.key)
		print(string.format("  %-20s  %s", table.concat(keys, "+"), entry.desc or ""))
	end
	return self
end

function obj:start()
	hs.autoLaunch(true)
	for _, entry in ipairs(hotkeysOf(self)) do
		enableWhenFree(entry.mods, entry.key, entry.fn)
	end
	self.mouseScroll.start()
	self.audio.start()

	return self
end

return obj
