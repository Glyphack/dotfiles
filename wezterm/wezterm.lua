local wezterm = require 'wezterm'
return {
  font = wezterm.font 'JetBrains Mono',
  font_size = 20.0,
  keys = {
    {
      key = 'm',
      mods = 'CMD',
      action = wezterm.action.DisableDefaultAssignment,
    },
  },
  color_scheme = 'Cai (Gogh)',
}
