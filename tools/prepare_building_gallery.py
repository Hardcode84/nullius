#!/usr/bin/env python3
"""Build and validate a labeled building gallery, then write its graphical launcher."""
import argparse
import json
from pathlib import Path
import shlex
from types import SimpleNamespace

from run_factorio_tests import MOD_UNDER_TEST, default_dependency_mods, default_factorio, execute


def prepare(destination, factorio, dependencies):
    if destination.exists():
        raise FileExistsError(f"Use a new gallery directory: {destination}")
    args = SimpleNamespace(factorio=factorio, dependency_mod_directory=dependencies,
                           mod_under_test=MOD_UNDER_TEST, until_tick=None, timeout_seconds=300)
    result = execute(args, "building-gallery", destination)
    (destination / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    save = destination / "saves/nullius-star/building-gallery.zip"
    launch = destination / "launch.sh"
    launch.write_text("#!/bin/sh\nexec " + shlex.join([
        str(factorio), "--config", str(destination / "config.ini"),
        "--mod-directory", str(destination / "mods"), "--load-game", str(save),
    ]) + ' "$@"\n')
    launch.chmod(0o755)
    print(json.dumps({**result, "save": str(save), "launch": str(launch)}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    prepare(args.destination.expanduser().resolve(), args.factorio.expanduser().resolve(),
            args.dependency_mod_directory.expanduser().resolve())
