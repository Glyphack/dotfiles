-- =========================================================================
-- KARABINER MODE INDICATOR (LIQUID GLASS EFFECT)
-- =========================================================================

-- 0. File-based IPC (more reliable than hs CLI which has known issues)
-- Karabiner writes mode changes to this file, Hammerspoon watches it
local modeFile = os.getenv("HOME") .. "/.hammerspoon/.karabiner_mode"

-- 1. Configuration
local colors = {
	red = { hex = "#ff7a93" }, -- v-mode
	cyan = { hex = "#7dcfff" }, -- a-mode
	orange = { hex = "#ff9e64" }, -- f-mode
	purple = { hex = "#bb9af7" }, -- dmode
	green = { hex = "#9ece6a" }, -- s-mode
}

local modeConfig = {
	["v-mode"] = { text = "NUMPAD", icon = "🔢", color = colors.red },
	["dmode"] = { text = "NUMPAD", icon = "🔢", color = colors.purple },
	["a-mode"] = { text = "NAVIGATE", icon = "✥", color = colors.cyan },
	["f-mode"] = { text = "BRACKETS", icon = "ƒ", color = colors.orange },
	["s-mode"] = { text = "SYMBOLS", icon = "⚡", color = colors.green },
}

-- 2. Dimensions
local hudWidth = 220
local hudHeight = 50
local cornerRadius = hudHeight / 2

-- 3. Create Canvas
local modeHUD = hs.canvas.new({ x = 0, y = 0, w = hudWidth, h = hudHeight })

-- Position: Top Right
local function repositionHUD()
	local screen = hs.screen.primaryScreen()
	-- frame() excludes the menu bar and dock, so it's safe to use
	local frame = screen:frame()

	local marginX = 20 -- Distance from right edge
	local marginY = 20 -- Distance from top (below menu bar)

	modeHUD:frame({
		x = frame.x + frame.w - hudWidth - marginX,
		y = frame.y + marginY,
		w = hudWidth,
		h = hudHeight,
	})
end

repositionHUD()
hs.screen.watcher.new(repositionHUD):start()

-- 4. Define Canvas Elements (Liquid Glass Layers)
modeHUD:appendElements({
	-- [1] Drop Shadow
	{
		type = "rectangle",
		action = "fill",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		fillColor = { alpha = 0 },
		shadow = {
			blurRadius = 20,
			color = { alpha = 0.6, white = 0 },
			offset = { h = 5, w = 0 },
		},
	},
	-- [2] Glass Base
	{
		type = "rectangle",
		action = "fill",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		fillColor = { hex = "#000000", alpha = 0.6 },
	},
	-- [3] Liquid Core
	{
		type = "rectangle",
		action = "fill",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		fillGradient = "radial",
		fillGradientCenter = { x = 0.5, y = 0.5 },
		fillGradientColors = {
			{ hex = "#ffffff", alpha = 0.0 },
			{ hex = "#000000", alpha = 0.0 },
		},
	},
	-- [4] Specular Highlight
	{
		type = "rectangle",
		action = "fill",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		fillGradient = "linear",
		fillGradientAngle = 90,
		fillGradientColors = {
			{ white = 1, alpha = 0.15 },
			{ white = 1, alpha = 0.00 },
		},
		frame = { x = 0, y = 0, w = hudWidth, h = hudHeight / 1.5 },
	},
	-- [5] Rim Light
	{
		type = "rectangle",
		action = "stroke",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		strokeColor = { white = 1, alpha = 0.15 },
		strokeWidth = 1,
	},
	-- [6] Text Label
	{
		type = "text",
		text = "",
		textColor = { white = 1, alpha = 0.95 },
		textSize = 18,
		textAlignment = "center",
		textFont = "Menlo-Bold",
		frame = { x = 0, y = 11, w = hudWidth, h = hudHeight },
		shadow = {
			blurRadius = 10,
			color = { alpha = 0.5, hex = "#ffffff" },
			offset = { h = 0, w = 0 },
		},
	},
})

-- 5. Trigger Function
function UpdateKarabinerMode(modeName, value)
	local config = modeConfig[modeName]

	if value == 1 and config then
		local mainColor = hs.drawing.color.asRGB(config.color)

		modeHUD[3].fillGradientColors = {
			{ red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.6 },
			{ red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.0 },
		}

		modeHUD[6].shadow.color = { red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.8 }

		local displayString = string.format("%s %s", config.icon, config.text)
		modeHUD[6].text = displayString

		modeHUD:show(0.3)
	elseif value == 0 then
		local currentText = modeHUD[6].text
		if config and string.find(currentText, config.text, 1, true) then
			modeHUD:hide(0.3)
		end
	end
end

-- 6. File-based watcher (alternative to hs CLI which has IPC port issues)
-- This watches a file that Karabiner can write to via shell_command
-- Format: "mode_name:0" or "mode_name:1"
local function parseAndUpdateMode(content)
	if not content or content == "" then
		return
	end
	local modeName, value = content:match("^([^:]+):(%d)$")
	if modeName and value then
		UpdateKarabinerMode(modeName, tonumber(value))
	end
end

local modeFileWatcher = nil
local function startModeFileWatcher()
	-- Create the mode file if it doesn't exist
	local f = io.open(modeFile, "a")
	if f then f:close() end

	modeFileWatcher = hs.pathwatcher.new(modeFile, function(paths, flags)
		local f = io.open(modeFile, "r")
		if f then
			local content = f:read("*l")
			f:close()
			if content then
				parseAndUpdateMode(content:match("^%s*(.-)%s*$")) -- trim whitespace
			end
		end
	end)
	modeFileWatcher:start()
end

startModeFileWatcher()
