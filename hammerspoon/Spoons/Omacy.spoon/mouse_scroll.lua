-- Grab scrolling: turns holding and dragging a mouse button into scroll events.
---@class omacy.MouseScroll
local mouseScroll = {}

local SCROLL_MOUSE_BUTTON = 2
local SCROLL_MULTIPLIER = -4 -- negative multiplier makes mouse work like traditional scrollwheel

local deferred = false
local oldMousePos = {}

local mouseDownWatcher
local mouseUpWatcher
local dragWatcher

local function onMouseDown(e)
	local pressedButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	if SCROLL_MOUSE_BUTTON == pressedButton then
		deferred = true
		return true
	end
end

local function onMouseUp(e)
	local pressedButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	if SCROLL_MOUSE_BUTTON ~= pressedButton then
		return false
	end
	if not deferred then
		return false
	end

	mouseDownWatcher:stop()
	mouseUpWatcher:stop()
	hs.eventtap.otherClick(e:location(), pressedButton)
	mouseDownWatcher:start()
	mouseUpWatcher:start()
	return true
end

local function onDrag(e)
	local pressedButton = e:getProperty(hs.eventtap.event.properties["mouseEventButtonNumber"])
	if SCROLL_MOUSE_BUTTON ~= pressedButton then
		return false, {}
	end

	deferred = false
	oldMousePos = hs.mouse.absolutePosition()
	local dx = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaX"])
	local dy = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaY"])
	local scroll = hs.eventtap.event.newScrollEvent({ -dx * SCROLL_MULTIPLIER, dy * SCROLL_MULTIPLIER }, {}, "pixel")
	-- put the mouse back
	hs.mouse.absolutePosition(oldMousePos)
	return true, { scroll }
end

function mouseScroll.start()
	mouseDownWatcher = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, onMouseDown)
	mouseUpWatcher = hs.eventtap.new({ hs.eventtap.event.types.otherMouseUp }, onMouseUp)
	dragWatcher = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDragged }, onDrag)

	mouseDownWatcher:start()
	mouseUpWatcher:start()
	dragWatcher:start()
end

function mouseScroll.stop()
	if mouseDownWatcher then
		mouseDownWatcher:stop()
	end
	if mouseUpWatcher then
		mouseUpWatcher:stop()
	end
	if dragWatcher then
		dragWatcher:stop()
	end
end

return mouseScroll
