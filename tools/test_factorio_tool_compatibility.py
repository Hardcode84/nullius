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


def stage_solar_neighbours(mod):
    source = (ROOT / "nullius-star/prototypes/entity/energy.lua").read_text()
    start = source.index('  {\n    type = "reactor",\n    name = "nullius-solar-collector-1",')
    end = source.index('  {\n    type = "assembling-machine",\n    name = "nullius-heat-exchanger-1",', start)
    setup = source[source.index("local function solar_neighbours("):source.index("local reactor_neighbours\n")]
    (mod / "solar-prototypes.lua").write_text(
        'local ENTITYPATH="__nullius-star__/graphics/entity/"\n'
        'for tier=1,3 do local name="nullius-solar-collector-"..tier; '
        'data:extend({{type="item",name=name,stack_size=10,place_result=name,'
        'icons={{icon="__base__/graphics/icons/solar-panel.png",icon_size=64}}}}); end\n'
        + setup + 'data:extend({\n' + source[start:end] + '})\n')
    (mod / "scenarios/solar-neighbours").symlink_to(ROOT / "tests/scenarios/solar-neighbours", target_is_directory=True)


def stage_reactor_neighbours(mod):
    source = (ROOT / "nullius-star/prototypes/entity/energy.lua").read_text()
    start = source.index('  {\n    type = "reactor",\n    name = "nullius-reactor",')
    end = source.index('  {\n    type = "reactor",\n    name = "nullius-solar-collector-1",', start)
    setup = source.index("local reactor_neighbours\n")
    connections = source[setup:source.index("data:extend({", setup)]
    (mod / "reactor-prototype.lua").write_text(
        'local ENTITYPATH="__nullius-star__/graphics/entity/"\n'
        'local collision_mask_util=require("collision-mask-util")\n'
        'data:extend({{type="fuel-category",name="nullius-nuclear"},'
        '{type="item",name="nullius-reactor",stack_size=10,place_result="nullius-reactor",'
        'icon="__base__/graphics/icons/nuclear-reactor.png"}})\n'
        + connections + 'data:extend({\n' + source[start:end] + '})\n')
    (mod / "reactor-neighbours.lua").symlink_to(ROOT / "tests/factorio-test-support/reactor-neighbours.lua")
    (mod / "scenarios/reactor-neighbours").symlink_to(ROOT / "tests/scenarios/reactor-neighbours", target_is_directory=True)


def stage_salvage_research(mod):
    source = (ROOT / "nullius-star/prototypes/technology.lua").read_text()
    end = source.index('  {\n    type = "technology",\n    name = "nullius-iron-smelting-1",')
    if source[:end].count('type = "technology"') != 2:
        raise TestFailure("Expected salvage and geology technologies")
    (mod / "salvage-technologies.lua").write_text(source[:end] + '})\n')
    source = (ROOT / "nullius-star/prototypes/entity/landing.lua").read_text()
    header = source[:source.index('data:extend({')]
    start = source.index('  {\n    type = "simple-entity-with-owner",\n    name = "nullius-landing-lab",')
    end = source.index('  {\n    type = "simple-entity-with-owner",\n    name = "nullius-landing-pylon",', start)
    (mod / "salvage-wreckage.lua").write_text(header + 'data:extend({\n' + source[start:end] + '})\n')
    (mod / "salvage-research.lua").symlink_to(ROOT / "tests/compatibility/salvage-research.lua")
    (mod / "scenarios/salvage-research").symlink_to(ROOT / "tests/scenarios/salvage-research", target_is_directory=True)


def stage_pump_wagons(mod):
    source = (ROOT / "nullius-star/prototypes/entity/plumbing.lua").read_text()
    start = source.index('  {\n    type = "pump",\n    name = "nullius-pump-1",')
    end = source.index('  {\n    type = "pump",\n    name = "nullius-small-pump-1",', start)
    header = source[:source.index('require("pipe_graphics")')]
    body = source[start:end]
    if body.count('type = "pump"') != 5:
        raise TestFailure("Expected five full-size pump prototypes")
    (mod / "pump-prototypes.lua").write_text(header + 'data:extend({\n' + body + '})\n')
    (mod / "pump-wagons.lua").symlink_to(ROOT / "tests/compatibility/pump-wagons.lua")
    (mod / "pump-test.lua").symlink_to(ROOT / "tests/factorio-test-support/pump-wagons.lua")
    (mod / "scenarios/pump-wagons").symlink_to(ROOT / "tests/scenarios/pump-wagons", target_is_directory=True)


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


def stage_plumbing_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/plumbing.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 113:
        raise TestFailure("Expected 113 plumbing recipe records")
    header = source.split("extend_plumbing_prototypes({", 1)[0]
    (mod / "plumbing-source.lua").write_text(header + "extend_plumbing_prototypes({\n" + ",\n".join(blocks) + "\n})\n")
    source = "\n".join(blocks)
    for target, source_path in (
        ("plumbing-recipes.lua", "tests/compatibility/plumbing-recipes.lua"),
        ("plumbing-recipe-executor.lua", "tests/factorio-test-support/plumbing-recipes.lua"),
        ("scenarios/plumbing-recipes", "tests/scenarios/plumbing-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one plumbing recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_building_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/buildings.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 137:
        raise TestFailure("Expected 137 building recipe records")
    header = source.split("extend_building_prototypes({", 1)[0]
    (mod / "building-source.lua").write_text(header + "extend_building_prototypes({\n" + ",\n".join(blocks) + "\n})\n")
    source = "\n".join(blocks)
    for target, source_path in (
        ("building-recipes.lua", "tests/compatibility/building-recipes.lua"),
        ("building-recipe-executor.lua", "tests/factorio-test-support/building-recipes.lua"),
        ("scenarios/building-recipes", "tests/scenarios/building-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one building recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_primitive_recipes(mod):
    for target, source in (
        ("primitive-source.lua", "nullius-star/prototypes/planet/primitive-robotics-items.lua"),
        ("primitive-recipes.lua", "tests/compatibility/primitive-recipes.lua"),
        ("primitive-recipe-executor.lua", "tests/factorio-test-support/primitive-recipes.lua"),
        ("scenarios/primitive-recipes", "tests/scenarios/primitive-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())


def stage_intermediate_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/intermediate.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 293:
        raise TestFailure("Expected 293 intermediate recipe records")
    header = source.split("extend_intermediate_prototypes({", 1)[0]
    (mod / "intermediate-source.lua").write_text(header + "extend_intermediate_prototypes({\n" + ",\n".join(blocks) + "\n})\n")
    source = "\n".join(blocks)
    for target, source_path in (
        ("intermediate-recipes.lua", "tests/compatibility/intermediate-recipes.lua"),
        ("intermediate-recipe-executor.lua", "tests/factorio-test-support/intermediate-recipes.lua"),
        ("scenarios/intermediate-recipes", "tests/scenarios/intermediate-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one intermediate recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_equipment_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/equipment.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 157:
        raise TestFailure("Expected 157 equipment recipe records")
    header = source.split("extend_equipment_prototypes({", 1)[0]
    (mod / "equipment-source.lua").write_text(header + "extend_equipment_prototypes({\n" + ",\n".join(blocks) + "\n})\n")
    source = "\n".join(blocks)
    for target, source_path in (
        ("equipment-recipes.lua", "tests/compatibility/equipment-recipes.lua"),
        ("equipment-recipe-executor.lua", "tests/factorio-test-support/equipment-recipes.lua"),
        ("scenarios/equipment-recipes", "tests/scenarios/equipment-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one equipment recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_fluid_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/fluid.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 223:
        raise TestFailure("Expected 223 fluid recipe records")
    header = source.split("extend_fluid_prototypes({", 1)[0]
    fluids = re.findall(r'^  \{\n    type = "fluid",.*?^  \}', source, re.M | re.S)
    # Register fluids first, then recipes in source order for icon references.
    staged = header + "extend_fluid_prototypes({\n" + ",\n".join(fluids) + "\n})\n"
    staged += "\n".join("extend_fluid_prototypes({\n" + block + "\n})" for block in blocks)
    (mod / "fluid-source.lua").write_text(staged + "\n")
    source += (ROOT / "nullius-star/legacyAngels.lua").read_text()
    for target, source_path in (
        ("fluid-recipes.lua", "tests/compatibility/fluid-recipes.lua"),
        ("fluid-recipe-executor.lua", "tests/factorio-test-support/fluid-recipes.lua"),
        ("scenarios/fluid-recipes", "tests/scenarios/fluid-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one fluid recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_biology_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/biology.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 152:
        raise TestFailure("Expected 152 biology recipe records")
    header = source.split("extend_biology_prototypes({", 1)[0]
    (mod / "biology-source.lua").write_text(header + "extend_biology_prototypes({\n" + ",\n".join(blocks) + "\n})\n")
    source = "\n".join(blocks)
    fluid_source = (ROOT / "nullius-star/prototypes/item/fluid.lua").read_text()
    names = set(re.findall(r'data\.raw\.fluid\["([^"\n]+)"\]', source))
    fluid_blocks = re.findall(r'^  \{\n    type = "fluid",.*?^  \}', fluid_source, re.M | re.S)
    selected = [block for block in fluid_blocks if re.search(r'name = "([^"\n]+)"', block).group(1) in names]
    if len(selected) != len(names):
        raise TestFailure("Missing biology fluid icon dependency")
    groups = sorted(set(re.findall(r'subgroup = "([^"\n]+)"', "\n".join(selected))))
    prelude = "\n".join('if not data.raw["item-subgroup"]["' + group + '"] then data:extend({{type="item-subgroup",name="' + group + '",group="production",order="z"}}) end' for group in groups)
    header = fluid_source.split("extend_fluid_prototypes({", 1)[0]
    (mod / "biology-fluids.lua").write_text(prelude + "\n" + header + "data:extend({\n" + ",\n".join(selected) + "\n})\n")
    source += "\n" + "\n".join(selected) + (ROOT / "nullius-star/legacyAngels.lua").read_text()

    for target, source_path in (
        ("biology-recipes.lua", "tests/compatibility/biology-recipes.lua"),
        ("biology-recipe-executor.lua", "tests/factorio-test-support/biology-recipes.lua"),
        ("scenarios/biology-recipes", "tests/scenarios/biology-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics", "boblogistics", "angelspetrochemgraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one biology recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_general_recipes(mod, mods, dependency_mod_directory):
    source = (ROOT / "nullius-star/prototypes/item/recipe.lua").read_text()
    marker = 'if settings.startup["bobmods-logistics-inserteroverhaul"].value == false then'
    if source.count(marker) != 1:
        raise TestFailure("Expected the conditional Bob inserter item after general recipes")
    (mod / "general-source.lua").write_text(source.split(marker, 1)[0])
    for target, source_path in (
        ("general-recipes.lua", "tests/compatibility/general-recipes.lua"),
        ("general-recipe-executor.lua", "tests/factorio-test-support/general-recipes.lua"),
        ("scenarios/general-recipes", "tests/scenarios/general-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics"):
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one general recipe graphic: {filename}")
                target = mods / name / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_landfill_recipes(mod):
    source = (ROOT / "nullius-star/prototypes/item/landfill.lua").read_text()
    marker = '  {\n    type = "tile",'
    if source.count(marker) != 5:
        raise TestFailure("Expected five landfill tile definitions after the recipes")
    prefix = source.split(marker, 1)[0]
    prefix = prefix.replace('local transitions = require("__alien-biomes__/prototypes/tile/tile-transitions-static")\n', '')
    if prefix.count('type = "recipe"') != 30:
        raise TestFailure("Expected 30 landfill recipes before the tiles")
    (mod / "landfill-source.lua").write_text(prefix + "})\n")
    for target, source in (
        ("landfill-recipes.lua", "tests/compatibility/landfill-recipes.lua"),
        ("landfill-recipe-executor.lua", "tests/factorio-test-support/landfill-recipes.lua"),
        ("scenarios/landfill-recipes", "tests/scenarios/landfill-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())


def stage_weapon_recipes(mod, mods, dependency_mod_directory):
    for target, source in (
        ("weapon-source.lua", "nullius-star/prototypes/item/weapon.lua"),
        ("weapon-recipes.lua", "tests/compatibility/weapon-recipes.lua"),
        ("weapon-recipe-executor.lua", "tests/factorio-test-support/weapon-recipes.lua"),
        ("scenarios/weapon-recipes", "tests/scenarios/weapon-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())
    filename = "graphics/icons/powder-aluminium.png"
    with zipfile.ZipFile(find_archive(dependency_mod_directory, "angelssmeltinggraphics")) as archive:
        members = [name for name in archive.namelist() if name.endswith("/" + filename)]
        if len(members) != 1:
            raise TestFailure("Expected one aluminum powder icon")
        target = mods / "angelssmeltinggraphics" / filename
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.read(members[0]))


def stage_drone_recipes(mod, mods, version, dependency_mod_directory):
    for target, source in (
        ("drone-source.lua", "nullius-star/prototypes/item/drone.lua"),
        ("drone-reskin.lua", "nullius-star/prototypes/reskin.lua"),
        ("drone-recipes.lua", "tests/compatibility/drone-recipes.lua"),
        ("drone-recipe-executor.lua", "tests/factorio-test-support/drone-recipes.lua"),
        ("scenarios/drone-recipes", "tests/scenarios/drone-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())
    source = (ROOT / "nullius-star/prototypes/item/drone.lua").read_text()
    for name in ("angelsrefininggraphics", "angelssmeltinggraphics"):
        graphics = mods / name
        graphics.mkdir()
        (graphics / "info.json").write_text(json.dumps({
            "name": name, "version": "0.0.1", "factorio_version": version,
            "title": "Drone graphics fixture", "author": "tests", "dependencies": ["base"],
        }))
        files = set(re.findall(r'"__' + name + r'__/([^"\n]+)"', source))
        if not files:
            raise TestFailure(f"No drone graphics for {name}")
        with zipfile.ZipFile(find_archive(dependency_mod_directory, name)) as archive:
            for filename in files:
                members = [member for member in archive.namelist() if member.endswith("/" + filename)]
                if len(members) != 1:
                    raise TestFailure(f"Expected one drone graphic: {filename}")
                target = graphics / filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(members[0]))


def stage_terrain_drone_recipes(mod):
    source = (ROOT / "nullius-star/prototypes/item/drone.lua").read_text()
    marker = "local function create_miner("
    if source.count(marker) != 1:
        raise TestFailure("Expected terrain drone generators before create_miner")
    calls = [line for line in source.splitlines() if line.startswith(("create_terraform(", "create_paving("))]
    if len(calls) != 15:
        raise TestFailure("Expected 15 terrain drone calls")
    (mod / "terrain-drone-source.lua").write_text(source.split(marker, 1)[0] + "\n" + "\n".join(calls) + "\n")
    for target, source in (
        ("terrain-drone-recipes.lua", "tests/compatibility/terrain-drone-recipes.lua"),
        ("terrain-drone-executor.lua", "tests/factorio-test-support/terrain-drone-recipes.lua"),
        ("scenarios/terrain-drone-recipes", "tests/scenarios/terrain-drone-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())


def stage_alignment_recipes(mod):
    for target, source in (
        ("alignment-recipes-source.lua", "nullius-star/prototypes/item/alignment.lua"),
        ("alignment-recipes.lua", "tests/compatibility/alignment-recipes.lua"),
        ("alignment-recipe-executor.lua", "tests/factorio-test-support/alignment-recipes.lua"),
        ("scenarios/alignment-recipes", "tests/scenarios/alignment-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())
    (mod / "alignment-setting-expected.lua").write_text("return true\n")
    (mod / "settings.lua").write_text('data:extend({{type="bool-setting",name="nullius-alignment",setting_type="startup",default_value=true}})\n')


def stage_module_recipes(mod):
    for target, source in (
        ("module-recipes-source.lua", "nullius-star/prototypes/item/module.lua"),
        ("module-recipes.lua", "tests/compatibility/module-recipes.lua"),
        ("module-recipe-executor.lua", "tests/factorio-test-support/module-recipes.lua"),
        ("scenarios/module-recipes", "tests/scenarios/module-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())


def stage_boxing_recipes(mod):
    source = (ROOT / "nullius-star/prototypes/item/boxing.lua").read_text()
    marker = '\ndata.raw["capsule"]["cliff-explosives"].localised_name'
    if source.count(marker) != 1:
        raise TestFailure("Expected boxing generator before item overrides")
    (mod / "boxing-generator.lua").write_text(source.split(marker, 1)[0] + "\nreturn create_boxed_item\n")
    for target, source_path in (
        ("boxing-recipes.lua", "tests/compatibility/boxing-recipes.lua"),
        ("boxing-recipe-executor.lua", "tests/factorio-test-support/boxing-recipes.lua"),
        ("scenarios/boxing-recipes", "tests/scenarios/boxing-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())


def stage_broken_recipes(mod, mods, version, dependency_mod_directory):
    for target, source in (
        ("broken-recipes-source.lua", "nullius-star/prototypes/item/broken.lua"),
        ("broken-recipes.lua", "tests/compatibility/broken-recipes.lua"),
        ("broken-recipe-executor.lua", "tests/factorio-test-support/broken-recipes.lua"),
        ("scenarios/broken-recipes", "tests/scenarios/broken-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source, target_is_directory=(ROOT / source).is_dir())
    graphics = mods / "angelspetrochemgraphics"
    graphics.mkdir()
    (graphics / "info.json").write_text(json.dumps({
        "name": "angelspetrochemgraphics", "version": "0.0.1", "factorio_version": version,
        "title": "Repair graphics fixture", "author": "tests", "dependencies": ["base"],
    }))
    filename = "graphics/icons/air-filter.png"
    with zipfile.ZipFile(find_archive(dependency_mod_directory, "angelspetrochemgraphics")) as archive:
        members = [name for name in archive.namelist() if name.endswith("/" + filename)]
        if len(members) != 1:
            raise TestFailure("Expected one Angel air-filter icon")
        target = graphics / filename
        target.parent.mkdir(parents=True)
        target.write_bytes(archive.read(members[0]))


def stage_turbine_recipes(mod):
    (mod / "turbine-recipes-source.lua").symlink_to(ROOT / "nullius-star/prototypes/item/turbine.lua")
    (mod / "turbine-recipes.lua").symlink_to(ROOT / "tests/compatibility/turbine-recipes.lua")
    (mod / "turbine-recipe-executor.lua").symlink_to(ROOT / "tests/factorio-test-support/turbine-recipes.lua")
    (mod / "scenarios/turbine-recipes").symlink_to(ROOT / "tests/scenarios/turbine-recipes", target_is_directory=True)


def stage_void_products(mod):
    (mod / "legacyAngels.lua").symlink_to(ROOT / "nullius-star/legacyAngels.lua")
    (mod / "void-recipes.lua").symlink_to(ROOT / "nullius-star/prototypes/item/void.lua")
    (mod / "void-recipe-fixture.lua").symlink_to(ROOT / "tests/compatibility/void-categories.lua")
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
        "dependencies": [f"base >= {version}.0", "boblogistics", "angelspetrochemgraphics", "angelsrefininggraphics", "angelssmeltinggraphics"],
    }))
    (mod / "data.lua").write_text('require("tool-fixture")\nrequire("productivity-fixture")\nrequire("fluid-preservation")\nrequire("helper-mining")\nrequire("drone-mining")\nrequire("recipe-filter")\nrequire("assembler-pipe-pictures")\nrequire("asteroid-miner-products")\nrequire("rock-drops")\nrequire("fluid-resource-fixture")\nrequire("fluid-resource-products")\nrequire("turbine-pictures")\nrequire("turbine-generator")\nrequire("vehicle-dependencies")\nrequire("car-prototypes")\nrequire("vehicle-forces")\nrequire("chest-doors")\nrequire("chest-test-port")\nrequire("miner-connectors")\nrequire("turbine-recipes")\nrequire("broken-recipes")\nrequire("broken-recipe-executor")\nrequire("boxing-recipes")\nrequire("boxing-recipe-executor")\nrequire("module-recipes")\nrequire("module-recipe-executor")\nrequire("turbine-recipe-executor")\nrequire("void-recipe-fixture")\nrequire("void-products")\nrequire("metallurgic-recipe-fixture")\nrequire("metallurgic-products")\nrequire("extractor-pictures")\nrequire("extractor-test")\nrequire("well-recipe-fixture")\nrequire("well-pictures")\nrequire("well-test")\nrequire("pump-wagons")\nrequire("pump-test")\nrequire("salvage-research")\nrequire("reactor-prototype")\nrequire("reactor-neighbours")\nrequire("solar-prototypes")\nrequire("terrain-drone-recipes")\nrequire("terrain-drone-executor")\nrequire("drone-recipes")\nrequire("drone-recipe-executor")\nrequire("alignment-recipes")\nrequire("alignment-recipe-executor")\nrequire("weapon-recipes")\nrequire("weapon-recipe-executor")\nrequire("landfill-recipes")\nrequire("landfill-recipe-executor")\nrequire("general-recipes")\nrequire("general-recipe-executor")\nrequire("biology-recipes")\nrequire("biology-recipe-executor")\nrequire("equipment-recipes")\nrequire("equipment-recipe-executor")\nrequire("building-recipes")\nrequire("building-recipe-executor")\nrequire("plumbing-recipes")\nrequire("plumbing-recipe-executor")\nrequire("fluid-recipes")\nrequire("fluid-recipe-executor")\nrequire("intermediate-recipes")\nrequire("intermediate-recipe-executor")\nrequire("primitive-recipes")\nrequire("primitive-recipe-executor")\n')
    for filename in ("tool-fixture.lua", "productivity-fixture.lua", "helper-mining.lua", "recipe-visibility.lua", "assembler-pipe-pictures.lua", "asteroid-miner-products.lua", "rock-drops.lua", "turbine-pictures.lua", "vehicle-dependencies.lua", "chest-doors.lua"):
        (mod / filename).symlink_to(ROOT / "tests/compatibility" / filename)
    (mod / "turbine-generator.lua").symlink_to(ROOT / "tests/factorio-test-support/turbine-generator.lua")
    (mod / "factorio-version.lua").symlink_to(ROOT / "nullius-star/factorio-version.lua")
    stage_chest_graphics(mods, version, dependency_mod_directory)
    (mod / "chest-test-port.lua").symlink_to(ROOT / "tests/factorio-test-support/chest-doors.lua")
    stage_car_prototypes(mod)
    stage_miner_connectors(mod)
    stage_void_products(mod)
    stage_turbine_recipes(mod)
    stage_boxing_recipes(mod)
    stage_module_recipes(mod)
    stage_alignment_recipes(mod)
    stage_terrain_drone_recipes(mod)
    stage_drone_recipes(mod, mods, version, dependency_mod_directory)
    stage_weapon_recipes(mod, mods, dependency_mod_directory)
    stage_landfill_recipes(mod)
    stage_general_recipes(mod, mods, dependency_mod_directory)
    stage_broken_recipes(mod, mods, version, dependency_mod_directory)
    stage_plumbing_recipes(mod, mods, dependency_mod_directory)
    stage_building_recipes(mod, mods, dependency_mod_directory)
    stage_equipment_recipes(mod, mods, dependency_mod_directory)
    stage_biology_recipes(mod, mods, dependency_mod_directory)
    stage_fluid_recipes(mod, mods, dependency_mod_directory)
    stage_intermediate_recipes(mod, mods, dependency_mod_directory)
    stage_primitive_recipes(mod)
    with (mod / "settings.lua").open("a") as settings_file:
        settings_file.write('data:extend({{type="bool-setting",name="nullius-hide-recipe-signals",setting_type="startup",default_value=false}})\n')
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
    stage_pump_wagons(mod)
    stage_salvage_research(mod)
    stage_reactor_neighbours(mod)
    stage_solar_neighbours(mod)
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
    for filename in ("solar.lua", "mirror.lua", "beacon.lua", "geothermal.lua", "vulcanus_heat.lua", "vulcanus_gasvent.lua", "drone.lua", "recipe_filter.lua"):
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
                            ("nullius-star", "turbine-recipes"),
                            ("nullius-star", "broken-recipes"),
                            ("nullius-star", "boxing-recipes"),
                            ("nullius-star", "module-recipes"),
                            ("nullius-star", "alignment-recipes"),
                            ("nullius-star", "terrain-drone-recipes"),
                            ("nullius-star", "drone-recipes"),
                            ("nullius-star", "weapon-recipes"),
                            ("nullius-star", "landfill-recipes"),
                            ("nullius-star", "general-recipes"),
                            ("nullius-star", "biology-recipes"),
                            ("nullius-star", "equipment-recipes"),
                            ("nullius-star", "building-recipes"),
                            ("nullius-star", "plumbing-recipes"),
                            ("nullius-star", "fluid-recipes"),
                            ("nullius-star", "intermediate-recipes"),
                            ("nullius-star", "primitive-recipes"),
                            ("nullius-star", "vehicle-forces"),
                            ("nullius-star", "chest-doors"),
                            ("nullius-star", "void-products"),
                            ("nullius-star", "metallurgic-products"),
                            ("nullius-star", "extractor-pictures"),
                            ("nullius-star", "well-pictures"),
                            ("nullius-star", "pump-wagons"),
                            ("nullius-star", "salvage-research"),
                            ("nullius-star", "reactor-neighbours"),
                            ("nullius-star", "solar-neighbours"),
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
    pumps = json.loads((work / "script-output/factorio-tests/pump-wagons.json").read_text())
    assert pumps["status"] == "pass" and pumps["cases"] == 16, pumps
    salvage = json.loads((work / "script-output/factorio-tests/salvage-research.json").read_text())
    assert salvage["status"] == "pass", salvage
    reactors = json.loads((work / "script-output/factorio-tests/reactor-neighbours.json").read_text())
    assert reactors["status"] == "pass" and reactors["layouts"] == 32, reactors
    solar = json.loads((work / "script-output/factorio-tests/solar-neighbours.json").read_text())
    assert solar["status"] == "pass" and solar["layouts"] == 144, solar
    plumbing = json.loads((work / "script-output/factorio-tests/plumbing-recipes.json").read_text())
    assert plumbing["status"] == "pass" and plumbing["recipes"] == 113, plumbing
    building = json.loads((work / "script-output/factorio-tests/building-recipes.json").read_text())
    assert building["status"] == "pass" and building["recipes"] == 137, building
    equipment = json.loads((work / "script-output/factorio-tests/equipment-recipes.json").read_text())
    assert equipment["status"] == "pass" and equipment["recipes"] == 157, equipment
    primitive = json.loads((work / "script-output/factorio-tests/primitive-recipes.json").read_text())
    assert primitive["status"] == "pass" and primitive["recipes"] == 5, primitive
    intermediate = json.loads((work / "script-output/factorio-tests/intermediate-recipes.json").read_text())
    assert intermediate["status"] == "pass" and intermediate["recipes"] == 293, intermediate
    fluid_recipes = json.loads((work / "script-output/factorio-tests/fluid-recipes.json").read_text())
    assert fluid_recipes["status"] == "pass" and fluid_recipes["recipes"] == 223, fluid_recipes
    biology = json.loads((work / "script-output/factorio-tests/biology-recipes.json").read_text())
    assert biology["status"] == "pass" and biology["recipes"] == 152, biology
    general = json.loads((work / "script-output/factorio-tests/general-recipes.json").read_text())
    assert general["status"] == "pass" and general["recipes"] == 66, general
    landfill = json.loads((work / "script-output/factorio-tests/landfill-recipes.json").read_text())
    assert landfill["status"] == "pass" and landfill["recipes"] == 30, landfill
    weapons = json.loads((work / "script-output/factorio-tests/weapon-recipes.json").read_text())
    assert weapons["status"] == "pass" and weapons["recipes"] == 17, weapons
    drone_recipes = json.loads((work / "script-output/factorio-tests/drone-recipes.json").read_text())
    assert drone_recipes["status"] == "pass" and drone_recipes["recipes"] == 50, drone_recipes
    terrain = json.loads((work / "script-output/factorio-tests/terrain-drone-recipes.json").read_text())
    assert terrain["status"] == "pass" and terrain["recipes"] == 15, terrain
    alignment = json.loads((work / "script-output/factorio-tests/alignment-recipes.json").read_text())
    assert alignment["status"] == "pass" and alignment["recipes"] == 9, alignment
    (mod / "settings.lua").write_text((mod / "settings.lua").read_text().replace("default_value=true", "default_value=false"))
    (mod / "alignment-setting-expected.lua").write_text("return false\n")
    (mods / "mod-settings.dat").unlink(missing_ok=True)
    prototype_dump = work / "script-output/data-raw-dump.json"
    enabled_dump = work / "script-output/alignment-enabled-dump.json"
    prototype_dump.rename(enabled_dump)
    execute("alignment-disabled", ["--dump-data"])
    prototype_dump.rename(work / "script-output/alignment-disabled-dump.json")
    enabled_dump.rename(prototype_dump)
    module_recipes = json.loads((work / "script-output/factorio-tests/module-recipes.json").read_text())
    assert module_recipes["status"] == "pass" and module_recipes["recipes"] == 46, module_recipes
    boxing = json.loads((work / "script-output/factorio-tests/boxing-recipes.json").read_text())
    assert boxing["status"] == "pass" and boxing["pairs"] == 16, boxing
    repairs = json.loads((work / "script-output/factorio-tests/broken-recipes.json").read_text())
    assert repairs["status"] == "pass" and repairs["recipes"] == 10, repairs
    turbine_recipes = json.loads((work / "script-output/factorio-tests/turbine-recipes.json").read_text())
    assert turbine_recipes["status"] == "pass" and turbine_recipes["recipes"] == 38, turbine_recipes
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
            "turbine_recipe_assertions": turbine_recipes["assertions"],
            "repair_assertions": repairs["assertions"],
            "boxing_assertions": boxing["assertions"],
            "module_recipe_assertions": module_recipes["assertions"],
            "alignment_assertions": alignment["assertions"],
            "terrain_drone_assertions": terrain["assertions"],
            "drone_recipe_assertions": drone_recipes["assertions"],
            "weapon_recipe_assertions": weapons["assertions"],
            "landfill_recipe_assertions": landfill["assertions"],
            "general_recipe_assertions": general["assertions"],
            "biology_recipe_assertions": biology["assertions"],
            "fluid_recipe_assertions": fluid_recipes["assertions"],
            "intermediate_recipe_assertions": intermediate["assertions"],
            "primitive_recipe_assertions": primitive["assertions"],
            "equipment_recipe_assertions": equipment["assertions"],
            "building_recipe_assertions": building["assertions"],
            "plumbing_recipe_assertions": plumbing["assertions"],
            "vehicle_assertions": vehicles["assertions"],
            "chest_assertions": chests["assertions"],
            "void_assertions": voids["assertions"],
            "metallurgic_assertions": metallurgy["assertions"],
            "extractor_assertions": extractors["assertions"],
            "well_assertions": wells["assertions"],
            "pump_assertions": pumps["assertions"],
            "salvage_assertions": salvage["assertions"],
            "reactor_assertions": reactors["assertions"],
            "solar_assertions": solar["assertions"],
            "recipe_filter_assertions": filtering["assertions"], "status": "pass"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    print(json.dumps(run(args.factorio.expanduser().resolve(), args.dependency_mod_directory.expanduser().resolve()), indent=2))


if __name__ == "__main__":
    main()
