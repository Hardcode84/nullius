#!/usr/bin/env python3
"""Load the production silo and craft and launch a rocket with either engine.

The fixture uses real silo and rocket recipe source, stub ingredient items,
and a declared electric source. It does not load the full dependency stack.
"""
import argparse
import json
from pathlib import Path
import tempfile

from run_factorio_tests import TestFailure
from test_vulcanus_processing_compatibility import ROOT, command


def run(engine):
    engine = engine.resolve()
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    if major not in {"2.0", "2.1"}:
        raise TestFailure(f"Unsupported engine: {version}")
    work = Path(tempfile.mkdtemp(prefix=f"silo-{major}-"))
    mod = work / "mods/silo-test"
    (mod / "scenarios/silo").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(name="silo-test", version="0.0.1",
        factorio_version=major, title="Silo test", author="tests", dependencies=["base"])))
    names = ["base", "space-age", "quality", "elevated-rails", "silo-test"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [
        dict(name=name, enabled=name in {"base", "silo-test"}) for name in names]}))
    (mod / "factorio-version.lua").symlink_to(ROOT / "nullius-star/factorio-version.lua")
    vehicles = (ROOT / "nullius-star/prototypes/entity/vehicle.lua").read_text()
    start = vehicles.index('  {\n    type = "rocket-silo",')
    (mod / "silo.lua").write_text("data:extend({\n" + vehicles[start:])
    equipment = (ROOT / "nullius-star/prototypes/item/equipment.lua").read_text()
    start = equipment.index('  {\n    type = "recipe",\n    name = "nullius-rocket",')
    end = equipment.index('\n  {\n    type = "item",\n    name = "nullius-satellite",', start)
    satellite_start = end
    satellite_end = equipment.index('  {\n    type = "recipe",\n    name = "nullius-satellite",', satellite_start)
    satellite = equipment[satellite_start:satellite_end]
    prefix = equipment[:equipment.index("local ICONPATH")]
    (mod / "rocket.lua").write_text(prefix + "extend_equipment_prototypes({\n" + equipment[start:end] + "})\n")
    (mod / "satellite.lua").write_text("data:extend({\n" + satellite + "})\n")
    (mod / "data.lua").write_text('''
require("rocket")
local function item(name)
  data:extend({{type="item", name=name, icon="__base__/graphics/icons/iron-plate.png",
    icon_size=64, stack_size=1000}})
end
item("nullius-rocket")
item("nullius-silo")
item("nullius-box-astronomy-pack")
data:extend({{type="item-subgroup",name="space",group="intermediate-products"}})
require("satellite")
data.raw.item["nullius-silo"].place_result = "nullius-silo"
for _, ingredient in ipairs(data.raw.recipe["nullius-rocket"].ingredients) do item(ingredient.name) end
data:extend({{type="recipe-category", name="rocketry"}})
require("silo")
local silo = data.raw["rocket-silo"]["nullius-silo"]
local base = data.raw["rocket-silo"]["rocket-silo"]
assert(table.compare(silo.working_sound, base.working_sound))
assert(table.compare(silo.graphics_set or {}, base.graphics_set or {}))
if base.graphics_set then assert(silo.graphics_set ~= base.graphics_set) end
assert(silo.rocket_parts_required == 1 and silo.module_slots == 4)
assert(silo.energy_usage == "800kW" and silo.active_energy_usage == "2600kW")
''')
    (mod / "scenarios/silo/control.lua").symlink_to(ROOT / "tests/scenarios/silo-compat/control.lua")
    deadline = json.loads((ROOT / "tests/scenarios/silo-compat/test.json").read_text())["until_tick"]
    command(work, engine, ["--scenario2map", "silo-test/silo"], "compile")
    command(work, engine, ["--load-game", str(work / "saves/silo-test/silo.zip"),
                          "--until-tick", str(deadline)], "run")
    result = json.loads((work / "script-output/factorio-tests/silo-compat.json").read_text())
    assert result["status"] == "pass", result
    print(f"PASS {version}: {result['assertions']} assertions; completion tick {result['tick']}; {work}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    run(parser.parse_args().factorio)
