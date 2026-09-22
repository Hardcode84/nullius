#!/usr/bin/env python3
"""Check native distillery layers, tier colours, and all rendered directions."""
import argparse
import copy
from pathlib import Path

from test_assembler_graphics_compatibility import capture, render
from run_factorio_tests import default_dependency_mods


def check_graphics(old, data):
    machines = data["assembling-machine"]
    names = []
    for tier in range(1, 4):
        name = f"nullius-distillery-{tier}"
        expected = copy.deepcopy(machines["oil-refinery"]["graphics_set"])
        tint = old["assembling-machine"][name]["graphics_set"]["animation"]["north"]["layers"][0].get("tint")
        for direction in ("north", "east", "south", "west"):
            for layer in expected["animation"][direction]["layers"]:
                if not layer.get("draw_as_shadow") and tint is not None:
                    layer["tint"] = tint
        assert machines[name]["graphics_set"] == expected, name
        names.append(name)
        for suffix in ("-pneumatic", "-thermal"):
            if name + suffix in machines:
                assert machines[name + suffix]["graphics_set"] == expected, name + suffix
                names.append(name + suffix)
    print(f"PASS native graphics, colours and variants: {len(names)} definitions", flush=True)
    return names


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--staged-dependency-mod-directory", type=Path, required=True)
    args = parser.parse_args()
    old, _ = capture(args.factorio_2_0, args.dependency_mod_directory, True,
                     "chemistry.lua", "f1eeedc")
    current, major = capture(args.factorio_2_0, args.dependency_mod_directory)
    assert old == current, "2.0 prototypes changed"
    modern, modern_major = capture(args.factorio_2_1, args.staged_dependency_mod_directory)
    names = check_graphics(old, modern)
    render(args.factorio_2_0, current, major, names, "distillery-graphics")
    render(args.factorio_2_1, modern, modern_major, names, "distillery-graphics")
