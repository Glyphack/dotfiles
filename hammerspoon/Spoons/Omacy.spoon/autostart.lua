---@class omacy.Autostart
local autostart = {}

local log = hs.logger.new("omacy.autostart", "info")

local HIDE_DELAY = 2

local tasks = {}
local hideTimers = {}

-- Menu bar apps (LSUIElement) have no Dock icon and no Cmd+Tab entry, so once
-- hidden nothing unhides them and their own hotkeys show nothing.
local function isMenuBarApp(bundleID)
	local info = hs.application.infoForBundleID(bundleID)
	if not info then
		return false
	end
	local flag = info.LSUIElement
	return flag == true or flag == 1 or flag == "1"
end

local function open(bundleID, hidden)
	local args = { "-g", "-b", bundleID }
	if hidden then
		table.insert(args, 2, "-j")
	end
	local task = hs.task.new("/usr/bin/open", function(code, _, stderr)
		if code ~= 0 then
			log.ef("could not start %s: %s", bundleID, stderr)
		end
	end, args)
	task:start()
	table.insert(tasks, task)
end

-- The running app with this bundle ID, or nil when it is not running.
local function running(bundleID)
	return hs.application.applicationsForBundleID(bundleID)[1]
end

local function hide(bundleID)
	local app = running(bundleID)
	if app then
		app:hide()
	end
end

-- Starts each app in bundleIDs that is not running yet and hides it a moment
-- later. Menu bar apps are started but never hidden. Bundle IDs look like
-- { "com.todoist.mac.Todoist", "com.raycast.macos" }.
function autostart.launch(bundleIDs)
	local toHide = {}
	for _, bundleID in ipairs(bundleIDs) do
		if not running(bundleID) then
			local hidden = not isMenuBarApp(bundleID)
			open(bundleID, hidden)
			if hidden then
				table.insert(toHide, bundleID)
			end
		end
	end
	local timer = hs.timer.doAfter(HIDE_DELAY, function()
		for _, bundleID in ipairs(toHide) do
			hide(bundleID)
		end
	end)
	table.insert(hideTimers, timer)
end

return autostart
