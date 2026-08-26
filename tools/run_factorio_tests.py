#!/usr/bin/env python3
"""Run Nullius Star scenarios in an isolated Factorio write directory."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


REPOSITORY = Path(__file__).resolve().parents[1]
MOD_UNDER_TEST = REPOSITORY / "nullius-star"
BUILTIN_MODS = ("base", "elevated-rails", "quality", "space-age")
DEPENDENCY_MODS = (
    "alien-biomes",
    "alien-biomes-graphics",
    "angelspetrochemgraphics",
    "angelsrefininggraphics",
    "angelssmeltinggraphics",
    "boblibrary",
    "boblogistics",
    "configurable-valves",
)


class TestFailure(RuntimeError):
    pass


def default_factorio() -> Path:
    configured = os.environ.get("FACTORIO_BIN")
    if configured:
        return Path(configured)
    return Path.home() / "factorio" / "bin" / "x64" / "factorio"


def default_dependency_mods() -> Path:
    configured = os.environ.get("FACTORIO_MOD_DIRECTORY")
    if configured:
        return Path(configured)
    return Path.home() / "factorio" / "mods"


def find_archive(mod_directory: Path, mod_name: str) -> Path:
    matches = sorted(mod_directory.glob(f"{mod_name}_*.zip"))
    if len(matches) != 1:
        rendered = ", ".join(str(path) for path in matches) or "none"
        raise TestFailure(
            f"expected exactly one archive for {mod_name!r} in "
            f"{mod_directory}, found: {rendered}"
        )
    return matches[0].resolve()


def prepare_mods(run_mods: Path, dependency_mods: Path) -> None:
    run_mods.mkdir(parents=True)
    enabled = [*BUILTIN_MODS]
    for mod_name in DEPENDENCY_MODS:
        archive = find_archive(dependency_mods, mod_name)
        (run_mods / archive.name).symlink_to(archive)
        enabled.append(mod_name)

    (run_mods / "nullius-star").symlink_to(MOD_UNDER_TEST, target_is_directory=True)
    enabled.append("nullius-star")
    mod_list = {"mods": [{"name": name, "enabled": True} for name in enabled]}
    (run_mods / "mod-list.json").write_text(
        json.dumps(mod_list, indent=2) + "\n", encoding="utf-8"
    )


def prepare_config(run_directory: Path, factorio: Path) -> Path:
    data_directory = factorio.resolve().parents[2] / "data"
    if not (data_directory / "core" / "info.json").is_file():
        raise TestFailure(f"Factorio data directory not found: {data_directory}")

    config = run_directory / "config.ini"
    config.write_text(
        "; version=13\n"
        "[path]\n"
        f"read-data={data_directory}\n"
        f"write-data={run_directory}\n\n"
        "[general]\n"
        "locale=en\n",
        encoding="utf-8",
    )
    return config


def run_factorio(
    command: list[str], log_path: Path, timeout_seconds: int
) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        cwd=REPOSITORY,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout_seconds,
        check=False,
    )
    log_path.write_text(completed.stdout, encoding="utf-8")
    return completed


def tail(path: Path, lines: int = 40) -> str:
    return "\n".join(path.read_text(encoding="utf-8").splitlines()[-lines:])


def execute(args: argparse.Namespace, run_directory: Path) -> dict[str, object]:
    factorio = args.factorio.expanduser().resolve()
    dependency_mods = args.dependency_mod_directory.expanduser().resolve()
    scenario = MOD_UNDER_TEST / "scenarios" / args.case
    if not factorio.is_file():
        raise TestFailure(f"Factorio executable not found: {factorio}")
    if not scenario.is_dir():
        raise TestFailure(f"scenario not found: {scenario}")
    if not dependency_mods.is_dir():
        raise TestFailure(f"dependency mod directory not found: {dependency_mods}")

    run_directory.mkdir(parents=True, exist_ok=True)
    for directory in ("saves", "script-output", "temp"):
        (run_directory / directory).mkdir()
    config = prepare_config(run_directory, factorio)
    run_mods = run_directory / "mods"
    prepare_mods(run_mods, dependency_mods)

    common = [
        str(factorio),
        "--config",
        str(config),
        "--mod-directory",
        str(run_mods),
        "--disable-audio",
    ]
    compile_log = run_directory / "compile.log"
    compiled = run_factorio(
        [*common, "--scenario2map", f"nullius-star/{args.case}"],
        compile_log,
        args.timeout_seconds,
    )
    if compiled.returncode != 0:
        raise TestFailure(
            f"scenario compilation exited {compiled.returncode}\n{tail(compile_log)}"
        )

    save = run_directory / "saves" / "nullius-star" / f"{args.case}.zip"
    if not save.is_file():
        raise TestFailure(f"scenario compilation did not create {save}")

    run_log = run_directory / "run.log"
    executed = run_factorio(
        [*common, "--load-game", str(save), "--until-tick", str(args.until_tick)],
        run_log,
        args.timeout_seconds,
    )

    result_path = run_directory / "script-output" / "factorio-tests" / f"{args.case}.json"
    if not result_path.is_file():
        raise TestFailure(
            f"scenario did not write required result {result_path}\n{tail(run_log)}"
        )
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise TestFailure(f"invalid result JSON at {result_path}: {error}") from error

    if executed.returncode != 0:
        raise TestFailure(
            f"scenario exited {executed.returncode}; result={result!r}\n{tail(run_log)}"
        )
    if result.get("case") != args.case:
        raise TestFailure(f"result names unexpected case: {result!r}")
    if result.get("status") != "pass":
        raise TestFailure(f"scenario reported failure: {result!r}")
    if result.get("failure_count") != 0:
        raise TestFailure(f"passing result contains failures: {result!r}")
    return result


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("case", nargs="?", default="vulcanus-gas-vent-smoke")
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument(
        "--dependency-mod-directory", type=Path, default=default_dependency_mods()
    )
    parser.add_argument("--until-tick", type=int, default=60)
    parser.add_argument("--timeout-seconds", type=int, default=300)
    parser.add_argument("--keep-run-directory", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    run_directory = Path(tempfile.mkdtemp(prefix=f"factorio-test-{args.case}-"))
    success = False
    try:
        result = execute(args, run_directory)
        success = True
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (TestFailure, subprocess.TimeoutExpired, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        print(f"run directory preserved at {run_directory}", file=sys.stderr)
        return 1
    finally:
        if success and not args.keep_run_directory:
            shutil.rmtree(run_directory)
        elif success:
            print(f"run directory preserved at {run_directory}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
