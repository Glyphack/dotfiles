HOME_MONITOR              = "DELL U2723QE"
MACBOOK_MONITOR           = 'Built-in Retina Display'
LG_MONITOR                = 'LG HDR 4K'

package.path              = package.path ..
    ";" .. os.getenv('HOME') .. '/Programming/dotfiles/dotfiles-flexport/Spoons/?.spoon/init.lua'

SpoonInstall = hs.loadSpoon("SpoonInstall")

local hasSecrets, secrets = pcall(require, 'secrets')
local hyper               = { "alt" }
local lesshyper           = { "ctrl", "alt" }
local GlobalMute          = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
  toggle = { hyper, "t" }
})
GlobalMute:configure({
  unmute_background     = 'file:///Library/Desktop%20Pictures/Solid%20Colors/Red%20Orange.png',
  mute_background       = 'file:///Library/Desktop%20Pictures/Solid%20Colors/Turquoise%20Green.png',
  enforce_desired_state = true,
  stop_sococo_for_zoom  = true,
  unmute_title          = "<---- UNMUTE -----",
  mute_title            = "<-- MUTE",
})
spoon.GlobalMute._logger.level = 3

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
      hs.notify.new({ title = 'Reloading', informativeText = 'Reloading Hammerspoon config' }):send()
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
  local primary = hs.screen.find(MACBOOK_MONITOR)
  for _, screen in pairs(screens) do
    if screen ~= primary then
      print("Setting " .. screen:name() .. " as primary")
      screen:setPrimary()
    end
  end
end

setPrimary()

-- half of screen
hs.hotkey.bind({ 'alt', 'cmd' }, 'h', function() hs.window.focusedWindow():moveToUnit({ 0, 0, 0.5, 1 }) end)
hs.hotkey.bind({ 'alt', 'cmd' }, 'l', function() hs.window.focusedWindow():moveToUnit({ 0.5, 0, 0.5, 1 }) end)
hs.hotkey.bind({ 'alt', 'cmd' }, 'k', function() hs.window.focusedWindow():moveToUnit({ 0, 0, 1, 0.5 }) end)
hs.hotkey.bind({ 'alt', 'cmd' }, 'j', function() hs.window.focusedWindow():moveToUnit({ 0, 0.5, 1, 0.5 }) end)
-- full screen
hs.hotkey.bind({ 'alt', 'cmd' }, 'f', function() hs.window.focusedWindow():moveToUnit({ 0, 0, 1, 1 }) end)
-- center screen
hs.hotkey.bind({ 'alt', 'cmd' }, 'c', function() hs.window.focusedWindow():centerOnScreen() end)

-- move between displays
hs.hotkey.bind({ 'shift', 'alt', 'cmd' }, 'l', function()
  local win = hs.window.focusedWindow()
  local next = win:screen():toEast()
  if next then
    win:moveToScreen(next, true)
  end
end)
hs.hotkey.bind({ 'shift', 'alt', 'cmd' }, 'h', function()
  local win = hs.window.focusedWindow()
  local next = win:screen():toWest()
  if next then
    win:moveToScreen(next, true)
  end
end)

-- grid gui
hs.grid.setMargins({ w = 0, h = 0 })
hs.hotkey.bind({ 'shift', 'cmd' }, 'g', hs.grid.show)

-- auto layout
hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'l', function() autoLayout() end)

-- size for recording
hs.hotkey.bind({ 'ctrl', 'alt', 'cmd' }, 'r', function()
  hs.window.focusedWindow():setSize({ w = 640, h = 360 })
end)

reloadWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', Reload):start()

-- Special config
if string.match(hs.host.localizedName(), "mbp") then
  pcall(function()
    hs.loadSpoon("FPowerTools"):start()
  end)

  if hasSecrets then
    local PagerDuty = hs.loadSpoon("PagerDuty")
    if secrets.pagerduty_user_id and secrets.pagerduty_api_key then
      PagerDuty:start(60, secrets.pagerduty_user_id, secrets.pagerduty_api_key)
    end
  end
end


-- Define the Lua table that maps names to URLs
local urlTable = {
    john = "https://example.com/john",
    alice = "https://example.com/alice",
    bob = "https://example.com/bob",
}

-- Register a callback for the custom hammerspoon:// URLs
hs.urlevent.bind("example", function(eventName, params, senderPID)
    local event = eventName -- The event name is the host in hammerspoon://host
    local name = params["name"]
    local matchedLink = urlTable[name]
    if name and matchedLink then
        hs.urlevent.openURL(matchedLink)
    else
        print("name not found or no action specified.")
        print(event, name)
    end
end)

