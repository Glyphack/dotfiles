local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

config.leader = { key = "a", mods = "CMD", timeout_milliseconds = 1000 }
config.key_tables = {
	copy_mode = wezterm.gui.default_key_tables().copy_mode,
}
config.font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.font_size = 18
config.color_scheme = "catppuccin-mocha"

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

local function get_workspace_choices()
	local choices = {}
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		table.insert(choices, { id = name, label = "🖥 " .. name })
	end
	-- Add a special entry to create a new workspace
	table.insert(choices, { id = "__new__", label = "Create workspace" })
	-- Add a special entry to rename current workspace
	table.insert(choices, { id = "__rename__", label = "Rename current workspace" })
	table.insert(choices, { id = "__clear__", label = "Clear workspaces" })
	return choices
end

local run_child_process = function(cmd)
	local process_args = { os.getenv("SHELL"), "-c", cmd }
	local success, stdout, stderr = wezterm.run_child_process(process_args)

	if not success then
		wezterm.log_error("Child process '" .. cmd .. "' failed with stderr: '" .. stderr .. "'")
	end
	return stdout
end

config.keys = {
	-- terminal
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

	-- Pane management
	{ key = "s", mods = "CMD", action = act.SplitHorizontal, description = "Split pane horizontally" },
	{
		key = "x",
		mods = "CMD",
		action = act.CloseCurrentPane({ confirm = true }),
		description = "Close current pane",
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

	-- Move around
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

	-- workspace
	{
		key = "Enter",
		mods = "CMD",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(
				act.InputSelector({
					title = "Workspace Switcher",
					choices = get_workspace_choices(),
					fuzzy = true,
					fuzzy_description = "Switch / Create / Rename: ",
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if not id then
							return
						end

						if id == "__new__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, pane)
									local cmd = run_child_process("echo $FZF_ALT_C_COMMAND")
									local stdout = run_child_process(cmd)

									local choices = {}
									for dir in stdout:gmatch("[^\n]+") do
										table.insert(choices, { label = dir })
									end

									win:perform_action(
										act.InputSelector({
											title = "Select project directory",
											fuzzy = true,
											fuzzy_description = "Search: ",
											choices = choices,
											action = wezterm.action_callback(function(inner_win, inner_pane, id, cwd)
												if not cwd or cwd == "" then
													return
												end
												local name = run_child_process("basename " .. cwd)
												inner_win:perform_action(
													act.SwitchToWorkspace({ name = name, spawn = { cwd = cwd } }),
													inner_pane
												)
											end),
										}),
										pane
									)
								end),
								inner_pane
							)
						elseif id == "__rename__" then
							inner_window:perform_action(
								act.PromptInputLine({
									description = "New name for workspace '" .. inner_window:active_workspace() .. "':",
									action = wezterm.action_callback(function(win, p, line)
										if line and line ~= "" then
											wezterm.mux.rename_workspace(win:active_workspace(), line)
										end
									end),
								}),
								inner_pane
							)
						elseif id == "__clear__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, pane)
									local active_workspace = win:active_workspace()
									local mux = wezterm.mux

									for _, mux_win in ipairs(mux.all_windows()) do
										if mux_win:get_workspace() ~= active_workspace then
											for _, tab in ipairs(mux_win:tabs()) do
												tab:close()
											end
										end
									end
								end),
								inner_pane
							)
						else
							inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
						end
					end),
				}),
				pane
			)
		end),
	},
}

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.colors = {
	scrollbar_thumb = "gray",
}
config.background = {
	{
		source = {
			File = wezterm.home_dir .. "/Programming/dotfiles/wezterm/backgrounds/planet.jpg",
		},
		repeat_x = "Mirror",
		hsb = { brightness = 0.05 },
	},
}

config.switch_to_last_active_tab_when_closing_tab = true

config.inactive_pane_hsb = {
	saturation = 0.7,
	brightness = 0.5,
}
config.scrollback_lines = 100000

local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")

return config
