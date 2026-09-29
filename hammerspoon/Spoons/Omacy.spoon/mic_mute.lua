---@class omacy.MicMute
local micMute = {}

local MUTED_ICON = "NSTouchBarAudioInputMuteTemplate"

local menubar = nil
local watchedDevices = {}

local function isMuted()
	local mic = hs.audiodevice.defaultInputDevice()
	return mic ~= nil and mic:inputMuted() == true
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
	table.insert(watchedDevices, device)
end

updateMenubar()

return micMute
