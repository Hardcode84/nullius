#!/usr/bin/env python3
"""Check the complete optional override file on Factorio 2.0 and 2.1 with declared external prototypes."""
import argparse
import json
from pathlib import Path
import tempfile
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure

ROOT = Path(__file__).resolve().parents[1]


def run(factorio, mode):
    metadata = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    work = Path(tempfile.mkdtemp(prefix="optional-override-compat-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": version,
        "title": "Optional override fixture", "author": "tests", "dependencies": ["base", "? Transport_Drones", "? cargo-ships", "? cargo-drone"],
    }))
    external_names = ["Transport_Drones", "cargo-ships", "cargo-drone"]
    for name in external_names:
        external = work / "mods" / name
        external.mkdir()
        (external / "info.json").write_text(json.dumps({
            "name": name, "version": "0.0.1", "factorio_version": version,
            "title": "External prototype fixture", "author": "tests", "dependencies": ["base"],
        }))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"] + external_names
    if version == "2.1":
        names.append("recycler")
    enabled = {"base", "nullius-star"} | (set(external_names) if mode != "no-mod" else set())
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [{"name": name, "enabled": name in enabled} for name in names]}))
    (mod / "settings.lua").write_text('data:extend({{type="bool-setting",name="offshore_oil_enabled",setting_type="startup",default_value=' + ("false" if mode == "no-oil" else "true") + '}})')
    for target, source_path in (
        ("factorio-version.lua", "nullius-star/factorio-version.lua"),
        ("fixture.lua", "tests/compatibility/optional-overrides.lua"),
        ("dependencies.lua", "tests/compatibility/optional-override-dependencies.lua"),
        ("integration.lua", "nullius-star/prototypes/override_mod.lua"),
        ("void-products.lua", "tests/factorio-test-support/void-products.lua"),
        ("scenarios/fluid-api.lua", "tests/scenarios/fluid-api.lua"),
        ("executor.lua", "tests/factorio-test-support/optional-override-recipes.lua"),
        ("scenarios/optional-override-recipes", "tests/scenarios/optional-override-recipes"),
    ):
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    (mod / "data.lua").write_text('data:extend({{type="recipe-category",name="nullius-liquid-void"},{type="recipe-category",name="nullius-gas-void"},{type="recipe-category",name="nullius-power-sink"}})\nrequire("fixture")\nrequire("integration")\n')
    deadline = json.loads((ROOT / "tests/scenarios/optional-override-recipes/test.json").read_text())["until_tick"]
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(work / "mods"), "--disable-audio"]
    for label, options in (
        ("dump", ["--dump-data"]),
        ("compile", ["--scenario2map", "nullius-star/optional-override-recipes"]),
        ("run", ["--load-game", str(work / "saves/nullius-star/optional-override-recipes.zip"), "--until-tick", str(deadline)]),
    ):
        result = run_factorio(common + options, work / f"{label}.log", 180)
        if result.returncode:
            raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")
    result = json.loads((work / "script-output/factorio-tests/optional-override-recipes.json").read_text())
    assert result["status"] == "pass" and result["active"] == (mode != "no-mod"), result
    return {"mode": mode, "artifacts": str(work), **result}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps([run(args.factorio.expanduser().resolve(), mode)
                      for mode in ("enabled", "no-oil", "no-mod")], indent=2))
