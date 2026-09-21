#!/usr/bin/env python3
"""Check planners, UI audit, crafting and productivity with isolated 2.0/2.1 fixtures."""

import argparse
import json
import re
from pathlib import Path
import tempfile
import zipfile
from types import SimpleNamespace

import analyze_factorio_prereqs as prereqs
import plan_factorio_factory as planner
from audit_recipe_ui import write_audit_support
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure, default_dependency_mods, find_archive

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


def stage_car_prototypes(mod):
    source = (ROOT / "nullius-star/prototypes/entity/vehicle.lua").read_text()
    marker = '  {\n    type = "spider-vehicle",'
    if source.count(marker) != 2:
        raise TestFailure("Vehicle fixture boundary changed")
    cars = source.split(marker, 1)[0]
    if cars.count('type = "car"') != 5 or cars.count('data:extend({') != 1:
        raise TestFailure("Expected five complete car prototypes before the spider vehicles")
    (mod / "car-prototypes.lua").write_text(cars + "})\n")


def stage_chest_graphics(mods, version, dependency_mod_directory):
    graphics_mod = mods / "boblogistics"
    graphics_mod.mkdir()
    (graphics_mod / "info.json").write_text(json.dumps({
        "name": "boblogistics", "version": "0.0.1", "factorio_version": version,
        "title": "Bob chest graphics fixture", "author": "tests", "dependencies": ["base"],
    }))
    source = (ROOT / "nullius-star/prototypes/entity/chest.lua").read_text()
    files = set(re.findall(r'"__boblogistics__/([^"\n]+)"', source))
    if not files:
        raise TestFailure("No Bob chest graphics found")
    with zipfile.ZipFile(find_archive(dependency_mod_directory, "boblogistics")) as archive:
        for filename in files:
            members = [name for name in archive.namelist() if name.endswith("/" + filename)]
            if len(members) != 1:
                raise TestFailure(f"Expected one Bob graphic: {filename}")
            target = graphics_mod / filename
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(members[0]))


def stage_well_pictures(mod, version):
    source = (ROOT / "nullius-star/prototypes/entity/plumbing.lua").read_text()
    start = source.index('  {\n    type = "assembling-machine",\n    name = "nullius-well-1",')
    end = source.index('circuit_connector_definitions["nullius-air-filter"]', start)
    (mod / "well-prototypes.lua").write_text(
        'local BASEENTITY="__base__/graphics/entity/"\nlocal ENTITYPATH="__nullius-star__/graphics/entity/"\ndata:extend({\n'
        + source[start:end] + 'data:extend({lw1,lw2})\n')
    recipes = (ROOT / "nullius-star/prototypes/item/fluid.lua").read_text()
    start = recipes.index('    name = "nullius-freshwater",', recipes.index('type = "recipe"'))
    body = recipes[start:recipes.index('\n  },', start)]
    duration = re.search(r'energy_required = ([\d.]+)', body)[1]
    results = body.split('    results = ',1)[1].split('    main_product =',1)[0].strip().rstrip(',')
    code = [
        'if not data.raw.fluid["nullius-freshwater"] then local fluid=table.deepcopy(data.raw.fluid.water); fluid.name="nullius-freshwater"; data:extend({fluid}); end',
        'data:extend({{type="recipe-category",name="water-pumping"}})',
        'local recipe={type="recipe",name="nullius-freshwater",enabled=true,ingredients={},',
        f'energy_required={duration},results=' + results + '}',
        'recipe.categories={"water-pumping"}' if version == "2.1" else 'recipe.category="water-pumping"',
        'data:extend({recipe})',
    ]
    (mod / "well-recipe-fixture.lua").write_text("\n".join(code) + "\n")
    (mod / "well-pictures.lua").symlink_to(ROOT / "tests/compatibility/well-pictures.lua")
    (mod / "well-test.lua").symlink_to(ROOT / "tests/factorio-test-support/well-pictures.lua")
    (mod / "scenarios/well-pictures").symlink_to(ROOT / "tests/scenarios/well-pictures", target_is_directory=True)


def stage_extractor_pictures(mod):
    source = (ROOT / "nullius-star/prototypes/entity/plumbing.lua").read_text()
    start = source.index('data:extend({\n  {\n    type = "mining-drill",')
    end = source.index('  {\n    type = "assembling-machine",', start)
    tail = source[source.index('local extractor_pictures = require('):]
    (mod / "extractor-prototypes.lua").write_text(
        'local BASEENTITY="__base__/graphics/entity/"\nlocal ENTITYPATH="__nullius-star__/graphics/entity/"\n'
        + source[start:end] + '})\n' + tail)
    (mod / "prototypes/entity/extractor-pictures.lua").symlink_to(ROOT / "nullius-star/prototypes/entity/extractor-pictures.lua")
    (mod / "extractor-pictures.lua").symlink_to(ROOT / "tests/compatibility/extractor-pictures.lua")
    (mod / "extractor-test.lua").symlink_to(ROOT / "tests/factorio-test-support/extractor-pictures.lua")
    (mod / "scenarios/extractor-pictures").symlink_to(ROOT / "tests/scenarios/extractor-pictures", target_is_directory=True)
    vent = (ROOT / "nullius-star/prototypes/planet/vulcanus-entities.lua").read_text()
    start = vent.index('local gas_vent_drill =')
    end = vent.index('data:extend({gas_vent_drill})', start) + len('data:extend({gas_vent_drill})')
    (mod / "gas-vent-prototype.lua").write_text(
        'data.raw["assembling-machine"]["nullius-lava-intake-1"]={collision_box={{-1.4,-1.4},{1.4,1.4}}}\n'
        'data:extend({{type="resource-category",name="nullius-gas-vent"}})\n'
        'local fluid=table.deepcopy(data.raw.fluid.water); fluid.name="nullius-compressed-volcanic-gas"; data:extend({fluid})\n'
        + vent[start:end] + '\ndata.raw["assembling-machine"]["nullius-lava-intake-1"]=nil\n')


def stage_metallurgic_products(mod, version):
    source = (ROOT / "nullius-star/prototypes/planet/vulcanus-recipes.lua").read_text()
    marker = '    name = "nullius-metallurgic-pack-efficient",'
    if source.count(marker) != 1:
        raise TestFailure("Expected one industrial metallurgic science recipe")
    body = source.split(marker, 1)[1].split('    main_product =', 1)[0]
    ingredients = body.split('    ingredients = ', 1)[1].split('    results = ', 1)[0].strip().rstrip(',')
    results = body.split('    results = ', 1)[1].strip().rstrip(',')
    duration = re.search(r'energy_required = ([\d.]+)', body)[1]
    probability = re.findall(r'^local probability = .*$', source, re.M)
    if len(probability) != 1:
        raise TestFailure("Expected one product probability selector")
    code = probability + [
        'data:extend({{type="surface-property",name="nullius-ambient-temperature",default_value=15}})',
        'local ingredients=' + ingredients,
        'local results=' + results,
        'for _, list in ipairs({ingredients,results}) do for _, item in ipairs(list) do',
        'if not data.raw.item[item.name] then data:extend({{type="item",name=item.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}}); end',
        'end; end',
        'if not data.raw["recipe-category"]["medium-crafting"] then data:extend({{type="recipe-category",name="medium-crafting"}}); end',
        'local recipe={type="recipe",name="nullius-metallurgic-pack-efficient",ingredients=ingredients,results=results,',
        f'energy_required={duration},main_product="nullius-metallurgic-pack",allow_productivity=true}}',
        'recipe.categories={"medium-crafting"}' if version == "2.1" else 'recipe.category="medium-crafting"',
        'data:extend({recipe})',
    ]
    (mod / "metallurgic-recipe-fixture.lua").write_text("\n".join(code) + "\n")
    (mod / "metallurgic-products.lua").symlink_to(ROOT / "tests/factorio-test-support/metallurgic-products.lua")
    (mod / "scenarios/metallurgic-products").symlink_to(ROOT / "tests/scenarios/metallurgic-products", target_is_directory=True)


def stage_void_products(mod, version):
    source = (ROOT / "nullius-star/prototypes/item/void.lua").read_text()
    blocks = re.findall(r'type = "recipe",(.*?)\n  }', source, re.S)
    if len(blocks) != 42:
        raise TestFailure(f"Expected 42 void recipes, got {len(blocks)}")
    code = [source.splitlines()[0]]
    for block in blocks:
        def field(pattern):
            matches = re.findall(pattern, block)
            if len(matches) != 1:
                raise TestFailure(f"Ambiguous void recipe field: {pattern}")
            return matches[0]
        name = field(r'^\s*name = "([^\"]+)"')
        category = field(r'category = "([^\"]+)"')
        duration = field(r'energy_required = ([\d.]+)')
        ingredients = field(r'ingredients = (\{\{[^\n]+\}\})')
        results = field(r'results = (\{\{[^\n]+\}\})')
        code.extend([
            'do local ingredients=' + ingredients + '; local results=' + results + ';',
            'local fluid=ingredients[1].name;',
            'if not data.raw.fluid[fluid] then local f=table.deepcopy(data.raw.fluid.water); f.name=fluid; data:extend({f}); end',
            'local item=results[1].name;',
            'if not data.raw.item[item] then data:extend({{type="item",name=item,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}}); end',
            f'if not data.raw["recipe-category"]["{category}"] then data:extend({{{{type="recipe-category",name="{category}"}}}}); end',
            f'local recipe={{type="recipe",name="{name}",energy_required={duration},ingredients=ingredients,results=results}};',
            f'recipe.categories={{"{category}"}};' if version == "2.1" else f'recipe.category="{category}";',
            'data:extend({recipe}); end',
        ])
    # Isolate the product port from the pending recipe presentation/category port.
    (mod / "void-recipe-fixture.lua").write_text("\n".join(code) + "\n")
    (mod / "void-products.lua").symlink_to(ROOT / "tests/factorio-test-support/void-products.lua")
    (mod / "scenarios/void-products").symlink_to(ROOT / "tests/scenarios/void-products", target_is_directory=True)


def stage_miner_connectors(mod):
    source = (ROOT / "nullius-star/prototypes/entity/furnace.lua").read_text()
    start = source.index("local function scale_wire_position(")
    end = source.index("local floatpipepics =", start)
    (mod / "miner-connector-scaling.lua").write_text(source[start:end])
    miner = ROOT / "nullius-star/prototypes/entity/miner.lua"
    (mod / "miner-prototypes.lua").symlink_to(miner)
    # Run the actual optional reskin branch and inspect its tables before restoring
    # normal prototypes. This does not load or validate the optional image assets.
    (mod / "miner-reskin-prototypes.lua").write_text(
        'local mods = setmetatable({["reskins-bobs"] = true}, {__index = mods})\n'
        + miner.read_text())
    (mod / "miner-connectors.lua").symlink_to(ROOT / "tests/compatibility/miner-connectors.lua")


def run(factorio, dependency_mod_directory):
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
        "dependencies": [f"base >= {version}.0", "boblogistics"],
    }))
    (mod / "data.lua").write_text('require("tool-fixture")\nrequire("productivity-fixture")\nrequire("fluid-preservation")\nrequire("helper-mining")\nrequire("drone-mining")\nrequire("recipe-filter")\nrequire("assembler-pipe-pictures")\nrequire("asteroid-miner-products")\nrequire("rock-drops")\nrequire("fluid-resource-fixture")\nrequire("fluid-resource-products")\nrequire("turbine-pictures")\nrequire("turbine-generator")\nrequire("vehicle-dependencies")\nrequire("car-prototypes")\nrequire("vehicle-forces")\nrequire("chest-doors")\nrequire("chest-test-port")\nrequire("miner-connectors")\nrequire("void-recipe-fixture")\nrequire("void-products")\nrequire("metallurgic-recipe-fixture")\nrequire("metallurgic-products")\nrequire("extractor-pictures")\nrequire("extractor-test")\nrequire("well-recipe-fixture")\nrequire("well-pictures")\nrequire("well-test")\n')
    for filename in ("tool-fixture.lua", "productivity-fixture.lua", "helper-mining.lua", "recipe-visibility.lua", "assembler-pipe-pictures.lua", "asteroid-miner-products.lua", "rock-drops.lua", "turbine-pictures.lua", "vehicle-dependencies.lua", "chest-doors.lua"):
        (mod / filename).symlink_to(ROOT / "tests/compatibility" / filename)
    (mod / "turbine-generator.lua").symlink_to(ROOT / "tests/factorio-test-support/turbine-generator.lua")
    (mod / "factorio-version.lua").symlink_to(ROOT / "nullius-star/factorio-version.lua")
    stage_chest_graphics(mods, version, dependency_mod_directory)
    (mod / "chest-test-port.lua").symlink_to(ROOT / "tests/factorio-test-support/chest-doors.lua")
    stage_car_prototypes(mod)
    stage_miner_connectors(mod)
    stage_void_products(mod, version)
    stage_metallurgic_products(mod, version)
    (mod / "vehicle-forces.lua").symlink_to(ROOT / "tests/factorio-test-support/vehicle-forces.lua")
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
    stage_extractor_pictures(mod)
    stage_well_pictures(mod, version)
    (mod / "prototypes/entity/chest.lua").symlink_to(ROOT / "nullius-star/prototypes/entity/chest.lua")
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
    (mod / "scenarios/vehicle-forces").symlink_to(ROOT / "tests/scenarios/vehicle-forces", target_is_directory=True)
    (mod / "scenarios/chest-doors").symlink_to(ROOT / "tests/scenarios/chest-doors", target_is_directory=True)
    for filename in ("planner-executor-runner.lua", "fluid-api.lua"):
        (mod / "scenarios" / filename).symlink_to(ROOT / "tests/scenarios" / filename)
    (scenario / "control.lua").write_text(
        'require("__nullius-star__/scenarios/planner-executor-runner")'
        '("tool-compat", require("fixture"))\n')
    write_audit_support(mods, "nullius-star", version)
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": name, "enabled": name in {"base", "nullius-star", "recipe-ui-audit-support", "boblogistics"}}
        for name in ("base", "space-age", "quality", "elevated-rails", "nullius-star", "recipe-ui-audit-support", "boblogistics")
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
                            ("nullius-star", "vehicle-forces"),
                            ("nullius-star", "chest-doors"),
                            ("nullius-star", "void-products"),
                            ("nullius-star", "metallurgic-products"),
                            ("nullius-star", "extractor-pictures"),
                            ("nullius-star", "well-pictures"),
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
    vehicles = json.loads((work / "script-output/factorio-tests/vehicle-forces.json").read_text())
    assert vehicles["status"] == "pass" and vehicles["vehicles"] == 5, vehicles
    chests = json.loads((work / "script-output/factorio-tests/chest-doors.json").read_text())
    assert chests["status"] == "pass" and chests["chests"] == 17, chests
    voids = json.loads((work / "script-output/factorio-tests/void-products.json").read_text())
    assert voids["status"] == "pass" and voids["recipes"] == 42 and voids["crafts"] == 210, voids
    metallurgy = json.loads((work / "script-output/factorio-tests/metallurgic-products.json").read_text())
    assert metallurgy["status"] == "pass" and metallurgy["science"] == 20, metallurgy
    extractors = json.loads((work / "script-output/factorio-tests/extractor-pictures.json").read_text())
    assert extractors["status"] == "pass" and extractors["extractors"] == 8, extractors
    wells = json.loads((work / "script-output/factorio-tests/well-pictures.json").read_text())
    assert wells["status"] == "pass" and wells["wells"] == 16, wells
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
            "vehicle_assertions": vehicles["assertions"],
            "chest_assertions": chests["assertions"],
            "void_assertions": voids["assertions"],
            "metallurgic_assertions": metallurgy["assertions"],
            "extractor_assertions": extractors["assertions"],
            "well_assertions": wells["assertions"],
            "recipe_filter_assertions": filtering["assertions"], "status": "pass"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    print(json.dumps(run(args.factorio.expanduser().resolve(), args.dependency_mod_directory.expanduser().resolve()), indent=2))


if __name__ == "__main__":
    main()
