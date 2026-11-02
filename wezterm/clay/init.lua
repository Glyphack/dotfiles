-- This file belongs to clay and is written again on every update.

local wezterm = require("wezterm")

local M = {}

local function copy_last_command_output(window, pane)
	local zones = pane:get_semantic_zones("Output")
	for i = #zones, 1, -1 do
		local text = pane:get_text_from_semantic_zone(zones[i]):gsub("%s+$", "")
		text = text:gsub("⏎$", "")
		if text ~= "" then
			window:copy_to_clipboard(text, "Clipboard")
			return
		end
	end
	window:toast_notification("wezterm", "No command output found", nil, 2000)
end

-- Lets outside tools switch workspace and pane by setting the user var
-- "switch_to" to "<workspace>|<pane id>|<nonce>". The pane id may be empty.
local function switch_on_user_var(window, pane, name, value)
	if name ~= "switch_to" then
		return
	end
	local workspace, pane_id = value:match("^(.-)|(%d*)|")
	if not workspace then
		return
	end
	window:perform_action(wezterm.action.SwitchToWorkspace({ name = workspace }), pane)
	local target = tonumber(pane_id) and wezterm.mux.get_pane(tonumber(pane_id))
	if not target then
		return
	end
	target:tab():activate()
	target:activate()
end

function M.set_theme(config, light, dark)
	if wezterm.gui and wezterm.gui.get_appearance():find("Dark") then
		config.color_scheme = dark
		return
	end
	config.color_scheme = light
end

local function use_hack_font(config)
	if config.font then
		return
	end
	config.font = wezterm.font("Hack Nerd Font Mono")
end

function M.apply_to_config(config)
	if not config.color_scheme then
		M.set_theme(config, "flexoki-light", "flexoki-dark")
	end
	use_hack_font(config)

	config.keys = config.keys or {}
	table.insert(config.keys, {
		key = "c",
		mods = "CMD|SHIFT",
		description = "Copy last command output to clipboard",
		action = wezterm.action_callback(copy_last_command_output),
	})

	wezterm.on("user-var-changed", switch_on_user_var)
end

local loading = false

function M.load()
	if loading then
		return nil
	end
	loading = true
	local config = dofile(wezterm.config_file)
	M.apply_to_config(config)
	return config
end

return M
