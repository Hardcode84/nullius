#!/usr/bin/env python3
"""Run Nullius Star scenarios in an isolated Factorio write directory."""

from __future__ import annotations

import argparse
from concurrent.futures import FIRST_COMPLETED, Future, ThreadPoolExecutor, wait
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


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


def discover_cases() -> list[str]:
    scenarios = MOD_UNDER_TEST / "scenarios"
    if not scenarios.is_dir():
        raise TestFailure(f"scenario directory not found: {scenarios}")
    return sorted(
        path.name
        for path in scenarios.iterdir()
        if path.is_dir() and (path / "control.lua").is_file()
    )


def deadline_for(args: argparse.Namespace, case: str) -> int:
    scenario = MOD_UNDER_TEST / "scenarios" / case
    if not scenario.is_dir() or not (scenario / "control.lua").is_file():
        raise TestFailure(f"scenario not found: {scenario}")
    metadata_path = scenario / "test.json"
    if not metadata_path.is_file():
        raise TestFailure(f"scenario metadata not found: {metadata_path}")
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise TestFailure(
            f"invalid scenario metadata {metadata_path}: {error}"
        ) from error
    if not isinstance(metadata, dict) or set(metadata) != {"schema", "until_tick"}:
        raise TestFailure(
            f"scenario metadata must contain only schema and until_tick: "
            f"{metadata_path}"
        )
    if metadata["schema"] != 1:
        raise TestFailure(
            f"unsupported scenario metadata schema in {metadata_path}: "
            f"{metadata['schema']!r}"
        )
    until_tick = metadata["until_tick"]
    if isinstance(until_tick, bool) or not isinstance(until_tick, int) or until_tick < 1:
        raise TestFailure(
            f"scenario until_tick must be a positive integer: {metadata_path}"
        )
    if args.until_tick is not None:
        return args.until_tick
    return until_tick


def execute(
    args: argparse.Namespace, case: str, run_directory: Path
) -> dict[str, object]:
    factorio = args.factorio.expanduser().resolve()
    dependency_mods = args.dependency_mod_directory.expanduser().resolve()
    scenario = MOD_UNDER_TEST / "scenarios" / case
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
        [*common, "--scenario2map", f"nullius-star/{case}"],
        compile_log,
        args.timeout_seconds,
    )
    if compiled.returncode != 0:
        raise TestFailure(
            f"scenario compilation exited {compiled.returncode}\n{tail(compile_log)}"
        )

    save = run_directory / "saves" / "nullius-star" / f"{case}.zip"
    if not save.is_file():
        raise TestFailure(f"scenario compilation did not create {save}")

    run_log = run_directory / "run.log"
    until_tick = deadline_for(args, case)
    executed = run_factorio(
        [*common, "--load-game", str(save), "--until-tick", str(until_tick)],
        run_log,
        args.timeout_seconds,
    )

    result_path = run_directory / "script-output" / "factorio-tests" / f"{case}.json"
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
    if result.get("case") != case:
        raise TestFailure(f"result names unexpected case: {result!r}")
    if result.get("status") != "pass":
        raise TestFailure(f"scenario reported failure: {result!r}")
    if result.get("failure_count") != 0:
        raise TestFailure(f"passing result contains failures: {result!r}")
    return result


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Nullius Star Factorio scenario tests."
    )
    parser.add_argument(
        "cases",
        nargs="*",
        metavar="CASE",
        help="scenario test(s) to run; the default is every discovered test",
    )
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument(
        "--dependency-mod-directory", type=Path, default=default_dependency_mods()
    )
    parser.add_argument("--until-tick", type=int)
    parser.add_argument("--timeout-seconds", type=int, default=300)
    parser.add_argument("--keep-run-directory", action="store_true")
    parser.add_argument(
        "-n",
        "--workers",
        type=parse_worker_count,
        default=1,
        metavar="WORKERS",
        help="run tests in parallel; use a positive integer or 'auto'",
    )
    parser.add_argument(
        "--json",
        dest="json_output",
        action="store_true",
        help="emit one machine-readable suite result instead of progress output",
    )
    return parser.parse_args()


def format_failure(error: str) -> str:
    return error.replace("\n", "\n    ")


def format_duration(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.1f}s"
    minutes, remainder = divmod(seconds, 60)
    if minutes < 60:
        return f"{int(minutes)}m {remainder:.1f}s"
    hours, minutes = divmod(minutes, 60)
    return f"{int(hours)}h {int(minutes)}m {remainder:.1f}s"


def parse_worker_count(value: str) -> int:
    if value == "auto":
        if hasattr(os, "sched_getaffinity"):
            return len(os.sched_getaffinity(0))
        return os.cpu_count() or 1
    try:
        workers = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(
            "worker count must be a positive integer or 'auto'"
        ) from error
    if workers < 1:
        raise argparse.ArgumentTypeError(
            "worker count must be a positive integer or 'auto'"
        )
    return workers


def run_case(args: argparse.Namespace, case: str) -> dict[str, object]:
    started = time.perf_counter()
    safe_case = "".join(
        character if character.isalnum() or character in "-_" else "-"
        for character in case
    )
    run_directory = Path(
        tempfile.mkdtemp(prefix=f"factorio-test-{safe_case or 'case'}-")
    )
    success = False
    try:
        result = execute(args, case, run_directory)
        success = True
        result_record = dict(result)
        result_record["duration_seconds"] = time.perf_counter() - started
        if args.keep_run_directory:
            result_record["run_directory"] = str(run_directory)
        return result_record
    except (TestFailure, subprocess.TimeoutExpired, OSError) as error:
        return {
            "case": case,
            "status": "fail",
            "error": str(error),
            "duration_seconds": time.perf_counter() - started,
            "run_directory": str(run_directory),
        }
    finally:
        if success and not args.keep_run_directory:
            shutil.rmtree(run_directory)


def print_case_result(
    index: int, total: int, case: str, result: dict[str, object]
) -> None:
    prefix = f"[{index}/{total}]"
    duration = format_duration(float(result["duration_seconds"]))
    if result.get("status") == "pass":
        assertions = result.get("assertions", "?")
        tick = result.get("tick", "?")
        version = result.get("factorio_version")
        context = f"{assertions} assertions, completed tick {tick}"
        if version is not None:
            context += f", Factorio {version}"
        print(f"{prefix} PASS {case} - {context}, {duration}")
        if "run_directory" in result:
            print(f"      artifacts: {result['run_directory']}")
        return

    print(f"{prefix} FAIL {case} - {duration}")
    print(f"      {format_failure(str(result['error']))}")
    print(f"      artifacts: {result['run_directory']}")


def main() -> int:
    suite_started = time.perf_counter()
    args = parse_arguments()
    try:
        cases = args.cases or discover_cases()
        for case in cases:
            deadline_for(args, case)
    except (TestFailure, OSError) as error:
        if args.json_output:
            print(json.dumps({"status": "fail", "error": str(error)}))
        else:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if not cases:
        error = "no scenario tests discovered"
        if args.json_output:
            print(json.dumps({"status": "fail", "error": error}))
        else:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    total = len(cases)
    worker_count = min(args.workers, total)
    results: list[dict[str, object] | None] = [None] * total
    if not args.json_output:
        noun = "test" if total == 1 else "tests"
        workers = f" with {worker_count} workers" if worker_count > 1 else ""
        print(f"Running {total} Factorio scenario {noun}{workers}\n")

    pending_cases = iter(enumerate(cases))
    futures: dict[Future[dict[str, object]], tuple[int, str]] = {}
    with ThreadPoolExecutor(max_workers=worker_count) as executor:
        while len(futures) < worker_count:
            try:
                index, case = next(pending_cases)
            except StopIteration:
                break
            if not args.json_output:
                print(
                    f"[{index + 1}/{total}] RUN  {case} "
                    f"(deadline tick {deadline_for(args, case)})",
                    flush=True,
                )
            futures[executor.submit(run_case, args, case)] = (index, case)

        while futures:
            completed, _ = wait(futures, return_when=FIRST_COMPLETED)
            for future in completed:
                index, case = futures.pop(future)
                result = future.result()
                results[index] = result
                if not args.json_output:
                    print_case_result(index + 1, total, case, result)

                try:
                    next_index, next_case = next(pending_cases)
                except StopIteration:
                    continue
                if not args.json_output:
                    print(
                        f"[{next_index + 1}/{total}] RUN  {next_case} "
                        f"(deadline tick {deadline_for(args, next_case)})",
                        flush=True,
                    )
                futures[executor.submit(run_case, args, next_case)] = (
                    next_index,
                    next_case,
                )

    completed_results = [result for result in results if result is not None]
    passed = sum(
        result.get("status") == "pass" for result in completed_results
    )
    failed = total - passed
    suite = {
        "status": "pass" if failed == 0 else "fail",
        "passed": passed,
        "failed": failed,
        "wall_time_seconds": time.perf_counter() - suite_started,
        "results": completed_results,
    }
    if args.json_output:
        print(json.dumps(suite, indent=2, sort_keys=True))
    else:
        print(
            f"\nResult: {passed} passed, {failed} failed in "
            f"{format_duration(float(suite['wall_time_seconds']))}"
        )
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
