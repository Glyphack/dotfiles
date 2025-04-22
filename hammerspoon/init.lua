HOME_MONITOR = "DELL U2723QE"
MACBOOK_MONITOR = "Built-in Retina Display"
LG_MONITOR = "LG HDR 4K"

package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/private/Spoons/?.spoon/init.lua"

SpoonInstall = hs.loadSpoon("SpoonInstall")

local hasCustom, custom = pcall(require, "custom")

if hasCustom then
	print("Loaded custom settings")
end

-- My shortcuts
-- Some of the shortcuts are still on Raycast, need to move them here
-- 1. Daily Schedule
WINDOW_MANAGEMENT_KEY = { "alt", "command", "ctrl" }
WINDOWS_SHORTCUTS = {
	{ "J", "Brave Browser" },
	{ "K", "WezTerm" },
	{ "O", "Obsidian" },
	{ "P", "OBS" },
	{ "Y", "Discord" },
	{ "U", "qutebrowser" },
	{ "'", "Visual Studio Code" },
}
if hasCustom then
	WINDOWS_SHORTCUTS = custom.WINDOWS_SHORTCUTS
end
require("keyboard")

TOGGLE_MUTE_SHORTCUT = { WINDOW_MANAGEMENT_KEY, "t" }

local hasSecrets, secrets = pcall(require, "secrets")
local GlobalMute = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
	toggle = TOGGLE_MUTE_SHORTCUT,
})
GlobalMute:configure({
	unmute_background = "file:///Library/Desktop%20Pictures/Solid%20Colors/Red%20Orange.png",
	mute_background = "file:///Library/Desktop%20Pictures/Solid%20Colors/Turquoise%20Green.png",
})

function SendClickableNotification(notification, link)
	local function notificationCallback()
		hs.urlevent.openURL(link)
	end
	local notificationObject = hs.notify.new(notificationCallback, notification)
	notificationObject:send()
end

local function useDefaultAudioDevice()
	local jbl_speaker = hs.audiodevice.findOutputByName("JBL Flip 6")
	if jbl_speaker then
		jbl_speaker:setDefaultOutputDevice()
		return
	end
	local mbp_speaker = hs.audiodevice.findOutputByName("MacBook Pro Speakers")
	if mbp_speaker then
		mbp_speaker:setDefaultOutputDevice()
		return
	end
	local mac_mini_speaker = hs.audiodevice.findOutputByName("Mac mini Speakers")
	if mac_mini_speaker then
		mac_mini_speaker:setDefaultOutputDevice()
		return
	end
end

local function selectInputDecide()
	local current = hs.audiodevice.defaultInputDevice():name()
	print("Current device: " .. current)
	if current == "External Microphone" then
		print("Forcing default output to Internal Speakers")
		useDefaultAudioDevice()
	end
	local blue_yeti_mic = hs.audiodevice.findInputByName("Yeti Stereo Microphone")
	if blue_yeti_mic ~= nil then
		blue_yeti_mic:setDefaultInputDevice()
	end
end

local function switchToJblFilip6AfterConnect()
	local jbl_speaker = hs.audiodevice.findOutputByName("JBL Flip 6")
	if jbl_speaker then
		jbl_speaker:setDefaultOutputDevice()
		return
	end
end

local function audiodeviceCallback(event)
	print("audiodeviceDeviceCallback: " .. event)
	if event == "dIn " then
		selectInputDecide()
	end
	if even == "dOut" then
		switchToJblFilip6AfterConnect()
	end
end

hs.audiodevice.watcher.setCallback(audiodeviceCallback)
hs.audiodevice.watcher.start()

selectInputDecide()

-- set the other screen than macbook as primary
local function setPrimary()
	local screens = hs.screen.allScreens()
	for _, screen in pairs(screens) do
		if screen:name() ~= MACBOOK_MONITOR then
			print("Setting " .. screen:name() .. " as primary")
			screen:setPrimary()
			local monitor_control_bundle = "/Applications/MonitorControl.app"
			local monitor_c = hs.application.find(monitor_control_bundle, false, false)
			if monitor_c == nil then
				hs.application.open(monitor_control_bundle)
			end
		end
	end
end

local function openApp(bundle)
	local app = hs.application.get(bundle)

	if not app then
		app = hs.application.open(bundle, 1, false)
		app:hide()
	else
		app:hide()
	end

	return app
end

local function screenCallback(layout)
	openApp("/Applications/flameshot.app")
	if layout == true then
		print("Screen did not change")
		return
	end
	setPrimary()
end

hs.screen.watcher.newWithActiveScreen(screenCallback):start()
setPrimary()

-- left
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "a", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0, 0.5, 1 })
end)
-- right
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "d", function()
	hs.window.focusedWindow():moveToUnit({ 0.5, 0, 0.5, 1 })
end)
-- up
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "w", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0, 1, 0.5 })
end)
-- down
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "s", function()
	hs.window.focusedWindow():moveToUnit({ 0, 0.5, 1, 0.5 })
end)
-- center
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "c", function()
	hs.window.focusedWindow():centerOnScreen()
end)
-- full screen
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "i", function()
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
hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, "g", hs.grid.show)

-- size for recording
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "r", function()
	hs.window.focusedWindow():setSize({ w = 640, h = 360 })
end)

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
		oldmousepos = hs.mouse.absolutePosition()
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

hs.notify.new({ title = "Hammerspoon", informativeText = "Ready to rock 🤘" }):send()

SpoonInstall:andUse("WindowScreenLeftAndRight", {
	config = {
		animationDuration = 0,
	},
	hotkeys = {
		screen_left = { WINDOW_MANAGEMENT_KEY, "[" },
		screen_right = { WINDOW_MANAGEMENT_KEY, "]" },
	},
})

local wm = hs.webview.windowMasks
SpoonInstall:andUse("PopupTranslateSelection", {
	disable = false,
	config = {
		popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable,
	},
	hotkeys = {
		translate_nl_en = { WINDOW_MANAGEMENT_KEY, "\\" },
	},
})
