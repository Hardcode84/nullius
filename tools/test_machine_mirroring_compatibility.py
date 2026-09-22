#!/usr/bin/env python3
"""Test real Nullius crafting-machine fluid layouts on both native engines."""
import argparse
import json
from pathlib import Path
import re
import tempfile

from run_factorio_tests import default_dependency_mods, prepare_mods
from test_vulcanus_processing_compatibility import ROOT, command, dump, lua


def capture(engine, dependencies):
    work = Path(tempfile.mkdtemp(prefix="mirroring-capture-"))
    prepare_mods(work / "mods", dependencies)
    resolved = dump(work, engine)
    fields = ("name", "collision_box", "selection_box", "fluid_boxes",
              "fluid_boxes_off_when_no_fluid_recipe")
    machines = []
    for kind in ("assembling-machine", "furnace"):
        for name, prototype in sorted(resolved[kind].items()):
            if name.startswith("nullius-") and prototype.get("forced_symmetry") == "horizontal":
                machines.append({key: prototype[key] for key in fields if key in prototype})
    assert machines, "No affected machines captured"
    return machines, work


def run(engine, machines):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    assert major in ("2.0", "2.1"), version
    work = Path(tempfile.mkdtemp(prefix=f"mirroring-{major}-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(name="nullius-star", version="0.0.3",
        factorio_version=major, title="Machine mirroring fixture", author="tests", dependencies=["base"])))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [
        dict(name=name, enabled=name in ("base", "nullius-star")) for name in names]}))
    declarations = []
    for file, count in (("assembler.lua", 7), ("furnace.lua", 6), ("vent.lua", 2)):
        source = (ROOT / "nullius-star/prototypes/entity" / file).read_text()
        pairs = re.findall(r'forced_symmetry\s*=([^\n]+)\n\s*use_mirroring\s*=([^\n]+)', source)
        assert len(pairs) == count, (file, len(pairs))
        declarations.extend("{forced_symmetry=" + old + "use_mirroring=" + new + "}" for old, new in pairs)
    (mod / "declarations.lua").write_text('local modern=require("factorio-version").is_2_1\nreturn {' + ",".join(declarations) + "}\n")
    (mod / "layouts.lua").write_text("return " + lua(machines) + "\n")
    for target, source in (("factorio-version.lua", "nullius-star/factorio-version.lua"),
                           ("data.lua", "tests/compatibility/machine-mirroring.lua"),
                           ("scenarios/machine-mirroring", "tests/scenarios/compatibility/machine-mirroring"),
                           ("scenarios/fluid-api.lua", "tests/scenarios/fluid-api.lua")):
        (mod / target).symlink_to(ROOT / source)
    command(work, engine, ["--scenario2map", "nullius-star/machine-mirroring"], "compile")
    deadline = json.loads((ROOT / "tests/scenarios/compatibility/machine-mirroring/test.json").read_text())["until_tick"]
    command(work, engine, ["--load-game", str(work / "saves/nullius-star/machine-mirroring.zip"),
                          "--until-tick", str(deadline)], "run")
    result = json.loads((work / "script-output/mirroring.json").read_text())
    assert result["machines"] == len(machines) and result["status"] == "pass", result
    return dict(version=version, **result, artifacts=str(work))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    machines, work = capture(args.factorio_2_0.resolve(), args.dependency_mod_directory.resolve())
    print(json.dumps(dict(capture=str(work), names=[p["name"] for p in machines])), flush=True)
    for engine in (args.factorio_2_0, args.factorio_2_1):
        print(json.dumps(run(engine.resolve(), machines)), flush=True)
