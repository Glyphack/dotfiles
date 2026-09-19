-- Moving and resizing the focused window.
---@class omacy.Window
local window = {}

-- Holds the previous frame of the one window most recently moved or resized
-- by an action below, so the same action can undo it. Acting on a different
-- window (or a different action on the same window) just replaces this.
local savedFrame = nil

local function focused()
	return hs.window.focusedWindow()
end

-- Runs applyFn on win, remembering its frame first so the same action can be
-- pressed again on the same window to undo it, like a single-window ctrl-z.
local function withUndo(win, action, applyFn)
	local id = win:id()
	if not id then
		return
	end
	if savedFrame and savedFrame.windowId == id and savedFrame.action == action then
		win:setFrame(savedFrame.frame)
		savedFrame = nil
		return
	end
	savedFrame = { windowId = id, action = action, frame = win:frame() }
	applyFn()
end

function window.snap(unit, action)
	local win = focused()
	if not win then
		return
	end
	withUndo(win, action, function()
		win:moveToUnit(unit)
	end)
end

function window.left()
	window.snap({ 0, 0, 0.5, 1 }, "left")
end

function window.right()
	window.snap({ 0.5, 0, 0.5, 1 }, "right")
end

function window.top()
	window.snap({ 0, 0, 1, 0.5 }, "top")
end

function window.bottom()
	window.snap({ 0, 0.5, 1, 0.5 }, "bottom")
end

function window.center()
	local win = focused()
	if not win then
		return
	end
	withUndo(win, "center", function()
		win:centerOnScreen()
	end)
end

-- Fills the screen the focused window sits on. Running it again puts the
-- window back where it was, as long as it is still on that screen.
function window.maximize()
	local win = focused()
	if not win then
		return
	end
	local screen = win:screen()
	withUndo(win, "maximize:" .. screen:id(), function()
		win:setFrame(screen:frame())
	end)
end

-- Moves the focused window to the next screen, keeping its relative size and
-- position. Screens wrap around, so the last screen leads back to the first.
function window.nextScreen()
	local win = focused()
	if not win then
		return
	end
	withUndo(win, "nextScreen", function()
		win:moveToScreen(win:screen():next(), true, true)
	end)
end

function window.previousScreen()
	local win = focused()
	if not win then
		return
	end
	withUndo(win, "previousScreen", function()
		win:moveToScreen(win:screen():previous(), true, true)
	end)
end

return window
