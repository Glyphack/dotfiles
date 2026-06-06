#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Log
# @raycast.mode silent
# @raycast.icon 📝
# @raycast.packageName Obsidian Tools
# @raycast.argument1 { "type": "text", "placeholder": "message" }
# @raycast.argument2 { "type": "text", "placeholder": "place", "optional": true }
# @raycast.argument3 { "type": "text", "placeholder": "from", "optional": true }

# Documentation:
# @raycast.author shayegan
# @raycast.description Log a timestamped message to today's section in the weekly Obsidian note

import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

FISH_SHELL = "/opt/homebrew/bin/fish"


def get_vault_path():
    result = subprocess.run(
        [FISH_SHELL, "-lc", "echo $vault"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Fish exited with {result.returncode}: {result.stderr.strip()}")
        sys.exit(1)
    if not result.stdout.strip():
        print("$vault is empty or not set in fish")
        sys.exit(1)
    return Path(result.stdout.strip())


VAULT = get_vault_path()
VAULT_WEEKLY = VAULT / "Weekly"


def build_log_entry(msg, place, start_time, end_time=None):
    timestamp = start_time.strftime("%H:%M")
    if end_time:
        timestamp = f"{timestamp}-{end_time.strftime('%H:%M')}"
    entry = f"{timestamp} > {msg}"
    if place:
        entry += f" place: {place}"
    return entry


def find_section(lines, header):
    for i, line in enumerate(lines):
        if line.strip() == header:
            return i
    return None


def find_next_header(lines, after):
    for i, line in enumerate(lines[after + 1 :], start=after + 1):
        if line.startswith("# "):
            return i
    return None


def find_first_date_header(lines):
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("# 20") and len(stripped) == 12:
            return i
    return None


def insert_log(lines, today_header, log_entry):
    today_idx = find_section(lines, today_header)

    if today_idx is None:
        return create_today_section(lines, today_header, log_entry)

    insert_at = find_next_header(lines, today_idx) or len(lines)
    while insert_at > today_idx + 1 and not lines[insert_at - 1].strip():
        insert_at -= 1
    lines.insert(insert_at, log_entry)
    return lines


def create_today_section(lines, today_header, log_entry):
    first_date_idx = find_first_date_header(lines)
    new_section = [today_header, "", log_entry, ""]

    if first_date_idx is not None:
        return lines[:first_date_idx] + new_section + lines[first_date_idx:]

    return lines + [""] + new_section


def log_msg(msg, place, start_time, end_time=None):
    today = date.today()
    iso = today.isocalendar()
    filepath = VAULT_WEEKLY / f"{iso.year}-W{iso.week:02d}.md"

    if not filepath.exists():
        print(f"Weekly file not found: {filepath.name}")
        sys.exit(1)

    log_entry = build_log_entry(msg, place, start_time, end_time)
    lines = filepath.read_text().splitlines()
    lines = insert_log(lines, f"# {today.isoformat()}", log_entry)

    filepath.write_text("\n".join(lines) + "\n")


def get_arg_optional(i):
    return sys.argv[i] if len(sys.argv) > i and sys.argv[i] else None


def main():
    msg = sys.argv[1]
    place = get_arg_optional(2)
    start_time = get_arg_optional(3)
    if start_time:
        parsed_time = datetime.strptime(start_time, "%H:%M").time()
        print(parsed_time)
        start_time = datetime.combine(date.today(), parsed_time)
        end_time = datetime.now()
    else:
        start_time = datetime.now()
        end_time = None

    log_msg(msg, place, start_time, end_time)


if __name__ == "__main__":
    main()
