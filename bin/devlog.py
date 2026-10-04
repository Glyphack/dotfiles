#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Devlog
# @raycast.mode silent
# @raycast.icon 🛠️
# @raycast.packageName Obsidian Tools
# @raycast.argument1 { "type": "text", "placeholder": "message" }

# Documentation:
# @raycast.author glyphack
# @raycast.description Prepend a timestamped message to the top of Devlogs.md

import subprocess
import sys
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
DEVLOGS = VAULT / "Devlogs.md"


def prepend(filepath: Path, entry: str):
    if filepath.exists() is False:
        return
    existing = filepath.read_text()

    pos = 0
    if existing.startswith("---"):
        pos = existing.find("---", 3) + 4

    filepath.write_text(existing[:pos] + entry + "\n" + existing[pos:])


def main():
    msg = sys.argv[1]
    prepend(DEVLOGS, msg)


if __name__ == "__main__":
    main()
