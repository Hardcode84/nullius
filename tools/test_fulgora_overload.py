#!/usr/bin/env python3
"""Run the Fulgora overload scenario and reload a checkpoint with a tripped grid."""
import argparse
import json
from pathlib import Path
import shutil
import tempfile

from run_factorio_tests import (
    MOD_UNDER_TEST, default_factorio, default_dependency_mods, deadline_for,
    execute, run_factorio, TestFailure, tail,
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    parser.add_argument("--case", choices=("fulgora-grid-overload", "fulgora-grounding-coils", "experiment-fulgora-overload"),
                        default="fulgora-grid-overload")
    args = parser.parse_args()
    args.mod_under_test = MOD_UNDER_TEST
    args.timeout_seconds = 300
    args.until_tick = None
    case = args.case
    work = Path(tempfile.mkdtemp(prefix="fulgora-overload-"))
    first = execute(args, case, work)
    common = [str(args.factorio.expanduser().resolve()), "--config", str(work / "config.ini"),
              "--mod-directory", str(work / "mods"), "--disable-audio"]
    save = work / f"saves/nullius-star/{case}.zip"

    def run(label, options):
        log = work / f"{label}.log"
        result = run_factorio([*common, *options], log, args.timeout_seconds)
        if result.returncode:
            raise TestFailure(f"Overload {label} failed: {work}\n{tail(log)}")

    # --until-tick writes the reached state back to the loaded map.
    run("compile-checkpoint", ["--scenario2map", f"nullius-star/{case}"])
    run("checkpoint", ["--load-game", str(save), "--until-tick", "102"])
    checkpoint = work / "saves/overload-checkpoint.zip"
    shutil.copyfile(save, checkpoint)
    result_path = work / f"script-output/factorio-tests/{case}.json"
    result_path.unlink()
    run("reload", ["--load-game", str(save), "--until-tick", str(deadline_for(args, case))])
    if not result_path.is_file():
        raise TestFailure(f"Overload reload produced no result: {work}")
    resumed = json.loads(result_path.read_text())
    reload_tick = resumed["observations"].pop("reload_tick", None)
    if reload_tick != 102:
        raise TestFailure(f"Expected restart at tick 102, got {reload_tick!r}")
    if resumed != first:
        raise TestFailure(f"Overload reload changed the result: {first!r} != {resumed!r}")
    print(json.dumps({"status": "pass", "initial": first, "reload": "identical result", "reload_tick": reload_tick,
                      "artifacts": str(work), "playable_save": str(checkpoint)}, indent=2))


if __name__ == "__main__":
    main()
