#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title lockin
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎯
# @raycast.argument1 {"type": "dropdown", "title": "Category", "placeholder": "Pick a category", "data": [{"title": "Work", "value": "work"}, {"title": "Writing", "value": "writing"}, {"title": "Programming", "value": "programming"}]}
# @raycast.argument2 {"type": "text", "title": "Duration (minutes)", "placeholder": "Default: 30", "optional": true}

import sys
import os
import subprocess
from urllib.parse import urlencode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from log import log_msg

# ─────────────────────────────────────────────
# CATEGORY → BLOCKED APPS MAPPING
# These must match Focus Categories you created
# in Raycast using "Create Focus Category".
#
# work        → blocks: (add your category names here, e.g. social,gaming)
# writing     → blocks: (add your category names here)
# programming → blocks: (add your category names here)
# ─────────────────────────────────────────────

CATEGORY_BLOCKS = {
    "work": [],
    "writing": ["writing-coding"],
    "programming": ["writing-coding"],
}

CATEGORY_GOALS = {
    "work": "Work",
    "writing": "Writing",
    "programming": "Programming",
}

DEFAULT_DURATION_MIN = 30

category = sys.argv[1] if len(sys.argv) > 1 else "work"
duration_min = (
    int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else DEFAULT_DURATION_MIN
)
duration_sec = duration_min * 60

goal = CATEGORY_GOALS.get(category, "Focus")
blocks = CATEGORY_BLOCKS.get(category, [])

params = {
    "goal": goal,
    "duration": duration_sec,
    "mode": "block",
}

if blocks:
    params["categories"] = ",".join(blocks)

log_msg(f"#focus-session on {goal}", None)
url = "raycast://focus/start?" + urlencode(params)
subprocess.run(["open", url])
