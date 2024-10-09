from string import Template

key_map = Template("""{
  "conditions": [
    {
      "name": "$mode-mode",
      "type": "variable_if",
      "value": 1
    }
  ],
  "from": {
    "key_code": "$_from",
    "modifiers": {
      "optional": [
        "any"
      ]
    }
  },
  "to": [
    {
      "key_code": "$to",
      "modifiers": [
        $to_mod
      ]
    }
  ],
  "type": "basic"
},
{
  "from": {
    "simultaneous": [
      {
        "key_code": "$mode"
      },
      {
        "key_code": "$_from"
      }
    ],
    "simultaneous_options": {
      "detect_key_down_uninterruptedly": true,
      "key_down_order": "strict",
      "key_up_order": "strict_inverse",
      "key_up_when": "any",
      "to_after_key_up": [
        {
          "set_variable": {
            "name": "$mode-mode",
            "value": 0
          }
        }
      ]
    }
  },
  "to": [
    {
      "set_variable": {
        "name": "$mode-mode",
        "value": 1
      }
    },
    {
      "key_code": "$to",
      "modifiers": [
        $to_mod
      ]
    }
  ],
  "type": "basic"
},
""")


# result = "["
# result += key_map.substitute(
#     mode="s", _from="y", to="grave_accent_and_tilde", to_mod=""
# )
# result += key_map.substitute(mode="s", _from="u", to="2", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="i", to="3", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="o", to="4", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="p", to="5", to_mod='"left_shift"')
# result += key_map.substitute(
#     mode="s", _from="h", to="grave_accent_and_tilde", to_mod='"left_shift"'
# )
# result += key_map.substitute(mode="s", _from="j", to="hyphen", to_mod="")
# result += key_map.substitute(mode="s", _from="k", to="hyphen", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="l", to="equal_sign", to_mod="")
# result += key_map.substitute(
#     mode="s", _from="semicolon", to="equal_sign", to_mod='"left_shift"'
# )
# result += key_map.substitute(mode="s", _from="m", to="1", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="comma", to="7", to_mod='"left_shift"')
# result += key_map.substitute(mode="s", _from="period", to="8", to_mod='"left_shift"')
# result += key_map.substitute(
#     mode="s", _from="slash", to="non_us_backslash", to_mod='"left_shift"'
# )
# result = result[: len(result) - 2]
# result += "]"
# print(result)
#
#
# print("f mode")
#
#
# result = "["
# result += key_map.substitute(
#     mode="f", _from="u", to="open_bracket", to_mod='"left_shift"'
# )
# result += key_map.substitute(
#     mode="f", _from="i", to="close_bracket", to_mod='"left_shift"'
# )
# result += key_map.substitute(mode="f", _from="j", to="9", to_mod='"left_shift"')
# result += key_map.substitute(mode="f", _from="k", to="0", to_mod='"left_shift"')
# result += key_map.substitute(mode="f", _from="l", to="comma", to_mod='"left_shift"')
# result += key_map.substitute(
#     mode="f", _from="semicolon", to="period", to_mod='"left_shift"'
# )
# result += key_map.substitute(mode="f", _from="m", to="comma", to_mod='"left_shift"')
# result += key_map.substitute(
#     mode="f", _from="comma", to="period", to_mod='"left_shift"'
# )
# result = result[: len(result) - 2]
# result += "]"
# print(result)

print("a mode")

result = ""
result += key_map.substitute(
    mode="a", _from="m", to="left_arrow", to_mod='"left_option"'
)
result += key_map.substitute(
    mode="a", _from="comma", to="right_arrow", to_mod='"left_option"'
)
result = result[: len(result) - 2]
print(result)
