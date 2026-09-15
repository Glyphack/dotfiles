mode({
  description: 'f layer: brackets',
  trigger: 'f',
  variable: 'f-mode',
  mappings: [
    { from: 'u', to: 'open_bracket', modifiers: SHIFT },
    { from: 'i', to: 'close_bracket', modifiers: SHIFT },
    { from: 'j', to: '9', modifiers: SHIFT },
    { from: 'k', to: '0', modifiers: SHIFT },
    { from: 'l', to: 'comma', modifiers: SHIFT },
    { from: 'semicolon', to: 'period', modifiers: SHIFT },
    { from: 'm', to: 'open_bracket' },
    { from: 'comma', to: 'close_bracket' },
  ],
})
