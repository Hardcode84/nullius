#!/usr/bin/env python3
"""Check the optional Induction Charging recipe on Factorio 2.0 and 2.1 with declared external prototypes."""
import argparse
import json
from pathlib import Path
import tempfile
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure

ROOT = Path(__file__).resolve().parents[1]


def run(factorio, mode):
    metadata = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    work = Path(tempfile.mkdtemp(prefix="induction-compat-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": version,
        "title": "Induction recipe fixture", "author": "tests", "dependencies": ["base", "? Induction Charging"],
    }))
    external = work / "mods/Induction Charging"
    external.mkdir()
    (external / "info.json").write_text(json.dumps({
        "name": "Induction Charging", "version": "0.0.1", "factorio_version": version,
        "title": "External item fixture", "author": "tests", "dependencies": ["base"],
    }))
    names = ["Induction Charging", "base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if version == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [{"name": name, "enabled": name in ({"base", "nullius-star", "Induction Charging"} if mode != "no-mod" else {"base", "nullius-star"})} for name in names]}))
    source = (ROOT / "nullius-star/prototypes/override_mod.lua").read_text()
    start = source.index('if mods["Induction Charging"] then')
    end = source.index('if mods["Transport_Drones"] then', start)
    (mod / "integration.lua").write_text(source.splitlines()[0] + "\n" + source[start:end])
    for target, source_path in (
        ("factorio-version.lua", "nullius-star/factorio-version.lua"),
        ("fixture.lua", "tests/compatibility/induction-recipe.lua"),
        ("executor.lua", "tests/factorio-test-support/induction-recipe.lua"),
        ("scenarios/induction-recipe", "tests/scenarios/induction-recipe"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    (mod / "data.lua").write_text('require("fixture")\nrequire("integration")\n')
    deadline = json.loads((ROOT / "tests/scenarios/induction-recipe/test.json").read_text())["until_tick"]
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(work / "mods"), "--disable-audio"]
    for label, options in (
        ("dump", ["--dump-data"]),
        ("compile", ["--scenario2map", "nullius-star/induction-recipe"]),
        ("run", ["--load-game", str(work / "saves/nullius-star/induction-recipe.zip"), "--until-tick", str(deadline)]),
    ):
        result = run_factorio(common + options, work / f"{label}.log", 180)
        if result.returncode:
            raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")
    result = json.loads((work / "script-output/factorio-tests/induction-recipe.json").read_text())
    assert result["status"] == "pass" and result["active"] == (mode == "enabled"), result
    return {"mode": mode, "artifacts": str(work), **result}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps([run(args.factorio.expanduser().resolve(), mode)
                      for mode in ("enabled", "no-mod")], indent=2))
