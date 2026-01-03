import json

OUTPUT_FILE = "./karabiner/karabiner.json"

HS_BIN = "/opt/homebrew/bin/hs"

SHIFT = ["left_shift"]
CTRL = ["left_control"]
OPT = ["left_option"]
CMD = ["left_command"]
HYPER = ["right_control", "right_option", "right_command"]

MODES = {
    "a": {
        "name": "a-mode",
        "mappings": {
            "u": "tab",
            "i": ("tab", ["left_shift", "left_control"]),
            "o": ("tab", CTRL),
            "p": ("tab", SHIFT),
            "h": "left_arrow",
            "j": "down_arrow",
            "k": "up_arrow",
            "l": "right_arrow",
            "m": ("left_arrow", OPT),  # Word left
            "comma": ("right_arrow", OPT),  # Word right
        },
    },
    "s": {
        "name": "s-mode",
        "mappings": {
            "y": "grave_accent_and_tilde",  # `
            "u": ("2", SHIFT),  # @
            "i": ("3", SHIFT),  # #
            "o": ("4", SHIFT),  # $
            "p": ("5", SHIFT),  # %
            # end
            "h": ("grave_accent_and_tilde", SHIFT),  # ~
            "j": "hyphen",  # -
            "k": ("hyphen", SHIFT),  # _
            "l": "equal_sign",  # =
            "semicolon": ("equal_sign", SHIFT),  # +
            # end
            "n": ("period", SHIFT),  # >
            "m": ("1", SHIFT),  # !
            "comma": ("7", SHIFT),  # &
            "period": ("8", SHIFT),  # *
            "slash": ("backslash", SHIFT),  # |
        },
    },
    "d": {
        "name": "dmode",
        "mappings": {
            "u": "7",
            "i": "8",
            "o": "9",
            "p": ("equal_sign", SHIFT),
            "h": "period",
            "j": "4",
            "k": "5",
            "l": "6",
            "semicolon": "hyphen",
            "n": "0",
            "m": "1",
            "comma": "2",
            "period": "3",
            "slash": "return_or_enter",
        },
    },
    "f": {
        "name": "f-mode",
        "mappings": {
            "u": ("open_bracket", SHIFT),  # (
            "i": ("close_bracket", SHIFT),  # )
            "j": ("9", SHIFT),  # (
            "k": ("0", SHIFT),  # )
            "l": ("comma", SHIFT),  # <
            "semicolon": ("period", SHIFT),  # >
            "m": "open_bracket",  # [
            "comma": "close_bracket",  # ]
        },
    },
}

STATIC_RULES = [
    {
        "description": "Capslock to Hyper",
        "manipulators": [
            {
                "description": "Click to Capslock, Hold to Hyper",
                "type": "basic",
                "from": {"key_code": "caps_lock", "modifiers": {"optional": ["any"]}},
                "to": [
                    {
                        "key_code": "right_command",
                        "modifiers": ["right_control", "right_option"],
                    }
                ],
                "to_if_alone": [{"key_code": "escape"}],
            }
        ],
    },
    {
        "description": "Remap section sign (§) to backtick",
        "manipulators": [
            {
                "type": "basic",
                "from": {"key_code": "non_us_backslash"},
                "to": [{"key_code": "grave_accent_and_tilde"}],
            },
            {
                "type": "basic",
                "from": {
                    "key_code": "non_us_backslash",
                    "modifiers": {"mandatory": ["option"]},
                },
                "to": [{"key_code": "grave_accent_and_tilde", "modifiers": ["option"]}],
            },
            {
                "type": "basic",
                "from": {
                    "key_code": "non_us_backslash",
                    "modifiers": {"mandatory": ["shift"], "optional": ["caps_lock"]},
                },
                "to": [{"key_code": "grave_accent_and_tilde", "modifiers": ["shift"]}],
            },
        ],
    },
    {
        "description": "Change Command-Delete to Command-Backspace",
        "manipulators": [
            {
                "type": "basic",
                "from": {
                    "key_code": "delete_forward",
                    "modifiers": {"mandatory": ["command"], "optional": ["any"]},
                },
                "to": [{"key_code": "delete_or_backspace", "modifiers": ["command"]}],
            }
        ],
    },
]


def make_manipulator(trigger_key, source_key, dest_key, dest_mods, var_name):
    """Generates the simultaneous logic for a single key pair."""

    held_manipulator = {
        "type": "basic",
        "conditions": [{"name": var_name, "type": "variable_if", "value": 1}],
        "from": {"key_code": source_key, "modifiers": {"optional": ["any"]}},
        "to": [{"key_code": dest_key}],
    }
    if dest_mods:
        held_manipulator["to"][0]["modifiers"] = dest_mods

    simultaneous_manipulator = {
        "type": "basic",
        "from": {
            "simultaneous": [{"key_code": trigger_key}, {"key_code": source_key}],
            "simultaneous_options": {
                "detect_key_down_uninterruptedly": True,
                "key_down_order": "strict",
                "key_up_order": "strict_inverse",
                "key_up_when": "any",
                "to_after_key_up": [
                    {"set_variable": {"name": var_name, "value": 0}},
                    {
                        "shell_command": f"{HS_BIN} -c 'UpdateKarabinerMode(\"{var_name}\", 0)'"
                    },
                ],
            },
        },
        "to": [
            {"set_variable": {"name": var_name, "value": 1}},
            {"shell_command": f"{HS_BIN} -c 'UpdateKarabinerMode(\"{var_name}\", 1)'"},
            {
                "key_code": dest_key,
            },
        ],
    }
    if dest_mods:
        simultaneous_manipulator["to"][-1]["modifiers"] = dest_mods

    return [held_manipulator, simultaneous_manipulator]


def generate_complex_modifications():
    rules = []

    for trigger, config in MODES.items():
        var_name = config["name"]
        mappings = config["mappings"]

        manipulators = []

        for source, target in mappings.items():
            if isinstance(target, tuple):
                dest_key, dest_mods = target
            else:
                dest_key = target
                dest_mods = []

            manipulators.extend(
                make_manipulator(trigger, source, dest_key, dest_mods, var_name)
            )

        rules.append(
            {"description": f"{var_name} generated rules", "manipulators": manipulators}
        )

    rules.extend(STATIC_RULES)

    return {
        "complex_modifications": {
            "parameters": {"basic.simultaneous_threshold_milliseconds": 150},
            "rules": rules,
        }
    }


def main():
    generated_profile = {
        "name": "Generated Profile",
        "virtual_hid_keyboard": {"country_code": 0, "keyboard_type_v2": "ansi"},
        **generate_complex_modifications(),
        "simple_modifications": [
            {
                "from": {"key_code": "right_command"},
                "to": [{"key_code": "right_control"}],
            },
            {"from": {"key_code": "right_option"}, "to": [{"key_code": "left_option"}]},
        ],
        "devices": [
            {
                "identifiers": {
                    "device_address": "f0-81-d4-b9-f3-2b",
                    "is_keyboard": True,
                    "is_pointing_device": True,
                },
                "ignore": False,
                "treat_as_built_in_keyboard": True,
            }
        ],
    }

    final_json = {
        "global": {"show_in_menu_bar": False},
        "profiles": [generated_profile],
    }

    with open(OUTPUT_FILE, "w") as f:
        json.dump(final_json, f, indent=2)

    print(f"Successfully generated {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
