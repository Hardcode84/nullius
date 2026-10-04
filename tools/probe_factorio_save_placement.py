#!/usr/bin/env python3
"""Inspect or exercise building placement in an isolated copy of a save."""

import argparse
import json
from pathlib import Path
import shutil
import tempfile
from run_factorio_tests import (
    prepare_mods,
    prepare_config,
    default_factorio,
    default_dependency_mods,
    run_factorio,
    tail,
    TestFailure,
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--save", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--exercise", action="store_true")
    parser.add_argument("--expect-rebuilt", action="store_true")
    parser.add_argument("--ticks", type=int, default=1200)
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix="placement-save-"))
    prepare_mods(work / "mods", default_dependency_mods())
    config = prepare_config(work, default_factorio())
    (work / "mods/factorio-test-support/control.lua").write_text(
        'require("__nullius-star__/scenarios/save-placement-probe")('
        + ("true" if args.exercise else "false")
        + ", "
        + str(args.ticks)
        + ")\n"
    )
    save = work / "input.zip"
    shutil.copyfile(args.save, save)
    log = work / "probe.log"
    result = run_factorio(
        [
            str(default_factorio()),
            "--config",
            str(config),
            "--mod-directory",
            str(work / "mods"),
            "--benchmark",
            str(save),
            "--benchmark-ticks",
            str(args.ticks),
            "--benchmark-runs",
            "1",
            "--disable-audio",
        ],
        log,
        180,
    )
    if result.returncode:
        raise TestFailure(f"Placement probe failed: {work}\n{tail(log)}")
    report = json.loads((work / "script-output/placement-probe.json").read_text())
    report["artifacts"] = str(work)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(
        json.dumps(
            {
                "artifacts": str(work),
                "buildings": [
                    {
                        k: v
                        for k, v in row.items()
                        if k not in ("nearby", "final_nearby")
                    }
                    for row in report["buildings"]
                ],
            },
            indent=2,
        )
    )
    if args.expect_rebuilt and (
        not args.exercise
        or not report["buildings"]
        or any(not row["removed"] or not row["rebuilt"] for row in report["buildings"])
    ):
        raise TestFailure(
            "Robots did not remove and rebuild every selected hydro plant"
        )


if __name__ == "__main__":
    main()
