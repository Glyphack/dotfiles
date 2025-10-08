#!/usr/bin/env python3

import os

source_files = ["CLAUDE.md", "AGENTS.md", "GEMINI.md"]
rules_file = ".rules"

found_file = None
for fname in source_files:
    if os.path.isfile(fname):
        found_file = fname
        break

if found_file and not os.path.exists(rules_file):
    with (
        open(found_file, "r", encoding="utf-8") as src,
        open(rules_file, "w", encoding="utf-8") as dst,
    ):
        dst.write(src.read())

for fname in source_files:
    if os.path.islink(fname) or os.path.isfile(fname):
        os.remove(fname)
    os.symlink(rules_file, fname)
