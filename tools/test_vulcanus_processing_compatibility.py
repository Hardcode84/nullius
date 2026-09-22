#!/usr/bin/env python3
"""Compare the complete Vulcanus recipe file on native 2.0 and 2.1 engines.

Capture actual dependencies before this file runs in full Nullius 2.0. Load the
same dependencies and complete source in isolation on each engine. Compare every
changed recipe and item, excluding graphics and version-specific presentation.
"""
import argparse
import json
from pathlib import Path
import tempfile

from run_factorio_tests import (
    default_dependency_mods, prepare_mods, prepare_config, run_factorio, TestFailure,
)

ROOT = Path(__file__).resolve().parents[1]


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (str, int, float)):
        return json.dumps(value, ensure_ascii=True)
    if isinstance(value, list):
        return "{" + ",".join(lua(v) for v in value) + "}"
    return "{" + ",".join("[" + lua(k) + "]=" + lua(v) for k, v in value.items()) + "}"


def command(work, engine, options, label):
    config = prepare_config(work, engine)
    result = run_factorio([str(engine), "--config", str(config), "--mod-directory",
                          str(work / "mods"), "--disable-audio", *options],
                         work / (label + ".log"), 180)
    if result.returncode:
        raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")


def dump(work, engine):
    command(work, engine, ["--dump-data"], "dump")
    return json.loads((work / "script-output/data-raw-dump.json").read_text())


def capture(engine, dependencies):
    work = Path(tempfile.mkdtemp(prefix="vulcanus-processing-baseline-"))
    prepare_mods(work / "mods", dependencies)
    mod = work / "mods/nullius-star"
    source = (mod / "data.lua").read_text()
    marker = 'require("prototypes.planet.vulcanus-recipes")'
    assert source.count(marker) == 1
    (mod / "data.lua").unlink()
    (mod / "data.lua").write_text(source.replace(marker, 'require("vulcanus-capture")'))
    (mod / "vulcanus-capture.lua").symlink_to(ROOT / "tests/compatibility/vulcanus-capture.lua")
    resolved = dump(work, engine)
    baseline = resolved["mod-data"]["vulcanus-capture"]["data"]
    # Compression fluids are generated after this file. Supply those real fluids
    # to the isolated loader without replacing its pre-file inputs.
    for name, fluid in resolved["fluid"].items():
        baseline["fluids"].setdefault(name, fluid)
    return baseline, work


def canonical(value):
    if isinstance(value, list):
        return [canonical(v) for v in value]
    if not isinstance(value, dict):
        return value
    result = {k: canonical(v) for k, v in value.items()
              if k not in {"icon", "icon_size", "icons", "show_amount_in_title", "always_show_products"}}
    if "category" in result:
        result["categories"] = [result.pop("category")]
    if "probability" in result:
        result["independent_probability"] = result.pop("probability")
    return result


def run(engine, baseline, alignment):
    version = json.loads((engine.parents[2] / "data/base/info.json").read_text())["version"]
    major = ".".join(version.split(".")[:2])
    if major not in {"2.0", "2.1"}:
        raise TestFailure(f"Unsupported version: {version}")
    work = Path(tempfile.mkdtemp(prefix=f"vulcanus-processing-{major}-"))
    mod = work / "mods/nullius-star"
    (mod / "prototypes/planet").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(
        name="nullius-star", version="0.0.3", factorio_version=major,
        title="Vulcanus processing fixture", author="tests", dependencies=["base", "space-age"],
        space_travel_required=True)))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if major == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [dict(name=n, enabled=True) for n in names]}))
    for name in ["factorio-version.lua", "prototypes/recipe-util.lua", "prototypes/planet/vulcanus-recipes.lua"]:
        (mod / name).symlink_to(ROOT / "nullius-star" / name)
    (mod / "fixture.lua").write_text("return " + lua(baseline) + "\n")
    (mod / "data.lua").write_text(f'local alignment_enabled={lua(alignment)}\n' +
                                   (ROOT / "tests/compatibility/vulcanus-processing.lua").read_text())
    contracts = {name: recipe for name, recipe in baseline["recipes"].items()
                 if name not in baseline["inputs"] and
                 (alignment or name != "nullius-align-identification-card-vulcanus")}
    assert contracts, "No generated Vulcanus recipes captured"
    (mod / "recipe-test-contracts.lua").write_text("return " + lua(contracts) + "\n")
    (mod / "executors.lua").symlink_to(ROOT / "tests/factorio-test-support/recipe-batches.lua")
    (mod / "scenarios").mkdir()
    (mod / "scenarios/recipe-batches").symlink_to(ROOT / "tests/scenarios/compatibility/recipe-batches")
    (mod / "scenarios/fluid-api.lua").symlink_to(ROOT / "tests/scenarios/fluid-api.lua")
    with (mod / "data.lua").open("a") as output:
        output.write('require("executors")\n')
    resolved = dump(work, engine)
    expected = baseline["recipes"]
    checked = 0
    for name, recipe in expected.items():
        if not alignment and name == "nullius-align-identification-card-vulcanus":
            assert name not in resolved["recipe"]
            continue
        actual = resolved["recipe"][name]
        assert canonical(actual) == canonical(recipe), f"Recipe differs: {name}"
        checked += 1
    for name, item in baseline["products"].items():
        actual = resolved[item["type"]][name]
        assert canonical(actual) == canonical(item), f"Item differs: {name}"
    if alignment:
        actual = resolved["mod-data"]["vulcanus-alignment-check"]["data"]["effects"]
        assert actual == baseline["alignment_after"]["effects"], "Alignment unlocks differ"
    assert resolved["recipe"]["nullius-boxed-solar-panel-1-vulcanus"].get(
        "categories", [resolved["recipe"]["nullius-boxed-solar-panel-1-vulcanus"].get("category")]) == ["huge-fluid-assembly"]
    deadline = json.loads((ROOT / "tests/scenarios/compatibility/recipe-batches/test.json").read_text())["until_tick"]
    command(work, engine, ["--scenario2map", "nullius-star/recipe-batches"], "compile")
    command(work, engine, ["--load-game", str(work / "saves/nullius-star/recipe-batches.zip"),
                           "--until-tick", str(deadline)], "run")
    result = json.loads((work / "script-output/factorio-tests/recipe-batches.json").read_text())
    assert result["status"] == "pass" and result["recipes"] == len(contracts), result
    return dict(version=version, alignment=alignment, recipes=checked, crafting=result,
                items=len(baseline["products"]), artifacts=str(work))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    baseline, work = capture(args.factorio_2_0.resolve(), args.dependency_mod_directory.resolve())
    results = [run(engine.resolve(), baseline, alignment)
               for engine in (args.factorio_2_0, args.factorio_2_1)
               for alignment in (True, False)]
    print(json.dumps(dict(baseline=str(work), results=results), indent=2))
