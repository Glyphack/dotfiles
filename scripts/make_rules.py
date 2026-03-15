#!/usr/bin/env python3

import os

files = ["CLAUDE.md", "AGENTS.md"]

source = None
for fname in files:
    if os.path.isfile(fname) and not os.path.islink(fname):
        source = fname
        break

if source is None:
    open("AGENTS.md", "w").close()
    source = "AGENTS.md"

for fname in files:
    if fname == source:
        continue
    if os.path.islink(fname) or os.path.isfile(fname):
        os.remove(fname)
    os.symlink(source, fname)
