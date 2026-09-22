#!/usr/bin/env python3
"""Load the complete optional-mod recipe file with declared dependencies on both engines."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import itertools
import json
from pathlib import Path
import tempfile

from test_vulcanus_processing_compatibility import ROOT, lua, canonical, command, dump
from run_factorio_tests import TestFailure

LEGACY_COMBINATORS = {"crafting_combinator", "crafting_combinator_xeraph"}
CONFIG = json.loads((ROOT / "tests/compatibility/mod-recipes.json").read_text())


def modes():
    yield "all", (set(CONFIG["mods"]) - LEGACY_COMBINATORS), dict.fromkeys(CONFIG["settings"], True)
    yield "none", set(), dict.fromkeys(CONFIG["settings"], False)
    for bits in itertools.product((False, True), repeat=3):
        settings = dict.fromkeys(CONFIG["settings"], True)
        settings.update(zip(("RTThrowersSetting", "RTZiplineSetting", "RTTrainRampSetting"), bits))
        settings["fmf-enable-duct-auto-join"] = False
        yield "switches-" + "".join(str(int(bit)) for bit in bits), (set(CONFIG["mods"]) - LEGACY_COMBINATORS), settings
    settings = dict.fromkeys(CONFIG["settings"], True)
    for name in CONFIG["settings"]:
        if name.startswith("miniloader-"):
            settings[name] = False
    yield "miniloader-off", (set(CONFIG["mods"]) - LEGACY_COMBINATORS), settings
    disabled = {"LogisticTrainNetwork", "miniloader", "factorissimo-2-notnotmelon",
                "crafting_combinator", "rec-blue-plus", "beautiful_bridge_railway",
                "beautiful_bridge_railway_Cargoships"}
    yield "alternatives", (set(CONFIG["mods"]) - LEGACY_COMBINATORS) - disabled, dict.fromkeys(CONFIG["settings"], True)


def run(engine, mode, enabled, settings, source):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    assert major in {"2.0", "2.1"}
    work = Path(tempfile.mkdtemp(prefix=f"mod-recipes-{major}-{mode}-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(
        name="nullius-star", version="0.0.3", factorio_version=major,
        title="Optional recipe fixture", author="tests", dependencies=["base", "space-age"],
        space_travel_required=True)))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [dict(name=n, enabled=True) for n in names]}))
    for target, path in (
        ("factorio-version.lua", "nullius-star/factorio-version.lua"),
        ("fixture-data.lua", "tests/compatibility/mod-recipes.lua"),
        ("register.lua", "tests/compatibility/mod-recipes-register.lua"),
        ("executors.lua", "tests/factorio-test-support/recipe-batches.lua"),
        ("scenarios/recipe-batches", "tests/scenarios/compatibility/recipe-batches"),
        ("scenarios/fluid-api.lua", "tests/scenarios/fluid-api.lua"),
    ):
        (mod / target).symlink_to(ROOT / path)
    # Only the external dependency switches and declared data registry are local.
    # The complete production file executes unchanged after this prefix.
    prefix = 'local data=require("fixture-data")\n'
    prefix += "local mods=" + lua(dict.fromkeys(sorted(enabled), "1.0.0")) + "\n"
    prefix += "local settings=" + lua({"startup": {k: {"value": v} for k, v in settings.items()}}) + "\n"
    (mod / "integration.lua").write_text(prefix + source)
    (mod / "data.lua").write_text('require("integration")\nrequire("register")\n')
    with (mod / "data.lua").open("a") as output:
        output.write('local pumps=require("fixture-data").raw.pump\n')
        output.write('for _,pump in pairs(pumps) do\n')
        if version.startswith("2.1"):
            output.write('assert(pump.fluid_wagon_connector_alignment_tolerance == nil, "obsolete Mini Trains tolerance")\n')
            output.write('assert(pump.fluid_wagon_tank_valve_max_distance == data.raw.pump.pump.fluid_wagon_tank_valve_max_distance, "Mini Trains changed native reach")\n')
        elif "Mini_Trains" in enabled:
            output.write('assert(pump.fluid_wagon_connector_alignment_tolerance == 20/32, "Mini Trains legacy tolerance")\n')
        output.write('end\n')
    resolved = dump(work, engine)
    contracts = resolved["mod-data"]["mod-recipe-contracts"]["data"]
    recipes = contracts["recipes"]
    result = dict(version=version, mode=mode, recipes=len(recipes),
                  technologies=len(contracts["technologies"]), artifacts=str(work))
    if recipes:
        (mod / "recipe-test-contracts.lua").write_text("return " + lua(recipes) + "\n")
        with (mod / "data.lua").open("a") as output:
            output.write('data:extend({{type="surface-property",name="nullius-ambient-temperature",default_value=200}})\nrequire("executors")\n')
        deadline = json.loads((ROOT / "tests/scenarios/compatibility/recipe-batches/test.json").read_text())["until_tick"]
        command(work, engine, ["--scenario2map", "nullius-star/recipe-batches"], "compile")
        command(work, engine, ["--load-game", str(work / "saves/nullius-star/recipe-batches.zip"),
                               "--until-tick", str(deadline)], "run")
        crafting = json.loads((work / "script-output/factorio-tests/recipe-batches.json").read_text())
        assert crafting["status"] == "pass" and crafting["recipes"] == len(recipes), crafting
        result["crafting"] = crafting
    return contracts, result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--baseline-source", type=Path, help="Optional unmodified 2.0 source for before/after comparison")
    args = parser.parse_args()
    source = (ROOT / "nullius-star/prototypes/mods.lua").read_text()
    baseline_source = args.baseline_source.read_text() if args.baseline_source else source
    results = []
    covered = set()
    for mode, enabled, settings in modes():
        specifications = [(args.factorio_2_0, baseline_source), (args.factorio_2_1, source)]
        if args.baseline_source:
            specifications.append((args.factorio_2_0, source))
        with ThreadPoolExecutor(max_workers=len(specifications)) as pool:
            jobs = [pool.submit(run, engine.resolve(), mode, enabled, settings, code)
                    for engine, code in specifications]
            runs = [job.result() for job in jobs]
        for candidate in runs[1:]:
            assert canonical(runs[0][0]) == canonical(candidate[0]), f"Contracts differ: {mode}"
        covered.update(runs[0][0]["recipes"])
        if mode == "none":
            assert all(result[1]["recipes"] == 0 for result in runs)
        results.extend(result[1] for result in runs)
        print(json.dumps(dict(mode=mode, results=[result[1] for result in runs])), flush=True)
    assert covered
    print(json.dumps(dict(unique_recipes=len(covered), configurations=len(results))), flush=True)
    # These two legacy mods use prototype names that both supported engines
    # reject. Keep the failure explicit until the dependency exposes valid names.
    for engine in (args.factorio_2_0, args.factorio_2_1):
        for name in sorted(LEGACY_COMBINATORS):
            try:
                run(engine.resolve(), "legacy-" + name, {name}, {}, source)
            except TestFailure as error:
                assert "Invalid prototype name" in str(error) and "crafting_combinator:" in str(error), error
                print(json.dumps(dict(mod=name, engine=str(engine), expected_failure="invalid legacy prototype names")), flush=True)
            else:
                raise AssertionError("Legacy names unexpectedly accepted: " + name)


if __name__ == "__main__":
    main()
