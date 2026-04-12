local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
--
config.leader = { key = "a", mods = "CMD", timeout_milliseconds = 500 }
config.key_tables = {
	copy_mode = wezterm.gui.default_key_tables().copy_mode,
}
-- config.font = wezterm.font("Hack Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.font_size = 16

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "flexoki-dark"
	else
		return "flexoki-light"
	end
end

local function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

config.color_scheme = scheme_for_appearance(get_appearance())

local run_child_process = function(cmd)
	local process_args = { os.getenv("SHELL"), "-c", cmd }
	local success, stdout, stderr = wezterm.run_child_process(process_args)

	if not success then
		wezterm.log_error("Child process '" .. cmd .. "' failed with stderr: '" .. stderr .. "'")
	end
	return stdout
end

local function get_workspace_choices()
	local choices = {}
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		table.insert(choices, { id = name, label = "🖥 " .. name })
	end
	table.insert(choices, { id = "__new__", label = "➕ Create new" })
	table.insert(choices, { id = "__delete__", label = "🗑 Delete current" })
	table.insert(choices, { id = "__replace__", label = "🔄 Replace" })
	table.insert(choices, { id = "__rename__", label = "✏️ Rename current" })
	table.insert(choices, { id = "__prune__", label = "🧹 Prune" })
	return choices
end

local function kill_workspace_panes(workspace_name)
	local stdout = run_child_process("wezterm cli list --format json")
	local json = wezterm.json_parse(stdout)
	for _, p in ipairs(json) do
		if p.workspace == workspace_name then
			run_child_process("wezterm cli kill-pane --pane-id=" .. p.pane_id)
		end
	end
end

local function pick_directory_and_switch(win, pane, callback)
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
				callback(inner_win, inner_pane, cwd)
			end),
		}),
		pane
	)
end

local function directory_name(pane)
	local cwd = pane:get_current_working_directory()
	if cwd then
		return cwd.file_path:match("([^/]+)/?$") or cwd.file_path
	end
	return nil
end

local function workspace_name_for_directory(cwd)
	local project, worktree = cwd:match("wk/([^/]+)/([^/]+)/?$")
	if project and worktree then
		return project .. "/" .. worktree
	end
	return cwd:match("([^/]+)/?$") or cwd
end

local function switch_to_workspace_for_directory(win, pane, opts)
	local old_workspace = opts and opts.old_workspace
	pick_directory_and_switch(win, pane, function(inner_win, inner_pane, cwd)
		local name = workspace_name_for_directory(cwd)
		inner_win:perform_action(act.SwitchToWorkspace({ name = name, spawn = { cwd = cwd } }), inner_pane)
		if old_workspace and old_workspace ~= "" then
			kill_workspace_panes(old_workspace)
		end
	end)
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
	{
		key = "d",
		mods = "LEADER",
		description = "Detach tab to new window",
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_window()
		end),
	},

	-- workspace
	{
		key = "Enter",
		mods = "CMD",
		action = wezterm.action_callback(function(window, pane)
			local current = window:active_workspace()
			if current ~= "default" then
				for _, name in ipairs(wezterm.mux.get_workspace_names()) do
					if name == "default" then
						kill_workspace_panes("default")
						break
					end
				end
			end
			window:perform_action(
				act.InputSelector({
					title = "Workspace Switcher",
					choices = get_workspace_choices(),
					fuzzy = true,
					fuzzy_description = "Workspaces:",
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if not id then
							return
						end

						if id == "__new__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, p)
									switch_to_workspace_for_directory(win, p)
								end),
								inner_pane
							)
						elseif id == "__delete__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, p)
									local current = win:active_workspace()
									local workspaces = wezterm.mux.get_workspace_names()
									local others = {}
									for _, name in ipairs(workspaces) do
										if name ~= current then
											table.insert(others, name)
										end
									end
									if #others == 0 then
										return
									end
									if #others == 1 then
										win:perform_action(act.SwitchToWorkspace({ name = others[1] }), p)
										kill_workspace_panes(current)
									else
										local choices = {}
										for _, name in ipairs(others) do
											table.insert(choices, { id = name, label = "🖥 " .. name })
										end
										win:perform_action(
											act.InputSelector({
												title = "Switch to which workspace?",
												choices = choices,
												fuzzy = true,
												fuzzy_description = "Switch to: ",
												action = wezterm.action_callback(function(w, pp, target_id)
													if target_id and target_id ~= "" then
														w:perform_action(
															act.SwitchToWorkspace({ name = target_id }),
															pp
														)
														kill_workspace_panes(current)
													end
												end),
											}),
											p
										)
									end
								end),
								inner_pane
							)
						elseif id == "__replace__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, p)
									switch_to_workspace_for_directory(
										win,
										p,
										{ old_workspace = win:active_workspace() }
									)
								end),
								inner_pane
							)
						elseif id == "__rename__" then
							inner_window:perform_action(
								act.PromptInputLine({
									description = "New name for workspace '" .. inner_window:active_workspace() .. "':",
									action = wezterm.action_callback(function(win, p, line)
										if line then
											local current_name = win:active_workspace()
											local new_name = line ~= "" and line
												or (current_name == "default" and directory_name(p) or nil)
											if new_name then
												wezterm.mux.rename_workspace(current_name, new_name)
											end
										end
									end),
								}),
								inner_pane
							)
						elseif id == "__prune__" then
							inner_window:perform_action(
								wezterm.action_callback(function(win, p)
									local active_workspace = win:active_workspace()
									for _, name in ipairs(wezterm.mux.get_workspace_names()) do
										if name ~= active_workspace then
											kill_workspace_panes(name)
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
-- config.background = {
-- 	{
-- 		source = {
-- 			File = wezterm.home_dir .. "/Programming/dotfiles/wezterm/backgrounds/planet.jpg",
-- 		},
-- 		repeat_x = "Mirror",
-- 		hsb = { brightness = 0.05 },
-- 	},
-- }

config.switch_to_last_active_tab_when_closing_tab = true

config.inactive_pane_hsb = {
	saturation = 0.7,
	brightness = 0.5,
}
config.scrollback_lines = 10000

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 10,
}

return config
