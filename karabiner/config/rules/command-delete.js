var rule = {
  description: 'Command delete to backspace',
  manipulators: [
    {
      type: 'basic',
      from: {
        key_code: 'delete_forward',
        modifiers: { mandatory: ['command'], optional: ['any'] },
      },
      to: [{ key_code: 'delete_or_backspace', modifiers: ['command'] }],
    },
  ],
}

rule
