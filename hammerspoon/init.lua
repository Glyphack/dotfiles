HOME_MONITOR = "DELL U2723QE"
MACBOOK_MONITOR = "Built-in Retina Display"
LG_MONITOR = "LG HDR 4K"

package.path = package.path
	.. ";"
	.. os.getenv("HOME")
	.. "/Programming/dotfiles/dotfiles-flexport/Spoons/?.spoon/init.lua"

SpoonInstall = hs.loadSpoon("SpoonInstall")

-- My shortcuts
local window_management_key = { "alt", "command", "ctrl", "shift" }
WINDOWS_SHORTCUTS = {
	{ "J", "Brave Browser" },
	{ "K", "WezTerm" },
	{ "O", "Obsidian" },
	{ "P", "OBS" },
}

TOGGLE_MUTE_SHORTCUT = { "alt", "t" }

local hasSecrets, secrets = pcall(require, "secrets")
local GlobalMute = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
	toggle = TOGGLE_MUTE_SHORTCUT,
})
GlobalMute:configure({
	unmute_background = "file:///Library/Desktop%20Pictures/Solid%20Colors/Red%20Orange.png",
	mute_background = "file:///Library/Desktop%20Pictures/Solid%20Colors/Turquoise%20Green.png",
})

function SendClickableNotificaiton(notification, link)
	local function notificationCallback()
		hs.urlevent.openURL(link)
	end
	local notificationObject = hs.notify.new(notificationCallback, notification)
	notificationObject:send()
end

function Reload(files)
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			hs.notify.new({ title = "Reloading", informativeText = "Reloading Hammerspoon config" }):send()
			hs.reload()
			return
		end
	end
end

hs.hotkey.bind({ "alt" }, "R", function()
	hs.reload()
end)

local function useDefaultAudioDevice()
	jbl_speaker = hs.audiodevice.findOutputByName("JBL Flip 6")
	if jbl_speaker then
		jbl_speaker:setDefaultOutputDevice()
		return
	end
	mbp_speaker = hs.audiodevice.findOutputByName("MacBook Pro Speakers")
	if mbp_speaker then
		mbp_speaker:setDefaultOutputDevice()
		return
	end
	mac_mini_speaker = hs.audiodevice.findOutputByName("Mac mini Speakers")
	if mac_mini_speaker then
		mac_mini_speaker:setDefaultOutputDevice()
		return
	end
end

local function switchOutputAfterExternalMicConnected()
	current = hs.audiodevice.defaultInputDevice():name()
	print("Current device: " .. current)
	if current == "External Microphone" then
		print("Forcing default output to Internal Speakers")
		useDefaultAudioDevice()
	end
end

local function audiodeviceDeviceCallback(event)
	print("audiodeviceDeviceCallback: " .. event)
	if event == "dIn " then
		switchOutputAfterExternalMicConnected()
	end
end

hs.audiodevice.watcher.setCallback(audiodeviceDeviceCallback)
hs.audiodevice.watcher.start()

switchOutputAfterExternalMicConnected()

-- set the other screen than macbook as primary
local function setPrimary()
	local screens = hs.screen.allScreens()
	for _, screen in pairs(screens) do
		if screen:name() ~= MACBOOK_MONITOR then
			print("Setting " .. screen:name() .. " as primary")
			screen:setPrimary()
		end
	end
end

setPrimary()

-- half of screen
hs.hotkey.bind(window_management_key, "a", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0, 0.5, 1 })
end)
hs.hotkey.bind(window_management_key, "d", function()
	hs.window.focusedWindow():moveToUnit({ 0.5, 0, 0.5, 1 })
end)
hs.hotkey.bind(window_management_key, "w", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0, 1, 0.5 })
end)
hs.hotkey.bind(window_management_key, "s", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0.5, 1, 0.5 })
end)
-- center screewindow_management_key
hs.hotkey.bind(window_management_key, "c", function()
	hs.window.focusedWindow():centerOnScreen()
end)

-- full screen
hs.hotkey.bind(window_management_key, "i", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0, 1, 1 })
end)

-- move between displays
-- hs.hotkey.bind(window_management_key, 'o', function()
--   local win = hs.window.focusedWindow()
--   local next = win:screen():toEast()
--   if next then
--     win:moveToScreen(next, true)
--   end
-- end)
-- hs.hotkey.bind(window_management_key, 'u', function()
--   local win = hs.window.focusedWindow()
--   local next = win:screen():toWest()
--   if next then
--     win:moveToScreen(next, true)
--   end
-- end)

-- grid gui
hs.grid.setMargins({ w = 0, h = 0 })
hs.hotkey.bind(window_management_key, "g", hs.grid.show)

-- size for recording
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "r", function()
	hs.window.focusedWindow():setSize({ w = 640, h = 360 })
end)

reloadWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", Reload):start()
reloadWatcher:start()

-- HANDLE SCROLLING WITH MOUSE BUTTON PRESSED
local scrollMouseButton = 2
local deferred = false

overrideOtherMouseDown = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(e)
	local pressedMouseButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	if scrollMouseButton == pressedMouseButton then
		deferred = true
		return true
	end
end)

overrideOtherMouseUp = hs.eventtap.new({ hs.eventtap.event.types.otherMouseUp }, function(e)
	local pressedMouseButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	if scrollMouseButton == pressedMouseButton then
		if deferred then
			overrideOtherMouseDown:stop()
			overrideOtherMouseUp:stop()
			hs.eventtap.otherClick(e:location(), pressedMouseButton)
			overrideOtherMouseDown:start()
			overrideOtherMouseUp:start()
			return true
		end
		return false
	end
	return false
end)

local oldmousepos = {}
local scrollmult = -4 -- negative multiplier makes mouse work like traditional scrollwheel

dragOtherToScroll = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDragged }, function(e)
	local pressedMouseButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	-- print ("pressed mouse " .. pressedMouseButton)
	if scrollMouseButton == pressedMouseButton then
		-- print("scroll");
		deferred = false
		oldmousepos = hs.mouse.getAbsolutePosition()
		local dx = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaX"])
		local dy = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaY"])
		local scroll = hs.eventtap.event.newScrollEvent({ -dx * scrollmult, dy * scrollmult }, {}, "pixel")
		-- put the mouse back
		hs.mouse.setAbsolutePosition(oldmousepos)
		return true, { scroll }
	else
		return false, {}
	end
end)

overrideOtherMouseDown:start()
overrideOtherMouseUp:start()
dragOtherToScroll:start()

-- Special config
if string.match(hs.host.localizedName(), "mbp") then
	pcall(function()
		hs.loadSpoon("FPowerTools"):start()
	end)

	if hasSecrets then
		local PagerDuty = hs.loadSpoon("PagerDuty")
		if secrets.pagerduty_user_id and secrets.pagerduty_api_key ~= "" then
			PagerDuty:start(60, secrets.pagerduty_user_id, secrets.pagerduty_api_key)
		end
	end
end

-- Use Control+` to reload Hammerspoon config
hs.hotkey.bind({ "ctrl" }, "`", nil, function()
	hs.reload()
end)

keyUpDown = function(modifiers, key)
	-- Un-comment & reload config to log each keystroke that we're triggering
	-- log.d('Sending keystroke:', hs.inspect(modifiers), key)

	hs.eventtap.keyStroke(modifiers, key, 0)
end

-- Subscribe to the necessary events on the given window filter such that the
-- given hotkey is enabled for windows that match the window filter and disabled
-- for windows that don't match the window filter.
--
-- windowFilter - An hs.window.filter object describing the windows for which
--                the hotkey should be enabled.
-- hotkey       - The hs.hotkey object to enable/disable.
--
-- Returns nothing.
enableHotkeyForWindowsMatchingFilter = function(windowFilter, hotkey)
	windowFilter:subscribe(hs.window.filter.windowFocused, function()
		hotkey:enable()
	end)

	windowFilter:subscribe(hs.window.filter.windowUnfocused, function()
		hotkey:disable()
	end)
end

require("keyboard")

hs.notify.new({ title = "Hammerspoon", informativeText = "Ready to rock 🤘" }):send()

local function launchOrFocusOrRotate(app)
	local focusedWindow = hs.window.focusedWindow()
	-- Output of the above is an hs.window object

	-- I can get the application it belongs to via the :application() method
	-- See https://www.hammerspoon.org/docs/hs.window.html#application
	local focusedWindowApp = focusedWindow:application()
	-- This returns an hs.application object

	-- Get the name of this application; this isn't really useful fof us as launchOrFocus needs the app name on disk
	-- I do use it below, further on...
	local focusedWindowAppName = focusedWindowApp:name()

	-- This gives the path - /Applications/<application>.app
	local focusedWindowPath = focusedWindowApp:path()

	-- I need to extract <application> from that
	local appNameOnDisk = string.gsub(focusedWindowPath, "/Applications/", "")
	local appNameOnDisk = string.gsub(appNameOnDisk, ".app", "")
	-- Finder has this as its path
	local appNameOnDisk = string.gsub(appNameOnDisk, "/System/Library/CoreServices/", "")

	-- If already focused, try to find the next window
	if focusedWindow and appNameOnDisk == app then
		-- hs.application.get needs the name as per hs.application:name() and not the name on disk
		-- It can also take pid or bundle, but that doesn't help here
		-- Since I have the name already from above, I can use that though
		local appWindows = hs.application.get(focusedWindowAppName):allWindows()

		-- https://www.hammerspoon.org/docs/hs.application.html#allWindows
		-- A table of zero or more hs.window objects owned by the application. From the current space.

		if #appWindows > 0 then
			-- It seems that this list order changes after one window get focused,
			-- Let's directly bring the last one to focus every time
			-- https://www.hammerspoon.org/docs/hs.window.html#focus
			if app == "Finder" then
				-- If the app is Finder the window count returned is one more than the actual count, so I subtract
				appWindows[#appWindows - 1]:focus()
			else
				appWindows[#appWindows]:focus()
			end
		else
			-- this should not happen, but just in case
			hs.application.launchOrFocus(app)
		end
	else -- if not focused
		hs.application.launchOrFocus(app)
	end
end

for i, shortcut in ipairs(WINDOWS_SHORTCUTS) do
	hs.hotkey.bind(window_management_key, shortcut[1], function()
		launchOrFocusOrRotate(shortcut[2])
	end)
end
