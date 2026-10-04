#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Work
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💼
# @raycast.argument1 {"type": "text", "title": "Duration (minutes)", "placeholder": "Default: 30", "optional": true}
# @raycast.argument2 {"type": "text", "title": "Message", "placeholder": "e.g. standup prep", "optional": true}

# Documentation:
# @raycast.author glyphack
# @raycast.description Start a Work focus session

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lockin_core import run

run("work")
