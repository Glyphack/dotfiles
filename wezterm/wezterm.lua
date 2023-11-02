local wezterm = require 'wezterm'
local act = wezterm.action

wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime '%a %b %-d %H:%M '

  local bat = ''
  for _, b in ipairs(wezterm.battery_info()) do
    bat = '🔋 ' .. string.format('%.0f%%', b.state_of_charge * 100)
  end

  window:set_right_status(wezterm.format {
    { Text = bat .. '   ' .. date },
  })
end)

local config = {
  font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
  font_size = 19.0,
  keys = {
    {
      key = 'm',
      mods = 'CMD',
      action = act.DisableDefaultAssignment,
    },
    {
      key = 'K',
      mods = 'CTRL|SHIFT',
      action = act.Multiple {
        act.ClearScrollback 'ScrollbackAndViewport',
        act.SendKey { key = 'L', mods = 'CTRL' },
      },
    },
    {
      key = "p",
      mods = "CMD",
      action = wezterm.action { QuickSelectArgs = {
        patterns = {
          "https?://\\S+"
        },
        action = wezterm.action_callback(function(window, pane)
          local url = window:get_selection_text_for_pane(pane)
          wezterm.log_info("opening: " .. url)
          wezterm.open_with(url)
        end)
      } }
    },
  },
  color_scheme = "catppuccin-mocha",
}

config.window_background_opacity = .9

return config
