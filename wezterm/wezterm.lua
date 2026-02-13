local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	local cwd = pane.current_working_dir
	local process = pane.foreground_process_name or ""
	local process_name = process:match("([^/]+)$") or "shell"
	if cwd then
		local folder = cwd.file_path:match("([^/]+)/?$") or cwd.file_path
		return string.format(" %s | %s ", folder, process_name)
	end
	return string.format(" %s ", process_name)
end)

wezterm.on("update-right-status", function(window)
	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = "🔋" .. string.format("%.0f%%", b.state_of_charge * 100)
	end

	local workspace = window:active_workspace()

	window:set_right_status(wezterm.format({
		{ Text = bat .. " | " .. workspace .. "   " },
	}))
end)

wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "switch_workspace" then
		window:perform_action(act.SwitchToWorkspace({ name = value }), pane)
	end
end)

local config = {
	leader = { key = "a", mods = "CMD", timeout_milliseconds = 1000 },
	key_tables = {
		copy_mode = wezterm.gui.default_key_tables().copy_mode,
	},
	font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	font_size = 20,
	keys = {
		{ key = "c", mods = "LEADER", action = act.ActivateCopyMode, description = "Activate copy mode" },
		{
			key = "K",
			mods = "CTRL|SHIFT",
			description = "Clear scrollback and viewport",
			action = act.Multiple({
				act.ClearScrollback("ScrollbackAndViewport"),
				act.SendKey({ key = "L", mods = "CTRL" }),
			}),
		},
		{
			key = "p",
			mods = "CMD",
			description = "Quick select and open URL",
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
		{ key = "[", mods = "LEADER", action = act.ScrollToPrompt(-1), description = "Scroll to previous prompt" },
		{ key = "]", mods = "LEADER", action = act.ScrollToPrompt(1), description = "Scroll to next prompt" },
		{
			key = "u",
			mods = "CMD",
			description = "Focus editor pane (index 0)",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local was_zoomed = tab:set_zoomed(false)
				window:perform_action(act.ActivatePaneByIndex(0), pane)
				tab:set_zoomed(was_zoomed)
			end),
		},
		{
			key = "i",
			mods = "CMD",
			description = "Focus terminal pane (index 1)",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local was_zoomed = tab:set_zoomed(false)
				window:perform_action(act.ActivatePaneByIndex(1), pane)
				tab:set_zoomed(was_zoomed)
			end),
		},
		{
			key = "o",
			mods = "CMD",
			description = "Focus agent pane (index 2)",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local was_zoomed = tab:set_zoomed(false)
				window:perform_action(act.ActivatePaneByIndex(2), pane)
				tab:set_zoomed(was_zoomed)
			end),
		},

		{ key = "x", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }), description = "Close current pane" },
		{ key = "s", mods = "CMD", action = act.SplitHorizontal, description = "Split pane horizontally" },
		{
			key = "e",
			mods = "CMD",
			description = "Cycle to next pane",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local is_zoomed = tab:set_zoomed(false)
				window:perform_action(act.ActivatePaneDirection("Next"), pane)
				tab:set_zoomed(is_zoomed)
			end),
		},
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left"), description = "Move to left pane" },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right"), description = "Move to right pane" },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down"), description = "Move to pane below" },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up"), description = "Move to pane above" },
		{ key = "]", mods = "CMD", action = act.ActivateTabRelative(1), description = "Next tab" },
		{ key = "[", mods = "CMD", action = act.ActivateTabRelative(-1), description = "Previous tab" },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState, description = "Toggle pane zoom" },
		{
			key = "Backspace",
			mods = "CMD",
			description = "Send 'wo' to terminal (fish only)",
			action = wezterm.action_callback(function(window, pane)
				local process = pane:get_foreground_process_name() or ""
				if process:match("fish$") then
					pane:send_text("wo\n")
				end
			end),
		},

		{
			key = "L",
			mods = "CMD|SHIFT",
			description = "Create 3-pane layout: Editor | Terminal / Agent",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				if #tab:panes() >= 3 then
					return
				end
				local right = pane:split({ direction = "Right", size = 0.4 })
				local agent = right:split({ direction = "Bottom", size = 0.5 })
				pane:send_text("vim\n")
				agent:send_text("amp --ide\n")
				pane:activate()
			end),
		},

		{
			key = "Enter",
			mods = "CMD",
			description = "Show workspace launcher",
			action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
		},
		{
			key = "r",
			mods = "LEADER",
			description = "Rename current workspace",
			action = act.PromptInputLine({
				description = "Enter new workspace name:",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
					end
				end),
			}),
		},
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

-- Dim inactive panes to highlight the active one
config.inactive_pane_hsb = {
	saturation = 0.7,
	brightness = 0.5,
}
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
