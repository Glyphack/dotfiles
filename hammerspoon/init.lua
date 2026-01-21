package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programniling/dotfiles/private/Spoons/?.spoon/init.lua"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/hammerspoon/?.lua"
SpoonInstall = hs.loadSpoon("SpoonInstall")
local fnutils = require("hs.fnutils")
local alert = require("hs.alert")
local ipc = require("hs.ipc")
local window = require("hs.window")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")
local popclick = require("hs.noises")
local hotkey = require("hs.hotkey")
local application = require("hs.application")
local grid = require("hs.grid")
local log = hs.logger.new("hammerspoon", "warning")

local hasCustom, custom = pcall(require, "custom")
local _, _ = pcall(require, "secrets")
require("karabiner")

if ipc.cliStatus() ~= true then
	ipc.cliInstall()
end

-- UTILS

local function moveMouseToWindowCenter(win)
	timer.doAfter(0.01, function()
		local frame = win:frame()
		local centerPoint = {
			x = frame.x + frame.w / 2,
			y = frame.y + frame.h / 2,
		}
		hs.mouse.absolutePosition(centerPoint)
	end)
end

local previousWindow = nil
local function launchOrFocusOrRotate(app)
	local focusedWindow = hs.window.focusedWindow()
	if focusedWindow == nil then
		application.launchOrFocus(app)
		timer.doAfter(0.1, function()
			local win = hs.window.focusedWindow()
			if win then
				moveMouseToWindowCenter(win)
			end
		end)
		return
	end

	-- See https://www.hammerspoon.org/docs/hs.window.html#application
	local focusedWindowApp = focusedWindow:application()
	local focusedWindowAppName = focusedWindowApp:name()
	local focusedWindowPath = focusedWindowApp:path()
	local appNameOnDisk = string.gsub(focusedWindowPath, "/Applications/", "")
	local appNameOnDisk = string.gsub(appNameOnDisk, ".app", "")
	local appNameOnDisk = string.gsub(appNameOnDisk, "/System/Library/CoreServices/", "")
	if focusedWindow and appNameOnDisk == app then
		local currentApp = application.get(focusedWindowAppName)
		local appWindows = currentApp:allWindows()
		if #appWindows == 1 then
			-- Instead of hiding, focus the previous window if it exists
			if previousWindow and previousWindow:isVisible() then
				previousWindow:focus()
				moveMouseToWindowCenter(previousWindow)
			else
				currentApp:hide()
			end
			return
		end

		if #appWindows > 0 then
			-- Store current window as previous before switching
			previousWindow = focusedWindow

			-- It seems that this list order changes after one window get focused,
			-- Let's directly bring the last one to focus every time
			-- https://www.hammerspoon.org/docs/hs.window.html#focus
			local targetWin
			if app == "Finder" then
				-- If the app is Finder the window count returned is one more than the actual count, so I subtract
				targetWin = appWindows[#appWindows - 1]
				targetWin:focus()
			else
				targetWin = appWindows[#appWindows]
				targetWin:focus()
			end
			moveMouseToWindowCenter(targetWin)
		else
			application.launchOrFocus(app)
			timer.doAfter(0.1, function()
				local win = hs.window.focusedWindow()
				if win then
					moveMouseToWindowCenter(win)
				end
			end)
		end
	else
		-- Store current window as previous before switching to different app
		previousWindow = focusedWindow

		application.launchOrFocus(app)
		timer.doAfter(0.1, function()
			local win = hs.window.focusedWindow()
			if win then
				moveMouseToWindowCenter(win)
			end
		end)
	end
end

function SendClickableNotification(notification, link)
	local function notificationCallback()
		hs.urlevent.openURL(link)
	end
	local notificationObject = hs.notify.new(notificationCallback, notification)
	notificationObject:send()
end

local function findScreenByName(name)
	for _, screen in ipairs(hs.screen.allScreens()) do
		if screen:name() == name then
			return screen
		end
	end
	return nil
end

local function moveAppToScreen(app, screenName, matchedPattern)
	local screen = findScreenByName(screenName)
	if not screen then
		log.w("Screen not found: " .. screenName)
		return
	end
	timer.doAfter(0.1, function()
		local wins = app:allWindows()
		for _, win in ipairs(wins) do
			log.d("Moving " .. app:name() .. " (matched: " .. matchedPattern .. ") to " .. screenName)
			win:moveToScreen(screen, true, true)
		end
	end)
end

local function openApp(bundle)
	local app = application.get(bundle)

	if not app then
		app = application.open(bundle, 1, false)
	else
		app:hide()
	end

	return app
end

grid.GRIDWIDTH = 6
grid.GRIDHEIGHT = 8
grid.MARGINX = 0
grid.MARGINY = 0
grid.setMargins({ w = 0, h = 0 })

local function applyPlace(win, place)
	local scrs = hs.screen.allScreens()
	local scr = nil
	if place[1] ~= nil then
		scr = scrs[place[1]]
	end
	grid.set(win, place[2], scr)
end

local function applyLayout(layout)
	return function()
		for appName, place in pairs(layout) do
			local app = application.get(appName)
			if app then
				for _, win in ipairs(app:allWindows()) do
					applyPlace(win, place)
				end
			end
		end
	end
end

local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT
local goleft = { x = 0, y = 0, w = gw / 2, h = gh }
local goright = { x = gw / 2, y = 0, w = gw / 2, h = gh }
local goup = { x = 0, y = 0, w = gw, h = gh / 2 }
local godown = { x = 0, y = gh / 2, w = gw, h = gh / 2 }
local gobig = { x = 0, y = 0, w = gw, h = gh }
local function moveWindow(position)
	return function()
		local win = hs.window.focusedWindow()
		if win then
			applyPlace(win, { nil, position })
		end
	end
end

-- WINDOW
local HYPER = { "cmd", "ctrl", "alt" }

HOME_MONITOR = "DELL U2723QE"
MACBOOK_MONITOR = "Built-in Retina Display"
LG_MONITOR = "LG HDR 4K"

WINDOWS_TO_PRIMARY = {
	"Pokerface - The Best Poker Game",
}
WINDOWS_TO_BIG_SCREEN = {
	"WezTerm",
}

-- Some of the shortcuts are still on Raycast, need to move them here
-- 1. Daily Schedule
WINDOWS_SHORTCUTS = {
	{ "U", "qutebrowser" },
	{ "J", "Brave Browser" },
	{ "K", "WezTerm" },
	{ "O", "Obsidian" },
	{ "P", "OBS" },
	{ "Y", "Discord" },
}
if hasCustom then
	WINDOWS_SHORTCUTS = fnutils.concat(WINDOWS_SHORTCUTS, custom.WINDOWS_SHORTCUTS)
end

for _, shortcut in ipairs(WINDOWS_SHORTCUTS) do
	hotkey.bind(HYPER, shortcut[1], function()
		launchOrFocusOrRotate(shortcut[2])
	end)
end

SavedWin = nil
function SaveFocus()
	SavedWin = window.focusedWindow()
	alert.show("Window '" .. SavedWin:title() .. "' saved.")
end
function FocusSaved()
	if SavedWin then
		SavedWin:focus()
	end
end

-- Layout positions

-- left
hotkey.bind(HYPER, "a", moveWindow(goleft))
-- right
hotkey.bind(HYPER, "d", moveWindow(goright))
-- up
hotkey.bind(HYPER, "w", moveWindow(goup))
-- down
hotkey.bind(HYPER, "s", moveWindow(godown))
-- center
hotkey.bind(HYPER, "c", function()
	local win = hs.window.focusedWindow()
	if win then
		win:centerOnScreen()
	end
end)
-- full screen
hotkey.bind(HYPER, "i", moveWindow(gobig))
hotkey.bind(HYPER, "g", grid.show)

-- Layout configuration for Brave + WezTerm split screen
local braveWezTermLayout = {
	["Brave Browser"] = { 1, goleft },
	["WezTerm"] = { 1, goright },
}

-- Bind layout to Hyper+5
hotkey.bind(HYPER, "6", applyLayout(braveWezTermLayout))

SpoonInstall:andUse("WindowScreenLeftAndRight", {
	config = {
		animationDuration = 0,
	},
	hotkeys = {
		screen_left = { HYPER, "[" },
		screen_right = { HYPER, "]" },
	},
})

local function handleAppLaunch(appName, eventType, app)
	if eventType ~= application.watcher.launched then
		return
	end

	local screens = hs.screen.allScreens()
	if #screens <= 1 then
		log.d("[WindowPlacement] Skipping - only one screen")
		return
	end

	log.d("[WindowPlacement] App launched: " .. appName)

	local function matches(pattern)
		if appName == pattern then
			return true
		end
		local wins = app:allWindows()
		for _, win in ipairs(wins) do
			local title = win:title() or ""
			if title:find(pattern, 1, true) then
				return true
			end
		end
		return false
	end

	for _, pattern in ipairs(WINDOWS_TO_PRIMARY) do
		if matches(pattern) then
			moveAppToScreen(app, MACBOOK_MONITOR, pattern)
			return
		end
	end

	for _, pattern in ipairs(WINDOWS_TO_BIG_SCREEN) do
		if matches(pattern) then
			moveAppToScreen(app, HOME_MONITOR, pattern)
			return
		end
	end
end

local appWatcher = application.watcher.new(handleAppLaunch)
appWatcher:start()

-- SOUND
TOGGLE_MUTE_SHORTCUT = { HYPER, "t" }

local GlobalMute = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
	toggle = TOGGLE_MUTE_SHORTCUT,
})
GlobalMute:configure({})
GlobalMute:unmute()

local PREFERRED_OUT = {
	"WH-1000XM5",
	"Farbod's JBL Flip 6",
	"External Headphones",
	"MacBook Pro Speakers",
	"Mac mini Speakers",
}

local PREFERRED_IN = {
	"Yeti Stereo Microphone",
	"Anker PowerConf C200",
	"MacBook Pro Microphone",
}

local function audiodeviceCallback(event)
	log.d("audiodeviceDeviceCallback: " .. event)
	if event == "dev#" then
		timer.doAfter(2, function()
			for _, name in ipairs(PREFERRED_IN) do
				local device = hs.audiodevice.findInputByName(name)
				if device then
					device:setDefaultInputDevice()
					break
				end
			end

			for _, name in ipairs(PREFERRED_OUT) do
				local device = hs.audiodevice.findOutputByName(name)
				if device then
					device:setDefaultOutputDevice()
					break
				end
			end
		end)
	end
end

hs.audiodevice.watcher.setCallback(audiodeviceCallback)
hs.audiodevice.watcher.start()

audiodeviceCallback("dev#")

local function screenCallback(layout)
	if layout == true then
		log.d("Screen did not change")
		return
	end
	local screens = hs.screen.allScreens()
	for _, screen in pairs(screens) do
		if screen:name() ~= MACBOOK_MONITOR then
			log.i("Setting " .. screen:name() .. " as primary")
			screen:setPrimary()

			-- Runs too slow
			-- local macbookScreen = findScreenByName(MACBOOK_MONITOR)
			-- local externalScreen = screen
			--
			-- if not macbookScreen or not externalScreen then
			-- 	log.w("Could not find both screens for window placement")
			-- 	return
			-- end
			--
			-- local allApps = application.runningApplications()
			-- for _, app in ipairs(allApps) do
			-- 	local appName = app:name()
			-- 	local windows = app:allWindows()
			--
			-- 	for _, win in ipairs(windows) do
			-- 		if appName == "WezTerm" then
			-- 			log.d("Moving WezTerm to external screen")
			-- 			win:moveToScreen(externalScreen, true, true)
			-- 			applyPlace(win, { 1, gobig })
			-- 		else
			-- 			log.d("Moving " .. appName .. " to MacBook screen")
			-- 			win:moveToScreen(macbookScreen, true, true)
			-- 		end
			-- 	end
			-- end

			timer.doAfter(2, function()
				openApp("/Applications/flameshot.app")
			end)

			return
		end
	end
end

local screenDebounceTimer = nil
hs.screen.watcher
	.newWithActiveScreen(function(layout)
		if screenDebounceTimer then
			screenDebounceTimer:stop()
			screenDebounceTimer = nil
		end
		screenDebounceTimer = hs.timer.doAfter(0.6, function()
			screenCallback(layout)
		end)
	end)
	:start()
screenCallback(false)

-- scroll with mouse button
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
	if scrollMouseButton == pressedMouseButton then
		deferred = false
		oldmousepos = hs.mouse.absolutePosition()
		local dx = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaX"])
		local dy = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaY"])
		local scroll = hs.eventtap.event.newScrollEvent({ -dx * scrollmult, dy * scrollmult }, {}, "pixel")
		-- put the mouse back
		hs.mouse.absolutePosition(oldmousepos)
		return true, { scroll }
	else
		return false, {}
	end
end)

overrideOtherMouseDown:start()
overrideOtherMouseUp:start()
dragOtherToScroll:start()

-- NOISE-BASED SCROLLING
local Scroller = {}
Scroller.__index = Scroller

function Scroller.new(delay, tick)
	return setmetatable({ delay = delay, tick = tick, timer = nil }, Scroller)
end

function Scroller:start()
	if self.timer == nil then
		self.timer = timer.doEvery(self.delay, function()
			eventtap.scrollWheel({ 0, self.tick }, {}, "pixel")
		end)
	end
end

function Scroller:stop()
	if self.timer then
		self.timer:stop()
		self.timer = nil
	end
end

local scrollState = {
	listener = nil,
	active = false,
	scrollDown = Scroller.new(0.02, -10),
	mode = false,
}

local function handleNoiseEvent(evNum)
	if evNum == 3 then
		scrollState.mode = not scrollState.mode
		alert.show(scrollState.mode and "Scroll Mode ON" or "Scroll Mode OFF")
	elseif evNum == 1 and scrollState.mode then
		scrollState.scrollDown:start()
	elseif evNum == 2 then
		scrollState.scrollDown:stop()
	end
end

local function initNoiseScrolling()
	scrollState.listener = popclick.new(handleNoiseEvent)
	scrollState.listener:start()
	scrollState.active = true
	log.i("Noise scrolling initialized")
end

-- initNoiseScrolling()

hotkey.bind({ "ctrl" }, "`", nil, function()
	hs.reload()
end)

local wm = hs.webview.windowMasks
SpoonInstall:andUse("PopupTranslateSelection", {
	disable = false,
	config = {
		popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable,
	},
	hotkeys = {
		translate_nl_en = { HYPER, "\\" },
	},
})

-- function printWindowsTitle()
-- 	local windows = hs.window.allWindows()
-- 	for _, win in ipairs(windows) do
-- 		log.i(win:title())
-- 	end
-- end
-- function printScreenNames()
-- 	local screens = hs.screen.allScreens()
-- 	for i, screen in ipairs(screens) do
-- 		log.i(string.format("Screen %d: %s", i, screen:name()))
-- 	end
-- end
