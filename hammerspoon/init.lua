local hyper     = {"alt"}
local lesshyper = {"ctrl", "alt"}
local GlobalMute = hs.loadSpoon("GlobalMute")
GlobalMute:bindHotkeys({
  unmute = {lesshyper, "u"},
  mute   = {lesshyper, "m"},
  toggle = {hyper, "t"}
})
GlobalMute:configure({
  unmute_background = 'file:///Library/Desktop%20Pictures/Solid%20Colors/Red%20Orange.png',
  mute_background   = 'file:///Library/Desktop%20Pictures/Solid%20Colors/Turquoise%20Green.png',
  enforce_desired_state = true,
  stop_sococo_for_zoom  = true,
  unmute_title = "<---- THEY CAN HEAR YOU -----",
  mute_title = "<-- MUTE",
  -- change_screens = "SCREENNAME1, SCREENNAME2"  -- This will only change the background of the specific screens.  string.find()
})
spoon.GlobalMute._logger.level = 3

function reload(files)
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      hs.notify.new({title='Reloading', informativeText='Reloading Hammerspoon config'}):send()
      hs.reload()
      return
    end
  end
end

hs.hotkey.bind({"alt"}, "R", function()
    hs.reload()
end)

reloadWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reload):start()

