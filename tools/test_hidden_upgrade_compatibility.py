#!/usr/bin/env python3
"""Check hidden build items and preserve valid upgrade targets on both engines."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from run_factorio_tests import default_dependency_mods, prepare_mods, TestFailure
from test_vulcanus_processing_compatibility import ROOT, dump


def isolated(engine):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    if major not in {"2.0", "2.1"}:
        raise TestFailure(f"Unsupported engine: {version}")
    work = Path(tempfile.mkdtemp(prefix=f"hidden-upgrades-{major}-"))
    mod = work / "mods/upgrade-test"
    (mod / "prototypes").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(name="upgrade-test", version="0.0.1",
        factorio_version=major, title="Upgrade visibility test", author="tests", dependencies=["base"])))
    names = ["base", "space-age", "quality", "elevated-rails", "upgrade-test"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [
        dict(name=name, enabled=name in {"base", "upgrade-test"}) for name in names]}))
    (mod / "prototypes/visible-build-items.lua").symlink_to(ROOT / "nullius-star/prototypes/visible-build-items.lua")
    source = (ROOT / "nullius-star/prototypes/hidden.lua").read_text()
    start = source.index('local visible_build_items = require("prototypes.visible-build-items")()')
    end = source.index("for _,type in pairs(hide_entity_list) do", start)
    (mod / "upgrade-cleanup.lua").write_text(source[start:end])
    (mod / "data.lua").symlink_to(ROOT / "tests/compatibility/hidden-upgrades.lua")
    data = dump(work, engine)
    cases = {"plain": True, "entity-data": True, "alternate": False,
             "mining-return": False, "explicit-visible": False, "explicit-hidden": True,
             "explicit-list": True, "explicit-list-visible-first": False, "not-minable": True, "results-list": True}
    for name, hidden in cases.items():
        source = data["container"]["upgrade-test-" + name]
        target = data["container"][source["name"] + "-target"]
        assert source.get("next_upgrade") == (None if hidden else target["name"]), name
        assert target.get("hidden", False) == (name == "mining-return"), name
    print(f"PASS {version}: 10 upgrade cases, 1 non-buildable helper; {work}", flush=True)


def full_mod(engine, dependencies, baseline_ref):
    snapshots = []
    for baseline in [True, False]:
        work = Path(tempfile.mkdtemp(prefix="hidden-upgrades-full-"))
        prepare_mods(work / "mods", dependencies)
        if baseline:
            staged = work / "mods/nullius-star/prototypes"
            staged.unlink()
            shutil.copytree(ROOT / "nullius-star/prototypes", staged)
            (staged / "hidden.lua").write_bytes(subprocess.check_output(
                ["git", "show", f"{baseline_ref}:nullius-star/prototypes/hidden.lua"], cwd=ROOT))
        snapshots.append(dump(work, engine))
        print(f"Full mod {'baseline' if baseline else 'current'}: {work}", flush=True)
    before, after = snapshots
    changes = []
    for kind in before.keys() | after.keys():
        assert before.get(kind, {}).keys() == after.get(kind, {}).keys(), kind
        for name, old in before.get(kind, {}).items():
            new = after[kind][name]
            if old == new:
                continue
            changed = {field for field in old.keys() | new.keys() if old.get(field) != new.get(field)}
            assert changed <= {"next_upgrade", "hidden"}, (kind, name, changed)
            changes.append(dict(type=kind, name=name, changes={field: [old.get(field), new.get(field)]
                                                             for field in sorted(changed)}))
    print(json.dumps({"changed_entities": changes}, indent=2))


def staged_full_mod(engine, dependencies):
    """Retarget only the subject/test manifests; dependencies must be staged."""
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    work = Path(tempfile.mkdtemp(prefix="hidden-upgrades-staged-"))
    prepare_mods(work / "mods", dependencies)
    for name in ["nullius-star", "factorio-test-support"]:
        path = work / "mods" / name / "info.json"
        metadata = json.loads(path.read_text())
        metadata["factorio_version"] = major
        if path.is_symlink():
            path.unlink()
        path.write_text(json.dumps(metadata))
    data = dump(work, engine)
    for kind in ["locomotive", "cargo-wagon", "fluid-wagon"]:
        for name in [kind, "bob-" + kind + "-2", "bob-armoured-" + kind]:
            assert data[kind][name].get("next_upgrade") is None, name
    print(f"PASS staged {version}: nine Bob rolling-stock links removed; {work}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--compare-full-mod", action="store_true")
    parser.add_argument("--staged-full-mod", action="store_true",
                        help="load a staged dependency set and check Bob rolling-stock links")
    parser.add_argument("--baseline-ref", default="8ab7a45")
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    engine = args.factorio.expanduser().resolve()
    isolated(engine)
    if args.compare_full_mod:
        full_mod(engine, args.dependency_mod_directory, args.baseline_ref)
    if args.staged_full_mod:
        staged_full_mod(engine, args.dependency_mod_directory)
