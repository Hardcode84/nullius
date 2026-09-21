#!/usr/bin/env python3
"""Check generated barrel recipe overrides on Factorio 2.0 and 2.1 with native barrel generation."""
import argparse
import json
from pathlib import Path
import tempfile
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure

ROOT = Path(__file__).resolve().parents[1]


def run(factorio):
    metadata = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    work = Path(tempfile.mkdtemp(prefix="barrel-recipe-compat-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": version,
        "title": "Barrel recipe fixture", "author": "tests", "dependencies": ["base"],
    }))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if version == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [{"name": name, "enabled": name in {"base", "nullius-star"}} for name in names]}))
    source = (ROOT / "nullius-star/prototypes/override_final.lua").read_text()
    start = source.index("for _,fluid in pairs(data.raw.fluid) do")
    end = source.index("-- Mods might overwrite character", start)
    (mod / "data-final-fixes.lua").write_text(
        'local modern = require("factorio-version").is_2_1\n' + source[start:end])
    for target, source_path in (
        ("factorio-version.lua", "nullius-star/factorio-version.lua"),
        ("fixture.lua", "tests/compatibility/barrel-recipes.lua"),
        ("executor.lua", "tests/factorio-test-support/barrel-recipes.lua"),
        ("scenarios/barrel-recipes", "tests/scenarios/barrel-recipes"),
        ("scenarios/fluid-api.lua", "tests/scenarios/fluid-api.lua"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    (mod / "data.lua").write_text('require("fixture")\n')
    deadline = json.loads((ROOT / "tests/scenarios/barrel-recipes/test.json").read_text())["until_tick"]
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(work / "mods"), "--disable-audio"]
    for label, options in (
        ("dump", ["--dump-data"]),
        ("compile", ["--scenario2map", "nullius-star/barrel-recipes"]),
        ("run", ["--load-game", str(work / "saves/nullius-star/barrel-recipes.zip"), "--until-tick", str(deadline)]),
    ):
        result = run_factorio(common + options, work / f"{label}.log", 180)
        if result.returncode:
            raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")
    result = json.loads((work / "script-output/factorio-tests/barrel-recipes.json").read_text())
    assert result["status"] == "pass" and result["recipes"] == 8, result
    return {"artifacts": str(work), **result}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(run(args.factorio.expanduser().resolve()), indent=2))
