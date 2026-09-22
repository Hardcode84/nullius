#!/usr/bin/env python3
"""Check chemical-plant layers, offsets, colours, effects and client rendering."""
import argparse
from pathlib import Path

from test_assembler_graphics_compatibility import capture, render
from run_factorio_tests import default_dependency_mods


def check_graphics(old, data):
    machines = data["assembling-machine"]
    native = machines["chemical-plant"]["graphics_set"]
    names = []
    for tier in range(1, 4):
        name = f"nullius-chemical-plant-{tier}"
        previous = old["assembling-machine"][name]["graphics_set"]
        graphics = machines[name]["graphics_set"]
        assert graphics["working_visualisations"] == previous["working_visualisations"], name
        for direction in ("north", "east", "south", "west"):
            legacy = previous["animation"][direction]["layers"]
            layers = graphics["animation"][direction]["layers"]
            originals = native["animation"][direction]["layers"]
            assert len(layers) == 4, (name, direction)
            pairs = list(zip(layers, originals, strict=True))
            pairs.append((graphics["frozen_patch"][direction], native["frozen_patch"][direction]))
            for actual, original in pairs:
                for field in ("filename", "width", "height", "frame_count", "line_length", "repeat_count", "x", "y"):
                    assert actual.get(field) == original.get(field), (name, direction, field)
                shadow = bool(original.get("draw_as_shadow"))
                old_layer = legacy[int(shadow)]
                ratio = old_layer["scale"] / 0.5
                origin = (27, 6) if shadow else (0.5, -9)
                assert abs(actual["scale"] - original["scale"] * ratio) < 1e-9, name
                for axis in (0, 1):
                    expected = original["shift"][axis] * ratio + old_layer["shift"][axis] - origin[axis] * ratio / 32
                    assert abs(actual["shift"][axis] - expected) < 1e-9, (name, direction, "origin")
            for layer in layers:
                if not layer.get("draw_as_shadow"):
                    assert layer.get("tint") == legacy[0].get("tint"), name
                frames = layer.get("frame_count", 1) * layer.get("repeat_count", 1)
                assert frames / layer.get("animation_speed", 1) == 24, (name, "cycle")
        names.append(name)
        variant = name + "-pneumatic"
        assert machines[variant]["graphics_set"] == graphics, variant
        names.append(variant)
    print("PASS six definitions: native frames, colours, offsets, timing, frozen overlays and recipe effects", flush=True)
    return names


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-2-0", type=Path, required=True)
    parser.add_argument("--factorio-2-1", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--staged-dependency-mod-directory", type=Path, required=True)
    args = parser.parse_args()
    old, _ = capture(args.factorio_2_0, args.dependency_mod_directory, True, "chemistry.lua", "c39fe2c")
    current, major = capture(args.factorio_2_0, args.dependency_mod_directory)
    assert old == current, "2.0 prototypes changed"
    modern, modern_major = capture(args.factorio_2_1, args.staged_dependency_mod_directory)
    names = check_graphics(old, modern)
    # The distillery fixture places any supplied machine list in all directions.
    render(args.factorio_2_0, current, major, names, "distillery-graphics")
    render(args.factorio_2_1, modern, modern_major, names, "distillery-graphics")
