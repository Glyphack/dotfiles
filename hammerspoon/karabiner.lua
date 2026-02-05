-- Karabiner Mode Indicator HUD

local colors = {
	red = { hex = "#ff7a93" },
	cyan = { hex = "#7dcfff" },
	orange = { hex = "#ff9e64" },
	purple = { hex = "#bb9af7" },
	green = { hex = "#9ece6a" },
}

local modeConfig = {
	["v-mode"] = { text = "NUMPAD", icon = "🔢", color = colors.red },
	["dmode"] = { text = "NUMPAD", icon = "🔢", color = colors.purple },
	["a-mode"] = { text = "NAVIGATE", icon = "✥", color = colors.cyan },
	["f-mode"] = { text = "BRACKETS", icon = "ƒ", color = colors.orange },
	["s-mode"] = { text = "SYMBOLS", icon = "⚡", color = colors.green },
}

local hudWidth = 220
local hudHeight = 50
local cornerRadius = hudHeight / 2

local modeHUD = hs.canvas.new({ x = 0, y = 0, w = hudWidth, h = hudHeight })

local function repositionHUD()
	local screen = hs.screen.primaryScreen()
	local frame = screen:frame()
	modeHUD:frame({
		x = frame.x + frame.w - hudWidth - 20,
		y = frame.y + 20,
		w = hudWidth,
		h = hudHeight,
	})
end

repositionHUD()
hs.screen.watcher.new(repositionHUD):start()

modeHUD:appendElements({
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
	{
		type = "rectangle",
		action = "fill",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		fillColor = { hex = "#000000", alpha = 0.6 },
	},
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
	{
		type = "rectangle",
		action = "stroke",
		roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
		strokeColor = { white = 1, alpha = 0.15 },
		strokeWidth = 1,
	},
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

function UpdateKarabinerMode(modeName, value)
	local config = modeConfig[modeName]

	if value == 1 and config then
		local mainColor = hs.drawing.color.asRGB(config.color)

		modeHUD[3].fillGradientColors = {
			{ red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.6 },
			{ red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.0 },
		}

		modeHUD[6].shadow.color = { red = mainColor.red, green = mainColor.green, blue = mainColor.blue, alpha = 0.8 }
		modeHUD[6].text = string.format("%s %s", config.icon, config.text)

		modeHUD:show(0.3)
	elseif value == 0 then
		local currentText = modeHUD[6].text
		if config and string.find(currentText, config.text, 1, true) then
			modeHUD:hide(0.3)
		end
	end
end

hs.urlevent.bind("karabinermode", function(eventName, params)
	local modeName = params.name
	local value = tonumber(params.value)
	if modeName and value then
		UpdateKarabinerMode(modeName, value)
	end
end)
