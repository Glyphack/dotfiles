#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Continue focus
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ⏩

# Documentation:
# @raycast.author glyphack
# @raycast.description Continue the last focus session

import os
import subprocess
import sys
from urllib.parse import quote, urlencode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from log import get_vault_name


def main():
    params = {"vault": get_vault_name(), "background": "1"}
    url = f"obsidian://dots-continue-focus?{urlencode(params, quote_via=quote)}"
    result = subprocess.run(["open", "-g", url], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Failed to open Obsidian: {result.stderr.strip()}")
        sys.exit(1)
    print("Continuing focus")


if __name__ == "__main__":
    main()
