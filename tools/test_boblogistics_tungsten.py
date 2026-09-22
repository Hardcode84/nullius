#!/usr/bin/env python3
"""Check patched Bob's updates with native Space Age and declared Bob provider fixtures."""
import argparse
import json
from pathlib import Path
import tempfile

from patch_boblogistics_tungsten import patch_archive
from run_factorio_tests import find_archive
from test_vulcanus_processing_compatibility import command


def check(engine, dependencies):
    work = Path(tempfile.mkdtemp(prefix="boblogistics-tungsten-test-"))
    patched = work / "boblogistics_3.0.1.zip"
    print(json.dumps(patch_archive(find_archive(dependencies, "boblogistics"), patched)), flush=True)
    for case, space_age, bob_provider in (
        ("space-age", True, False), ("bob-provider", False, True),
        ("both-providers", True, True), ("no-tungsten", False, False),
    ):
        run = work / case
        fixture = run / "mods/tungsten-test"
        fixture.mkdir(parents=True)
        (run / "mods" / patched.name).symlink_to(patched)
        library = find_archive(dependencies, "boblibrary")
        (run / "mods" / library.name).symlink_to(library)
        (fixture / "info.json").write_text(json.dumps(dict(
            name="tungsten-test", version="0.0.1", factorio_version="2.1",
            title="Tungsten prerequisite test", author="tests", dependencies=["boblogistics", "? space-age"])))
        names = ["base", "boblibrary", "boblogistics", "tungsten-test"]
        optional = ["space-age", "quality", "elevated-rails", "recycler"]
        (run / "mods/mod-list.json").write_text(json.dumps({"mods": [
            dict(name=name, enabled=name in names or space_age) for name in names + optional]}))
        setup = ""
        if bob_provider:
            setup = '''
if not data.raw.item["tungsten-carbide"] then
  local item = table.deepcopy(data.raw.item["steel-plate"])
  item.name = "tungsten-carbide"
  data:extend({item})
end
local technology = table.deepcopy(data.raw.technology.automation)
technology.name = "bob-tungsten-processing"
technology.prerequisites = nil
technology.effects = nil
data:extend({technology})
'''
        (fixture / "data.lua").write_text(setup)
        expected = '"bob-tungsten-processing"' if bob_provider else ('"tungsten-carbide"' if space_age else 'nil')
        (fixture / "data-final-fixes.lua").write_text('local expected = ' + expected + '''
for _, name in ipairs({"bob-robots-3", "bob-repair-pack-5"}) do
  local found = false
  for _, prerequisite in pairs(data.raw.technology[name].prerequisites or {}) do
    assert(data.raw.technology[prerequisite], name .. ": missing " .. prerequisite)
    if prerequisite == expected then found = true end
  end
  assert(found == (expected ~= nil), name .. ": tungsten prerequisite")
end
for _, name in ipairs({"bob-robot-tool-logistic-4", "bob-repair-pack-5"}) do
  local found = false
  for _, ingredient in pairs(data.raw.recipe[name].ingredients) do
    if ingredient.name == "tungsten-carbide" then found = true end
  end
  assert(found == (expected ~= nil), name .. ": tungsten ingredient")
end
''')
        command(run, engine, ["--dump-data"], "dump")
        log = (run / "dump.log").read_text()
        assert "Prerequisite technology" not in log, log[-4000:]
        print(f"PASS {case}: both prerequisites and recipe ingredients; {run}", flush=True)
    return patched


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, required=True)
    args = parser.parse_args()
    print(check(args.factorio.resolve(), args.dependency_mod_directory.resolve()))
