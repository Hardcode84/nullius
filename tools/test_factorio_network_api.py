#!/usr/bin/env python3
"""Run isolated Space Age electrical fixtures, without the Nullius dependency stack."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.run_factorio_tests import prepare_config, run_factorio

ROOT = Path(__file__).resolve().parents[1]
CASES = ("experiment-network-trip", "experiment-network-sink", "experiment-lightning-poles")


def run_case(factorio, case):
    work = Path(tempfile.mkdtemp(prefix=f"factorio-network-api-{case}-"))
    mod = work / "mods" / "nullius-star"
    mod.mkdir(parents=True)
    (mod / "info.json").write_text(json.dumps({
        "name": "nullius-star", "version": "0.0.3", "factorio_version": "2.1",
        "title": "Isolated electrical API experiment", "author": "Nullius Star tests",
        "dependencies": ["base >= 2.1.19", "space-age >= 2.1.19"],
    }) + "\n")
    (mod / "data.lua").write_text('require("lightning-poles")\nrequire("network-trip")\n')
    for name in ("lightning-poles.lua", "network-trip.lua"):
        (mod / name).symlink_to(ROOT / "tests" / "factorio-test-support" / name)
    (mod / "scenarios").symlink_to(ROOT / "tests" / "scenarios", target_is_directory=True)
    (work / "mods" / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": name, "enabled": True}
        for name in ("base", "elevated-rails", "quality", "space-age", "nullius-star")
    ]}) + "\n")
    config = prepare_config(work, factorio)
    common = [str(factorio), "--config", str(config), "--mod-directory", str(work / "mods"),
              "--disable-audio"]
    contract = json.loads((ROOT / "tests" / "scenarios" / case / "test.json").read_text())
    commands = [
        ("compile", ["--scenario2map", f"nullius-star/{case}"]),
        ("run", ["--load-game", str(work / "saves" / "nullius-star" / f"{case}.zip"),
                 "--until-tick", str(contract["until_tick"])]),
    ]
    for phase, options in commands:
        completed = run_factorio(common + options, work / f"{phase}.log", 120)
        if completed.returncode:
            raise RuntimeError(f"{case}: {phase} failed; artifacts: {work}\n{completed.stdout[-6000:]}")
    result = json.loads((work / "script-output" / "factorio-tests" / f"{case}.json").read_text())
    if result["status"] != "pass":
        raise RuntimeError(f"{case}: assertions failed: {result}; artifacts: {work}")
    if not result["factorio_version"].startswith("2.1."):
        raise RuntimeError(f"Expected Factorio 2.1, got {result['factorio_version']}")
    if case == "experiment-network-trip" and "network_api" not in result["observations"]:
        raise RuntimeError("2.1 network API assertions did not run")
    return {"artifacts": str(work), "result": result}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    args = parser.parse_args()
    factorio = args.factorio.expanduser().resolve()
    with ThreadPoolExecutor(max_workers=len(CASES)) as pool:
        futures = [pool.submit(run_case, factorio, case) for case in CASES]
        failed = False
        for future in futures:
            try:
                print(json.dumps(future.result()), flush=True)
            except Exception as error:
                failed = True
                print(str(error), file=sys.stderr, flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
