#!/usr/bin/env python3
"""Check Vulcanus entity recipes on Factorio 2.0 and 2.1 with Space Age."""
import argparse
import json
import re
from pathlib import Path
import tempfile
from run_factorio_tests import prepare_config, run_factorio, supported_factorio_version, TestFailure

ROOT = Path(__file__).resolve().parents[1]


def run(factorio):
    metadata = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = supported_factorio_version(".".join(metadata["version"].split(".")[:2]))
    work = Path(tempfile.mkdtemp(prefix="vulcanus-recipe-compat-"))
    mod = work / "mods/nullius-star"
    (mod / "scenarios").mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": version,
        "title": "Vulcanus recipe fixture", "author": "tests", "dependencies": ["base", "space-age"],
        "space_travel_required": True,
    }))
    names = ["base", "space-age", "quality", "elevated-rails", "nullius-star"]
    if version == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [{"name": name, "enabled": True} for name in names]}))
    source = (ROOT / "nullius-star/prototypes/planet/vulcanus-entities.lua").read_text()
    blocks = re.findall(r'^  \{\n    type = "recipe",.*?^  \}', source, re.M | re.S)
    if len(blocks) != 5:
        raise TestFailure("Expected five Vulcanus entity recipe records")
    header = source.split("-- Vulcanus-specific entities:", 1)[0]
    (mod / "vulcanus-entity-source.lua").write_text(header + "extend_vulcanus_entities({\n" + ",\n".join(blocks) + "\n})\n")
    for target, source_path in (
        ("factorio-version.lua", "nullius-star/factorio-version.lua"),
        ("prototypes/entity/hide-fluid-connections.lua", "nullius-star/prototypes/entity/hide-fluid-connections.lua"),
        ("fixture.lua", "tests/compatibility/vulcanus-entity-recipes.lua"),
        ("void-products.lua", "tests/factorio-test-support/void-products.lua"),
        ("executor.lua", "tests/factorio-test-support/vulcanus-entity-recipes.lua"),
        ("scenarios/vulcanus-entity-recipes", "tests/scenarios/vulcanus-entity-recipes"),
        ("scenarios/fluid-api.lua", "tests/scenarios/fluid-api.lua"),
    ):
        (mod / target).parent.mkdir(parents=True, exist_ok=True)
        (mod / target).symlink_to(ROOT / source_path, target_is_directory=(ROOT / source_path).is_dir())
    (mod / "data.lua").write_text('data:extend({{type="recipe-category",name="nullius-liquid-void"},{type="recipe-category",name="nullius-gas-void"},{type="recipe-category",name="nullius-power-sink"}})\nrequire("fixture")\nrequire("void-products")\nrequire("executor")\n')
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(work / "mods"), "--disable-audio"]
    for label, options in (
        ("dump", ["--dump-data"]),
        ("compile", ["--scenario2map", "nullius-star/vulcanus-entity-recipes"]),
        ("run", ["--load-game", str(work / "saves/nullius-star/vulcanus-entity-recipes.zip"), "--until-tick", "965"]),
    ):
        result = run_factorio(common + options, work / f"{label}.log", 180)
        if result.returncode:
            raise TestFailure(f"{label} failed; artifacts: {work}\n{result.stdout[-5000:]}")
    result = json.loads((work / "script-output/factorio-tests/vulcanus-entity-recipes.json").read_text())
    assert result["status"] == "pass" and result["recipes"] == 5, result
    return {"artifacts": str(work), **result}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(run(args.factorio.expanduser().resolve()), indent=2))
