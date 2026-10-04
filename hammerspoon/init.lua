-- Omacy load DO NOT EDIT
require("hs.ipc")
local omacy = nil
if hs.spoons.isInstalled("Omacy") then
	hs.loadSpoon("Omacy")
	omacy = spoon.Omacy
else
	print("omacy is not installed on this machine, its Hammerspoon shortcuts stay off")
end
-- Omacy load DO NOT EDIT

package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/private/Spoons/?.spoon/init.lua"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/Programming/dotfiles/hammerspoon/?.lua"
SpoonInstall = hs.loadSpoon("SpoonInstall")
SpoonInstall:andUse("ReloadConfiguration", {
	config = {
		watch_paths = { os.getenv("HOME") .. "/Programming/dotfiles/hammerspoon" },
	},
	start = true,
})
local ipc = require("hs.ipc")
local timer = require("hs.timer")
require("hs.task")
local application = require("hs.application")
local log = hs.logger.new("hammerspoon", "info")

if ipc.cliStatus() ~= true then
	ipc.cliInstall()
end

-- Setup

omacy:map(omacy.HYPER, "u", function()
	omacy.focus.launchOrFocusOrRotate({ app = "org.qutebrowser.qutebrowser" })
end, "qutebrowser")
omacy:map(omacy.HYPER, "o", function()
	omacy.focus.launchOrFocusOrRotate({ app = "md.obsidian" })
end, "Obsidian")
omacy:map(omacy.HYPER, "p", function()
	omacy.focus.launchOrFocusOrRotate({ app = "com.obsproject.obs-studio" })
end, "OBS")
omacy:map(omacy.HYPER, "y", function()
	omacy.focus.launchOrFocusOrRotate({ app = "com.hnc.Discord" })
end, "Discord")

local wm = hs.webview.windowMasks
omacy:map(omacy.HYPER, "\\", function()
	omacy.translate:translateSelectionPopup({
		from = "nl",
		to = "en",
		popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable,
	})
end, "translate selection")

pcall(require, "local")

omacy:showShortcuts()

-- UTILS

function SendClickableNotification(notification, link)
	local function notificationCallback()
		hs.urlevent.openURL(link)
	end
	local notificationObject = hs.notify.new(notificationCallback, notification)
	notificationObject:send()
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

omacy.autostart.launch({
	"com.todoist.mac.Todoist",
	"com.glyphack.whispertron",
	"org.flameshot.Flameshot",
	"com.raycast.macos",
	"app.monitorcontrol.MonitorControl",
})

-- SOUND
omacy.audio.prefer({
	output = {
		"WH-1000XM5",
		"Farbod's JBL Flip 6",
		"External Headphones",
		"MacBook Pro Speakers",
		"Mac mini Speakers",
	},
	input = {
		"Yeti Stereo Microphone",
		"Anker PowerConf C200",
		"MacBook Pro Microphone",
	},
})

-- Restart flameshot if monitor is connected
local MACBOOK_MONITOR = "Built-in Retina Display"

local function screenCallback(layout)
	if layout == true then
		log.d("Screen did not change")
		return
	end
	local screens = hs.screen.allScreens()
	for _, screen in pairs(screens) do
		if screen:name() ~= MACBOOK_MONITOR then
			if screen:id() ~= hs.screen.primaryScreen():id() then
				log.i("Setting " .. screen:name() .. " as primary")
				screen:setPrimary()
			end

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

local function bluetoothOn()
	local _, btOn = hs.execute("/usr/sbin/system_profiler SPBluetoothDataType 2>/dev/null | grep -q 'State: On'")
	if not btOn then
		return false
	end
	return true
end

function HueEnableAlarms()
	if bluetoothOn() == false then
		return
	end

	fishRunCommand("hue_auto_alarm.py")
end

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

local WIFI_CONNECT_DELAY_SECONDS = 3

local function muteSpeaker()
	local speaker = hs.audiodevice.defaultOutputDevice()
	if not speaker then
		log.w("No default output device found to mute")
		return
	end
	speaker:setMuted(true)
end

local function checkHomeWifi()
	if hs.wifi.currentNetwork() ~= HOME_WIFI then
		muteSpeaker()
		return
	end

	HueEnableAlarms()
end

function OnWake(eventType)
	log.i("event: " .. eventType)
	if eventType == hs.caffeinate.watcher.screensDidUnlock or eventType == hs.caffeinate.watcher.systemDidWake then
		HueTurnOn()
		timer.doAfter(WIFI_CONNECT_DELAY_SECONDS, checkHomeWifi)
	end
end

local wakeWatcher = hs.caffeinate.watcher.new(OnWake)
wakeWatcher:start()

-- Omacy apply DO NOT EDIT
if omacy then
	omacy:start()
end
-- Omacy apply DO NOT EDIT
