#!/usr/bin/env python3
"""Render wells and extractors in every direction and check fluid production."""
import argparse
import copy
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace

from test_assembler_graphics_compatibility import capture, execute_multiplayer
from test_vulcanus_processing_compatibility import ROOT, command, lua
from run_factorio_tests import default_dependency_mods, prepare_config

NAMES = {**{f"nullius-{prefix}well-{tier}": "assembling-machine"
            for prefix in ("", "legacy-") for tier in (1, 2)},
         **{f"nullius-extractor-{tier}{suffix}": "mining-drill"
            for tier in (1, 2) for suffix in ("", "-pneumatic")}}


def check_graphics(old, data):
    native = data["mining-drill"]["pumpjack"]["graphics_set"]["animation"]["north"]["layers"][1]
    for name, kind in NAMES.items():
        animation = data[kind][name]["graphics_set"]["animation"]
        previous = old[kind][name]["graphics_set"]["animation"]
        for direction, value in animation.items():
            layers = value["layers"]
            body, shadow = layers[-2:]
            assert body == previous[direction]["layers"][-2], (name, direction, "custom arm")
            expected = copy.deepcopy(native)
            expected.update(scale=body["scale"], animation_speed=body["animation_speed"],
                            shift=previous[direction]["layers"][-1]["shift"])
            assert shadow == expected, (name, direction, "native shadow")
            assert shadow["frame_count"] == body["frame_count"], name
    print("PASS native shadow bounds, custom arms, origins, scale and timing", flush=True)


def render(engine, data, major):
    work = Path(tempfile.mkdtemp(prefix=f"pumpjack-render-{major}-"))
    mod = work / "mods/nullius-star"
    scenario = mod / "scenarios/pumpjack-graphics"
    scenario.mkdir(parents=True)
    (mod / "scenarios/fluid-api.lua").symlink_to(ROOT / "tests/scenarios/fluid-api.lua")
    (mod / "graphics").symlink_to(ROOT / "nullius-star/graphics", target_is_directory=True)
    (mod / "info.json").write_text(json.dumps(dict(name="nullius-star", version="0.0.3",
        factorio_version=major, title="Pumpjack graphics test", author="tests",
        dependencies=["base", "space-age"], space_travel_required=True)))
    builtin = ["base", "quality", "space-age", "elevated-rails", "nullius-star"]
    if major == "2.1": builtin.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [dict(name=n, enabled=True) for n in builtin]}))
    entities = []
    for name, kind in NAMES.items():
        source = data[kind][name]
        fields = ("graphics_set", "collision_box", "selection_box", "mining_speed",
                  "crafting_speed", "fluid_boxes", "output_fluid_box", "base_picture",
                  "base_render_layer", "forced_symmetry", "use_mirroring",
                  "resource_searching_radius", "resource_categories", "vector_to_place_result")
        entities.append(dict(name=name, type=kind, **{k: source[k] for k in fields if k in source}))
        if kind == "assembling-machine":
            assert isinstance(source["fluid_boxes"], list), (name, source["fluid_boxes"].keys())
    (mod / "data.lua").write_text("local machines=" + lua(entities) + '''
for _,p in ipairs(machines) do
  local template=p.type=="mining-drill" and "pumpjack" or "assembling-machine-1"
  local e=table.deepcopy(data.raw[p.type][template])
  for k,v in pairs(p) do e[k]=v end
  e.minable=nil; e.next_upgrade=nil; e.energy_source={type="void"}; e.working_sound=nil
  if e.type=="assembling-machine" then e.crafting_categories={"chemistry"} end
  data:extend({e})
end
local recipe=table.deepcopy(data.raw.recipe["sulfuric-acid"])
recipe.name="graphics-water"; recipe.energy_required=1; recipe.enabled=true
recipe.main_product=nil
''' + ('recipe.categories={"chemistry"}\n' if major == "2.1" else 'recipe.category="chemistry"\n') + '''
recipe.ingredients={}; recipe.results={{type="fluid",name="water",amount=10}}
local resource=table.deepcopy(data.raw.resource["crude-oil"])
resource.name="graphics-resource"; resource.autoplace=nil; resource.infinite=false
resource.minable={mining_time=1,results={{type="fluid",name="water",amount=10}}}
data:extend({recipe,resource})
''')
    source = ROOT / "tests/scenarios/compatibility/pumpjack-graphics"
    (scenario / "control.lua").write_text("local names=" + lua(list(NAMES)) + "\n" + (source / "control.lua").read_text())
    command(work, engine, ["--scenario2map", "nullius-star/pumpjack-graphics"], "compile")
    common = [str(engine), "--config", str(prepare_config(work, engine)), "--mod-directory", str(work / "mods"), "--disable-audio"]
    deadline = json.loads((source / "test.json").read_text())["until_tick"]
    execute_multiplayer(SimpleNamespace(timeout_seconds=180, multiplayer_until_tick=deadline), common,
                        work / "saves/nullius-star/pumpjack-graphics.zip", work)
    result = json.loads((work / "script-output/factorio-tests/pumpjack-graphics.json").read_text())
    assert result["status"] == "pass", result
    print(f"PASS rendered {major}: {result['assertions']} assertions; {work}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--staged-dependency-mod-directory", type=Path, required=True)
    args = parser.parse_args()
    old, _ = capture(args.factorio_2_0, args.dependency_mod_directory, True, "plumbing.lua", "01f1a51")
    current, major = capture(args.factorio_2_0, args.dependency_mod_directory)
    assert old == current, "2.0 prototypes changed"
    modern, modern_major = capture(args.factorio_2_1, args.staged_dependency_mod_directory)
    check_graphics(old, modern)
    render(args.factorio_2_0, current, major)
    render(args.factorio_2_1, modern, modern_major)
