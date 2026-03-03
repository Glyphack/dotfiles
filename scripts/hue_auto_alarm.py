#!/usr/bin/env python3

import json
import subprocess
import sys

ALARM_NAMES = ["Wake up", "morning off", "Night"]


def run_command(args):
    return subprocess.run(args, check=False, capture_output=True, text=True)


def is_alarm_enabled(alarm):
    if "active" in alarm:
        return bool(alarm["active"])
    return False


def enable_alarm_by_name(name, alarms):
    matches = [alarm for alarm in alarms if alarm.get("name") == name]
    if not matches:
        print(f"No alarm named '{name}' found", file=sys.stderr)
        return 1

    alarm = matches[0]
    alarm_id = alarm.get("id")
    if alarm_id is None:
        print(f"Alarm named '{name}' has no id", file=sys.stderr)
        return 1

    if is_alarm_enabled(alarm):
        return 0

    result = run_command(
        ["uv", "run", "huec", "alarms", "enable", "--id", str(alarm_id)]
    )
    if result.returncode != 0:
        err = result.stderr.strip() or f"Failed to enable alarm '{name}'"
        print(err, file=sys.stderr)
        return result.returncode or 1

    return 0


def main():
    result = run_command(["uv", "run", "huec", "alarms", "list", "--json"])
    if result.returncode != 0:
        err = result.stderr.strip() or "Failed to list alarms"
        print(err, file=sys.stderr)
        return result.returncode or 1

    try:
        alarms = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        print(f"Failed to parse alarms JSON: {exc}", file=sys.stderr)
        return 1

    for alarm_name in ALARM_NAMES:
        exit_code = enable_alarm_by_name(alarm_name, alarms)
        if exit_code != 0:
            return exit_code

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
