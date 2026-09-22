#!/usr/bin/env python3
"""Check production robotics research effects with either native engine.

Use the source effect tables with base technology metadata and recipe stubs.
This isolates force modifiers from the incomplete full-mod 2.1 port.
"""
import argparse
import json
from pathlib import Path
import tempfile

from run_factorio_tests import TestFailure
from test_vulcanus_processing_compatibility import ROOT, command

TECHNOLOGIES = {
    "nullius-robotics-1": "prototypes/technology.lua",
    "nullius-construction-robot-1": "prototypes/technology.lua",
    "nullius-logistic-robot-1": "prototypes/technology.lua",
    "nullius-primitive-robotics": "prototypes/planet/vulcanus-technology.lua",
}


def run(engine):
    engine = engine.resolve()
    metadata = json.loads((engine.parents[2] / "data/base/info.json").read_text())
    version = ".".join(metadata["version"].split(".")[:2])
    if version not in {"2.0", "2.1"}:
        raise TestFailure(f"Unsupported engine: {metadata['version']}")
    work = Path(tempfile.mkdtemp(prefix=f"logistic-unlock-{version}-"))
    mod = work / "mods/unlock-test"
    scenario = mod / "scenarios/research"
    scenario.mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps(dict(
        name="unlock-test", version="0.0.1", factorio_version=version,
        title="Robotics research test", author="tests", dependencies=["base"])))
    names = ["base", "space-age", "quality", "elevated-rails", "unlock-test"]
    if version == "2.1":
        names.append("recycler")
    (work / "mods/mod-list.json").write_text(json.dumps({"mods": [
        dict(name=name, enabled=name in {"base", "unlock-test"}) for name in names]}))
    (mod / "factorio-version.lua").symlink_to(ROOT / "nullius-star/factorio-version.lua")
    definitions = []
    for name, path in TECHNOLOGIES.items():
        source = (ROOT / "nullius-star" / path).read_text()
        marker = f'name = "{name}"'
        assert source.count(marker) == 1, (path, name)
        start = source.index("effects = ", source.index(marker)) + len("effects = ")
        end = source.index("\n    unit = ", start)
        effects = source[start:end].strip().removesuffix(",")
        definitions.append(f'''
do
  local technology = table.deepcopy(data.raw.technology.automation)
  technology.name = {json.dumps(name)}
  technology.prerequisites = nil
  technology.effects = {effects}
  for _, effect in ipairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = table.deepcopy(data.raw.recipe["iron-stick"])
      recipe.name = effect.recipe
      recipe.enabled = false
      data:extend({{recipe}})
    end
  end
  data:extend({{technology}})
end
''')
    (mod / "data.lua").write_text("\n".join(definitions))
    (scenario / "control.lua").symlink_to(ROOT / "tests/compatibility/logistic-unlock.lua")
    command(work, engine, ["--scenario2map", "unlock-test/research"], "research")
    result = json.loads((work / "script-output/logistic-unlock.json").read_text())
    assert result["technologies"] == len(TECHNOLOGIES), result
    assert result["modern"] == (version == "2.1"), result
    print(f"PASS {metadata['version']}: {result['assertions']} assertions; {work}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    run(parser.parse_args().factorio)
