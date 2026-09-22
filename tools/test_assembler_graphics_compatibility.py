#!/usr/bin/env python3
"""Render captured production assembler graphics and test native crafting."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from types import SimpleNamespace

from run_factorio_tests import default_dependency_mods, prepare_mods, prepare_config
from test_vulcanus_processing_compatibility import ROOT, command, dump, lua
sys.path.insert(0, str(ROOT))
from tools.factorio_multiplayer import execute_multiplayer

NAMES = {"nullius-small-assembler-1": 1, "nullius-medium-assembler-1": 1,
         "nullius-large-assembler-1": 2, "nullius-small-assembler-2": 2,
         "nullius-small-assembler-3": 3, "nullius-medium-assembler-2": 2,
         "nullius-medium-assembler-3": 3, "nullius-large-assembler-2": 3}


def capture(engine, dependencies, baseline=False):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    work = Path(tempfile.mkdtemp(prefix="assembler-capture-"))
    prepare_mods(work / "mods", dependencies)
    for name in ["nullius-star", "factorio-test-support"]:
        p = work / "mods" / name / "info.json"
        info = json.loads(p.read_text()); info["factorio_version"] = major
        if p.is_symlink(): p.unlink()
        p.write_text(json.dumps(info))
    if baseline:
        p = work / "mods/nullius-star/prototypes"
        p.unlink(); shutil.copytree(ROOT / "nullius-star/prototypes", p)
        (p / "entity/assembler.lua").write_bytes(subprocess.check_output(
            ["git", "show", "6491f73:nullius-star/prototypes/entity/assembler.lua"], cwd=ROOT))
    data = dump(work, engine)
    print(f"Captured {version}, baseline={baseline}: {work}", flush=True)
    return data, major


def check_graphics(old, data):
    for name, tier in NAMES.items():
        legacy = old["assembling-machine"][name]["graphics_set"]["animation"]["layers"]
        graphics = data["assembling-machine"][name]["graphics_set"]
        native = data["assembling-machine"][f"assembling-machine-{tier}"]["graphics_set"]
        layers = graphics["animation"]["layers"]
        assert len(layers) == 3, name
        ratio = legacy[0]["scale"] / 0.5
        old_cycle = legacy[0]["frame_count"] / legacy[0].get("animation_speed", 1)
        for actual, original in zip(layers, native["animation"]["layers"]):
            for field in ("filename", "width", "height", "line_length", "frame_count", "repeat_count"):
                assert actual.get(field) == original.get(field), (name, field)
            assert abs(actual["scale"] - original.get("scale", 1) * ratio) < 1e-9, name
            frames = actual.get("frame_count", 1) * actual.get("repeat_count", 1)
            assert abs(frames / actual["animation_speed"] - old_cycle) < 1e-9, name
        # Every new layer retains its native offset relative to the other layers.
        body = layers[0]
        native_body = native["animation"]["layers"][0]
        overlays = [(v["animation"], n["animation"]) for v, n in zip(
            graphics["working_visualisations"], native["working_visualisations"], strict=True)]
        overlays.append((graphics["frozen_patch"], native["frozen_patch"]))
        for actual, original in list(zip(layers[:2], native["animation"]["layers"][:2])) + overlays:
            assert abs(actual["scale"] - original.get("scale", 1) * ratio) < 1e-9, name
            for axis in (0, 1):
                assert abs((actual["shift"][axis] - body["shift"][axis]) -
                           (original["shift"][axis] - native_body["shift"][axis]) * ratio) < 1e-9, name
        for variant in (name + "-pneumatic", name + "-thermal"):
            if variant in data["assembling-machine"]:
                assert data["assembling-machine"][variant]["graphics_set"] == graphics, variant


def render(engine, data, major):
    work = Path(tempfile.mkdtemp(prefix=f"assembler-render-{major}-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios/assembler-graphics").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(name="nullius-star",version="0.0.3",
        factorio_version=major,title="Assembler graphics test",author="tests",dependencies=["base", "space-age"], space_travel_required=True)))
    builtin = ["base", "quality", "space-age", "elevated-rails", "nullius-star"]
    if major == "2.1": builtin.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods":[dict(name=n,enabled=True) for n in builtin]}))
    # Keep resolved graphics, geometry and speed; declare void power and one
    # iron-plate batch per machine to isolate rendering from the energy supply.
    entities = []
    for name in NAMES:
        p = data["assembling-machine"][name]
        entities.append({k: p[k] for k in ("name", "graphics_set", "collision_box", "selection_box", "crafting_speed")})
    (mod / "data.lua").write_text("local machines=" + lua(entities) + '''
for _, p in ipairs(machines) do
  local e=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  for k,v in pairs(p) do e[k]=v end
  e.next_upgrade=nil; e.minable=nil; e.energy_source={type="void"}
  e.crafting_categories={"crafting"}; e.working_sound=nil
  data:extend({e})
end
local recipe=table.deepcopy(data.raw.recipe["iron-stick"])
recipe.name="graphics-craft";recipe.energy_required=1;recipe.enabled=true
recipe.ingredients={{type="item",name="iron-plate",amount=1}}
recipe.results={{type="item",name="iron-stick",amount=1}}
data:extend({recipe})
''')
    scenario = mod / "scenarios/assembler-graphics/control.lua"
    scenario.write_text('local names=' + lua(list(NAMES)) + '\n' + (ROOT / "tests/scenarios/compatibility/assembler-graphics/control.lua").read_text())
    command(work, engine, ["--scenario2map", "nullius-star/assembler-graphics"], "compile")
    common = [str(engine), "--config", str(prepare_config(work,engine)), "--mod-directory", str(work/"mods"), "--disable-audio"]
    deadline = json.loads((ROOT / "tests/scenarios/compatibility/assembler-graphics/test.json").read_text())["until_tick"]
    execute_multiplayer(SimpleNamespace(timeout_seconds=180, multiplayer_until_tick=deadline), common,
                        work/"saves/nullius-star/assembler-graphics.zip", work)
    result=json.loads((work/"script-output/factorio-tests/assembler-graphics.json").read_text())
    assert result["status"]=="pass", result
    print(f"PASS rendered {major}: {result['assertions']} assertions; {work}", flush=True)


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--staged-dependency-mod-directory", type=Path, required=True)
    args=parser.parse_args()
    old,_=capture(args.factorio_2_0,args.dependency_mod_directory,True)
    current,major=capture(args.factorio_2_0,args.dependency_mod_directory)
    assert old==current, "2.0 prototypes changed"
    render(args.factorio_2_0,current,major)
    current,major=capture(args.factorio_2_1,args.staged_dependency_mod_directory)
    check_graphics(old,current)
    render(args.factorio_2_1,current,major)
