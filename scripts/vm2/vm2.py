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

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

HOME = Path.home()
DOTFILES = HOME / "Programming" / "dotfiles"
SCRIPT_DIR = Path(__file__).resolve().parent
VM_HOME = Path("/home/node")
IMAGE_TAG = "vm2"

# Updating first matters: the launcher resolves the version at exec time, so
# starting the baked binary pins the whole session to whatever the image shipped.
CLAUDE_LAUNCH = "claude update; claude --dangerously-skip-permissions"

SIZES: dict[str, dict[str, str]] = {
    "small": {"memory": "4g", "cpus": "4"},
    "large": {"memory": "6g", "cpus": "4"},
}


def exec(cmd, cwd=None, quite=True, check=True) -> subprocess.CompletedProcess[str]:
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

    if result.returncode != 0 and not check:
        return result

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


def container_ls_names(*, include_stopped: bool = True) -> list[str]:
    cmd = ["container", "ls", "-q"] + (["-a"] if include_stopped else [])
    return [n for n in exec(cmd).stdout.splitlines() if n.strip()]


def is_vm2_resource(name: str, project: str | None) -> bool:
    """True if the container or volume belongs to vm2, and to project if given."""
    if not name.startswith(f"{IMAGE_TAG}-"):
        return False
    if project is None:
        return True
    container_names = {f"{IMAGE_TAG}-{size}-{project}" for size in SIZES}
    return name in container_names or name.startswith(f"{IMAGE_TAG}-{project}-")


def host_claude_version() -> str | None:
    """Read the version the host last updated to, so the image can match it."""
    result_file = HOME / ".claude" / ".last-update-result.json"
    if not result_file.is_file():
        return None
    try:
        payload = json.loads(result_file.read_text())
    except (json.JSONDecodeError, OSError):
        return None
    version = payload.get("version_to")
    if not isinstance(version, str) or not re.fullmatch(r"[0-9]+(\.[0-9]+)+", version):
        return None
    return version


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
    """Container-run contributions: volume mounts, env vars, and setup commands."""

    volume_args: list[str] = field(default_factory=list)
    env_args: list[str] = field(default_factory=list)
    setup_commands: list[str] = field(default_factory=list)

    def extend(self, other: PluginsOutput) -> None:
        self.volume_args.extend(other.volume_args)
        self.env_args.extend(other.env_args)
        self.setup_commands.extend(other.setup_commands)


@dataclass
class ProjectVolumes:
    """Volume mounts for a project and the dirs whose ownership needs fixing.

    Named volumes are created owned by root, so the `node` user cannot write to
    them until they are chowned. cache_dirs holds those mount points.
    """

    args: list[str]
    cache_dirs: list[Path]


def split_setup_commands(value: str) -> list[str]:
    """Split a SETUP value on `;`, honoring `\\;` as a literal semicolon."""
    commands = []
    for part in re.split(r"(?<!\\);", value):
        command = part.replace(r"\;", ";").strip()
        if command:
            commands.append(command)
    return commands


def load_plugins() -> PluginsOutput:
    result = PluginsOutput()

    path = plugin_path()
    if not path.is_file():
        return result

    plugin_output = exec([sys.executable, str(path)], quite=True)

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


def project_volumes(*, pwd: Path) -> ProjectVolumes:
    project_id = pwd.name
    result = ProjectVolumes(args=[], cache_dirs=[])

    append_mount(result.args, pwd, pwd)
    append_mount(result.args, f"{HOME}/.claude", f"{VM_HOME}/.claude")
    append_mount(result.args, f"{HOME}/.databrickscfg", "/tmp/databrickscfg", ro=True)

    cache_volumes = {
        "package.json": ("node_modules", pwd / "node_modules"),
        "Cargo.toml": ("target", pwd / "target"),
        "go.mod": ("gobin", pwd / "bin"),
    }
    for marker, (suffix, target) in cache_volumes.items():
        if not (pwd / marker).is_file():
            continue
        append_mount(result.args, f"vm2-{project_id}-{suffix}", str(target))
        result.cache_dirs.append(target)

    if is_git_repo():
        git_dir = exec(["git", "rev-parse", "--git-common-dir"]).stdout.strip()
        if git_dir == ".git":
            git_dir = pwd / git_dir
        append_mount(result.args, git_dir, pwd / ".git")

    return result


def github_auth() -> PluginsOutput:
    """Read the host gh token and prepare the container to use it for git and gh."""
    auth = PluginsOutput()

    if not shutil.which("gh"):
        print("Warning: gh not found on host, container gets no GitHub auth.")
        return auth

    result = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True)
    token = result.stdout.strip()
    if result.returncode != 0 or not token:
        print("Warning: 'gh auth token' failed, container gets no GitHub auth.")
        return auth

    auth.env_args = ["-e", f"GH_TOKEN={token}", "-e", f"GITHUB_TOKEN={token}"]
    auth.setup_commands = [
        "gh auth setup-git",
        "git config --global --add url.https://github.com/.insteadOf git@github.com:",
        "git config --global --add url.https://github.com/.insteadOf ssh://git@github.com/",
    ]
    return auth


def cmd_build() -> None:
    exec(
        [
            "container",
            "system",
            "start",
        ]
    )

    claude_version = host_claude_version()
    if claude_version is None:
        claude_version = "latest"
        print(
            "Warning: could not read the host Claude version, building with "
            "'latest'. The install layer may be served from cache and stay on "
            "an older version. Add --no-cache if the container Claude is stale."
        )

    exec_replace(
        [
            "container",
            "build",
            "-f",
            str(SCRIPT_DIR / "Containerfile"),
            "--build-arg",
            f"CLAUDE_VERSION={claude_version}",
            "-t",
            IMAGE_TAG,
            f"{SCRIPT_DIR}/",
        ]
    )


def print_disk_usage(label: str) -> None:
    print(f"{label}:")
    print(exec(["container", "system", "df"]).stdout, end="")


def prune_containers(*, project: str | None, force: bool) -> None:
    running = set(container_ls_names(include_stopped=False))
    targets = [n for n in container_ls_names() if is_vm2_resource(n, project)]
    if not targets:
        print("No vm2 containers to remove.")
        return

    removable = [n for n in targets if force or n not in running]
    kept = [n for n in targets if n not in removable]

    if removable:
        print(f"Removing containers: {', '.join(removable)}")
        container_remove(removable, force=True)
    if kept:
        print(f"Leaving running containers alone (use --force): {', '.join(kept)}")


def prune_volumes(*, project: str | None) -> None:
    targets = [n for n in volume_ls_names() if is_vm2_resource(n, project)]
    if not targets:
        print("No vm2 volumes to remove.")
        return

    for volume in targets:
        result = exec(["container", "volume", "rm", volume], check=False)
        if result.returncode == 0:
            print(f"Removed volume {volume}")
            continue
        print(f"Kept volume {volume}, it is still attached to a container")


def prune_images(*, all_unused: bool) -> None:
    print("Pruning images...")
    cmd = ["container", "image", "prune"] + (["--all"] if all_unused else [])
    exec(cmd, quite=False, check=False)


def prune_builder() -> None:
    if "buildkit" not in container_ls_names():
        return
    print("Deleting the builder to drop its build cache...")
    exec(["container", "builder", "delete", "--force"], check=False)


def cmd_prune(*, project: str | None, force: bool, all_images: bool) -> None:
    print_disk_usage("Disk usage before")

    prune_containers(project=project, force=force)
    prune_volumes(project=project)
    if project is None:
        prune_images(all_unused=all_images)
        prune_builder()

    print_disk_usage("Disk usage after")


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
                f"{CLAUDE_LAUNCH}; exec zsh",
            ]
        )

    plugins = github_auth()
    plugins.extend(load_plugins())
    volumes = project_volumes(pwd=pwd)

    setup_commands = []

    setup_commands.append(
        [
            f"git config --global --add safe.directory {shlex.quote(str(pwd))}",
        ]
    )
    for cache_dir in volumes.cache_dirs:
        setup_commands.append([f"sudo chown node:node {shlex.quote(str(cache_dir))}"])
    setup_commands.extend([command] for command in plugins.setup_commands)
    setup_commands.append([CLAUDE_LAUNCH])
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
        *volumes.args,
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
    prune_parser = subparsers.add_parser(
        "prune",
        help="Reclaim disk from vm2 containers, volumes, images, and build cache.",
    )
    prune_parser.add_argument(
        "project",
        nargs="?",
        help=(
            "Only prune this project's container and volumes. "
            "Images and the build cache are left alone."
        ),
    )
    prune_parser.add_argument(
        "--force",
        action="store_true",
        help="Also remove running containers, killing their sessions.",
    )
    prune_parser.add_argument(
        "--all",
        dest="all_images",
        action="store_true",
        help="Remove every unused image, not just dangling ones.",
    )
    parser.set_defaults(command="s")

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)

    ensure_container_installed()

    if args.command == "build":
        cmd_build()
    elif args.command == "prune":
        cmd_prune(
            project=args.project,
            force=args.force,
            all_images=args.all_images,
        )
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
