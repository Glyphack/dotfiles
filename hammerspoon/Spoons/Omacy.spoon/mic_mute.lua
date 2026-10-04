---@class omacy.MicMute
local micMute = {}

local MUTED_ICON = "NSTouchBarAudioInputMuteTemplate"

local menubar = nil
micMute.watchedDevices = {}

local function isMuted()
	local muted = false
	for _, device in ipairs(hs.audiodevice.allInputDevices()) do
		local state = device:inputMuted()
		if state == false then
			return false
		end
		muted = muted or state == true
	end
	return muted
end

local function showIcon()
	if menubar then
		return
	end
	menubar = hs.menubar.new(true, "mic-status")
	local icon = hs.image.imageFromName(MUTED_ICON)
	if icon then
		menubar:setIcon(icon)
	else
		menubar:setTitle("MIC OFF")
	end
end

local function hideIcon()
	if not menubar then
		return
	end
	menubar:delete()
	menubar = nil
end

local function updateMenubar()
	if isMuted() then
		showIcon()
	else
		hideIcon()
	end
end

local function setMuted(muted)
	for _, device in ipairs(hs.audiodevice.allInputDevices()) do
		device:setInputMuted(muted)
	end
	updateMenubar()
end

function micMute.mute()
	setMuted(true)
end

function micMute.unmute()
	setMuted(false)
end

function micMute.toggle()
	if isMuted() then
		micMute.unmute()
	else
		micMute.mute()
	end
end

for _, device in ipairs(hs.audiodevice.allInputDevices()) do
	device:watcherCallback(function(_, event)
		if event == "mute" then
			updateMenubar()
		end
	end)
	device:watcherStart()
	table.insert(micMute.watchedDevices, device)
end

updateMenubar()

return micMute
