#!/usr/bin/env python3

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta
from urllib.parse import quote, urlencode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import subprocess

from log import LogRequest

DEFAULT_DURATION_MIN = 30
FISH_SHELL = "/opt/homebrew/bin/fish"


@dataclass(frozen=True)
class Category:
    key: str
    goal: str
    blocks: tuple[str, ...] = ()
    notify: bool = True


CATEGORIES = {
    c.key: c
    for c in [
        Category("writing", "Writing", blocks=("writing-coding",)),
        Category("programming", "Programming", blocks=("writing-coding",)),
        Category("work", "Work"),
        Category("reading", "Reading"),
        Category("afk", "AFK"),
        Category("break", "Break"),
        Category("track", "Track"),
    ]
}


@dataclass
class Session:
    category: Category
    duration_min: int
    message: str | None = None

    def label(self):
        base = f"#focus-session {self.category.goal}"
        return f"{base}: {self.message}" if self.message else base

    def start(self):
        end = datetime.now() + timedelta(minutes=self.duration_min)
        LogRequest(self.label(), end=end.strftime("%H:%M")).send()

        if self.category.notify:
            self.send_notification()

        self.set_one_thing()
        self.open_focus()

    def set_one_thing(self):
        text = (
            f"{self.category.goal}: {self.message}"
            if self.message
            else self.category.goal
        )
        subprocess.run(
            ["open", "--background", "one-thing:?text=" + quote(text, safe="")]
        )

    def send_notification(self):
        subprocess.run(
            [
                FISH_SHELL,
                "-lc",
                f"ntfy {self.duration_min}min '{self.category.goal} time is up'",
            ]
        )

    def open_focus(self):
        params = {
            "goal": self.category.goal,
            "duration": self.duration_min * 60,
            "mode": "block",
        }
        if self.category.blocks:
            params["categories"] = ",".join(self.category.blocks)
        subprocess.run(["open", "raycast://focus/start?" + urlencode(params)])


def parse_duration(raw):
    if not raw:
        return DEFAULT_DURATION_MIN
    try:
        return int(raw)
    except ValueError:
        return DEFAULT_DURATION_MIN


def arg(i):
    return sys.argv[i] if len(sys.argv) > i and sys.argv[i] else None


def run(category_key):
    category = CATEGORIES.get(category_key, Category(category_key, "Focus"))
    session = Session(category, parse_duration(arg(1)), arg(2))
    session.start()
