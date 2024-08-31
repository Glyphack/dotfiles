local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on("update-right-status", function(window, pane)
	local date = wezterm.strftime("%a %b %-d %H:%M ")

	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = "🔋 " .. string.format("%.0f%%", b.state_of_charge * 100)
	end

	window:set_right_status(wezterm.format({
		{ Text = bat .. "   " .. date },
	}))
end)

local config = {
	font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 23,
	keys = {
		{
			key = "a",
			mods = "CMD",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "d",
			mods = "CMD",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "K",
			mods = "CTRL|SHIFT",
			action = act.Multiple({
				act.ClearScrollback("ScrollbackAndViewport"),
				act.SendKey({ key = "L", mods = "CTRL" }),
			}),
		},
		{
			key = "p",
			mods = "CMD",
			action = wezterm.action({
				QuickSelectArgs = {
					patterns = {
						"https?://\\S+",
					},
					action = wezterm.action_callback(function(window, pane)
						local url = window:get_selection_text_for_pane(pane)
						wezterm.log_info("opening: " .. url)
						wezterm.open_with(url)
					end),
				},
			}),
		},
		{ key = "u", mods = "CMD", action = act.CopyMode("ClearPattern") },
	},
	color_scheme = "catppuccin-mocha",
}

-- config.window_background_opacity = .9
-- The art is a bit too bright and colorful to be useful as a backdrop
-- for text, so we're going to dim it down to 10% of its normal brightness
local dimmer = { brightness = 0.1 }

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.colors = {
	scrollbar_thumb = "gray",
}
config.background = {
	-- This is the deepest/back-most layer. It will be rendered first
	{
		source = {
			File = wezterm.home_dir .. "/Programming/dotfiles/wezterm/backgrounds/bg-1.jpeg",
		},
		-- The texture tiles vertically but not horizontally.
		-- When we repeat it, mirror it so that it appears "more seamless".
		-- An alternative to this is to set `width = "100%"` and have
		-- it stretch across the display
		repeat_x = "Mirror",
		hsb = dimmer,
		-- When the viewport scrolls, move this layer 10% of the number of
		-- pixels moved by the main viewport. This makes it appear to be
		-- further behind the text.
	},
}

config.scrollback_lines = 100000

return config
