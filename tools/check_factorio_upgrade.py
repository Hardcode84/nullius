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
import time
import zipfile

if __package__:
    from .build_release import prepare_release_mods, run_checked
    from .run_factorio_tests import REPOSITORY, default_factorio, default_dependency_mods, prepare_config
else:
    from build_release import prepare_release_mods, run_checked
    from run_factorio_tests import REPOSITORY, default_factorio, default_dependency_mods, prepare_config


def check_upgrade(candidate: Path, factorio: Path, dependencies: Path, timeout: int,
                  previous_version: str = "0.0.1", previous_factorio: Path | None = None,
                  previous_dependencies: Path | None = None) -> dict:
    previous_factorio = (previous_factorio or factorio).expanduser().resolve()
    previous_dependencies = (previous_dependencies or dependencies).expanduser().resolve()
    fixture = REPOSITORY / "tests/upgrades" / previous_version
    if not fixture.is_dir():
        raise ValueError(f"No upgrade fixture for {previous_version}")
    with zipfile.ZipFile(candidate) as archive:
        candidate_version = json.loads(archive.read("nullius-star/info.json"))["version"]
    with tempfile.TemporaryDirectory(prefix="nullius-upgrade-") as temporary:
        root = Path(temporary)
        origin = root / "origin"
        target = root / "target"
        for run in (origin, target):
            for name in ("saves", "script-output", "temp"):
                (run / name).mkdir(parents=True)
        origin_config = prepare_config(origin, previous_factorio)
        config = prepare_config(target, factorio)
        mods = origin / "mods"
        prepare_release_mods(mods, previous_dependencies, candidate)
        (mods / candidate.name).unlink()
        target_mods = target / "mods"
        prepare_release_mods(target_mods, dependencies, candidate)
        (target_mods / candidate.name).unlink()
        previous = subprocess.run(
            ["git", "archive", "--format=zip", f"v{previous_version}", "nullius-star"],
            cwd=REPOSITORY, check=True, stdout=subprocess.PIPE,
        ).stdout
        with zipfile.ZipFile(io.BytesIO(previous)) as archive:
            archive.extractall(mods)

        def install_fixture(mods: Path) -> None:
            mod = mods / "nullius-star"
            with (mod / "control.lua").open("a") as control:
                control.write("\nlocal candidate_version = " + json.dumps(candidate_version) + "\n"
                              + (fixture / "bridge.lua").read_text())
            scenario = mod / "scenarios/release-upgrade"
            scenario.mkdir(parents=True)
            shutil.copyfile(fixture / "control.lua", scenario / "control.lua")

        install_fixture(mods)
        origin_common = [str(previous_factorio), "--config", str(origin_config),
                         "--mod-directory", str(mods), "--disable-audio"]
        common = [str(factorio), "--config", str(config), "--mod-directory", str(target_mods), "--disable-audio"]
        run_checked([*origin_common, "--scenario2map", "nullius-star/release-upgrade"],
                    f"{previous_version} upgrade fixture", timeout)
        save = origin / "saves/nullius-star/release-upgrade.zip"
        with zipfile.ZipFile(candidate) as archive:
            archive.extractall(target_mods)
        install_fixture(target_mods)
        settings = root / "server-settings.json"
        server_settings = json.loads((factorio.parents[2] /
            "data/server-settings.example.json").read_text())
        server_settings.update({"name": "Release upgrade check",
            "visibility": {"public": False, "lan": False},
            "require_user_verification": False, "auto_pause": False})
        settings.write_text(json.dumps(server_settings))
        upgraded = target / "saves/_autosave-release-upgraded.zip"
        log_path = root / "upgrade-server.log"
        with log_path.open("w") as log:
            server = subprocess.Popen([*common, "--start-server", str(save),
                "--bind", "127.0.0.1:0", "--server-settings", str(settings)],
                stdout=log, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + timeout
                while not upgraded.is_file():
                    if server.poll() is not None or time.monotonic() >= deadline:
                        raise ValueError("upgrade server did not save:\n" + log_path.read_text())
                    time.sleep(0.1)
            finally:
                if server.poll() is None:
                    server.terminate()
                server.wait(timeout=30)
        run_checked([*common, "--load-game", str(upgraded), "--until-tick", "3"],
                    "upgraded save reload", timeout)
        result = json.loads((target / "script-output/upgrade-result.json").read_text())
        if result.get("status") != "pass":
            raise ValueError(f"upgrade failed: {result}")
        return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--dependencies", type=Path, default=default_dependency_mods())
    parser.add_argument("--from-version", default="0.0.1")
    parser.add_argument("--previous-factorio", type=Path)
    parser.add_argument("--previous-dependencies", type=Path)
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()
    print(json.dumps(check_upgrade(args.candidate.resolve(), args.factorio.resolve(),
                                   args.dependencies.resolve(), args.timeout, args.from_version,
                                   args.previous_factorio, args.previous_dependencies), indent=2))
