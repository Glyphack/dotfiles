package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/private/Spoons/?.spoon/init.lua"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/hammerspoon/?.lua"
SpoonInstall = hs.loadSpoon("SpoonInstall")
local alert = require("hs.alert")
local ipc = require("hs.ipc")
local window = require("hs.window")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")
local popclick = require("hs.noises")
local hotkey = require("hs.hotkey")
require("hs.task")
local application = require("hs.application")
local grid = require("hs.grid")
local log = hs.logger.new("hammerspoon", "info")

HYPER = { "cmd", "ctrl", "alt" }

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

local function centerMouseOnFocusedWindow()
	timer.doAfter(0.1, function()
		local win = hs.window.focusedWindow()
		if win then
			moveMouseToWindowCenter(win)
		end
	end)
end

local function windowBelongsToApp(win, appName)
	-- See https://www.hammerspoon.org/docs/hs.window.html#application
	local path = win:application():path()
	local nameOnDisk = string.gsub(path, "/Applications/", "")
	nameOnDisk = string.gsub(nameOnDisk, ".app", "")
	nameOnDisk = string.gsub(nameOnDisk, "/System/Library/CoreServices/", "")
	return nameOnDisk:find(appName, 1, true) ~= nil
end

local APP_LAUNCH_RETRY_DELAY = 0.3
local APP_LAUNCH_MAX_ATTEMPTS = 20

local function escapeForAppleScript(text)
	return (text:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

-- Tabs are driven over AppleScript, which covers Chromium based browsers such
-- as Chrome, Brave and Edge. macOS asks once for permission to control the
-- browser and every script here fails until that is granted.
local browserTabs = {}

function browserTabs.run(appName, body)
	local script = string.format('tell application "%s"\n%s\nend tell', escapeForAppleScript(appName), body)
	local ok, result, err = hs.osascript.applescript(script)
	if not ok then
		log.w("browser script failed for " .. appName .. ": " .. hs.inspect(err))
	end
	return ok, result
end

-- Brings forward the first tab in any window whose title or address contains
-- the pattern.
function browserTabs.focus(target)
	local pattern = escapeForAppleScript(target.tab)
	local ok, found = browserTabs.run(
		target.app,
		string.format(
			[[
	repeat with theWindow in windows
		set tabIndex to 0
		repeat with theTab in tabs of theWindow
			set tabIndex to tabIndex + 1
			if (title of theTab contains "%s") or (URL of theTab contains "%s") then
				set active tab index of theWindow to tabIndex
				set index of theWindow to 1
				return true
			end if
		end repeat
	end repeat
	return false]],
			pattern,
			pattern
		)
	)
	return ok and found == true
end

function browserTabs.openURL(target)
	local url = escapeForAppleScript(target.url)
	local ok = browserTabs.run(
		target.app,
		string.format(
			[[
	if (count of windows) is 0 then
		make new window
		set URL of active tab of front window to "%s"
	else
		tell front window to make new tab with properties {URL:"%s"}
		set index of front window to 1
	end if]],
			url,
			url
		)
	)
	return ok
end

-- Focuses the tab matching target.tab, and opens target.url in a new tab when
-- no tab matches.
local function selectTabOrOpenURL(app, target)
	if browserTabs.focus(target) then
		return
	end
	if not target.url then
		return
	end
	if browserTabs.openURL(target) then
		return
	end
	hs.urlevent.openURLWithBundle(target.url, app:bundleID())
end

local function focusPreviousOrHide(app)
	if previousWindow and previousWindow:isVisible() then
		previousWindow:focus()
		moveMouseToWindowCenter(previousWindow)
		return
	end
	app:hide()
end

local function rotateWindows(app, appName)
	local appWindows = app:allWindows()
	if #appWindows <= 1 then
		focusPreviousOrHide(app)
		return
	end

	previousWindow = hs.window.focusedWindow()
	-- The window list order changes after one window gets focused,
	-- so directly bring the last one to focus every time
	-- https://www.hammerspoon.org/docs/hs.window.html#focus
	local targetWin = appWindows[#appWindows]
	if appName == "Finder" then
		-- Finder reports one more window than actually exists, so subtract one
		targetWin = appWindows[#appWindows - 1]
	end
	targetWin:focus()
	moveMouseToWindowCenter(targetWin)
end

local function withApp(appName, fn, attempt)
	attempt = attempt or 1
	local app = application.get(appName)
	if app then
		fn(app)
		return
	end
	if attempt >= APP_LAUNCH_MAX_ATTEMPTS then
		log.w("App never showed up: " .. appName)
		return
	end
	timer.doAfter(APP_LAUNCH_RETRY_DELAY, function()
		withApp(appName, fn, attempt + 1)
	end)
end

local function openTarget(target)
	application.launchOrFocus(target.app)
	if target.tab then
		withApp(target.app, function(app)
			selectTabOrOpenURL(app, target)
		end)
	end
	centerMouseOnFocusedWindow()
end

-- target is an app name string or a table { app = "...", tab = "...", url = "..." }.
-- When tab is set, focuses the app tab whose title matches; if no tab matches
-- and url is set, opens the url in the app instead.
-- Pressing the shortcut again while the target is focused goes back to the
-- previous window (or hides the app); multi-window apps rotate their windows.
function launchOrFocusOrRotate(target)
	if type(target) == "string" then
		target = { app = target }
	end
	log.d("launchOrFocusOrRotate: " .. target.app .. (target.tab and (" tab=" .. target.tab) or ""))

	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow or not windowBelongsToApp(focusedWindow, target.app) then
		previousWindow = focusedWindow
		openTarget(target)
		return
	end

	local app = focusedWindow:application()
	if not target.tab then
		rotateWindows(app, target.app)
		return
	end

	local title = focusedWindow:title() or ""
	if title:find(target.tab, 1, true) then
		focusPreviousOrHide(app)
		return
	end
	selectTabOrOpenURL(app, target)
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

-- Maximizes the focused window on the screen it currently sits on. Triggering
-- it again restores the pre-maximize frame, but only while the window is still
-- on that same screen; otherwise it just maximizes on the new screen.
local maximizeToggle = {
	savedFrames = {},
}

function maximizeToggle:toggle()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end
	local id = win:id()
	if not id then
		return
	end
	local screen = win:screen()
	local saved = self.savedFrames[id]
	if saved and saved.screenId == screen:id() then
		win:setFrame(saved.frame)
		self.savedFrames[id] = nil
		return
	end
	self.savedFrames[id] = { frame = win:frame(), screenId = screen:id() }
	win:setFrame(screen:frame())
end

-- WINDOW

HOME_MONITOR = "DELL U2723QE"
MACBOOK_MONITOR = "Built-in Retina Display"
LG_MONITOR = "LG HDR 4K"

WINDOWS_TO_PRIMARY = {
	"",
}
WINDOWS_TO_BIG_SCREEN = {
	"",
}

local braveWezTermLayout = {
	["Brave Browser"] = { 1, goleft },
	["WezTerm"] = { 1, goright },
}

-- { name, mods, key, desc, fn }
-- fn = nil means binding is managed by a Spoon (use GetShortcut to look up)
SHORTCUTS = {
	-- App Launching
	{
		"app_qutebrowser",
		HYPER,
		"u",
		"qutebrowser",
		function()
			launchOrFocusOrRotate("qutebrowser")
		end,
	},
	{
		"app_brave",
		HYPER,
		"j",
		"Brave Browser",
		function()
			launchOrFocusOrRotate("Brave Browser")
		end,
	},
	{
		"app_wezterm",
		HYPER,
		"k",
		"WezTerm",
		function()
			launchOrFocusOrRotate("WezTerm")
		end,
	},
	{
		"app_obsidian",
		HYPER,
		"o",
		"Obsidian",
		function()
			launchOrFocusOrRotate("Obsidian")
		end,
	},
	{
		"app_obs",
		HYPER,
		"p",
		"OBS",
		function()
			launchOrFocusOrRotate("OBS")
		end,
	},
	{
		"app_discord",
		HYPER,
		"y",
		"Discord",
		function()
			launchOrFocusOrRotate("Discord")
		end,
	},
	{
		"app_teams",
		HYPER,
		"1",
		"Teams tab in Chrome",
		function()
			launchOrFocusOrRotate({
				app = "Google Chrome",
				tab = "Microsoft Teams",
				url = "https://teams.microsoft.com",
			})
		end,
	},
	-- Window Management
	{ "snap_left", HYPER, "a", "snap left", moveWindow(goleft) },
	{ "snap_right", HYPER, "d", "snap right", moveWindow(goright) },
	{ "snap_top", HYPER, "w", "snap top", moveWindow(goup) },
	{ "snap_bottom", HYPER, "s", "snap bottom", moveWindow(godown) },
	{
		"center",
		HYPER,
		"c",
		"center window",
		function()
			local w = hs.window.focusedWindow()
			if w then
				w:centerOnScreen()
			end
		end,
	},
	{
		"fullscreen",
		HYPER,
		"i",
		"toggle full screen",
		function()
			maximizeToggle:toggle()
		end,
	},
	{ "grid", HYPER, "g", "show grid", grid.show },
	{ "layout_split", HYPER, "6", "Brave+WezTerm split", applyLayout(braveWezTermLayout) },
	-- Screen (Spoon-managed)
	{ "screen_left", HYPER, "[", "move to left screen", nil },
	{ "screen_right", HYPER, "]", "move to right screen", nil },
	-- Audio (Spoon-managed)
	{ "toggle_mute", HYPER, "t", "toggle mic mute", nil },
	-- Translation (Spoon-managed)
	{ "translate", HYPER, "\\", "translate selection", nil },
	-- Misc
	{
		"reload",
		{ "ctrl" },
		"`",
		"reload config",
		function()
			hs.reload()
		end,
	},
}

function GetShortcut(name)
	for _, s in ipairs(SHORTCUTS) do
		if s[1] == name then
			return { s[2], s[3] }
		end
	end
	error("Shortcut not found: " .. name)
end

-- An entry reusing an existing name replaces it instead of adding a second
-- binding for the same key, where whichever bound last would silently win.
local function mergeShortcuts(base, extra)
	local indexByName = {}
	for i, s in ipairs(base) do
		indexByName[s[1]] = i
	end
	for _, s in ipairs(extra) do
		local existing = indexByName[s[1]]
		if existing then
			base[existing] = s
		else
			table.insert(base, s)
			indexByName[s[1]] = #base
		end
	end
	return base
end

if hasCustom and custom.SHORTCUTS then
	SHORTCUTS = mergeShortcuts(SHORTCUTS, custom.SHORTCUTS)
end

for _, s in ipairs(SHORTCUTS) do
	if s[5] then
		hotkey.bind(s[2], s[3], s[5])
	end
end

function ShowShortcuts()
	print("=== Shortcuts (HYPER = Cmd+Ctrl+Alt) ===")
	for _, s in ipairs(SHORTCUTS) do
		local mods = table.concat(s[2], "+")
		print(string.format("  %-20s  %s", mods .. "+" .. s[3], s[4]))
	end
end
ShowShortcuts()

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

SpoonInstall:andUse("WindowScreenLeftAndRight", {
	config = {
		animationDuration = 0,
	},
	hotkeys = {
		screen_left = GetShortcut("screen_left"),
		screen_right = GetShortcut("screen_right"),
	},
})

-- Opens http(s) URLs in the first app whose pattern matches; unmatched URLs
-- go to the default handler. Hammerspoon must be set as the system default
-- browser for URLs to be routed through this.
SpoonInstall:andUse("URLDispatcher", {
	config = {
		url_patterns = {
			{ "teams%.microsoft%.com", "com.google.Chrome" },
			{ "^https://github%.com/letsrotate/", "com.google.Chrome" },
			{ "cloud%.databricks%.com", "com.google.Chrome" },
			{ "^https://letsrotate.atlassian.net/", "com.google.Chrome" },
		},
		default_handler = "com.brave.Browser",
	},
	start = true,
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

local autostart = {
	apps = {
		"Todoist",
		"Igloo",
		"Whispertron",
		"Flameshot",
	},
	pending = {},
	watcher = nil,
}

function autostart:hideApp(app)
	for _, delay in ipairs({ 0, 0.5, 1.5, 3 }) do
		timer.doAfter(delay, function()
			if not app:isHidden() then
				app:hide()
			end
		end)
	end
end

function autostart:stop()
	if not self.watcher then
		return
	end
	self.watcher:stop()
	self.watcher = nil
end

function autostart:onAppEvent(appName, eventType, app)
	if eventType ~= application.watcher.launched or appName == nil then
		return
	end
	local key = appName:lower()
	if not self.pending[key] then
		return
	end
	self.pending[key] = nil
	self:hideApp(app)
	if next(self.pending) == nil then
		self:stop()
	end
end

function autostart:start()
	local toLaunch = {}
	for _, name in ipairs(self.apps) do
		if not application.get(name) then
			table.insert(toLaunch, name)
			self.pending[name:lower()] = true
		end
	end
	if #toLaunch == 0 then
		return
	end
	self.watcher = application.watcher.new(function(appName, eventType, app)
		self:onAppEvent(appName, eventType, app)
	end)
	self.watcher:start()
	timer.doAfter(60, function()
		self:stop()
	end)
	for _, name in ipairs(toLaunch) do
		hs.task.new("/usr/bin/open", nil, { "-gj", "-a", name }):start()
	end
end

autostart:start()

-- SOUND
local GlobalMute = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
	toggle = GetShortcut("toggle_mute"),
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

-- Hue Automation
local HOME_WIFI = "tardis"
local HUE_LIGHTS_ON_START_HOUR = 18
local HUE_LIGHTS_ON_END_HOUR = 23
local FISH_SHELL = "/opt/homebrew/bin/fish"

local function fishRunCommand(command)
	local task, taskErr = hs.task.new(FISH_SHELL, function(exitCode, stdout, stderr)
		if exitCode == 0 then
			if stdout ~= nil and stdout ~= "" then
				log.i(command .. " output: " .. stdout)
			end
			return
		end

		log.w(command .. " failed (exit " .. tostring(exitCode) .. "): " .. tostring(stderr))
	end, { "-lc", command })

	if not task then
		log.w("Failed to create task for " .. command .. ": " .. tostring(taskErr))
		return
	end

	if not task:start() then
		log.w("Failed to start task for " .. command)
	end
end

local wm = hs.webview.windowMasks
SpoonInstall:andUse("PopupTranslateSelection", {
	disable = false,
	config = {
		popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable,
	},
	hotkeys = {
		translate_nl_en = GetShortcut("translate"),
	},
})

local function printWindowsTitle()
	local windows = hs.window.allWindows()
	for _, win in ipairs(windows) do
		log.i(win:title())
	end
end
local function printScreenNames()
	local screens = hs.screen.allScreens()
	for i, screen in ipairs(screens) do
		log.i(string.format("Screen %d: %s", i, screen:name()))
	end
end

local function bluetoothOn()
	local _, btOn = hs.execute("/usr/sbin/system_profiler SPBluetoothDataType 2>/dev/null | grep -q 'State: On'")
	if not btOn then
		return false
	end
	return true
end

function HueEnableAlarms()
	if hs.wifi.currentNetwork() ~= HOME_WIFI then
		return
	end

	if bluetoothOn() == false then
		return
	end

	fishRunCommand("hue_auto_alarm.py")
end

function WifiChanged()
	if hs.wifi.currentNetwork() ~= HOME_WIFI then
		local speaker = hs.audiodevice.defaultOutputDevice()
		if speaker then
			speaker:setMuted(true)
		else
			log.w("No default output device found to mute")
		end
		return
	end

	HueEnableAlarms()
end

local wifiWatcher = hs.wifi.watcher.new(WifiChanged)
wifiWatcher:start()
WifiChanged()

function HueTurnOn()
	local currentHour = os.date("*t").hour
	local shouldTurnOn = currentHour >= HUE_LIGHTS_ON_START_HOUR and currentHour < HUE_LIGHTS_ON_END_HOUR
	log.i(shouldTurnOn)
	if shouldTurnOn == false then
		return
	end

	if bluetoothOn() == false then
		return
	end

	fishRunCommand("huec power on")
end

function ToggleLights(eventType)
	log.i("event: " .. eventType)
	if eventType == hs.caffeinate.watcher.screensDidUnlock or eventType == hs.caffeinate.watcher.systemDidWake then
		HueTurnOn()
		HueEnableAlarms()
	elseif
		eventType == hs.caffeinate.watcher.screensDidLock
		or eventType == hs.caffeinate.watcher.systemWillSleep
		or eventType == hs.caffeinate.watcher.systemWillPowerOff
		or eventType == hs.caffeinate.watcher.screensDidSleep
	then
	end
end

local lightsWatcher = hs.caffeinate.watcher.new(ToggleLights)
lightsWatcher:start()
