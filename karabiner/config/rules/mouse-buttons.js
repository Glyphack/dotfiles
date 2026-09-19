var rule = {
  description: 'Mouse side buttons copy and paste',
  manipulators: [
    {
      type: 'basic',
      from: { pointing_button: 'button4' },
      to: [{ key_code: 'c', modifiers: ['left_command'] }],
    },
    {
      type: 'basic',
      from: { pointing_button: 'button5' },
      to: [{ key_code: 'v', modifiers: ['left_command'] }],
    },
  ],
}

rule
