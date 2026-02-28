#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Logger
# @raycast.mode silent
# @raycast.icon 📝
# @raycast.packageName Obsidian Tools
# @raycast.argument1 { "type": "text", "placeholder": "message" }
# @raycast.argument2 { "type": "text", "placeholder": "place", "optional": true }

# Documentation:
# @raycast.author shayegan
# @raycast.description Log a timestamped message to today's section in the weekly Obsidian note

import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

VAULT = subprocess.check_output(["fish", "-c", "echo $vault"], text=True).strip()
VAULT_WEEKLY = Path(VAULT) / "Weekly"


def build_log_entry(msg, place):
    timestamp = datetime.now().strftime("%H:%M")
    entry = f'log: {timestamp} "{msg}"'
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


def main():
    msg = sys.argv[1]
    place = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None

    today = date.today()
    iso = today.isocalendar()
    filepath = VAULT_WEEKLY / f"{iso.year}-W{iso.week:02d}.md"

    if not filepath.exists():
        print(f"Weekly file not found: {filepath.name}")
        sys.exit(1)

    log_entry = build_log_entry(msg, place)
    lines = filepath.read_text().splitlines()
    lines = insert_log(lines, f"# {today.isoformat()}", log_entry)

    filepath.write_text("\n".join(lines) + "\n")


main()
