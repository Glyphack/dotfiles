---@class omacy.Autostart
local autostart = {}

local log = hs.logger.new("omacy.autostart", "info")

local HIDE_DELAY = 2

local tasks = {}
local hideTimers = {}

local function open(name)
	local task = hs.task.new("/usr/bin/open", function(code, _, stderr)
		if code ~= 0 then
			log.ef("could not start %s: %s", name, stderr)
		end
	end, { "-g", "-j", "-a", name })
	task:start()
	table.insert(tasks, task)
end

local function hide(name)
	local app = hs.application.find(name, true)
	if app then
		app:hide()
	end
end

-- Starts each app in names that is not running yet and hides it a moment
-- later. Names are the app names as shown in Activity Monitor, such as
-- { "Todoist", "Raycast" }.
function autostart.launch(names)
	local started = {}
	for _, name in ipairs(names) do
		if not hs.application.find(name, true) then
			open(name)
			table.insert(started, name)
		end
	end
	local timer = hs.timer.doAfter(HIDE_DELAY, function()
		for _, name in ipairs(started) do
			hide(name)
		end
	end)
	table.insert(hideTimers, timer)
end

return autostart
