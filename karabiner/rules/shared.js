var SHIFT = ['left_shift']
var CTRL = ['left_control']
var OPT = ['left_option']
var SHIFT_CTRL = ['left_shift', 'left_control']

var SIMULTANEOUS_THRESHOLD_MILLISECONDS = 150

function mode(layer) {
  var manipulators = []

  layer.mappings.forEach(function (mapping) {
    manipulators.push(whileHeld(layer, mapping))
    manipulators.push(pressedTogether(layer, mapping))
  })

  return { description: layer.description, manipulators: manipulators }
}

function whileHeld(layer, mapping) {
  return {
    type: 'basic',
    conditions: [{ name: layer.variable, type: 'variable_if', value: 1 }],
    from: { key_code: mapping.from, modifiers: { optional: ['any'] } },
    to: [output(mapping)],
  }
}

function pressedTogether(layer, mapping) {
  return {
    type: 'basic',
    parameters: {
      'basic.simultaneous_threshold_milliseconds': SIMULTANEOUS_THRESHOLD_MILLISECONDS,
    },
    from: {
      simultaneous: [{ key_code: layer.trigger }, { key_code: mapping.from }],
      simultaneous_options: {
        detect_key_down_uninterruptedly: true,
        key_down_order: 'strict',
        key_up_order: 'strict_inverse',
        key_up_when: 'any',
        to_after_key_up: [{ set_variable: { name: layer.variable, value: 0 } }],
      },
    },
    to: [{ set_variable: { name: layer.variable, value: 1 } }, output(mapping)],
  }
}

function output(mapping) {
  if (!mapping.modifiers) {
    return { key_code: mapping.to }
  }

  return { key_code: mapping.to, modifiers: mapping.modifiers }
}
