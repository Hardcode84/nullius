#!/usr/bin/env python3
"""Build and validate the exact Nullius Star release archive."""

from __future__ import annotations

import argparse
import contextlib
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import functools
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile

if __package__:
    from .run_factorio_tests import (
        die_with_parent,
        BUILTIN_MODS,
        DEPENDENCY_MODS,
        TestFailure,
        default_dependency_mods,
        default_factorio,
        find_archive,
        format_duration,
        prepare_config,
        safe_archive_members,
    )
else:
    from run_factorio_tests import (
        die_with_parent,
        BUILTIN_MODS,
        DEPENDENCY_MODS,
        TestFailure,
        default_dependency_mods,
        default_factorio,
        find_archive,
        format_duration,
        prepare_config,
        safe_archive_members,
    )


REPOSITORY = Path(__file__).resolve().parents[1]
MOD_DIRECTORY = REPOSITORY / "nullius-star"
PROGRESSION_CONTRACTS = REPOSITORY / "tests" / "progression"
VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
CHANGELOG_VERSION = re.compile(r"^Version:\s*([^\s]+)\s*$", re.MULTILINE)
FORBIDDEN_SUFFIXES = {
    ".bat",
    ".cmd",
    ".com",
    ".dll",
    ".dylib",
    ".exe",
    ".ps1",
    ".py",
    ".pyc",
    ".sh",
    ".so",
}
FORBIDDEN_PARTS = {".git", "__pycache__"}


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build and validate a Nullius Star release archive."
    )
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument("--factorio-version", choices=("2.1",), default="2.1")
    parser.add_argument("--upgrade-factorio", type=Path,
                        help="engine used to create prior-release saves")
    parser.add_argument("--upgrade-factorio-2-1", type=Path,
                        help="historical 2.1 engine for the 0.0.4 upgrade fixture: its binary, or the "
                             "official Linux .tar.xz, unpacked once into ~/.cache/nullius/engines")
    parser.add_argument("--upgrade-dependency-mod-directory", type=Path,
                        help="dependencies used to create prior-release saves")
    parser.add_argument(
        "--dependency-mod-directory", type=Path, default=default_dependency_mods()
    )
    parser.add_argument("--output-directory", type=Path,
                        help="where the archive and manifest are written; default: release/")
    parser.add_argument("--dry-run", action="store_true",
                        help="validate a release without writing its archive or manifest")
    parser.add_argument(
        "-n",
        "--workers",
        default="auto",
        help="scenario workers: a positive integer or 'auto'",
    )
    parser.add_argument("--timeout-seconds", type=int, default=300)
    args = parser.parse_args()
    if args.dry_run and args.output_directory:
        parser.error("--dry-run writes nothing, so it takes no --output-directory")
    return args


def output_directory(args: argparse.Namespace, stack: contextlib.ExitStack) -> Path:
    """Return where the archive is built.

    Validation needs a real archive, so a dry run builds one in a temporary
    directory that the stack removes.
    """
    if args.dry_run:
        return Path(stack.enter_context(tempfile.TemporaryDirectory(prefix="nullius-release-dry-run-")))
    return (args.output_directory or REPOSITORY / "release").expanduser().resolve()


def checked_output(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        cwd=REPOSITORY,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise TestFailure(
            f"command failed ({completed.returncode}): {' '.join(command)}\n{detail}"
        )
    return completed.stdout


def require_clean_checkout() -> str:
    status = checked_output(
        ["git", "status", "--porcelain=v1", "--untracked-files=all"]
    )
    if status:
        raise TestFailure(f"release requires a clean checkout:\n{status.rstrip()}")
    return checked_output(["git", "rev-parse", "HEAD"]).strip()


def read_metadata() -> dict[str, object]:
    info_path = MOD_DIRECTORY / "info.json"
    try:
        metadata = json.loads(info_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise TestFailure(f"cannot read {info_path}: {error}") from error
    if not isinstance(metadata, dict):
        raise TestFailure(f"mod metadata root must be an object: {info_path}")
    if metadata.get("name") != "nullius-star":
        raise TestFailure("release mod name must be 'nullius-star'")
    version = metadata.get("version")
    if not isinstance(version, str) or VERSION.fullmatch(version) is None:
        raise TestFailure(f"invalid release version: {version!r}")
    if any(int(component) > 65535 for component in version.split(".")):
        raise TestFailure(f"release version component exceeds 65535: {version}")
    if metadata.get("factorio_version") != "2.1":
        raise TestFailure("release factorio_version must be '2.1'")
    dependencies = metadata.get("dependencies")
    if not isinstance(dependencies, list) or "! nullius" not in dependencies:
        raise TestFailure("release must declare upstream Nullius incompatible")
    migrations = sorted((MOD_DIRECTORY / "migrations").glob("*"))
    if version == "0.0.1" and migrations:
        names = ", ".join(path.name for path in migrations)
        raise TestFailure(f"initial release must not contain migrations: {names}")
    changelog = (MOD_DIRECTORY / "changelog.txt").read_text(encoding="utf-8")
    match = CHANGELOG_VERSION.search(changelog)
    if match is None:
        raise TestFailure("changelog has no Version field")
    if match.group(1) != version:
        raise TestFailure(
            f"info.json version {version} does not match first changelog "
            f"version {match.group(1)}"
        )
    return metadata


def tracked_mod_files() -> list[Path]:
    raw = checked_output(["git", "ls-files", "-z", "--", "nullius-star"])
    files = [REPOSITORY / name for name in raw.split("\0") if name]
    if not files:
        raise TestFailure("no tracked files found under nullius-star/")
    for path in files:
        relative = path.relative_to(REPOSITORY)
        if not path.is_file() or path.is_symlink():
            raise TestFailure(
                f"release input must be a tracked regular file: {relative}"
            )
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            raise TestFailure(f"forbidden release file type: {relative}")
        if FORBIDDEN_PARTS.intersection(relative.parts):
            raise TestFailure(f"forbidden release path: {relative}")
    return sorted(files)


def zip_timestamp() -> tuple[int, int, int, int, int, int]:
    raw = checked_output(["git", "show", "-s", "--format=%ct", "HEAD"]).strip()
    value = datetime.fromtimestamp(int(raw), tz=timezone.utc)
    year = max(value.year, 1980)
    return (
        year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second // 2 * 2,
    )


def build_archive(output_directory: Path, metadata: dict[str, object]) -> Path:
    output_directory.mkdir(parents=True, exist_ok=True)
    version = str(metadata["version"])
    destination = output_directory / f"nullius-star_{version}.zip"
    temporary = destination.with_suffix(".zip.tmp")
    timestamp = zip_timestamp()
    try:
        with zipfile.ZipFile(
            temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
        ) as archive:
            for source in tracked_mod_files():
                relative = source.relative_to(REPOSITORY)
                info = zipfile.ZipInfo(relative.as_posix(), timestamp)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o100644 << 16
                payload = source.read_bytes()
                if relative.as_posix() == "nullius-star/info.json":
                    payload = (json.dumps(metadata, indent=2) + "\n").encode("utf-8")
                archive.writestr(info, payload, compresslevel=9)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    with zipfile.ZipFile(destination) as archive:
        safe_archive_members(archive, "nullius-star")
        bad = archive.testzip()
        if bad is not None:
            raise TestFailure(f"corrupt release archive member: {bad}")
    return destination


def prepare_release_mods(mods: Path, dependencies: Path, release_archive: Path,
                         *, historical_quality: bool = False) -> None:
    mods.mkdir(parents=True)
    enabled = list(BUILTIN_MODS)
    for dependency in DEPENDENCY_MODS:
        archive = find_archive(dependencies, dependency)
        (mods / archive.name).symlink_to(archive)
        enabled.append(dependency)
    (mods / release_archive.name).symlink_to(release_archive)
    enabled.append("nullius-star")
    (mods / "mod-list.json").write_text(
        json.dumps(
            {"mods": [{"name": name, "enabled": True} for name in enabled] +
             [{"name": "quality", "enabled": historical_quality}]},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def run_checked(command: list[str], label: str, timeout: int) -> str:
    completed = subprocess.run(
        command,
        preexec_fn=die_with_parent,
        cwd=REPOSITORY,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )
    if completed.returncode != 0:
        output = "\n".join(completed.stdout.splitlines()[-60:])
        raise TestFailure(f"{label} exited {completed.returncode}\n{output}")
    return completed.stdout


def run_streaming(command: list[str], label: str, timeout: int) -> None:
    completed = subprocess.run(
        command,
        preexec_fn=die_with_parent,
        cwd=REPOSITORY,
        timeout=timeout,
        check=False,
    )
    if completed.returncode != 0:
        raise TestFailure(f"{label} exited {completed.returncode}")


def validate_factorio_archive(
    factorio: Path,
    dependencies: Path,
    release_archive: Path,
    timeout: int,
    run_directory: Path,
) -> Path:
    for name in ("saves", "script-output", "temp"):
        (run_directory / name).mkdir(parents=True)
    config = prepare_config(run_directory, factorio)
    mods = run_directory / "mods"
    prepare_release_mods(mods, dependencies, release_archive)
    common = [
        str(factorio),
        "--config",
        str(config),
        "--mod-directory",
        str(mods),
        "--disable-audio",
    ]
    dump_output = run_checked(
        [*common, "--check-unused-prototype-data", "--dump-data"],
        "strict prototype load",
        timeout,
    )
    unused = [
        line for line in dump_output.splitlines() if "was not used" in line.lower()
    ]
    if unused:
        raise TestFailure(
            "strict prototype load reported unused data:\n" + "\n".join(unused)
        )
    data_raw = run_directory / "script-output" / "data-raw-dump.json"
    if not data_raw.is_file():
        raise TestFailure("strict prototype load did not produce data-raw-dump.json")

    save = run_directory / "saves" / "release-smoke.zip"
    run_checked(
        [*common, "--create", str(save), "--map-gen-seed", "0"],
        "fresh map creation",
        timeout,
    )
    if not save.is_file():
        raise TestFailure("fresh map creation did not produce its save")
    run_checked(
        [*common, "--load-game", str(save), "--until-tick", "10"],
        "fresh map reload",
        timeout,
    )
    return data_raw


VALIDATION_ERRORS = (TestFailure, OSError, ValueError, subprocess.TimeoutExpired)


def run_jobs(jobs: dict[str, object]) -> dict[str, object]:
    """Run independent validation jobs at once and report every failure.

    Each job is a callable that runs child processes; all of them finish
    before the failures, if any, are raised together.
    """
    with ThreadPoolExecutor(max_workers=len(jobs)) as executor:
        futures = {label: executor.submit(job) for label, job in jobs.items()}
    results: dict[str, object] = {}
    failures = []
    for label, future in futures.items():
        try:
            results[label] = future.result()
        except VALIDATION_ERRORS as error:
            failures.append(f"{label}: {error}")
    if failures:
        raise TestFailure("\n\n".join(failures))
    return results


def run_progression_contracts(data_raw: Path, timeout: int) -> int:
    contract_names = json.loads((PROGRESSION_CONTRACTS / "release.json").read_text())["contracts"]
    contracts = [PROGRESSION_CONTRACTS / name for name in contract_names]
    if not contracts:
        raise TestFailure("no progression contracts found")
    analyzer = REPOSITORY / "tools" / "analyze_factorio_prereqs.py"
    run_jobs({
        contract.name: functools.partial(
            run_checked,
            [sys.executable, str(analyzer), f"@{contract}", "--data-raw", str(data_raw), "--json"],
            f"progression contract {contract.name}",
            timeout,
        )
        for contract in contracts
    })
    return len(contracts)



def run_unlock_audits(data_raw: Path, timeout: int, directory: Path) -> int:
    configs = json.loads((PROGRESSION_CONTRACTS / "release.json").read_text())["unlock_audits"]
    if not configs:
        raise TestFailure("no recipe unlock audits found")
    for config in configs:
        run_checked([sys.executable, str(REPOSITORY / "tools/audit_recipe_unlocks.py"),
                     "--config", str(PROGRESSION_CONTRACTS / config),
                     "--data-raw", str(data_raw),
                     "--output", str(directory / (Path(config).stem + "-report.json")),
                     "--check"],
                    f"recipe unlock audit {config}", timeout)
    return len(configs)


def run_bootstrap_checks(data_raw: Path, timeout: int, directory: Path) -> list[dict]:
    checks = json.loads((PROGRESSION_CONTRACTS / "release.json").read_text())["bootstrap"]
    if not checks:
        raise TestFailure("no staged bootstrap checks found")
    results = []
    for check in checks:
        plan = directory / (check["name"] + "-plan.json")
        output = directory / (check["name"] + "-bootstrap.json")
        run_checked([sys.executable, str(REPOSITORY / "tools/plan_factorio_factory.py"),
                     "--config", str(PROGRESSION_CONTRACTS / check["planner"]),
                     "--data-raw", str(data_raw), "--output", str(plan)],
                    check["name"] + " factory plan", timeout)
        run_checked([sys.executable, str(REPOSITORY / "tools/audit_factorio_building_bootstrap.py"),
                     "--config", str(PROGRESSION_CONTRACTS / check["config"]),
                     "--plan", str(plan), "--data-raw", str(data_raw), "--output", str(output)],
                    check["name"] + " staged bootstrap", timeout)
        report = json.loads(output.read_text())
        if report["blocked_targets"] or report["unreached_research"]:
            raise TestFailure(check["name"] + " bootstrap has blocked targets or research")
        results.append({"name": check["name"], "status": "pass",
                        "targets": len(report["targets"]), "buildings": len(report["building_targets"]),
                        "dump_sha256": report["dump_sha256"]})
    return results


def extract_release(release_archive: Path, destination: Path) -> Path:
    with zipfile.ZipFile(release_archive) as archive:
        safe_archive_members(archive, "nullius-star")
        archive.extractall(destination)
    return destination / "nullius-star"


ENGINE_ARCHIVE_SUFFIX = ".tar.xz"


def engine_cache() -> Path:
    return Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "nullius" / "engines"


def historical_engine(path: Path, cache: Path) -> Path:
    """Return an engine binary, unpacking an official Linux archive once into the cache.

    The archive unpacks into a temporary sibling that is renamed into place, so
    an interrupted unpack never leaves a cache entry that looks complete.
    """
    path = path.expanduser().resolve()
    if not path.name.endswith(ENGINE_ARCHIVE_SUFFIX):
        return path
    target = cache / path.name.removesuffix(ENGINE_ARCHIVE_SUFFIX)
    binary = target / "factorio" / "bin" / "x64" / "factorio"
    if not binary.is_file():
        cache.mkdir(parents=True, exist_ok=True)
        partial = Path(tempfile.mkdtemp(prefix=target.name + ".", dir=cache))
        try:
            subprocess.run(["tar", "-xJf", str(path), "-C", str(partial)], check=True)
            if not (partial / "factorio" / "bin" / "x64" / "factorio").is_file():
                raise TestFailure(f"{path} has no factorio/bin/x64/factorio")
            partial.rename(target)
        except BaseException:
            shutil.rmtree(partial, ignore_errors=True)
            raise
    return binary


def run_validation(args: argparse.Namespace, archive: Path) -> dict[str, object]:
    factorio = args.factorio.expanduser().resolve()
    dependencies = args.dependency_mod_directory.expanduser().resolve()
    if not factorio.is_file():
        raise TestFailure(f"Factorio executable not found: {factorio}")
    if not dependencies.is_dir():
        raise TestFailure(f"dependency mod directory not found: {dependencies}")

    if __package__:
        from .check_factorio_upgrade import check_upgrade
    else:
        from check_factorio_upgrade import check_upgrade
    timeout = args.timeout_seconds
    with tempfile.TemporaryDirectory(prefix="nullius-star-release-") as temporary:
        root = Path(temporary)
        data_raw = validate_factorio_archive(factorio, dependencies, archive, timeout, root / "factorio")
        extracted_mod = extract_release(archive, root / "extracted")
        scenario_result = root / "scenario-result.json"

        def tool(name: str, *arguments: str) -> list[str]:
            return [sys.executable, str(REPOSITORY / "tools" / name), *arguments]

        # Every job below reads only the archive, the dump, or its own files.
        jobs = {
            "progression contracts": functools.partial(run_progression_contracts, data_raw, timeout),
            "launch vehicle cost bounds": functools.partial(run_checked, tool(
                "check_launch_vehicle.py", "--data-raw", str(data_raw), "--output", str(root / "launch-cost.json")),
                "launch vehicle cost bounds", timeout),
            "radio astronomy contracts": functools.partial(run_checked, tool(
                "check_astronomy.py", "--data-raw", str(data_raw), "--output", str(root / "astronomy.json")),
                "radio astronomy contracts", timeout),
            "copper research placement": functools.partial(run_checked, tool(
                "check_copper_research.py", "--data-raw", str(data_raw)), "copper research placement", timeout),
            "asteroid mining removal": functools.partial(run_checked, tool(
                "check_asteroid_removal.py", "--data-raw", str(data_raw)), "asteroid mining removal", timeout),
            "nuclear research placement": functools.partial(run_checked, tool(
                "check_nuclear_research.py", "--data-raw", str(data_raw)), "nuclear research placement", timeout),
            "research tree structure": functools.partial(run_checked, tool(
                "check_research_tree.py", "--data-raw", str(data_raw)), "research tree structure", timeout),
            "recipe unlock audits": functools.partial(run_unlock_audits, data_raw, timeout, root),
            "staged bootstrap": functools.partial(run_bootstrap_checks, data_raw, timeout, root),
            "prototype locale audit": functools.partial(run_checked, tool(
                "check_factorio_locale.py", "--mod", str(extracted_mod), "--factorio", str(factorio),
                "--dependency-mod-directory", str(dependencies), "--timeout-seconds", str(timeout)),
                "prototype locale audit", timeout * 2),
            "Factorio scenario suite": functools.partial(run_streaming, tool(
                "run_factorio_tests.py", "--mod-under-test", str(archive), "--factorio", str(factorio),
                "--dependency-mod-directory", str(dependencies), "-n", args.workers,
                "--result-json", str(scenario_result)), "Factorio scenario suite", timeout * 3),
        }
        upgrades = {"0.0.1": (args.upgrade_factorio, args.upgrade_dependency_mod_directory),
                    "0.0.2": (args.upgrade_factorio, args.upgrade_dependency_mod_directory),
                    "0.0.3": (args.upgrade_factorio, args.upgrade_dependency_mod_directory),
                    "0.0.4": (args.upgrade_factorio_2_1 and historical_engine(args.upgrade_factorio_2_1,
                                                                               engine_cache()), dependencies),
                    "0.0.5": (None, None),
                    "0.0.6": (None, None)}
        for version, (engine, mods) in upgrades.items():
            jobs[f"{version} upgrade"] = functools.partial(
                check_upgrade, archive, factorio, dependencies, timeout, version, engine, mods)
        results = run_jobs(jobs)
        if not scenario_result.is_file():
            raise TestFailure("Factorio scenario suite wrote no structured result")
        scenario_suite = json.loads(scenario_result.read_text(encoding="utf-8"))
        if scenario_suite.get("status") != "pass":
            raise TestFailure(f"invalid passing scenario result: {scenario_suite!r}")
    return {
        "bootstrap": results["staged bootstrap"],
        "upgrade": [results[f"{version} upgrade"] for version in upgrades],
        "progression_contracts": results["progression contracts"],
        "scenario_tests": scenario_suite["passed"],
        "scenario_wall_time_seconds": scenario_suite["wall_time_seconds"],
    }


def main() -> int:
    # Stage lines must reach a redirected log as they happen.
    sys.stdout.reconfigure(line_buffering=True)
    args = parse_arguments()
    started = time.perf_counter()
    stack = contextlib.ExitStack()
    try:
        print("[1/5] RUN  checkout and metadata")
        commit = require_clean_checkout()
        if __package__:
            from .factorio_package import engine_series, package_metadata
        else:
            from factorio_package import engine_series, package_metadata
        metadata = package_metadata(read_metadata(), args.factorio_version)
        if engine_series(args.factorio.expanduser()) != args.factorio_version:
            raise TestFailure("release target does not match the selected Factorio engine")
        print("[1/5] PASS checkout and metadata")

        print("[2/5] RUN  Python unit tests, alongside the archive and validation")
        unit_tests = functools.partial(run_checked, [
            sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py",
        ], "Python unit tests", args.timeout_seconds)

        def package_and_validate() -> tuple[Path, str, dict[str, object]]:
            print("[3/5] RUN  deterministic release archive")
            archive = build_archive(output_directory(args, stack), metadata)
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            print(f"[3/5] PASS deterministic release archive - {archive}")
            print("[4/5] RUN  packaged Factorio and progression validation")
            validation = run_validation(args, archive)
            print("[4/5] PASS packaged Factorio and progression validation")
            return archive, digest, validation

        archive, digest, validation = run_jobs({
            "Python unit tests": unit_tests, "release": package_and_validate})["release"]
        print("[2/5] PASS Python unit tests")

        if args.dry_run:
            print("[5/5] SKIP release manifest - dry run")
            print(f"\nRelease validation PASS in {format_duration(time.perf_counter() - started)}; "
                  "dry run wrote no archive or manifest")
            return 0
        print("[5/5] RUN  release manifest")
        manifest = {
            "schema": 1,
            "status": "pass",
            "mod": metadata["name"],
            "version": metadata["version"],
            "factorio_version": metadata["factorio_version"],
            "commit": commit,
            "archive": archive.name,
            "sha256": digest,
            "archive_bytes": archive.stat().st_size,
            **validation,
        }
        manifest_path = archive.with_suffix(".json")
        manifest_path.write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        print(f"[5/5] PASS release manifest - {manifest_path}")
        print(f"\nRelease PASS in {format_duration(time.perf_counter() - started)}")
        print(f"SHA-256 {digest}  {archive.name}")
        return 0
    except VALIDATION_ERRORS as error:
        sys.stdout.flush()
        print(f"\nRelease FAIL: {error}")
        return 1
    finally:
        stack.close()


if __name__ == "__main__":
    raise SystemExit(main())
