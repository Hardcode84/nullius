#!/usr/bin/env python3
"""Check that only the two legacy valve keypad defaults change on 2.1."""
import argparse
import copy
from pathlib import Path

from run_factorio_tests import default_dependency_mods
from test_assembler_graphics_compatibility import capture


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--staged-dependency-mod-directory", type=Path, required=True)
    args = parser.parse_args()
    for engine, dependencies in ((args.factorio_2_0, args.dependency_mod_directory),
                                 (args.factorio_2_1, args.staged_dependency_mod_directory)):
        old, major = capture(engine, dependencies, True, "inputs.lua", "77aa2f1", "")
        current, _ = capture(engine, dependencies)
        expected = copy.deepcopy(old)
        changes = 0
        for name, before, after in (("minus", "PAD -", "KP_MINUS"), ("plus", "PAD +", "KP_PLUS")):
            key = "configurable-valves-" + name
            assert old["custom-input"][key]["key_sequence"] == before, (major, key, "baseline")
            if major == "2.1":
                expected["custom-input"][key]["key_sequence"] = after
                changes += 1
        assert current == expected, f"{major}: unexpected prototype changes"
        print(f"PASS {major}: full prototype comparison, {changes} keypad defaults changed", flush=True)
