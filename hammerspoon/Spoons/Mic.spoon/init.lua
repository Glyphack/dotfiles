--- === Mic ===
---
--- Mutes and unmutes every microphone at once. While muted, a crossed-out
--- microphone icon is shown in the menubar; while live, nothing is shown.

local obj = {}
obj.__index = obj

obj.name = "Mic"
obj.version = "1.0"
obj.author = "Glyphack"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Menubar item, present only while muted.
obj.menubar = nil
-- Input devices being watched. A device that is no longer referenced from Lua
-- also loses its watcher, so they are kept here for as long as the spoon runs.
obj.devices = {}

local MUTED_ICON = "NSTouchBarAudioInputMuteTemplate"

local function isMuted()
	local mic = hs.audiodevice.defaultInputDevice()
	return mic ~= nil and mic:inputMuted() == true
end

function obj:showIcon()
	if self.menubar then
		return
	end
	self.menubar = hs.menubar.new(true, "mic-status")
	local icon = hs.image.imageFromName(MUTED_ICON)
	if icon then
		self.menubar:setIcon(icon)
	else
		self.menubar:setTitle("MIC OFF")
	end
end

function obj:hideIcon()
	if not self.menubar then
		return
	end
	self.menubar:delete()
	self.menubar = nil
end

function obj:updateMenubar()
	if isMuted() then
		self:showIcon()
	else
		self:hideIcon()
	end
end

function obj:setMuted(muted)
	for _, device in ipairs(hs.audiodevice.allInputDevices()) do
		device:setInputMuted(muted)
	end
	self:updateMenubar()
	return self
end

function obj:mute()
	return self:setMuted(true)
end

function obj:unmute()
	return self:setMuted(false)
end

function obj:toggle()
	return self:setMuted(not isMuted())
end

function obj:bindHotkeys(mapping)
	hs.spoons.bindHotkeysToSpec({
		toggle = function()
			self:toggle()
		end,
	}, mapping)
	return self
end

function obj:start()
	self:stop()
	for _, device in ipairs(hs.audiodevice.allInputDevices()) do
		device:watcherCallback(function(_, event)
			if event == "mute" then
				self:updateMenubar()
			end
		end)
		device:watcherStart()
		table.insert(self.devices, device)
	end
	return self:unmute()
end

function obj:stop()
	for _, device in ipairs(self.devices) do
		device:watcherStop()
	end
	self.devices = {}
	self:hideIcon()
	return self
end

return obj
