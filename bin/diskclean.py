#!/usr/bin/env python3

"""
Free disk space by cleaning developer caches and build artifacts.

Deletes Rust target folders under ~/Programming, old rustup toolchains, and
tool caches. --dry-run prints what would run or be deleted instead.
"""

import argparse
import os
import re
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()
PROGRAMMING = HOME / "Programming"

COMMANDS = [
    ["uv", "cache", "prune"],
    ["go", "clean", "-cache", "-modcache"],
    ["npm", "cache", "clean", "--force"],
    ["pnpm", "store", "prune"],
    ["pre-commit", "gc"],
    ["brew", "cleanup", "--prune=all"],
    ["mise", "cache", "clear"],
]

FOLDERS = [
    ".cargo/registry/cache",
    ".cargo/registry/src",
    ".cargo/git/db",
    ".cargo/git/checkouts",
    ".rustup/downloads",
    ".rustup/tmp",
    ".npm/_npx",
    ".cache/puppeteer",
    ".cache/rod",
    ".cache/clojure-lsp",
    ".cache/pyright-python",
    ".cache/proselint",
    ".cache/nvim",
    "Library/Caches/pip",
    "Library/Caches/node-gyp",
    "Library/Caches/Yarn",
    "Library/Caches/ms-playwright-go",
    "Library/Caches/virtualenv",
    "Library/Caches/goimports",
    "Library/Caches/typescript",
    "Library/Caches/vscode-cpptools",
    "Library/Developer/Xcode/DerivedData",
]

# Matches stable, beta, and the latest nightly, but not dated nightlies or versions.
KEPT_TOOLCHAIN = re.compile(r"(stable|beta|nightly)-\D")

SKIPPED_DIRS = {".git", "target", "node_modules", ".venv"}


def run(cmd: list[str], dry_run: bool) -> None:
    if shutil.which(cmd[0]) is None:
        return
    print(f"==> {' '.join(cmd)}")
    if not dry_run:
        subprocess.run(cmd)


def remove(path: Path, dry_run: bool) -> int:
    if path.is_symlink() or not path.exists():
        return 0
    du = subprocess.run(["du", "-sk", path], capture_output=True, text=True)
    kb = int(du.stdout.split()[0])
    print(f"deleting {path} ({kb / 1024:.1f} MB)")
    if not dry_run:
        shutil.rmtree(path)
    return kb


def cargo_targets() -> list[Path]:
    found = []
    for root, dirs, files in os.walk(PROGRAMMING):
        if "Cargo.toml" in files:
            found.append(Path(root) / "target")
        dirs[:] = [name for name in dirs if name not in SKIPPED_DIRS]
    return found


def remove_old_toolchains(dry_run: bool) -> None:
    if shutil.which("rustup") is None:
        return
    listing = subprocess.run(
        ["rustup", "toolchain", "list"], capture_output=True, text=True
    ).stdout
    for line in listing.splitlines():
        name = line.split(" ")[0]
        if not name or "(" in line or KEPT_TOOLCHAIN.match(name):
            continue
        run(["rustup", "toolchain", "uninstall", name], dry_run)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    dry_run = parser.parse_args().dry_run

    for cmd in COMMANDS:
        run(cmd, dry_run)
    remove_old_toolchains(dry_run)
    paths = [HOME / folder for folder in FOLDERS] + cargo_targets()
    total_kb = sum(remove(path, dry_run) for path in paths)
    print(f"deleted {total_kb / 1024**2:.1f} GB")


if __name__ == "__main__":
    main()
