#!/usr/bin/env python3

"""
Run a container with apple container inside a project to have a sandboxed environment.

Volumes, env vars, etc. can be customized by setting a VM2_PLUGIN_PATH to a file.
This file is python file that after execution must print configuration to stdout.
The configuration is:
    VOLUME src:dest
    SETUP command1;command2
    ENV VAR1=VAL1
"""

from __future__ import annotations
import shutil

import argparse
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

HOME = Path.home()
DOTFILES = HOME / "Programming" / "dotfiles"
SCRIPT_DIR = Path(__file__).resolve().parent
VM_HOME = Path("/home/node")
IMAGE_TAG = "vm2"

SIZES: dict[str, dict[str, str]] = {
    "small": {"memory": "2g", "cpus": "2"},
    "large": {"memory": "6g", "cpus": "4"},
}


def exec(cmd, cwd=None, quite=True) -> subprocess.CompletedProcess[str]:
    if not quite:
        print(f"$ {shlex.join(cmd)}")

    result = subprocess.run(
        cmd,
        cwd=cwd,
        shell=False,
        check=False,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("Error: ", end="")
        if result.returncode == 127:
            print("Command not found")
            sys.exit(result.returncode)
        print(f"Command failed with exit code {result.returncode}")
        print("=" * shutil.get_terminal_size().columns)
        print("stderr:")
        print(result.stderr, end="")
        print("stdout:")
        print(result.stderr, end="")
        sys.exit(1)
    if not quite:
        print(result.stdout, end="")

    return result


def exec_replace(cmd: list[str]) -> None:
    """Replace the current process with cmd (does not return on success)."""
    sys.stdout.flush()
    sys.stderr.flush()
    os.execvp(cmd[0], cmd)


def ensure_container_installed() -> None:
    """Exit with an install hint if the `container` CLI is missing."""
    if shutil.which("container"):
        return
    print("Error: the 'container' command was not found.")
    print("Install it from https://github.com/apple/container")
    sys.exit(1)


def container_ls_names() -> list[str]:
    return [
        n
        for n in exec(["container", "ls", "-q", "-a"]).stdout.splitlines()
        if n.strip()
    ]


def volume_ls_names() -> list[str]:
    return [
        n
        for n in exec(["container", "volume", "ls", "-q"]).stdout.splitlines()
        if n.strip()
    ]


def container_remove(
    names: list[str], *, force: bool = False, quiet: bool = False
) -> None:
    if not names:
        return
    cmd = ["container", "rm"] + (["-f"] if force else []) + names
    if quiet:
        exec(cmd)
        return
    exec(cmd)


def is_container_present(name: str) -> bool:
    """True if a container with this exact name is currently running."""
    res = exec(["container", "ls", "--format", "json"])
    return f'"{name}"' in res.stdout


def append_mount(args: list[str], host, container, *, ro: bool = False) -> None:
    """Append a -v HOST:CONTAINER[:ro] pair to args."""
    spec = f"{host}:{container}"
    if ro:
        spec += ":ro"
    args.extend(["-v", spec])


def plugin_path() -> Path:
    override = os.environ.get("VM2_PLUGIN_PATH")
    return Path(override).expanduser() if override else SCRIPT_DIR / "plugin.py"


@dataclass
class PluginsOutput:
    """The container-run contributions parsed from a plugin's directives."""

    volume_args: list[str]
    env_args: list[str]
    setup_commands: list[str]


def split_setup_commands(value: str) -> list[str]:
    """Split a SETUP value on `;`, honoring `\\;` as a literal semicolon."""
    commands = []
    for part in re.split(r"(?<!\\);", value):
        command = part.replace(r"\;", ";").strip()
        if command:
            commands.append(command)
    return commands


def load_plugins() -> PluginsOutput:
    path = plugin_path()
    if not path.is_file():
        raise FileNotFoundError(f"vm2 plugin not found: {path}")

    plugin_output = exec([sys.executable, str(path)], quite=True)

    result = PluginsOutput(volume_args=[], env_args=[], setup_commands=[])

    for lineno, raw in enumerate(plugin_output.stdout.splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        directive, sep, value = line.partition(" ")
        if not sep:
            raise ValueError(f"plugin.py:{lineno}: directive has no value: {raw!r}")
        if directive == "VOLUME":
            result.volume_args.extend(["-v", value])
        elif directive == "ENV":
            result.env_args.extend(["-e", value])
        elif directive == "SETUP":
            result.setup_commands.extend(split_setup_commands(value))
        else:
            raise ValueError(f"plugin.py:{lineno}: unknown directive: {raw!r}")

    return result


def is_git_repo() -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--git-common-dir"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def volume_args(*, pwd: Path) -> list[str]:
    project_id = pwd.name
    args: list[str] = []

    append_mount(args, pwd, pwd)
    append_mount(args, f"{HOME}/.claude", f"{VM_HOME}/.claude")
    append_mount(args, f"{HOME}/.config/gh", f"{VM_HOME}/.config/gh", ro=True)
    append_mount(args, f"{HOME}/.databrickscfg", "/tmp/databrickscfg", ro=True)

    if (pwd / "package.json").is_file():
        append_mount(args, f"vm2-{project_id}-node_modules", f"{pwd}/node_modules")
    if (pwd / "Cargo.toml").is_file():
        append_mount(args, f"vm2-{project_id}-target", f"{pwd}/target")
    if (pwd / "go.mod").is_file():
        append_mount(args, f"vm2-{project_id}-gobin", f"{pwd}/bin")

    if is_git_repo():
        git_dir = exec(["git", "rev-parse", "--git-common-dir"]).stdout.strip()
        if git_dir == ".git":
            git_dir = pwd / git_dir
        append_mount(args, git_dir, pwd / ".git")

    return args


def cmd_build() -> None:
    exec(
        [
            "container",
            "system",
            "start",
        ]
    )
    exec_replace(
        [
            "container",
            "build",
            "-f",
            str(SCRIPT_DIR / "Containerfile"),
            "-t",
            IMAGE_TAG,
            f"{SCRIPT_DIR}/",
        ]
    )


def cmd_prune() -> None:
    print("Removing vm2 containers...")
    vm2_containers = [n for n in container_ls_names() if n.startswith("vm2")]
    container_remove(vm2_containers, force=True)

    print("Removing vm2 volumes...")
    vm2_volumes = [n for n in volume_ls_names() if n.startswith("vm2")]
    if vm2_volumes:
        exec(["container", "volume", "rm", *vm2_volumes])

    print("Prune complete.")


def cmd_run(*, size: str) -> None:
    profile = SIZES[size]
    pwd = Path.cwd()
    container_name = f"vm2-{size}-{pwd.name}"

    exec(["container", "system", "start"])

    if is_container_present(container_name):
        print(f"Attaching to running container {container_name}...")
        exec_replace(
            [
                "container",
                "exec",
                "-it",
                "-w",
                str(pwd),
                container_name,
                "zsh",
                "-c",
                "claude --dangerously-skip-permissions; exec zsh",
            ]
        )

    plugins = load_plugins()

    setup_commands = []

    setup_commands.append(
        [
            f"git config --global --add safe.directory {shlex.quote(str(pwd))}",
        ]
    )
    setup_commands.extend([command] for command in plugins.setup_commands)
    setup_commands.append(["claude --dangerously-skip-permissions"])
    setup_commands.append(["exec zsh"])
    init = "; ".join(" && ".join(parts) for parts in setup_commands)

    cmd = [
        "container",
        "run",
        "--rm",
        "-it",
        "--name",
        container_name,
        "-e",
        f"CLAUDE_CONFIG_DIR={VM_HOME}/.claude/",
        "-w",
        str(pwd),
        "--memory",
        profile["memory"],
        "--cpus",
        profile["cpus"],
        *plugins.env_args,
        *plugins.volume_args,
        *volume_args(pwd=pwd),
        IMAGE_TAG,
        "zsh",
        "-c",
        init,
    ]

    # print("\n".join(cmd))

    exec_replace(cmd)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="vm2",
        description=(
            "Launch (or attach to) a sandboxed container for the current "
            "project. The container has Claude, language toolchains, and "
            "host config mounted in."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser(
        "s",
        help="Run a small container for the current project (default).",
    )
    subparsers.add_parser(
        "l",
        help="Run a large container for the current project.",
    )
    subparsers.add_parser(
        "build",
        help="Rebuild the vm2 image.",
    )
    subparsers.add_parser(
        "prune",
        help="Remove all vm2 containers and volumes.",
    )
    parser.set_defaults(command="s")

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)

    ensure_container_installed()

    if args.command == "build":
        cmd_build()
    elif args.command == "prune":
        cmd_prune()
    else:
        size = "large" if args.command == "l" else "small"
        cmd_run(
            size=size,
        )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
