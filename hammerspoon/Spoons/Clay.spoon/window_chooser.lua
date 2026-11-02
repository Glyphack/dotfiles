local windowFilter = require("hs.window.filter")
local FuzzyChooser = dofile(hs.spoons.resourcePath("fuzzy_chooser.lua"))

local log = hs.logger.new("clay.windowChooser", "info")

local function bundleIcon(bundleId)
	return hs.image.imageFromAppBundle(bundleId)
end

local function appIcon(app)
	local bundleId = app:bundleID()
	if not bundleId then
		return nil
	end
	return bundleIcon(bundleId)
end

local function elapsedMs(start)
	return (hs.timer.secondsSinceEpoch() - start) * 1000
end

-- Running tasks, kept here so they are not garbage collected before they finish.
local runningTasks = {}

-- Runs a program in the background and calls done with its output, or with nil when it fails.
local function runTask(path, args, done)
	local task
	task = hs.task.new(path, function(exitCode, stdOut, stdErr)
		runningTasks[task] = nil
		if exitCode ~= 0 then
			log.e(path .. " " .. table.concat(args, " ") .. " failed: " .. stdErr)
			done(nil)
			return
		end
		done(stdOut)
	end, args)
	if not task then
		log.e("could not start " .. path)
		done(nil)
		return
	end
	runningTasks[task] = true
	task:start()
end

local function runOsascript(language, script, done)
	runTask("/usr/bin/osascript", { "-l", language, "-e", script }, done)
end

local WindowSource = {}
WindowSource.__index = WindowSource

function WindowSource.new()
	return setmetatable({
		name = "windows",
		filter = windowFilter.new():setDefaultFilter({}):keepActive(),
		windowsById = {},
		clay = nil,
	}, WindowSource)
end

function WindowSource:load(done)
	self.windowsById = {}
	local choices = {}
	for _, win in ipairs(self.filter:getWindows(windowFilter.sortByFocusedLast)) do
		local id = win:id()
		local app = win:application()
		if id and app then
			local appName = app:name()
			local title = win:title()
			if title == "" then
				title = appName
			end
			self.windowsById[id] = win
			table.insert(choices, {
				text = title,
				subText = "Window · " .. appName,
				image = appIcon(app),
				windowId = id,
			})
		end
	end
	done(choices)
end

function WindowSource:focus(choice)
	local win = self.windowsById[choice.windowId]
	if not win then
		return
	end
	self.clay.focus.focusOrRotate(win)
end

local ChromiumTabSource = {}
ChromiumTabSource.__index = ChromiumTabSource

function ChromiumTabSource.new(bundleId, name)
	return setmetatable({ bundleId = bundleId, name = name }, ChromiumTabSource)
end

function ChromiumTabSource:choicesFrom(tabs)
	local icon = bundleIcon(self.bundleId)
	local choices = {}
	for windowIndex, windowId in ipairs(tabs.ids) do
		local titles = tabs.titles[windowIndex]
		-- A window with a single tab is already listed as a window.
		if #titles == 1 then
			titles = {}
		end
		for tabIndex, title in ipairs(titles) do
			table.insert(choices, {
				text = title,
				subText = self.name .. " tab · " .. tabs.urls[windowIndex][tabIndex],
				image = icon,
				windowId = windowId,
				tabIndex = tabIndex,
				isTab = true,
			})
		end
	end
	return choices
end

function ChromiumTabSource:load(done)
	if not hs.application.get(self.bundleId) then
		done({})
		return
	end
	local script = string.format(
		[[
var app = Application("%s");
JSON.stringify({ ids: app.windows.id(), titles: app.windows.tabs.title(), urls: app.windows.tabs.url() });
]],
		self.bundleId
	)
	runOsascript("JavaScript", script, function(output)
		if not output then
			done({})
			return
		end
		done(self:choicesFrom(hs.json.decode(output)))
	end)
end

function ChromiumTabSource:focus(choice)
	local script = string.format(
		[[
tell application id "%s"
	set active tab index of window id %d to %d
	set index of window id %d to 1
	activate
end tell]],
		self.bundleId,
		choice.windowId,
		choice.tabIndex,
		choice.windowId
	)
	runOsascript("AppleScript", script, function() end)
end

local WezTermSource = {}
WezTermSource.__index = WezTermSource

WezTermSource.bundleId = "com.github.wez.wezterm"

function WezTermSource.new()
	return setmetatable({ name = "WezTerm" }, WezTermSource)
end

-- Runs a wezterm cli command in the background and calls done with its decoded
-- json output, an empty table when it prints nothing, or nil when it fails.
function WezTermSource:cli(args, done)
	local wezterm = hs.application.pathForBundleID(self.bundleId) .. "/Contents/MacOS/wezterm"
	table.insert(args, 1, "cli")
	runTask(wezterm, args, function(output)
		if not output then
			done(nil)
			return
		end
		if not output:match("%S") then
			done({})
			return
		end
		done(hs.json.decode(output))
	end)
end

local function shortPath(cwdUrl)
	local path = cwdUrl:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	local home = os.getenv("HOME")
	if path:sub(1, #home) == home then
		return "~" .. path:sub(#home + 1)
	end
	return path
end

-- Groups panes into tabs, keeping the order wezterm lists them in.
local function tabsOf(panes)
	local tabs = {}
	local byId = {}
	for _, pane in ipairs(panes) do
		local tab = byId[pane.tab_id]
		if not tab then
			tab = { id = pane.tab_id, workspace = pane.workspace, paneCount = 0 }
			byId[pane.tab_id] = tab
			table.insert(tabs, tab)
		end
		tab.paneCount = tab.paneCount + 1
		if pane.is_active or not tab.activePane then
			tab.activePane = pane
		end
	end
	return tabs
end

function WezTermSource:choicesFrom(panes)
	local icon = bundleIcon(self.bundleId)
	local choices = {}
	for _, tab in ipairs(tabsOf(panes)) do
		local subText = "WezTerm tab · " .. shortPath(tab.activePane.cwd)
		if tab.paneCount > 1 then
			subText = subText .. " · " .. tab.paneCount .. " panes"
		end
		table.insert(choices, {
			text = tab.workspace .. " - " .. tab.activePane.title,
			subText = subText,
			image = icon,
			workspace = tab.workspace,
			paneId = tab.activePane.pane_id,
			isTab = true,
		})
	end
	return choices
end

function WezTermSource:load(done)
	if not hs.application.get(self.bundleId) then
		done({})
		return
	end
	self:cli({ "list", "--format", "json" }, function(panes)
		if not panes then
			done({})
			return
		end
		done(self:choicesFrom(panes))
	end)
end

-- Asks wezterm to switch workspace by setting a user var on a visible pane,
-- which the user-var-changed handler in the clay WezTerm module acts on.
function WezTermSource:requestSwitch(client, workspace, paneId)
	self:cli({ "list", "--format", "json" }, function(panes)
		local tty = nil
		for _, pane in ipairs(panes or {}) do
			if pane.pane_id == client.focused_pane_id then
				tty = pane.tty_name
			end
		end
		if not tty then
			log.e("no tty for focused wezterm pane " .. tostring(client.focused_pane_id))
			return
		end
		local value = string.format("%s|%s|%d", workspace, paneId or "", hs.timer.absoluteTime())
		local file = io.open(tty, "w")
		if not file then
			log.e("could not open " .. tty)
			return
		end
		file:write("\27]1337;SetUserVar=switch_to=" .. hs.base64.encode(value) .. "\7")
		file:close()
	end)
end

function WezTermSource:focus(choice)
	hs.application.launchOrFocusByBundleID(self.bundleId)
	self:cli({ "list-clients", "--format", "json" }, function(clients)
		local client = clients and clients[1]
		if not client then
			return
		end
		if client.workspace ~= choice.workspace then
			self:requestSwitch(client, choice.workspace, choice.paneId)
			return
		end
		if choice.paneId then
			self:cli({ "activate-pane", "--pane-id", tostring(choice.paneId) }, function() end)
		end
	end)
end

-- Moves tabs below every other choice, keeping the order within each group.
local function tabsLast(choices)
	local result = {}
	local tabs = {}
	for _, choice in ipairs(choices) do
		table.insert(choice.isTab and tabs or result, choice)
	end
	for _, choice in ipairs(tabs) do
		table.insert(result, choice)
	end
	return result
end

local WindowChooser = {
	log = log,
	windows = WindowSource.new(),
	sources = {},
	-- choices of each source from the latest load, by source index
	loaded = {},
	-- counts loads so results that arrive after a newer load started are dropped
	generation = 0,
	chooser = nil,
}

WindowChooser.sources = {
	WindowChooser.windows,
	ChromiumTabSource.new("com.google.Chrome", "Chrome"),
	ChromiumTabSource.new("com.brave.Browser", "Brave"),
	WezTermSource.new(),
}

function WindowChooser:init(clay)
	self.windows.clay = clay
end

function WindowChooser:combined()
	local choices = {}
	for sourceIndex = 1, #self.sources do
		for _, choice in ipairs(self.loaded[sourceIndex] or {}) do
			choice.sourceIndex = sourceIndex
			table.insert(choices, choice)
		end
	end
	return tabsLast(choices)
end

-- Returns the choices that are ready right away. Choices from sources that
-- answer later are added to the open chooser when they arrive.
function WindowChooser:load()
	self.generation = self.generation + 1
	local generation = self.generation
	local start = hs.timer.secondsSinceEpoch()
	local starting = true
	self.loaded = {}
	for sourceIndex, source in ipairs(self.sources) do
		source:load(function(choices)
			if generation ~= self.generation then
				return
			end
			log.d(string.format("%s loaded %d choices in %.0f ms", source.name, #choices, elapsedMs(start)))
			self.loaded[sourceIndex] = choices
			if not starting then
				self.chooser:setChoices(self:combined())
			end
		end)
	end
	starting = false
	log.d(string.format("chooser ready in %.0f ms", elapsedMs(start)))
	return self:combined()
end

function WindowChooser:focus(choice)
	self.sources[choice.sourceIndex]:focus(choice)
end

function WindowChooser:show()
	self.chooser:show()
end

function WindowChooser:toggle()
	self.chooser:toggle()
end

WindowChooser.chooser = FuzzyChooser.new("Window or tab", function()
	return WindowChooser:load()
end, function(choice)
	WindowChooser:focus(choice)
end)

local rank = WindowChooser.chooser.filter
WindowChooser.chooser.filter = function(chooser, query)
	return tabsLast(rank(chooser, query))
end

return WindowChooser
