local wezterm = require("wezterm")
local act = wezterm.action

local function is_pane_zoomed(pane)
	local pane_info = pane:get_foreground_process_info()
	-- Access pane information to check zoom state
	return pane:get_dimensions().is_zoomed
end

wezterm.on("update-right-status", function(window)
	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = "🔋" .. string.format("%.0f%%", b.state_of_charge * 100)
	end

	window:set_right_status(wezterm.format({
		{ Text = bat .. "   " },
	}))
end)

local config = {
	leader = { key = "a", mods = "CMD", timeout_milliseconds = 1000 },
	key_tables = {
		copy_mode = wezterm.gui.default_key_tables().copy_mode,
	},
	font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 20,
	keys = {
		{ key = "c", mods = "LEADER", action = act.ActivateCopyMode },
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
		{ key = "[", mods = "LEADER", action = act.ScrollToPrompt(-1) },
		{ key = "]", mods = "LEADER", action = act.ScrollToPrompt(1) },
		{ key = "u", mods = "CMD", action = act.CopyMode("ClearPattern") },

		-- multiplexing

		{ key = "x", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },
		--  split
		{ key = "s", mods = "CMD", action = act.SplitHorizontal },
		--  move
		{
			key = "e",
			mods = "CMD",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local is_zoomed = tab:set_zoomed(false)
				window:perform_action(act.ActivatePaneDirection("Next"), pane)
				tab:set_zoomed(is_zoomed)
			end),
		},
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "]", mods = "CMD", action = act.ActivateTabRelative(1) },
		{ key = "[", mods = "CMD", action = act.ActivateTabRelative(-1) },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	},
	color_scheme = "catppuccin-mocha",
}

local dimmer = { brightness = 0.05 }

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.colors = {
	scrollbar_thumb = "gray",
}
config.background = {
	-- This is the deepest/back-most layer. It will be rendered first
	{
		source = {
			File = wezterm.home_dir .. "/Programming/dotfiles/wezterm/backgrounds/planet.jpg",
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

config.switch_to_last_active_tab_when_closing_tab = true
config.scrollback_lines = 100000

for i, binding in ipairs(config.key_tables.copy_mode) do
	if binding.key == "y" and binding.mods == "NONE" then
		config.key_tables.copy_mode[i] = {
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "ClearSelectionMode" }, -- Clear selection but stay in copy mode
			}),
		}
		break
	end
end

return config
