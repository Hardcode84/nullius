#!/usr/bin/env python3
"""Check planners, UI audit, crafting and productivity with isolated 2.0/2.1 fixtures."""

import argparse
import json
import re
from pathlib import Path
import tempfile
from types import SimpleNamespace

import analyze_factorio_prereqs as prereqs
import plan_factorio_factory as planner
from audit_recipe_ui import write_audit_support
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure

ROOT = Path(__file__).resolve().parents[1]


def check_data(data):
    names = ["compat-recipe", "compat-uncertain", "compat-shared"]
    descriptions = prereqs.describe_recipes(data, names)
    assert all(set(row["categories"]) == {"compat-primary", "compat-secondary"}
               for row in descriptions)
    for name in names[1:]:
        product = data["recipe"][name]["results"][0]
        try:
            prereqs.deterministic_amount(product)
        except TestFailure:
            pass
        else:
            raise AssertionError(f"accepted uncertain output: {name}")
        assert planner.amount(product, "guaranteed") == 0
    boundary = {"technologies": [], "surface": {}, "fuel": "compat-fuel",
                "machines": ["compat-machine"], "forbid_categories": ["compat-primary"],
                "uncertain_outputs": "guaranteed", "heat_contract": {"MAX_HEAT": 500},
                "extractors": {}}
    rows, _, _ = planner.recipe_catalog(data, boundary)
    assert len(rows) == 3, [(r["recipe"], r["machine"]) for r in rows]
    assert all(row["category"] == "compat-secondary" for row in rows)
    flow = planner.solve_flow(rows, {"copper-plate": 120}, ["iron-plate", "water"], ["steam"])
    assert flow["status"] == "optimal", flow
    assert flow["raw_per_minute"] == {"iron-plate": 60, "water": 3000}, flow
    # Select this recipe explicitly: base recipes are outside this witness.
    args = SimpleNamespace(targets=["copper-plate"], technology=[], surface_property=[],
                           raw=["iron-plate", "water"], available=[],
                           available_machine=["compat-machine"],
                           recipe=[("copper-plate", "compat-recipe")],
                           forbid_category=["compat-primary"])
    result = prereqs.analyze(data, args)
    assert result["unresolved"] == [], result
    selected = next(row for row in result["selected_recipes"] if row["product"] == "copper-plate")
    assert selected["category"] == "compat-secondary", selected
    boundary["surface"] = {"nullius-ambient-temperature": 15}
    return {"stages": [{"name": "compat", "boundary": boundary,
                        "allowed_technologies": [], "plans": [{"flow": flow}]}]}


def stage_fluid_resource_products(mod):
    # Copy the exact product literals, not a second implementation of their fields.
    # Reject missing/ambiguous source matches so the witness cannot silently drift.
    specifications = (
        ("nullius-fumarole", "prototypes/resource.lua", "nullius-volcanic-gas"),
        ("offshore-oil", "prototypes/resource_override.lua", "nullius-volcanic-gas"),
        ("sulfuric-acid-geyser", "data-final-fixes.lua", "nullius-hydrogen-chloride"),
    )
    code = ['for _, name in ipairs({"nullius-volcanic-gas", "nullius-hydrogen-chloride"}) do',
            'local fluid=table.deepcopy(data.raw.fluid.water); fluid.name=name;',
            'fluid.max_temperature=1000; data:extend({fluid}); end']
    for name, path, fluid in specifications:
        source = (ROOT / "nullius-star" / path).read_text()
        pattern = r'\{\s*type\s*=\s*"fluid",\s*name\s*=\s*"' + re.escape(fluid) + r'"[^}]*\}'
        matches = re.findall(pattern, source)
        if len(matches) != 1:
            raise TestFailure(f"Expected one {fluid} resource product in {path}, got {len(matches)}")
        code.extend([
            'do local resource=table.deepcopy(data.raw.resource["crude-oil"]);',
            f'resource.name="{name}"; resource.autoplace=nil;',
            'resource.minable={mining_time=1, results={' + matches[0] + '}};',
            'data:extend({resource}); end',
        ])
    (mod / "fluid-resource-fixture.lua").write_text("\n".join(code) + "\n")


def run(factorio):
    work = Path(tempfile.mkdtemp(prefix="factorio-tool-compat-"))
    metadata = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    mods = work / "mods"
    mod = mods / "nullius-star"
    scenario = mod / "scenarios" / "tool-compat"
    scenario.mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": version,
        "title": "Tool compatibility fixture", "author": "Nullius Star tests",
        "dependencies": [f"base >= {version}.0"],
    }))
    (mod / "data.lua").write_text('require("tool-fixture")\nrequire("productivity-fixture")\nrequire("fluid-preservation")\nrequire("helper-mining")\nrequire("drone-mining")\nrequire("recipe-filter")\nrequire("assembler-pipe-pictures")\nrequire("asteroid-miner-products")\nrequire("rock-drops")\nrequire("fluid-resource-fixture")\nrequire("fluid-resource-products")\nrequire("turbine-pictures")\nrequire("turbine-generator")\n')
    for filename in ("tool-fixture.lua", "productivity-fixture.lua", "helper-mining.lua", "recipe-visibility.lua", "assembler-pipe-pictures.lua", "asteroid-miner-products.lua", "rock-drops.lua", "turbine-pictures.lua"):
        (mod / filename).symlink_to(ROOT / "tests/compatibility" / filename)
    (mod / "turbine-generator.lua").symlink_to(ROOT / "tests/factorio-test-support/turbine-generator.lua")
    stage_fluid_resource_products(mod)
    (mod / "fluid-resource-products.lua").symlink_to(ROOT / "tests/factorio-test-support/fluid-resource-products.lua")
    (mod / "fluid-preservation.lua").symlink_to(ROOT / "tests/factorio-test-support/fluid-preservation.lua")
    (mod / "drone-mining.lua").symlink_to(ROOT / "tests/factorio-test-support/drone-mining.lua")
    (mod / "recipe-filter.lua").symlink_to(ROOT / "tests/factorio-test-support/recipe-filter.lua")
    (mod / "data-updates.lua").write_text('require("recipe-visibility")\n')
    (mod / "prototypes").mkdir()
    for filename in ("rock.lua", "rock-products.lua", "vulcanus-rocks.lua"):
        (mod / "prototypes" / filename).symlink_to(ROOT / "nullius-star/prototypes" / filename)
    (mod / "prototypes/item").mkdir()
    (mod / "prototypes/item/asteroid-miner-products.lua").symlink_to(ROOT / "nullius-star/prototypes/item/asteroid-miner-products.lua")
    (mod / "prototypes/entity").mkdir()
    (mod / "graphics").symlink_to(ROOT / "nullius-star/graphics", target_is_directory=True)
    (mod / "prototypes/entity/turbine.lua").symlink_to(ROOT / "nullius-star/prototypes/entity/turbine.lua")
    (mod / "prototypes/entity/assembler-pipe-pictures.lua").symlink_to(ROOT / "nullius-star/prototypes/entity/assembler-pipe-pictures.lua")
    (mod / "prototypes/recipe-visibility.lua").symlink_to(ROOT / "nullius-star/prototypes/recipe-visibility.lua")
    (mod / "prototypes/recipe-productivity.lua").symlink_to(
        ROOT / "nullius-star/prototypes/recipe-productivity.lua")
    (mod / "scenarios/recipe-productivity-family").symlink_to(
        ROOT / "tests/scenarios/recipe-productivity-family", target_is_directory=True)
    (mod / "scripts").mkdir()
    for filename in ("mirror.lua", "beacon.lua", "geothermal.lua", "vulcanus_heat.lua", "vulcanus_gasvent.lua", "drone.lua", "recipe_filter.lua"):
        (mod / "scripts" / filename).symlink_to(ROOT / "nullius-star/scripts" / filename)
    (mod / "scenarios/helper-mining").symlink_to(
        ROOT / "tests/compatibility/helper-mining", target_is_directory=True)
    (mod / "scenarios/fluid-preservation").symlink_to(
        ROOT / "tests/scenarios/fluid-preservation", target_is_directory=True)
    (mod / "scenarios/drone-mining").symlink_to(
        ROOT / "tests/scenarios/drone-mining", target_is_directory=True)
    (mod / "scenarios/startup-recipe-filter").symlink_to(ROOT / "tests/scenarios/startup-recipe-filter", target_is_directory=True)
    (mod / "scenarios/asteroid-miner-products").symlink_to(ROOT / "tests/scenarios/asteroid-miner-products", target_is_directory=True)
    (mod / "scenarios/rock-drops").symlink_to(ROOT / "tests/scenarios/rock-drops", target_is_directory=True)
    (mod / "scenarios/fluid-resource-products").symlink_to(ROOT / "tests/scenarios/fluid-resource-products", target_is_directory=True)
    (mod / "scenarios/turbine-generator").symlink_to(ROOT / "tests/scenarios/turbine-generator", target_is_directory=True)
    for filename in ("planner-executor-runner.lua", "fluid-api.lua"):
        (mod / "scenarios" / filename).symlink_to(ROOT / "tests/scenarios" / filename)
    (scenario / "control.lua").write_text(
        'require("__nullius-star__/scenarios/planner-executor-runner")'
        '("tool-compat", require("fixture"))\n')
    write_audit_support(mods, "nullius-star", version)
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": name, "enabled": name in {"base", "nullius-star", "recipe-ui-audit-support"}}
        for name in ("base", "space-age", "quality", "elevated-rails", "nullius-star", "recipe-ui-audit-support")
    ]}))
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(mods), "--disable-audio"]

    def execute(label, options):
        result = run_factorio(common + options, work / f"{label}.log", 180)
        if result.returncode:
            raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")

    execute("dump", ["--dump-data"])
    data = json.loads((work / "script-output/data-raw-dump.json").read_text())
    report = check_data(data)
    planner.write_executor_fixture(report, "compat", scenario / "fixture.lua")
    for namespace, name in (("nullius-star", "tool-compat"),
                            ("nullius-star", "recipe-productivity-family"),
                            ("nullius-star", "fluid-preservation"),
                            ("nullius-star", "helper-mining"),
                            ("nullius-star", "drone-mining"),
                            ("nullius-star", "startup-recipe-filter"),
                            ("nullius-star", "asteroid-miner-products"),
                            ("nullius-star", "rock-drops"),
                            ("nullius-star", "fluid-resource-products"),
                            ("nullius-star", "turbine-generator"),
                            ("recipe-ui-audit-support", "audit")):
        execute(f"compile-{name}", ["--scenario2map", f"{namespace}/{name}"])
        execute(f"run-{name}", ["--load-game", str(work / "saves" / namespace / f"{name}.zip"),
                               "--until-tick", "4000"])
    result = json.loads((work / "script-output/factorio-tests/tool-compat.json").read_text())
    assert result["status"] == "pass", result
    productivity = json.loads((work / "script-output/factorio-tests/recipe-productivity-family.json").read_text())
    assert productivity["status"] == "pass", productivity
    preservation = json.loads((work / "script-output/factorio-tests/fluid-preservation.json").read_text())
    assert preservation["status"] == "pass", preservation
    mining = json.loads((work / "script-output/factorio-tests/helper-mining.json").read_text())
    assert mining["status"] == "pass", mining
    drones = json.loads((work / "script-output/factorio-tests/drone-mining.json").read_text())
    assert drones["status"] == "pass", drones
    filtering = json.loads((work / "script-output/factorio-tests/startup-recipe-filter.json").read_text())
    assert filtering["status"] == "pass", filtering
    asteroid = json.loads((work / "script-output/factorio-tests/asteroid-miner-products.json").read_text())
    assert asteroid["status"] == "pass", asteroid
    rocks = json.loads((work / "script-output/factorio-tests/rock-drops.json").read_text())
    assert rocks["status"] == "pass", rocks
    resources = json.loads((work / "script-output/factorio-tests/fluid-resource-products.json").read_text())
    assert resources["status"] == "pass", resources
    assert resources["resources"] == 3, resources
    turbines = json.loads((work / "script-output/factorio-tests/turbine-generator.json").read_text())
    assert turbines["status"] == "pass" and turbines["variants"] == 18, turbines
    audit = json.loads((work / "script-output/recipe-ui-audit.json").read_text())
    assert set(audit["recipes"]["compat-recipe"]["categories"]) == {"compat-primary", "compat-secondary"}
    return {"factorio_version": result["factorio_version"], "artifacts": str(work),
            "executor_assertions": result["assertions"],
            "productivity_assertions": productivity["assertions"],
            "fluid_assertions": preservation["assertions"],
            "helper_mining_assertions": mining["assertions"],
            "drone_mining_assertions": drones["assertions"],
            "asteroid_return_assertions": asteroid["assertions"],
            "rock_drop_assertions": rocks["assertions"],
            "rock_types": rocks["rocks"],
            "fluid_resource_assertions": resources["assertions"],
            "turbine_assertions": turbines["assertions"],
            "recipe_filter_assertions": filtering["assertions"], "status": "pass"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(run(args.factorio.expanduser().resolve()), indent=2))


if __name__ == "__main__":
    main()
