function swap(mapping) {
  return {
    type: 'basic',
    from: {
      key_code: mapping.from,
      modifiers: { optional: ['any'] },
    },
    to: [{ key_code: mapping.to }],
  }
}

function main() {
  var mappings = [
    { from: 'right_command', to: 'right_control' },
    { from: 'right_option', to: 'left_option' },
  ]

  return {
    description: 'Right command to control, right option to left option',
    manipulators: mappings.map(swap),
  }
}

main()
