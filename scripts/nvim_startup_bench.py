#!/usr/bin/env python3

# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""
Measure Neovim startup time and fail when it exceeds a budget.

Two scenarios are timed, each with its own budget: opening the dotfiles
directory, and opening a single file. Opening a file costs more than opening a
directory because it pays for treesitter parsing and an LSP attach.

Each scenario runs a few warmup iterations, then several measured ones, and is
judged on its fastest sample. The fastest sample is the one least polluted by
unrelated load on the machine, so it tracks a real change in startup cost far
more tightly than the median does. The median and slowest samples are reported
alongside it for context but do not decide the outcome.

Timings are read from Neovim's own --startuptime log rather than wall clock, so
shell and process spawn overhead are excluded. Neovim is started headless. A
headless start skips the terminal background colour query that an interactive
start performs, so these numbers are a lower bound on what a real terminal
costs, not an exact match for it.
"""

from __future__ import annotations

import argparse
import shutil
import statistics
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
FOLDER_BUDGET_MS = 50.0
FILE_BUDGET_MS = 76.0
DEFAULT_RUNS = 7
WARMUP_RUNS = 2
STARTED_MARKER = "--- NVIM STARTED ---"


@dataclass(frozen=True)
class Scenario:
    name: str
    target: Path
    budget_ms: float

    def command(self, log: Path) -> list[str]:
        return [
            "nvim",
            "--headless",
            "--startuptime",
            str(log),
            str(self.target),
            "+qa!",
        ]


@dataclass
class Measurement:
    scenario: Scenario
    samples: list[float]

    @property
    def best(self) -> float:
        return min(self.samples)

    @property
    def median(self) -> float:
        return statistics.median(self.samples)

    @property
    def worst(self) -> float:
        return max(self.samples)

    @property
    def budget_ms(self) -> float:
        return self.scenario.budget_ms

    def within_budget(self) -> bool:
        return self.best <= self.budget_ms

    def format(self) -> str:
        status = "ok" if self.within_budget() else "FAIL"
        return (
            f"{status:>4}  {self.scenario.name:<16} "
            f"{self.best:6.1f} ms  budget {self.budget_ms:5.1f} ms  "
            f"(median {self.median:.1f}, slowest {self.worst:.1f}, n={len(self.samples)})"
        )


def read_total_ms(log: Path) -> float:
    """Return the largest startup total in a --startuptime log.

    A log can hold more than one profile when Neovim splits its UI and server
    into separate processes. The largest total is the one that covers a full
    startup.
    """
    totals = [
        float(line.split()[0])
        for line in log.read_text().splitlines()
        if STARTED_MARKER in line
    ]
    if not totals:
        raise RuntimeError(f"no startup marker found in {log}")
    return max(totals)


def time_once(scenario: Scenario) -> float:
    with tempfile.TemporaryDirectory() as tmp:
        log = Path(tmp) / "startuptime.log"
        result = subprocess.run(
            scenario.command(log), capture_output=True, text=True, timeout=60
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"nvim exited {result.returncode} for {scenario.name}: "
                f"{result.stderr.strip()}"
            )
        return read_total_ms(log)


def measure(scenario: Scenario, runs: int) -> Measurement:
    for _ in range(WARMUP_RUNS):
        time_once(scenario)
    return Measurement(scenario, [time_once(scenario) for _ in range(runs)])


def build_scenarios(budget_override: float | None) -> list[Scenario]:
    folder_budget = budget_override if budget_override else FOLDER_BUDGET_MS
    file_budget = budget_override if budget_override else FILE_BUDGET_MS
    return [
        Scenario("dotfiles folder", REPO, folder_budget),
        Scenario("single file", REPO / "nvim" / "init.lua", file_budget),
    ]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--budget-ms",
        type=float,
        default=None,
        help=(
            "override every scenario budget in ms "
            f"(defaults: folder {FOLDER_BUDGET_MS:.0f}, file {FILE_BUDGET_MS:.0f})"
        ),
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=DEFAULT_RUNS,
        help=f"measured runs per scenario (default: {DEFAULT_RUNS})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if shutil.which("nvim") is None:
        print("nvim not on PATH, skipping startup benchmark")
        return 0

    scenarios = build_scenarios(args.budget_ms)
    measurements = [measure(scenario, args.runs) for scenario in scenarios]
    for measurement in measurements:
        print(measurement.format())

    over = [m for m in measurements if not m.within_budget()]
    if not over:
        print("\nboth scenarios are within budget")
        return 0

    for measurement in over:
        excess = measurement.best - measurement.budget_ms
        print(
            f"\n{measurement.scenario.name} is {excess:.1f} ms over its "
            f"{measurement.budget_ms:.0f} ms budget"
        )
    return 1


if __name__ == "__main__":
    sys.exit(main())
