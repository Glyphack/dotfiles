var rule = {
  description: 'Caps lock to escape or hyper',
  manipulators: [
    {
      type: 'basic',
      from: { key_code: 'caps_lock', modifiers: { optional: ['any'] } },
      to: [{ key_code: 'right_command', modifiers: ['right_control', 'right_option'] }],
      to_if_alone: [{ key_code: 'escape' }],
    },
  ],
}

rule
