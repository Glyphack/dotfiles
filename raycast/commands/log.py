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
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote, urlencode

FISH_SHELL = "/opt/homebrew/bin/fish"


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


@dataclass
class LogRequest:
    message: str
    place: str | None = None
    start: str | None = None
    end: str | None = None

    def params(self):
        params = {"vault": get_vault_name(), "message": self.message}
        if self.place:
            params["place"] = self.place
        if self.start:
            params["from"] = self.start
        if self.end:
            params["to"] = self.end
        return params

    def send(self):
        url = f"obsidian://dots-log?{urlencode(self.params(), quote_via=quote)}"
        result = subprocess.run(["open", "-g", url], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Failed to open Obsidian: {result.stderr.strip()}")
            sys.exit(1)


def get_arg_optional(i):
    return sys.argv[i] if len(sys.argv) > i and sys.argv[i] else None


def main():
    request = LogRequest(
        message=sys.argv[1],
        place=get_arg_optional(2),
        start=get_arg_optional(3),
    )
    request.send()
    print("Logged")


if __name__ == "__main__":
    main()
