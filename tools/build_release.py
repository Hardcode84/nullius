#!/usr/bin/env python3
"""Build and validate the exact Nullius Star release archive."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import zipfile

if __package__:
    from .run_factorio_tests import (
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
    parser.add_argument(
        "--dependency-mod-directory", type=Path, default=default_dependency_mods()
    )
    parser.add_argument("--output-directory", type=Path, default=REPOSITORY / "release")
    parser.add_argument(
        "-n",
        "--workers",
        default="auto",
        help="scenario workers: a positive integer or 'auto'",
    )
    parser.add_argument("--timeout-seconds", type=int, default=300)
    return parser.parse_args()


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
    if metadata.get("factorio_version") != "2.0":
        raise TestFailure("release factorio_version must be '2.0'")
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
                archive.writestr(info, source.read_bytes(), compresslevel=9)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    with zipfile.ZipFile(destination) as archive:
        safe_archive_members(archive, "nullius-star")
        bad = archive.testzip()
        if bad is not None:
            raise TestFailure(f"corrupt release archive member: {bad}")
    return destination


def prepare_release_mods(mods: Path, dependencies: Path, release_archive: Path) -> None:
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
            {"mods": [{"name": name, "enabled": True} for name in enabled]},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def run_checked(command: list[str], label: str, timeout: int) -> str:
    completed = subprocess.run(
        command,
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


def run_progression_contracts(data_raw: Path, timeout: int) -> int:
    contracts = sorted(PROGRESSION_CONTRACTS.glob("*.args"))
    if not contracts:
        raise TestFailure("no progression contracts found")
    analyzer = REPOSITORY / "tools" / "analyze_factorio_prereqs.py"
    for contract in contracts:
        run_checked(
            [
                sys.executable,
                str(analyzer),
                f"@{contract}",
                "--data-raw",
                str(data_raw),
                "--json",
            ],
            f"progression contract {contract.name}",
            timeout,
        )
    return len(contracts)


def extract_release(release_archive: Path, destination: Path) -> Path:
    with zipfile.ZipFile(release_archive) as archive:
        safe_archive_members(archive, "nullius-star")
        archive.extractall(destination)
    return destination / "nullius-star"


def run_validation(args: argparse.Namespace, archive: Path) -> dict[str, object]:
    factorio = args.factorio.expanduser().resolve()
    dependencies = args.dependency_mod_directory.expanduser().resolve()
    if not factorio.is_file():
        raise TestFailure(f"Factorio executable not found: {factorio}")
    if not dependencies.is_dir():
        raise TestFailure(f"dependency mod directory not found: {dependencies}")

    with tempfile.TemporaryDirectory(prefix="nullius-star-release-") as temporary:
        root = Path(temporary)
        data_raw = validate_factorio_archive(
            factorio, dependencies, archive, args.timeout_seconds, root / "factorio"
        )
        contract_count = run_progression_contracts(data_raw, args.timeout_seconds)
        extracted_mod = extract_release(archive, root / "extracted")
        run_checked(
            [
                sys.executable,
                str(REPOSITORY / "tools" / "check_factorio_locale.py"),
                "--mod",
                str(extracted_mod),
                "--factorio",
                str(factorio),
                "--dependency-mod-directory",
                str(dependencies),
                "--timeout-seconds",
                str(args.timeout_seconds),
            ],
            "prototype locale audit",
            args.timeout_seconds * 2,
        )
        scenario_result = root / "scenario-result.json"
        run_streaming(
            [
                sys.executable,
                str(REPOSITORY / "tools" / "run_factorio_tests.py"),
                "--mod-under-test",
                str(archive),
                "--factorio",
                str(factorio),
                "--dependency-mod-directory",
                str(dependencies),
                "--timeout-seconds",
                str(args.timeout_seconds),
                "-n",
                args.workers,
                "--result-json",
                str(scenario_result),
            ],
            "Factorio scenario suite",
            args.timeout_seconds * 3,
        )
        if not scenario_result.is_file():
            raise TestFailure("Factorio scenario suite wrote no structured result")
        scenario_suite = json.loads(scenario_result.read_text(encoding="utf-8"))
        if scenario_suite.get("status") != "pass":
            raise TestFailure(f"invalid passing scenario result: {scenario_suite!r}")
    return {
        "progression_contracts": contract_count,
        "scenario_tests": scenario_suite["passed"],
        "scenario_wall_time_seconds": scenario_suite["wall_time_seconds"],
    }


def main() -> int:
    args = parse_arguments()
    started = time.perf_counter()
    try:
        print("[1/5] RUN  checkout and metadata")
        commit = require_clean_checkout()
        metadata = read_metadata()
        print("[1/5] PASS checkout and metadata")

        print("[2/5] RUN  Python unit tests")
        run_checked(
            [
                sys.executable,
                "-m",
                "unittest",
                "discover",
                "-s",
                "tests",
                "-p",
                "test_*.py",
            ],
            "Python unit tests",
            args.timeout_seconds,
        )
        print("[2/5] PASS Python unit tests")

        print("[3/5] RUN  deterministic release archive")
        archive = build_archive(args.output_directory.expanduser().resolve(), metadata)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        print(f"[3/5] PASS deterministic release archive - {archive}")

        print("[4/5] RUN  packaged Factorio and progression validation")
        validation = run_validation(args, archive)
        print("[4/5] PASS packaged Factorio and progression validation")

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
    except (TestFailure, OSError, ValueError, subprocess.TimeoutExpired) as error:
        sys.stdout.flush()
        print(f"\nRelease FAIL: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
