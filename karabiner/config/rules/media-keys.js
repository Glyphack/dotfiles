function mediaKey(mapping) {
  return {
    type: 'basic',
    from: {
      key_code: mapping.from,
      modifiers: { optional: ['any'] },
    },
    to: [{ consumer_key_code: mapping.to }],
  }
}

function main() {
  var mappings = [
    { from: 'f1', to: 'display_brightness_decrement' },
    { from: 'f2', to: 'display_brightness_increment' },
    { from: 'f7', to: 'rewind' },
    { from: 'f8', to: 'play_or_pause' },
    { from: 'f9', to: 'fastforward' },
    { from: 'f10', to: 'mute' },
    { from: 'f11', to: 'volume_decrement' },
    { from: 'f12', to: 'volume_increment' },
  ]

  return {
    description: 'Function keys to brightness, media and volume',
    manipulators: mappings.map(mediaKey),
  }
}

main()
