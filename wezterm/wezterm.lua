local wezterm = require 'wezterm'
local act = wezterm.action
return {
  font = wezterm.font 'JetBrains Mono',
  font_size = 20.0,
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
  },
  color_scheme = 'Erebus (terminal.sexy)',
}
