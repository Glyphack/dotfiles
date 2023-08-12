HOME_MONITOR = "DELL U2723QE"
MACBOOK_MONITOR = 'Built-in Retina Display'


local hyper      = { "alt" }
local lesshyper  = { "ctrl", "alt" }
local GlobalMute = hs.loadSpoon("GlobalMute")
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

function reload(files)
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

local function switchOutputAfterExternalMicConnected()
  current = hs.audiodevice.defaultInputDevice():name()
  print("Current device: " .. current)
  if current == "External Microphone" then
    print("Forcing default output to Internal Speakers")
    hs.audiodevice.findOutputByName("MacBook Pro Speakers"):setDefaultOutputDevice()
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

reloadWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reload):start()
