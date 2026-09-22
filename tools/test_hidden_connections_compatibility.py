#!/usr/bin/env python3
"""Check hidden fluid connections against a fresh full-mod 2.0 baseline."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import shutil
import tempfile

from run_factorio_tests import default_dependency_mods, prepare_mods
from test_vulcanus_processing_compatibility import ROOT, dump, lua

SOURCES = ["prototypes/entity/plumbing.lua", "prototypes/entity/turbine.lua",
           "prototypes/planet/vulcanus-entities.lua"]


def hidden_boxes(value, path=()):
    if isinstance(value, dict):
        if value.get("hide_connection_info") is True and "pipe_connections" in value:
            yield path, value
        for key, child in value.items():
            yield from hidden_boxes(child, (*path, key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from hidden_boxes(child, (*path, index))


def capture(engine, dependencies, baseline_ref):
    work = Path(tempfile.mkdtemp(prefix="hidden-connections-baseline-"))
    prepare_mods(work / "mods", dependencies)
    staged = work / "mods/nullius-star/prototypes"
    staged.unlink()
    shutil.copytree(ROOT / "nullius-star/prototypes", staged)
    for source in SOURCES:
        content = subprocess.check_output(["git", "show", f"{baseline_ref}:nullius-star/{source}"], cwd=ROOT)
        target = work / "mods/nullius-star" / source
        target.unlink()
        target.write_bytes(content)
    baseline = dump(work, engine)
    current_work = Path(tempfile.mkdtemp(prefix="hidden-connections-current-"))
    prepare_mods(current_work / "mods", dependencies)
    current = dump(current_work, engine)
    # Require exact 2.0 parity for all resolved data, including inherited variants.
    assert current == baseline, "Full-mod 2.0 prototypes differ"
    boxes = [dict(path=list(path), box=box,
                  collision_box=baseline[path[0]][path[1]]["collision_box"]) for path, box in hidden_boxes(baseline)
             if len(path) > 2 and str(path[1]).startswith("nullius-")]
    assert boxes, "No hidden fluid boxes found"
    return boxes, dict(baseline=str(work), current=str(current_work))


def run(engine, boxes):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    assert major in ("2.0", "2.1"), version
    work = Path(tempfile.mkdtemp(prefix=f"hidden-connections-{major}-"))
    mod = work / "mods/nullius-star"
    (mod / "prototypes/entity").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(name="nullius-star", version="0.0.3",
        factorio_version=major, title="Hidden connection fixture", author="tests", dependencies=["base"])))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [
        dict(name=name, enabled=name in ("base", "nullius-star")) for name in names]}))
    for source in ("factorio-version.lua", "prototypes/entity/hide-fluid-connections.lua"):
        (mod / source).symlink_to(ROOT / "nullius-star" / source)
    (mod / "boxes.lua").write_text("return " + lua(boxes) + "\n")
    (mod / "data.lua").symlink_to(ROOT / "tests/compatibility/hidden-connections.lua")
    resolved = dump(work, engine)
    actual = resolved["mod-data"]["hidden-connections"]["data"]["boxes"]
    expected = copy.deepcopy(boxes)
    connections = 0
    for row in expected:
        box = row["box"]
        connections += len(box["pipe_connections"])
        if major == "2.1":
            del box["hide_connection_info"]
            for connection in box["pipe_connections"]:
                connection["hide_connection_info"] = True
    assert actual == expected, "Hidden flags or connection geometry differ"
    return dict(version=version, boxes=len(boxes), connections=connections, artifacts=str(work))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--baseline-ref", default="9620d61")
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    boxes, artifacts = capture(args.factorio_2_0.resolve(), args.dependency_mod_directory.resolve(), args.baseline_ref)
    print(json.dumps(dict(capture=artifacts, paths=[row["path"] for row in boxes])), flush=True)
    for engine in (args.factorio_2_0, args.factorio_2_1):
        print(json.dumps(run(engine.resolve(), boxes)), flush=True)
