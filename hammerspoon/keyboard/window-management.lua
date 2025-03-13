local function launchOrFocusOrRotate(app)
	local focusedWindow = hs.window.focusedWindow()
	if focusedWindow == nil then
		hs.application.launchOrFocus(app)
		return
	end

	-- See https://www.hammerspoon.org/docs/hs.window.html#application
	local focusedWindowApp = focusedWindow:application()
	local focusedWindowAppName = focusedWindowApp:name()
	local focusedWindowPath = focusedWindowApp:path()
	local appNameOnDisk = string.gsub(focusedWindowPath, "/Applications/", "")
	local appNameOnDisk = string.gsub(appNameOnDisk, ".app", "")
	local appNameOnDisk = string.gsub(appNameOnDisk, "/System/Library/CoreServices/", "")
	if focusedWindow and appNameOnDisk == app then
		local currentApp = hs.application.get(focusedWindowAppName)
		local appWindows = currentApp:allWindows()
		if #appWindows == 1 then
			currentApp:hide()
			return
		end

		if #appWindows > 0 then
			-- It seems that this list order changes after one window get focused,
			-- Let's directly bring the last one to focus every time
			-- https://www.hammerspoon.org/docs/hs.window.html#focus
			if app == "Finder" then
				-- If the app is Finder the window count returned is one more than the actual count, so I subtract
				appWindows[#appWindows - 1]:focus()
			else
				appWindows[#appWindows]:focus()
			end
		else
			hs.application.launchOrFocus(app)
		end
	else
		hs.application.launchOrFocus(app)
	end
end

for _, shortcut in ipairs(WINDOWS_SHORTCUTS) do
	hs.hotkey.bind(WINDOW_MANAGEMENT_KEY, shortcut[1], function()
		launchOrFocusOrRotate(shortcut[2])
	end)
end
