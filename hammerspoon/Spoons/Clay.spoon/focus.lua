---@class clay.Focus
local focus = {}

local log = hs.logger.new("clay.focus", "info")

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
	hs.mouse.absolutePosition(window:frame().center)
end

local function focusWindow(win)
	if win:isMinimized() then
		win:unminimize()
	end
	win:focus()
	mouseToCenter(win)
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

local chromiumTabs = {}

function chromiumTabs.focus(target)
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

function chromiumTabs.isFocusedOn(target)
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

function chromiumTabs.openURL(target)
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

local safariTabs = {}

function safariTabs.focus(target)
	local pattern = escapeForAppleScript(browserTabs.matchText(target))
	local ok, found = browserTabs.run(
		target.app,
		string.format(
			[[
	repeat with theWindow in windows
		repeat with theTab in tabs of theWindow
			if (name of theTab contains "%s") or (URL of theTab contains "%s") then
				set current tab of theWindow to theTab
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

function safariTabs.isFocusedOn(target)
	local pattern = escapeForAppleScript(browserTabs.matchText(target))
	local ok, found = browserTabs.run(
		target.app,
		string.format(
			[[
	if (count of windows) is 0 then
		return false
	end if
	if (name of current tab of front window contains "%s") or (URL of current tab of front window contains "%s") then
		return true
	end if
	return false]],
			pattern,
			pattern
		)
	)
	return ok and found == true
end

function safariTabs.openURL(target)
	local url = escapeForAppleScript(target.url)
	local ok = browserTabs.run(
		target.app,
		string.format(
			[[
	if (count of windows) is 0 then
		make new document with properties {URL:"%s"}
	else
		tell front window to set current tab to (make new tab with properties {URL:"%s"})
		set index of front window to 1
	end if]],
			url,
			url
		)
	)
	return ok
end

local function selectTabOrOpenURL(browser, target)
	if browser.focus(target) then
		return
	end
	if not target.url then
		log.e("no url to open for " .. target.app .. " tab " .. tostring(target.tab))
		return
	end
	browser.openURL(target)
end

local function focusPreviousOrHide(hsApp)
	local previous = focusHistory.previousWindow()
	if previous then
		focusWindow(previous)
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

	focusWindow(appWindows[#appWindows])
end

local function openTarget(browser, target)
	if not hs.application.launchOrFocusByBundleID(target.app) then
		log.e("Failed to launch or focus: " .. target.app)
		return
	end
	if browserTabs.matchText(target) then
		selectTabOrOpenURL(browser, target)
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
-- Must be provided with the bundle ID of Safari or a Chromium browser such as Brave or Chrome. It will open the app and focus this tab or create it if does not exist.
function focus.launchOrFocusOrRotate(target)
	local browser = chromiumTabs
	if target.app == "com.apple.Safari" then
		browser = safariTabs
	end

	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow or not windowBelongsToApp(focusedWindow, target.app) then
		openTarget(browser, target)
		return
	end

	local hsApp = focusedWindow:application()
	if not browserTabs.matchText(target) then
		rotateWindows(hsApp)
		return
	end

	if browser.isFocusedOn(target) then
		focusPreviousOrHide(hsApp)
		return
	end
	selectTabOrOpenURL(browser, target)
end

-- Focuses win and moves the mouse into it. If win is already focused it cycles between the other windows of its app, and when there are none it moves the focus to the previous window.
function focus.focusOrRotate(win)
	local focusedWindow = hs.window.focusedWindow()
	if focusedWindow and focusedWindow:id() == win:id() then
		rotateWindows(win:application())
		return
	end
	focusWindow(win)
end

return focus
