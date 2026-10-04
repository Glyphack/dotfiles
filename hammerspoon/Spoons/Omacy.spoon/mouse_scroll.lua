---@class omacy.MouseScroll
local mouseScroll = {}

local SCROLL_MOUSE_BUTTON = 2
local SCROLL_MULTIPLIER = -4

local RING_RADIUS = 22
local OUTLINE_WIDTH = 1.5
local ARROW_NEAR = 8
local ARROW_FAR = 16
local ARROW_HALF_WIDTH = 5
local BAND_WIDTH = 3
local TIP_RADIUS = 4.5
local FADE_IN = 0.08
local FADE_OUT = 0.25
local MOTION_SMOOTHING = 0.35
local LIT_SHARE = 0.5

local ACCENT_COLOR = { list = "System", name = "controlAccentColor" }
local OUTLINE_COLOR = { white = 1, alpha = 0.9 }
local IDLE_ARROW_COLOR = { white = 1, alpha = 0.35 }

local DIRECTIONS = {
	{ x = 0, y = -1 },
	{ x = 1, y = 0 },
	{ x = 0, y = 1 },
	{ x = -1, y = 0 },
}

local BAND = 1
local DISC = 2
local FIRST_ARROW = 3
local TIP = FIRST_ARROW + #DIRECTIONS

local function arrowPoints(center, direction)
	local sideX, sideY = -direction.y, direction.x
	local function at(distance, side)
		return {
			x = center.x + direction.x * distance + sideX * side,
			y = center.y + direction.y * distance + sideY * side,
		}
	end
	return {
		at(ARROW_FAR, 0),
		at(ARROW_NEAR, ARROW_HALF_WIDTH),
		at(ARROW_NEAR, -ARROW_HALF_WIDTH),
	}
end

local PanIndicator = {}
PanIndicator.__index = PanIndicator

function PanIndicator.new(point)
	local frame = hs.mouse.getCurrentScreen():fullFrame()
	local self = setmetatable({ origin = { x = frame.x, y = frame.y }, motion = { x = 0, y = 0 } }, PanIndicator)
	self.anchor = self:toCanvas(point)
	self.canvas = hs.canvas
		.new(frame)
		:level(hs.canvas.windowLevels.overlay)
		:replaceElements(self:elements())
		:show(FADE_IN)
	return self
end

function PanIndicator:toCanvas(point)
	return { x = point.x - self.origin.x, y = point.y - self.origin.y }
end

function PanIndicator:ringEdgeToward(tip)
	local dx, dy = tip.x - self.anchor.x, tip.y - self.anchor.y
	local distance = math.sqrt(dx * dx + dy * dy)
	if distance <= RING_RADIUS then
		return tip
	end
	local scale = RING_RADIUS / distance
	return { x = self.anchor.x + dx * scale, y = self.anchor.y + dy * scale }
end

function PanIndicator:elements()
	local elements = {
		[BAND] = {
			type = "segments",
			coordinates = { self.anchor, self.anchor },
			action = "stroke",
			strokeColor = { list = "System", name = "controlAccentColor", alpha = 0.6 },
			strokeWidth = BAND_WIDTH,
			strokeCapStyle = "round",
		},
		[DISC] = {
			type = "circle",
			center = self.anchor,
			radius = RING_RADIUS,
			action = "strokeAndFill",
			fillColor = { white = 0, alpha = 0.55 },
			strokeColor = OUTLINE_COLOR,
			strokeWidth = OUTLINE_WIDTH,
			withShadow = true,
			shadow = { blurRadius = 8, color = { white = 0, alpha = 0.45 }, offset = { h = -2, w = 0 } },
		},
	}
	for i, direction in ipairs(DIRECTIONS) do
		elements[FIRST_ARROW + i - 1] = {
			type = "segments",
			coordinates = arrowPoints(self.anchor, direction),
			closed = true,
			action = "fill",
			fillColor = IDLE_ARROW_COLOR,
		}
	end
	elements[TIP] = {
		type = "circle",
		center = self.anchor,
		radius = TIP_RADIUS,
		action = "strokeAndFill",
		fillColor = ACCENT_COLOR,
		strokeColor = OUTLINE_COLOR,
		strokeWidth = OUTLINE_WIDTH,
	}
	return elements
end

function PanIndicator:follow(point, dx, dy)
	local tip = self:toCanvas(point)
	self.canvas:elementAttribute(BAND, "coordinates", { self:ringEdgeToward(tip), tip })
	self.canvas:elementAttribute(TIP, "center", tip)

	self.motion.x = self.motion.x + (dx - self.motion.x) * MOTION_SMOOTHING
	self.motion.y = self.motion.y + (dy - self.motion.y) * MOTION_SMOOTHING
	local strongest = math.max(math.abs(self.motion.x), math.abs(self.motion.y))
	for i, direction in ipairs(DIRECTIONS) do
		local along = self.motion.x * direction.x + self.motion.y * direction.y
		local lit = strongest > 0 and along >= strongest * LIT_SHARE
		self.canvas:elementAttribute(FIRST_ARROW + i - 1, "fillColor", lit and ACCENT_COLOR or IDLE_ARROW_COLOR)
	end
end

function PanIndicator:hide()
	self.canvas:delete(FADE_OUT)
end

local deferred = false
local indicator = nil

local mouseDownWatcher
local mouseUpWatcher
local dragWatcher

local function hideIndicator()
	if not indicator then
		return
	end
	indicator:hide()
	indicator = nil
end

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
	hideIndicator()
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
	if not indicator then
		indicator = PanIndicator.new(e:location())
	end
	local dx = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaX"])
	local dy = e:getProperty(hs.eventtap.event.properties["mouseEventDeltaY"])
	indicator:follow(e:location(), dx, dy)
	local scroll = hs.eventtap.event.newScrollEvent({ -dx * SCROLL_MULTIPLIER, dy * SCROLL_MULTIPLIER }, {}, "pixel")
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
	hideIndicator()
end

return mouseScroll
