-- Launching apps, focusing them, and rotating between their windows or
-- browser tabs from a single entry point.
---@class omacy.Focus
local focus = {}

local log = hs.logger.new("omacy.focus", "info")

local APP_LAUNCH_RETRY_DELAY = 0.3
local APP_LAUNCH_MAX_ATTEMPTS = 20

local focusHistory = {}
local currentFocusedId = nil
local previousFocusedId = nil

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

local function windowBelongsToApp(win, appName)
	local path = win:application():path()
	if not path then
		return false
	end
	return path:find(appName, 1, true) ~= nil
end

local function escapeForAppleScript(text)
	return (text:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

local browserTabs = {}

function browserTabs.run(appName, body)
	local script = string.format('tell application "%s"\n%s\nend tell', escapeForAppleScript(appName), body)
	local ok, result, err = hs.osascript.applescript(script)
	if not ok then
		log.e("browser script failed for " .. appName .. ": " .. hs.inspect(err))
	end
	return ok, result
end

function browserTabs.focus(target)
	local pattern = escapeForAppleScript(target.tab)
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
	local pattern = escapeForAppleScript(target.tab)
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
	local url = escapeForAppleScript(target.tab)
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

-- Focuses the tab whose title or URL matches target.tab, and opens target.tab
-- as a new tab when no tab matches.
local function selectTabOrOpenURL(target)
	if browserTabs.focus(target) then
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

-- hs.window.allWindows() drops Finder's desktop window by keeping only
-- windows whose role is AXWindow; this does the same for a single app.
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

	-- The window list order changes after one window gets focused,
	-- so directly bring the last one to focus every time
	-- https://www.hammerspoon.org/docs/hs.window.html#focus
	local targetWin = appWindows[#appWindows]
	targetWin:focus()
	mouseToCenter(targetWin)
end

local function withApp(appName, fn, attempt)
	attempt = attempt or 1
	local hsApp = hs.application.get(appName)
	if hsApp then
		fn(hsApp)
		return
	end
	if attempt >= APP_LAUNCH_MAX_ATTEMPTS then
		log.e("App never showed up: " .. appName)
		return
	end
	hs.timer.doAfter(APP_LAUNCH_RETRY_DELAY, function()
		withApp(appName, fn, attempt + 1)
	end)
end

local function openTarget(target)
	if not hs.application.launchOrFocus(target.app) then
		log.e("Failed to launch or focus: " .. target.app)
	end
	if target.tab then
		withApp(target.app, function()
			selectTabOrOpenURL(target)
		end)
	end
	hs.timer.doAfter(0.1, function()
		local win = hs.window.focusedWindow()
		if win then
			mouseToCenter(win)
		end
	end)
end

-- target is a table { app = "...", tab = "..." }.
-- app is app name. opens the app or focuses it's window. If it's window is already focused then it cycles between other windows of the app. If there are no other windows it moves the focus to previous window.
-- tab is a URL opens the tab with that url in the browser.
-- Must be provided with app = Brave Browser or app = Chrome. It will open the app and focus this tab or create it if does not exist.
function focus.launchOrFocusOrRotate(target)
	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow or not windowBelongsToApp(focusedWindow, target.app) then
		openTarget(target)
		return
	end

	local hsApp = focusedWindow:application()
	if not target.tab then
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
