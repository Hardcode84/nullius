#!/usr/bin/env python3
"""Check that removal of unused geothermal base layers preserves both engines."""
import argparse
from pathlib import Path

from run_factorio_tests import default_dependency_mods
from test_assembler_graphics_compatibility import capture


def check(engine, dependencies, baseline_ref):
    old, _ = capture(engine, dependencies, True, "energy.lua", baseline_ref)
    current, version = capture(engine, dependencies)
    for tier in (1, 2, 3):
        name = f"nullius-geothermal-build-{tier}"
        before = old["mining-drill"][name]
        after = current["mining-drill"][name]
        assert "base_picture" not in before and "base_picture" not in after, name
        assert before["graphics_set"]["animation"]["frame_count"] == 1, name
        assert before["base_render_layer"] == "lower-object-above-shadow", name
        expected = {key: value for key, value in before.items() if key != "base_render_layer"}
        assert after == expected, (name, "changed fields beyond the unused base layer")
    print(f"PASS {version}: all three drill prototypes differ only in the unused base layer", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--baseline-ref", default="867a6fb")
    args = parser.parse_args()
    check(args.factorio.expanduser().resolve(), args.dependency_mod_directory, args.baseline_ref)
