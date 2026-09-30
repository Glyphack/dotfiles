# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Writes every file in rules/ into karabiner.json as its own eval_js rule.

Each generated rule gets the description "dotfiles: <file name>". On a rerun, rules with that description get their
code updated in place, keeping their position and the enabled state set in the Karabiner window. Rules whose file is
gone are removed, new files are added at the end, and rules without that description (added by hand or by other
tools) are left alone. Files named *-layer.js get shared.js pasted in front of them.
"""

import json
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

CLI = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
CONFIG_DIR = Path(__file__).resolve().parent / "config"
PROFILE = "Generated Profile"
PREFIX = "dotfiles: "


@dataclass
class Rule:
    name: str
    code: str

    @property
    def description(self) -> str:
        return PREFIX + self.name

    def to_json(self) -> dict:
        return {"description": self.description, "eval_js": self.code}


@dataclass
class RuleSet:
    rules: list[Rule]

    @classmethod
    def load(cls, rules_dir: Path) -> "RuleSet":
        shared = (rules_dir / "shared.js").read_text()
        rules = []
        for path in sorted(rules_dir.glob("*.js")):
            if path.name == "shared.js":
                continue
            code = path.read_text()
            if path.name.endswith("-layer.js"):
                code = shared + code
            rules.append(Rule(path.stem, code))
        return cls(rules)

    def lint(self) -> None:
        with tempfile.TemporaryDirectory() as work:
            for rule in self.rules:
                (Path(work) / f"{rule.name}.js").write_text(rule.code)
            result = subprocess.run(
                [CLI, "--lint-complex-modifications", f"{work}/*.js"], check=False
            )
        if result.returncode != 0:
            sys.exit("lint failed, karabiner.json was not changed")

    def merge_into(self, existing: list[dict]) -> list[dict]:
        pending = {rule.description: rule for rule in self.rules}
        merged = []
        for entry in existing:
            description = entry.get("description", "")
            if not description.startswith(PREFIX):
                merged.append(entry)
                continue
            rule = pending.pop(description, None)
            if rule is None:
                continue
            merged.append(entry | {"eval_js": rule.code})
        merged.extend(rule.to_json() for rule in pending.values())
        return merged


@dataclass
class Config:
    path: Path
    data: dict

    @classmethod
    def load(cls, path: Path) -> "Config":
        return cls(path, json.loads(path.read_text()))

    def profile(self, name: str) -> dict:
        for profile in self.data["profiles"]:
            if profile["name"] == name:
                return profile
        sys.exit(f"no profile named {name!r} in {self.path}")

    def update_rules(self, profile_name: str, rule_set: RuleSet) -> None:
        modifications = self.profile(profile_name).setdefault(
            "complex_modifications", {}
        )
        modifications["rules"] = rule_set.merge_into(modifications.get("rules", []))

    def save(self) -> None:
        new = self.path.with_name(self.path.name + ".new")
        new.write_text(json.dumps(self.data, indent=4, ensure_ascii=False) + "\n")
        new.replace(self.path)
        subprocess.run([CLI, "--format-json", str(self.path)], check=True)


def main() -> None:
    rule_set = RuleSet.load(CONFIG_DIR / "rules")
    rule_set.lint()

    config = Config.load(CONFIG_DIR / "karabiner.json")
    config.update_rules(PROFILE, rule_set)
    config.save()

    print(f"wrote {len(rule_set.rules)} rules into {config.path}")


if __name__ == "__main__":
    main()
