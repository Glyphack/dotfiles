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
# @raycast.author glyphack
# @raycast.description Log a timestamped message to today's section in the weekly Obsidian note

from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import quote, urlencode

FISH_SHELL = "/opt/homebrew/bin/fish"
OBSIDIAN_BUNDLE_ID = "md.obsidian"


def get_vault_name():
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
    return Path(result.stdout.strip()).name


def obsidian_is_frontmost():
    result = subprocess.run(
        ["osascript", "-e", "id of app (path to frontmost application as text)"],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() == OBSIDIAN_BUNDLE_ID


@dataclass
class DotsAction:
    name: str
    params: dict[str, str | None] = field(default_factory=dict)

    def url(self):
        params = {"vault": get_vault_name()}
        if not obsidian_is_frontmost():
            params["background"] = "1"
        params.update({key: value for key, value in self.params.items() if value})
        return f"obsidian://dots-{self.name}?{urlencode(params, quote_via=quote)}"

    def send(self):
        result = subprocess.run(["open", "-g", self.url()], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Failed to open Obsidian: {result.stderr.strip()}")
            sys.exit(1)


def arg(i):
    return sys.argv[i] if len(sys.argv) > i and sys.argv[i] else None


def log():
    DotsAction("log", {"message": arg(1), "place": arg(2), "from": arg(3)}).send()
    print("Logged")


def track_time(category):
    DotsAction(
        "track-time",
        {"category": category, "duration": arg(1), "message": arg(2)},
    ).send()


def continue_focus():
    DotsAction("continue-focus").send()
    print("Continuing focus")


if __name__ == "__main__":
    log()
