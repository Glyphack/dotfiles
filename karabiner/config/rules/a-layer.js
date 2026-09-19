mode({
  description: 'a layer: arrows',
  trigger: 'a',
  variable: 'a-mode',
  mappings: [
    { from: 'u', to: 'tab' },
    { from: 'i', to: 'tab', modifiers: SHIFT_CTRL },
    { from: 'o', to: 'tab', modifiers: CTRL },
    { from: 'p', to: 'tab', modifiers: SHIFT },
    { from: 'h', to: 'left_arrow' },
    { from: 'j', to: 'down_arrow' },
    { from: 'k', to: 'up_arrow' },
    { from: 'l', to: 'right_arrow' },
    { from: 'm', to: 'left_arrow', modifiers: OPT },
    { from: 'comma', to: 'right_arrow', modifiers: OPT },
  ],
})
