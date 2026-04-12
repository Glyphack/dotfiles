#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title lockin
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎯
# @raycast.argument1 {"type": "dropdown", "title": "Category", "placeholder": "Pick a category", "data": [{"title": "Work", "value": "work"}, {"title": "Writing", "value": "writing"}, {"title": "Programming", "value": "programming"}, {"title": "AFK", "value": "afk"}, {"title": "Rest", "value": "rest"}, {"title": "Reading", "value": "reading"}]}
# @raycast.argument2 {"type": "text", "title": "Duration (minutes)", "placeholder": "Default: 30", "optional": true}
# @raycast.argument3 {"type": "text", "title": "Message", "placeholder": "e.g. fixing auth bug", "optional": true}

import sys
import os
import subprocess
from datetime import datetime, timedelta
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
    "writing": ["writing-coding"],
    "programming": ["writing-coding"],
}

CATEGORY_GOALS = {
    "reading": "Reading",
    "work": "Work",
    "writing": "Writing",
    "programming": "Programming",
    "afk": "AFK",
    "rest": "Rest",
}

DEFAULT_DURATION_MIN = 30
NTFY_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ntfy.sh")

category = sys.argv[1] if len(sys.argv) > 1 else "work"
duration_min = (
    int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else DEFAULT_DURATION_MIN
)
message = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None
duration_sec = duration_min * 60

goal = CATEGORY_GOALS.get(category, "Focus")

start = datetime.now()
end = start + timedelta(minutes=duration_min)
label = f"#focus-session {goal}: {message}" if message else f"#focus-session {goal}"
log_msg(label, None, start_time=start, end_time=end)

if category in ("afk", "rest"):
    subprocess.run([NTFY_SCRIPT, f"{duration_min}min", f"{goal} time is up"])

blocks = CATEGORY_BLOCKS.get(category, [])
params = {
    "goal": goal,
    "duration": duration_sec,
    "mode": "block",
}
if blocks:
    params["categories"] = ",".join(blocks)
url = "raycast://focus/start?" + urlencode(params)
subprocess.run(["open", url])
