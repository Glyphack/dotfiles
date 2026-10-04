---@class omacy.Focus
local focus = {}

local log = hs.logger.new("omacy.focus", "info")

local focusHistory = {}
local currentFocusedId = nil
local previousFocusedId = nil
local pointerTimer = nil

local function recordFocus(win)
	if not win then
		return
	end
	local id = win:id()
	if id == currentFocusedId then
		return
	end
	previousFocusedId = currentFocusedId
	currentFocusedId = id
end

function focusHistory.previousWindow()
	if not previousFocusedId then
		return nil
	end
	local win = hs.window.get(previousFocusedId)
	if win and win:isVisible() then
		return win
	end
	return nil
end

focus.watcher = hs.window.filter.new():subscribe(hs.window.filter.windowFocused, recordFocus)

local function mouseToCenter(window)
	local current_pos = hs.geometry(hs.mouse.absolutePosition())
	local frame = window:frame()
	if not current_pos:inside(frame) then
		hs.mouse.absolutePosition(frame.center)
	end
end

local function windowBelongsToApp(win, bundleID)
	return win:application():bundleID() == bundleID
end

local function escapeForAppleScript(text)
	return (text:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

local browserTabs = {}

function browserTabs.matchText(target)
	return target.tab or target.url
end

function browserTabs.run(bundleID, body)
	local script = string.format('tell application id "%s"\n%s\nend tell', escapeForAppleScript(bundleID), body)
	local ok, result, err = hs.osascript.applescript(script)
	if not ok then
		log.e("browser script failed for " .. bundleID .. ": " .. hs.inspect(err))
	end
	return ok, result
end

function browserTabs.focus(target)
	local pattern = escapeForAppleScript(browserTabs.matchText(target))
	local ok, found = browserTabs.run(
		target.app,
		string.format(
			[[
	repeat with theWindow in windows
		set tabIndex to 0
		repeat with theTab in tabs of theWindow
			set tabIndex to tabIndex + 1
			if (title of theTab contains "%s") or (URL of theTab contains "%s") then
				set active tab index of theWindow to tabIndex
				set index of theWindow to 1
				return true
			end if
		end repeat
	end repeat
	return false]],
			pattern,
			pattern
		)
	)
	return ok and found == true
end

function browserTabs.isFocusedOn(target)
	local pattern = escapeForAppleScript(browserTabs.matchText(target))
	local ok, found = browserTabs.run(
		target.app,
		string.format(
			[[
	if (count of windows) is 0 then
		return false
	end if
	if (title of active tab of front window contains "%s") or (URL of active tab of front window contains "%s") then
		return true
	end if
	return false]],
			pattern,
			pattern
		)
	)
	return ok and found == true
end

function browserTabs.openURL(target)
	local url = escapeForAppleScript(target.url)
	local ok = browserTabs.run(
		target.app,
		string.format(
			[[
	if (count of windows) is 0 then
		make new window
		set URL of active tab of front window to "%s"
	else
		tell front window to make new tab with properties {URL:"%s"}
		set index of front window to 1
	end if]],
			url,
			url
		)
	)
	return ok
end

local function selectTabOrOpenURL(target)
	if browserTabs.focus(target) then
		return
	end
	if not target.url then
		log.e("no url to open for " .. target.app .. " tab " .. tostring(target.tab))
		return
	end
	browserTabs.openURL(target)
end

local function focusPreviousOrHide(hsApp)
	local previous = focusHistory.previousWindow()
	if previous then
		previous:focus()
		mouseToCenter(previous)
		return
	end
	if not hsApp:hide() then
		log.e("Failed to hide: " .. hsApp:name())
	end
end

local function realWindows(hsApp)
	local windows = {}
	for _, win in ipairs(hsApp:allWindows()) do
		if win:role() == "AXWindow" then
			table.insert(windows, win)
		end
	end
	return windows
end

local function rotateWindows(hsApp)
	local appWindows = realWindows(hsApp)
	if #appWindows <= 1 then
		focusPreviousOrHide(hsApp)
		return
	end

	local targetWin = appWindows[#appWindows]
	targetWin:focus()
	mouseToCenter(targetWin)
end

local function openTarget(target)
	if not hs.application.launchOrFocusByBundleID(target.app) then
		log.e("Failed to launch or focus: " .. target.app)
		return
	end
	if browserTabs.matchText(target) then
		selectTabOrOpenURL(target)
	end
	pointerTimer = hs.timer.doAfter(0.1, function()
		local win = hs.window.focusedWindow()
		if win then
			mouseToCenter(win)
		end
	end)
end

-- target is a table { app = "...", tab = "...", url = "..." }.
-- app is the bundle ID of the app, such as "com.brave.Browser". opens the app or focuses it's window. If it's window is already focused then it cycles between other windows of the app. If there are no other windows it moves the focus to previous window.
-- url is the address opened in a new browser tab when no tab matches.
-- tab is an optional title or URL fragment matched against open tabs, the url is matched when it is missing.
-- Must be provided with the bundle ID of Brave Browser or Chrome. It will open the app and focus this tab or create it if does not exist.
function focus.launchOrFocusOrRotate(target)
	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow or not windowBelongsToApp(focusedWindow, target.app) then
		openTarget(target)
		return
	end

	local hsApp = focusedWindow:application()
	if not browserTabs.matchText(target) then
		rotateWindows(hsApp)
		return
	end

	if browserTabs.isFocusedOn(target) then
		focusPreviousOrHide(hsApp)
		return
	end
	selectTabOrOpenURL(target)
end

return focus
