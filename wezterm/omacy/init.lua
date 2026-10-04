-- This file belongs to omacy and is written again on every update.

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

local function follow_system_appearance(config)
	if config.color_scheme then
		return
	end
	if wezterm.gui and wezterm.gui.get_appearance():find("Dark") then
		config.color_scheme = "flexoki-dark"
		return
	end
	config.color_scheme = "flexoki-light"
end

local function use_hack_font(config)
	if config.font then
		return
	end
	config.font = wezterm.font("Hack Nerd Font Mono")
end

function M.apply_to_config(config)
	follow_system_appearance(config)
	use_hack_font(config)

	config.keys = config.keys or {}
	table.insert(config.keys, {
		key = "c",
		mods = "CMD|SHIFT",
		description = "Copy last command output to clipboard",
		action = wezterm.action_callback(copy_last_command_output),
	})
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
