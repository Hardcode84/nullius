#!/usr/bin/env python3
"""Compare every recipe before and after removal of obsolete display settings."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from run_factorio_tests import default_dependency_mods, prepare_mods, supported_factorio_version
from summarize_factorio_test_log import prototype_warnings
from test_vulcanus_processing_compatibility import ROOT, command

FIELDS = {"always_show_products", "show_amount_in_title"}


def capture(engine, dependencies, version, baseline_ref=None):
    work = Path(tempfile.mkdtemp(prefix=f"recipe-display-{version}-"))
    prepare_mods(work / "mods", dependencies)
    for name in ("nullius-star", "factorio-test-support"):
        path = work / "mods" / name / "info.json"
        info = json.loads(path.read_text())
        info["factorio_version"] = version
        if path.is_symlink():
            path.unlink()
        path.write_text(json.dumps(info))
    if baseline_ref:
        path = work / "mods/nullius-star/data-final-fixes.lua"
        source = subprocess.check_output(
            ["git", "show", f"{baseline_ref}:nullius-star/data-final-fixes.lua"], cwd=ROOT)
        if path.is_symlink():
            path.unlink()
        path.write_bytes(source)
    command(work, engine, ["--dump-data", "--check-unused-prototype-data"], "dump")
    data = json.loads((work / "script-output/data-raw-dump.json").read_text())
    warnings = prototype_warnings((work / "dump.log").read_text())
    print(f"Captured {'baseline' if baseline_ref else 'current'} {version}: {work}", flush=True)
    return data["recipe"], warnings


def check(engine, dependencies, baseline_ref):
    metadata = json.loads((engine.parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    before, old_warnings = capture(engine, dependencies, version, baseline_ref)
    after, warnings = capture(engine, dependencies, version)
    assert before.keys() == after.keys(), "recipe set changed"
    removed = {field: 0 for field in FIELDS}
    for name, recipe in before.items():
        expected = recipe.copy()
        if version == "2.1":
            for field in FIELDS:
                if field in expected:
                    del expected[field]
                    removed[field] += 1
        assert after[name] == expected, (name, "recipe changed beyond obsolete display fields")
    if version == "2.1":
        assert all(removed.values()), "baseline did not exercise both removed fields"
        assert warnings["nullius_warnings"] == 0, warnings
    else:
        assert warnings == old_warnings, "2.0 strict warnings changed"
    print(json.dumps({"version": version, "recipes_checked": len(after),
                      "removed_fields": removed, "strict": warnings}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--baseline-ref", default="887d341")
    args = parser.parse_args()
    check(args.factorio.expanduser().resolve(), args.dependency_mod_directory, args.baseline_ref)
