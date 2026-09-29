---@class omacy.Audio
local audio = {}

local SETTLE_DELAY = 1

local favorites = { input = {}, output = {} }
local settleTimer = nil

local function firstConnected(names, find)
	for _, name in ipairs(names) do
		local device = find(name)
		if device then
			return device
		end
	end
	return nil
end

local function useFavorites()
	local input = firstConnected(favorites.input, hs.audiodevice.findInputByName)
	if input then
		input:setDefaultInputDevice()
	end
	local output = firstConnected(favorites.output, hs.audiodevice.findOutputByName)
	if output then
		output:setDefaultOutputDevice()
	end
end

local function useFavoritesSoon()
	if settleTimer then
		settleTimer:stop()
	end
	settleTimer = hs.timer.doAfter(SETTLE_DELAY, useFavorites)
end

local function onDeviceEvent(event)
	if event ~= "dev#" then
		return
	end
	useFavoritesSoon()
end

-- devices is { input = { ... }, output = { ... } }, each a list of device
-- names as shown in the Sound settings, best first. Either list can be left
-- out.
function audio.prefer(devices)
	favorites.input = devices.input or {}
	favorites.output = devices.output or {}
end

function audio.start()
	if #favorites.input == 0 and #favorites.output == 0 then
		return
	end
	hs.audiodevice.watcher.setCallback(onDeviceEvent)
	hs.audiodevice.watcher.start()
	useFavoritesSoon()
end

return audio
