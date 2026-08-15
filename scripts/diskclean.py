#!/usr/bin/env python3

"""
Free disk space by cleaning developer caches and build artifacts.

The default run prunes the uv cache, runs cargo clean on every Rust project
under ~/Programming, uninstalls rustup toolchains that are not stable, the
latest nightly, or pinned by a rust-toolchain file, and clears the cargo,
go, npm, pnpm, pre-commit, Homebrew, and mise caches plus a fixed list of
tool caches under ~/Library/Caches and ~/.cache.

--dry-run prints what would be removed and how much space it would free,
without deleting anything.
--deep additionally deletes node_modules and virtualenv directories under
~/Programming, wipes the whole uv cache instead of pruning it, and removes
mise tool versions that no config references.
"""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

try:
    import tomllib
except ImportError:
    tomllib = None

HOME = Path.home()
PROGRAMMING = HOME / "Programming"
CACHE = HOME / ".cache"
LIB_CACHES = HOME / "Library" / "Caches"
RUSTUP = HOME / ".rustup"
CARGO = HOME / ".cargo"
NPM = HOME / ".npm"
UV_CACHE = CACHE / "uv"
GO_DIR = HOME / "go"
GO_MOD_CACHE = GO_DIR / "pkg" / "mod"
GO_BUILD_CACHE = LIB_CACHES / "go-build"
PNPM_DIR = HOME / "Library" / "pnpm"
DERIVED_DATA = HOME / "Library" / "Developer" / "Xcode" / "DerivedData"
MISE_INSTALLS = HOME / ".local" / "share" / "mise" / "installs"

ALLOWED_RM_PREFIXES = (
    CACHE,
    CARGO,
    RUSTUP,
    NPM,
    LIB_CACHES,
    DERIVED_DATA,
    GO_DIR,
    PROGRAMMING,
    PNPM_DIR,
)

LIB_CACHE_TARGETS = (
    "pip",
    "node-gyp",
    "Yarn",
    "ms-playwright-go",
    "virtualenv",
    "goimports",
    "typescript",
    "vscode-cpptools",
)

DOT_CACHE_TARGETS = (
    "puppeteer",
    "rod",
    "clojure-lsp",
    "pyright-python",
    "proselint",
)

MAX_WALK_DEPTH = 12
SKIP_DIRS = {".git", "target"}

VERSION_RE = re.compile(r"\d+(\.\d+){0,2}")
DATED_NIGHTLY_RE = re.compile(r"nightly-\d{4}-\d{2}-\d{2}")


def run_capture(argv: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(argv, capture_output=True, text=True, check=False)


def error_snippet(result: subprocess.CompletedProcess[str]) -> str:
    text = (result.stderr or result.stdout or "").strip()
    if not text:
        return f"exit code {result.returncode}"
    return text.splitlines()[-1][:200]


def du_kb(path: Path) -> int:
    if not os.path.lexists(path):
        return 0
    result = run_capture(["du", "-sk", str(path)])
    try:
        return int(result.stdout.split()[0])
    except (IndexError, ValueError):
        return 0


def human(kb: float) -> str:
    value = float(kb)
    for unit in ("KB", "MB", "GB"):
        if value < 1024:
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{value:.1f} TB"


def display(path: Path) -> str:
    text = str(path)
    home = str(HOME)
    if text.startswith(home):
        return "~" + text[len(home) :]
    return text


def free_space_kb() -> int:
    stats = os.statvfs(HOME)
    return stats.f_bavail * stats.f_frsize // 1024


def assert_rm_allowed(path: Path) -> None:
    resolved = path.resolve()
    for prefix in ALLOWED_RM_PREFIXES:
        if resolved != prefix and resolved.is_relative_to(prefix):
            return
    raise RuntimeError(f"refusing to delete {path}, outside the allowed locations")


def remove_tree(path: Path) -> None:
    assert_rm_allowed(path)
    if path.is_dir():
        shutil.rmtree(path)
    else:
        path.unlink()


def remove_contents(path: Path) -> None:
    for child in path.iterdir():
        if child.is_symlink():
            continue
        remove_tree(child)


def parse_toolchain_channel(path: Path) -> str | None:
    try:
        text = path.read_text()
    except OSError:
        return None
    if tomllib is not None:
        try:
            data = tomllib.loads(text)
        except Exception:
            data = None
        if isinstance(data, dict):
            channel = data.get("toolchain", {}).get("channel")
            if isinstance(channel, str) and channel:
                return channel
            return None
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            return line
    return None


@dataclass
class Discovery:
    cargo_roots: list[Path] = field(default_factory=list)
    node_modules: list[Path] = field(default_factory=list)
    venvs: list[Path] = field(default_factory=list)
    toolchain_channels: set[str] = field(default_factory=set)


def scan_programming() -> Discovery:
    found = Discovery()
    if not PROGRAMMING.is_dir():
        return found
    base_depth = len(PROGRAMMING.parts)
    for root, dirs, files in os.walk(PROGRAMMING, topdown=True, followlinks=False):
        root_path = Path(root)
        if len(root_path.parts) - base_depth >= MAX_WALK_DEPTH:
            dirs[:] = []
            continue
        descend = []
        for name in dirs:
            child = root_path / name
            if name == "node_modules":
                found.node_modules.append(child)
            elif name in SKIP_DIRS:
                pass
            elif (child / "pyvenv.cfg").is_file():
                found.venvs.append(child)
            else:
                descend.append(name)
        dirs[:] = descend
        target = root_path / "target"
        if "Cargo.toml" in files and not target.is_symlink() and target.is_dir():
            found.cargo_roots.append(root_path)
        for file_name in ("rust-toolchain", "rust-toolchain.toml"):
            if file_name in files:
                channel = parse_toolchain_channel(root_path / file_name)
                if channel:
                    found.toolchain_channels.add(channel)
    return found


@dataclass
class RustupPlan:
    keep: list[str]
    remove: list[str]


def rustup_host() -> str:
    result = run_capture(["rustup", "show"])
    for line in result.stdout.splitlines():
        if line.startswith("Default host:"):
            return line.split(":", 1)[1].strip()
    return ""


def channel_part(name: str, host: str) -> str:
    suffix = "-" + host
    if host and name.endswith(suffix):
        return name[: -len(suffix)]
    return name


def version_components(text: str) -> list[int] | None:
    if not VERSION_RE.fullmatch(text):
        return None
    return [int(piece) for piece in text.split(".")]


def channel_keeps(channel: str, name: str, part: str) -> bool:
    if channel in (name, part):
        return True
    if channel in ("stable", "beta", "nightly") or DATED_NIGHTLY_RE.fullmatch(channel):
        return part == channel
    wanted = version_components(channel)
    installed = version_components(part)
    if wanted is None or installed is None:
        return False
    return installed[: len(wanted)] == wanted


def plan_rustup_removals(channels: set[str]) -> RustupPlan | None:
    listing = run_capture(["rustup", "toolchain", "list"])
    if listing.returncode != 0:
        return None
    entries: list[tuple[str, bool]] = []
    for line in listing.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        name = line.split()[0]
        flags = line[len(name) :]
        entries.append((name, "default" in flags or "active" in flags))
    if not entries:
        return None
    host = rustup_host()
    parts = {name: channel_part(name, host) for name, _ in entries}
    keep = {name for name, protected in entries if protected}
    keep.update(name for name, _ in entries if parts[name] in ("stable", "beta"))
    nightlies = [
        name
        for name, _ in entries
        if parts[name] == "nightly" or DATED_NIGHTLY_RE.fullmatch(parts[name])
    ]
    if nightlies:
        undated = [name for name in nightlies if parts[name] == "nightly"]
        keep.add(
            undated[0] if undated else max(nightlies, key=lambda name: parts[name])
        )
    for channel in channels:
        keep.update(
            name for name, _ in entries if channel_keeps(channel, name, parts[name])
        )
    remove = [name for name, _ in entries if name not in keep]
    return RustupPlan(keep=sorted(keep), remove=remove)


def mise_install_size(tool: str, version: str) -> int:
    slug = tool.replace(":", "-").replace("/", "-").replace(".", "-")
    return du_kb(MISE_INSTALLS / slug / version)


def parse_mise_prune_versions(output: str) -> list[tuple[str, str]]:
    versions: list[tuple[str, str]] = []
    for line in output.splitlines():
        for token in line.split():
            if "@" not in token:
                continue
            tool, _, version = token.partition("@")
            if tool and version and (tool, version) not in versions:
                versions.append((tool, version))
            break
    return versions


def git_tracks_files(path: Path) -> bool:
    if shutil.which("git") is None:
        return False
    result = run_capture(["git", "-C", str(path), "ls-files", "--", "."])
    return result.returncode == 0 and bool(result.stdout.strip())


@dataclass
class Step:
    text: str
    kb: int = 0
    ok: bool = True
    upper_bound: bool = False


@dataclass
class TaskSpec:
    name: str
    run: Callable[[Cleaner], list[Step]]
    tool: str | None = None
    deep_only: bool = False


@dataclass
class TaskOutcome:
    name: str
    kb: int
    upper_bound: bool
    failures: int


class Cleaner:
    def __init__(self, deep: bool, dry_run: bool) -> None:
        self.deep = deep
        self.dry_run = dry_run
        self.found = Discovery()

    def command_step(
        self, argv: list[str], probes: list[Path], upper_bound: bool = False
    ) -> list[Step]:
        existing = [probe for probe in probes if os.path.lexists(probe)]
        if not existing:
            missing = ", ".join(display(probe) for probe in probes)
            return [Step(f"nothing to do, {missing} missing")]
        before = sum(du_kb(probe) for probe in existing)
        if self.dry_run:
            prefix = "up to " if upper_bound else ""
            return [
                Step(
                    f"would run: {shlex.join(argv)} (frees {prefix}{human(before)})",
                    kb=before,
                    upper_bound=upper_bound,
                )
            ]
        result = run_capture(argv)
        after = sum(du_kb(probe) for probe in existing)
        freed = max(before - after, 0)
        if result.returncode != 0:
            return [
                Step(
                    f"failed: {shlex.join(argv)}: {error_snippet(result)}",
                    kb=freed,
                    ok=False,
                )
            ]
        return [Step(f"{shlex.join(argv)} freed {human(freed)}", kb=freed)]

    def rm_step(self, path: Path, contents_only: bool = False) -> list[Step]:
        if path.is_symlink():
            return [Step(f"skipped, {display(path)} is a symlink")]
        if not os.path.lexists(path):
            return [Step(f"nothing to do, {display(path)} missing")]
        if not contents_only:
            assert_rm_allowed(path)
        kb = du_kb(path)
        label = f"contents of {display(path)}" if contents_only else display(path)
        if self.dry_run:
            return [Step(f"would delete {label} ({human(kb)})", kb=kb)]
        try:
            if contents_only:
                remove_contents(path)
            else:
                remove_tree(path)
        except (OSError, RuntimeError) as error:
            return [Step(f"failed to delete {label}: {error}", ok=False)]
        return [Step(f"deleted {label} ({human(kb)})", kb=kb)]

    def wipe_project_dirs(
        self, paths: list[Path], label: str, require_sibling: str | None = None
    ) -> list[Step]:
        if not paths:
            return [Step(f"no {label} found")]
        steps: list[Step] = []
        for path in paths:
            if not path.resolve().is_relative_to(PROGRAMMING):
                steps.append(
                    Step(f"skipped, {display(path)} resolves outside ~/Programming")
                )
                continue
            if require_sibling and not (path.parent / require_sibling).is_file():
                steps.append(
                    Step(f"skipped, {display(path)} has no sibling {require_sibling}")
                )
                continue
            if git_tracks_files(path):
                steps.append(
                    Step(f"skipped, {display(path)} contains git-tracked files")
                )
                continue
            steps.extend(self.rm_step(path))
        return steps

    def task_uv_cache(self) -> list[Step]:
        argv = ["uv", "cache", "clean"] if self.deep else ["uv", "cache", "prune"]
        return self.command_step(argv, [UV_CACHE], upper_bound=not self.deep)

    def task_cargo_projects(self) -> list[Step]:
        if not self.found.cargo_roots:
            return [Step("no cargo projects with a target directory found")]
        steps: list[Step] = []
        for root in self.found.cargo_roots:
            kb = du_kb(root / "target")
            if self.dry_run:
                steps.append(
                    Step(
                        f"would run cargo clean in {display(root)} ({human(kb)})", kb=kb
                    )
                )
                continue
            result = run_capture(
                ["cargo", "clean", "--manifest-path", str(root / "Cargo.toml")]
            )
            if result.returncode != 0:
                steps.append(
                    Step(
                        f"failed: cargo clean in {display(root)}: {error_snippet(result)}",
                        ok=False,
                    )
                )
            else:
                steps.append(
                    Step(f"cargo clean in {display(root)} freed {human(kb)}", kb=kb)
                )
        return steps

    def task_rustup_toolchains(self) -> list[Step]:
        plan = plan_rustup_removals(self.found.toolchain_channels)
        if plan is None:
            return [Step("failed to read the rustup toolchain list", ok=False)]
        pins = ", ".join(sorted(self.found.toolchain_channels)) or "none"
        steps = [
            Step(f"pinned channels found in ~/Programming: {pins}"),
            Step("keeping: " + ", ".join(plan.keep)),
        ]
        if not plan.remove:
            steps.append(Step("no toolchains to remove"))
            return steps
        for name in plan.remove:
            kb = du_kb(RUSTUP / "toolchains" / name)
            if self.dry_run:
                steps.append(Step(f"would uninstall {name} ({human(kb)})", kb=kb))
                continue
            result = run_capture(["rustup", "toolchain", "uninstall", name])
            if result.returncode != 0:
                steps.append(
                    Step(
                        f"failed to uninstall {name}: {error_snippet(result)}", ok=False
                    )
                )
            else:
                steps.append(Step(f"uninstalled {name} ({human(kb)})", kb=kb))
        return steps

    def task_cargo_registry(self) -> list[Step]:
        steps: list[Step] = []
        for sub in ("registry/cache", "registry/src", "git/db", "git/checkouts"):
            steps.extend(self.rm_step(CARGO / sub))
        return steps

    def task_rustup_scratch(self) -> list[Step]:
        steps: list[Step] = []
        for sub in ("downloads", "tmp"):
            steps.extend(self.rm_step(RUSTUP / sub, contents_only=True))
        return steps

    def task_go_caches(self) -> list[Step]:
        return self.command_step(
            ["go", "clean", "-cache", "-modcache"], [GO_MOD_CACHE, GO_BUILD_CACHE]
        )

    def task_npm_cache(self) -> list[Step]:
        steps = self.command_step(
            ["npm", "cache", "clean", "--force"], [NPM / "_cacache"]
        )
        steps.extend(self.rm_step(NPM / "_npx"))
        return steps

    def task_node_modules(self) -> list[Step]:
        return self.wipe_project_dirs(
            self.found.node_modules,
            "node_modules directories",
            require_sibling="package.json",
        )

    def task_venvs(self) -> list[Step]:
        return self.wipe_project_dirs(self.found.venvs, "virtualenvs")

    def task_pnpm_store(self) -> list[Step]:
        store = PNPM_DIR / "store"
        if not store.is_dir():
            return [Step("pnpm store not present, nothing to do")]
        return self.command_step(["pnpm", "store", "prune"], [store], upper_bound=True)

    def task_pre_commit(self) -> list[Step]:
        return self.command_step(
            ["pre-commit", "gc"], [CACHE / "pre-commit"], upper_bound=True
        )

    def task_homebrew(self) -> list[Step]:
        return self.command_step(
            ["brew", "cleanup", "--prune=all"],
            [LIB_CACHES / "Homebrew"],
            upper_bound=True,
        )

    def task_mise_cache(self) -> list[Step]:
        return self.command_step(["mise", "cache", "clear"], [LIB_CACHES / "mise"])

    def task_mise_prune(self) -> list[Step]:
        preview = run_capture(["mise", "prune", "--dry-run"])
        if preview.returncode != 0:
            return [
                Step(
                    f"failed: mise prune --dry-run: {error_snippet(preview)}", ok=False
                )
            ]
        versions = parse_mise_prune_versions(preview.stdout + preview.stderr)
        if not versions:
            return [Step("mise prune has nothing to remove")]
        steps: list[Step] = []
        rust_versions = [
            f"rust@{version}" for tool, version in versions if tool == "rust"
        ]
        if rust_versions:
            steps.append(
                Step(
                    "leaving to rustup, not pruned via mise: "
                    + ", ".join(rust_versions)
                )
            )
        tools = sorted({tool for tool, _ in versions if tool != "rust"})
        if not tools:
            steps.append(Step("nothing to prune besides rust versions"))
            return steps
        argv = ["mise", "prune", "-y", *tools]
        if self.dry_run:
            total = 0
            for tool, version in versions:
                if tool == "rust":
                    continue
                kb = mise_install_size(tool, version)
                total += kb
                suffix = f" ({human(kb)})" if kb else ""
                steps.append(Step(f"would remove {tool}@{version}{suffix}", kb=kb))
            steps.append(Step(f"would run: {shlex.join(argv)}"))
            return steps
        steps.extend(self.command_step(argv, [MISE_INSTALLS]))
        return steps

    def task_library_caches(self) -> list[Step]:
        steps: list[Step] = []
        for name in LIB_CACHE_TARGETS:
            steps.extend(self.rm_step(LIB_CACHES / name))
        return steps

    def task_dot_cache(self) -> list[Step]:
        steps: list[Step] = []
        for name in DOT_CACHE_TARGETS:
            steps.extend(self.rm_step(CACHE / name))
        return steps

    def task_derived_data(self) -> list[Step]:
        return self.rm_step(DERIVED_DATA, contents_only=True)

    def task_nvim_cache(self) -> list[Step]:
        running = subprocess.run(["pgrep", "-x", "nvim"], capture_output=True)
        if running.returncode == 0:
            return [Step("skipped, nvim is running")]
        return self.rm_step(CACHE / "nvim")

    def run(self) -> int:
        mode = "deep" if self.deep else "default"
        if self.dry_run:
            print(f"diskclean dry run ({mode} tier), nothing will be deleted")
        else:
            print(f"diskclean ({mode} tier)")
        free_before = free_space_kb()
        print(f"free space: {human(free_before)}")
        print("scanning ~/Programming ...")
        self.found = scan_programming()
        print(
            f"found {len(self.found.cargo_roots)} cargo projects, "
            f"{len(self.found.node_modules)} node_modules, "
            f"{len(self.found.venvs)} virtualenvs, "
            f"{len(self.found.toolchain_channels)} pinned rust channels"
        )
        outcomes: list[TaskOutcome] = []
        for spec in TASKS:
            if spec.deep_only and not self.deep:
                continue
            print(f"==> {spec.name}")
            if spec.tool and shutil.which(spec.tool) is None:
                steps = [Step(f"skipped, {spec.tool} is not installed")]
            else:
                try:
                    steps = spec.run(self)
                except Exception as error:
                    steps = [Step(f"failed: {error}", ok=False)]
            for step in steps:
                print(f"    {step.text}")
            outcomes.append(
                TaskOutcome(
                    name=spec.name,
                    kb=sum(step.kb for step in steps),
                    upper_bound=any(step.upper_bound for step in steps),
                    failures=sum(1 for step in steps if not step.ok),
                )
            )
        self.print_summary(outcomes, free_before)
        self.print_manual_opportunities()
        return 1 if any(outcome.failures for outcome in outcomes) else 0

    def print_summary(self, outcomes: list[TaskOutcome], free_before: int) -> None:
        print()
        print("summary (dry run)" if self.dry_run else "summary")
        for outcome in outcomes:
            size = human(outcome.kb)
            if outcome.upper_bound:
                size = "up to " + size
            line = f"  {outcome.name:<36} {size:>14}"
            if outcome.failures:
                line += f"  ({outcome.failures} failed)"
            print(line)
        total = sum(outcome.kb for outcome in outcomes)
        if self.dry_run:
            qualifier = "up to " if any(o.upper_bound for o in outcomes) else ""
            print(f"  estimated total reclaim: {qualifier}{human(total)}")
            return
        free_after = free_space_kb()
        print(f"  per-target estimate: {human(total)}")
        print(f"  free space gained: {human(max(free_after - free_before, 0))}")
        print("  the two can differ because of hardlinked cache entries")

    def print_manual_opportunities(self) -> None:
        items = [
            (
                HOME / "Library" / "Developer" / "Toolchains",
                "manually installed toolchains, remove by hand if unused",
            ),
            (LIB_CACHES / "com.spotify.client", "Spotify cache, skipped by design"),
            (LIB_CACHES / "BraveSoftware", "Brave cache, skipped by design"),
            (LIB_CACHES / "com.brave.Browser", "Brave cache, skipped by design"),
            (LIB_CACHES / "Google", "Google apps cache, skipped by design"),
            (LIB_CACHES / "Steam", "Steam cache, skipped by design"),
        ]
        if not self.deep:
            items.append(
                (
                    MISE_INSTALLS,
                    "mise tool versions, run diskclean.py --deep or mise prune",
                )
            )
        lines = []
        for path, note in items:
            if not path.exists():
                continue
            lines.append(f"  {display(path):<52} {human(du_kb(path)):>12}  {note}")
        if not lines:
            return
        print()
        print("left alone, clean manually if you want the space:")
        for line in lines:
            print(line)


TASKS = (
    TaskSpec("uv cache", Cleaner.task_uv_cache, tool="uv"),
    TaskSpec("cargo clean projects", Cleaner.task_cargo_projects, tool="cargo"),
    TaskSpec("rustup toolchains", Cleaner.task_rustup_toolchains, tool="rustup"),
    TaskSpec("cargo registry and git caches", Cleaner.task_cargo_registry),
    TaskSpec("rustup downloads and tmp", Cleaner.task_rustup_scratch),
    TaskSpec("go caches", Cleaner.task_go_caches, tool="go"),
    TaskSpec("npm cache", Cleaner.task_npm_cache, tool="npm"),
    TaskSpec(
        "node_modules in ~/Programming", Cleaner.task_node_modules, deep_only=True
    ),
    TaskSpec("virtualenvs in ~/Programming", Cleaner.task_venvs, deep_only=True),
    TaskSpec("pnpm store", Cleaner.task_pnpm_store, tool="pnpm"),
    TaskSpec("pre-commit environments", Cleaner.task_pre_commit, tool="pre-commit"),
    TaskSpec("homebrew leftovers", Cleaner.task_homebrew, tool="brew"),
    TaskSpec("mise cache", Cleaner.task_mise_cache, tool="mise"),
    TaskSpec(
        "mise unused tool versions",
        Cleaner.task_mise_prune,
        tool="mise",
        deep_only=True,
    ),
    TaskSpec("tool caches in ~/Library/Caches", Cleaner.task_library_caches),
    TaskSpec("tool caches in ~/.cache", Cleaner.task_dot_cache),
    TaskSpec("Xcode DerivedData", Cleaner.task_derived_data),
    TaskSpec("nvim cache", Cleaner.task_nvim_cache),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="diskclean.py",
        description="Free disk space by cleaning developer caches and build artifacts.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print what would be removed and how much space it would free, delete nothing",
    )
    parser.add_argument(
        "--deep",
        action="store_true",
        help="also delete node_modules and virtualenvs under ~/Programming, "
        "wipe the whole uv cache, and prune unused mise tool versions",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cleaner = Cleaner(deep=args.deep, dry_run=args.dry_run)
    return cleaner.run()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
