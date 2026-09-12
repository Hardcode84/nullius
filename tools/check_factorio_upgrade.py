#!/usr/bin/env python3
"""Load a save made by the tagged prior release with the candidate payload."""
from __future__ import annotations

import argparse
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

from tools.build_release import prepare_release_mods, run_checked
from tools.run_factorio_tests import REPOSITORY, default_factorio, default_dependency_mods, prepare_config


def check_upgrade(candidate: Path, factorio: Path, dependencies: Path, timeout: int) -> dict:
    fixture = REPOSITORY / "tests/upgrades/0.0.1"
    with tempfile.TemporaryDirectory(prefix="nullius-upgrade-") as temporary:
        root = Path(temporary)
        for name in ("saves", "script-output", "temp"):
            (root / name).mkdir()
        config = prepare_config(root, factorio)
        mods = root / "mods"
        prepare_release_mods(mods, dependencies, candidate)
        (mods / candidate.name).unlink()
        previous = subprocess.run(
            ["git", "archive", "--format=zip", "v0.0.1", "nullius-star"],
            cwd=REPOSITORY, check=True, stdout=subprocess.PIPE,
        ).stdout
        with zipfile.ZipFile(io.BytesIO(previous)) as archive:
            archive.extractall(mods)

        def install_fixture() -> None:
            mod = mods / "nullius-star"
            with (mod / "control.lua").open("a") as control:
                control.write("\n" + (fixture / "bridge.lua").read_text())
            scenario = mod / "scenarios/release-upgrade"
            scenario.mkdir(parents=True)
            shutil.copyfile(fixture / "control.lua", scenario / "control.lua")

        install_fixture()
        common = [str(factorio), "--config", str(config), "--mod-directory", str(mods), "--disable-audio"]
        run_checked([*common, "--scenario2map", "nullius-star/release-upgrade"],
                    "0.0.1 upgrade fixture", timeout)
        save = root / "saves/nullius-star/release-upgrade.zip"
        shutil.rmtree(mods / "nullius-star")
        with zipfile.ZipFile(candidate) as archive:
            archive.extractall(mods)
        install_fixture()
        run_checked([*common, "--load-game", str(save), "--until-tick", "2"],
                    "0.0.1 to candidate upgrade", timeout)
        result = json.loads((root / "script-output/upgrade-result.json").read_text())
        if result.get("status") != "pass":
            raise ValueError(f"upgrade failed: {result}")
        return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--dependencies", type=Path, default=default_dependency_mods())
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()
    print(json.dumps(check_upgrade(args.candidate.resolve(), args.factorio.resolve(),
                                   args.dependencies.resolve(), args.timeout), indent=2))
