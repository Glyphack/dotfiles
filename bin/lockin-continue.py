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
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from log import continue_focus

continue_focus()
