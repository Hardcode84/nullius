#!/usr/bin/env python3
"""Capture or compare complete resolved recipe and technology contracts."""
import argparse
import gzip
import json
from pathlib import Path

from check_factorio_locale import run_dumps, DEFAULT_MOD
from run_factorio_tests import default_factorio, default_dependency_mods


def differences(before, after, path=""):
    if isinstance(before, dict) and isinstance(after, dict):
        for key in sorted(before.keys() | after.keys()):
            child = f"{path}/{key}"
            if key not in before:
                yield {"path": child, "added": after[key]}
            elif key not in after:
                yield {"path": child, "removed": before[key]}
            else:
                yield from differences(before[key], after[key], child)
    elif isinstance(before, list) and isinstance(after, list):
        if len(before) != len(after):
            yield {"path": path, "before": before, "after": after}
        else:
            for i, (left, right) in enumerate(zip(before, after)):
                yield from differences(left, right, f"{path}/{i}")
    elif before != after or (isinstance(before, bool) != isinstance(after, bool)):
        yield {"path": path, "before": before, "after": after}


def main():
    parser = argparse.ArgumentParser(description=__doc__, fromfile_prefix_chars="@")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--capture", type=Path)
    mode.add_argument("--compare", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--mod", type=Path, default=DEFAULT_MOD)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    raw, _, version = run_dumps(args.factorio, args.dependency_mod_directory, args.mod, 120)
    current = {"schema": 1, "factorio": version,
               "prototypes": {kind: raw[kind] for kind in ("recipe", "technology")}}
    if args.capture:
        with gzip.open(args.capture, "wt") as stream:
            json.dump(current, stream, sort_keys=True)
        print(f"Captured {len(raw['recipe'])} recipes and {len(raw['technology'])} technologies on {version}")
        return 0
    with gzip.open(args.compare, "rt") as stream:
        baseline = json.load(stream)
    if baseline["schema"] != 1 or baseline["factorio"] != version:
        raise ValueError("Snapshot schema and engine version must match")
    changes = list(differences(baseline["prototypes"], current["prototypes"]))
    report = {"differences": len(changes), "changes": changes}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    else:
        print(json.dumps(report, indent=2))
    print(f"{len(changes)} differences across {len(raw['recipe'])} recipes and {len(raw['technology'])} technologies")
    return int(bool(changes))


if __name__ == "__main__":
    raise SystemExit(main())
