local micMute = false

hs.hotkey.bind({"alt"}, "T", function()
    hs.loadSpoon("MicMute"):toggleMicMute()
    if micMute then
        micMute = false
        hs.alert.show("Mic unmuted")
    else
        micMute = true
        hs.alert.show("Mic muted")
    end
end)

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

