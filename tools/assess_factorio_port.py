#!/usr/bin/env python3
"""Stage an isolated version-port assessment and inventory installed dependencies."""

import argparse
import hashlib
from concurrent.futures import ThreadPoolExecutor
import json
import re
from pathlib import Path
import shutil
import sys
import subprocess
import urllib.request
import urllib.error
import urllib.parse
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEPENDENCIES = (
    "alien-biomes",
    "alien-biomes-graphics",
    "angelspetrochemgraphics",
    "angelsrefininggraphics",
    "angelssmeltinggraphics",
    "boblibrary",
    "boblogistics",
    "configurable-valves",
)


def portal_versions(name, target):
    with urllib.request.urlopen(
        f"https://mods.factorio.com/api/mods/{name}/full", timeout=30
    ) as response:
        data = json.load(response)
    releases = [
        release
        for release in data["releases"]
        if release["info_json"].get("factorio_version") == target
    ]
    return {
        "name": name,
        "target_releases": [r["version"] for r in releases],
        "source_url": data.get("source_url"),
        "url": f"https://mods.factorio.com/mod/{name}",
    }


def download_release(name, target_version, directory, credentials):
    with urllib.request.urlopen(
        f"https://mods.factorio.com/api/mods/{name}", timeout=30
    ) as response:
        data = json.load(response)
    matches = [
        r
        for r in data["releases"]
        if r["info_json"].get("factorio_version") == target_version
    ]
    release = max(matches, key=lambda r: tuple(int(v) for v in r["version"].split(".")))
    path = directory / release["file_name"]
    query = urllib.parse.urlencode(
        {
            "username": credentials["service-username"],
            "token": credentials["service-token"],
        }
    )
    try:
        with (
            urllib.request.urlopen(
                "https://mods.factorio.com" + release["download_url"] + "?" + query,
                timeout=120,
            ) as source,
            path.open("wb") as output,
        ):
            shutil.copyfileobj(source, output)
    except urllib.error.URLError as error:
        raise RuntimeError(
            f"Download failed for {name}: HTTP {getattr(error, 'code', 'transport failure')}"
        ) from None
    with path.open("rb") as downloaded:
        if hashlib.file_digest(downloaded, "sha1").hexdigest() != release["sha1"]:
            raise ValueError(f"Download checksum mismatch: {name}")
    return {
        "name": name,
        "version": release["version"],
        "factorio_version": target_version,
    }


def stage_source_dependency(name, repository, target_version, directory):
    """Archive a committed dependency without changing its native manifest."""
    def git(*arguments):
        return subprocess.check_output(["git", "-C", str(repository), *arguments])

    commit = git("rev-parse", "HEAD").decode().strip()
    info = json.loads(git("show", f"{commit}:info.json"))
    if info["name"] != name or name not in DEPENDENCIES:
        raise ValueError(f"Dependency source name mismatch: {name}")
    if info["factorio_version"] != target_version:
        raise ValueError(f"Dependency source {name} does not target {target_version}")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", info["version"]):
        raise ValueError(f"Invalid dependency version: {name}")
    prefix = f"{name}_{info['version']}"
    contents = git("archive", "--format=zip", f"--prefix={prefix}/", commit)
    with (directory / f"{prefix}.zip").open("xb") as output:
        output.write(contents)
    return {"name": name, "version": info["version"],
            "factorio_version": target_version, "source_commit": commit,
            "source_kind": "git"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path)
    parser.add_argument("--factorio-version", required=True)
    parser.add_argument(
        "--dependency-mod-directory",
        type=Path,
        default=Path.home() / "factorio" / "mods",
    )
    parser.add_argument("--dependency-source", action="append", default=[],
                        metavar="NAME=CHECKOUT",
                        help="Stage the committed HEAD of a native-version dependency checkout")
    parser.add_argument("--portal", action="store_true")
    parser.add_argument("--portal-only", action="store_true")
    parser.add_argument("--source-audit", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--apply-probe-edits", type=Path)
    parser.add_argument("--planner-schema-witness", type=Path)
    parser.add_argument("--baseline-api", type=Path)
    parser.add_argument("--candidate-api", type=Path)
    parser.add_argument("--download-target-releases", action="store_true")
    parser.add_argument(
        "--player-data",
        type=Path,
        default=Path.home() / "factorio" / "player-data.json",
    )
    args = parser.parse_args()
    if args.baseline_api or args.candidate_api:
        if not (args.baseline_api and args.candidate_api):
            parser.error("Both API paths are required")
        old = json.loads(args.baseline_api.read_text())
        new = json.loads(args.candidate_api.read_text())
        new_classes = {c["name"]: c for c in new["classes"]}
        source_files = [
            p
            for root in ("nullius-star/scripts", "tools", "tests/scenarios")
            for p in (ROOT / root).rglob("*")
            if p.suffix in (".lua", ".py") and p != Path(__file__)
        ]
        sources = {p: p.read_text().splitlines() for p in source_files}
        changes = []
        for cls in old["classes"]:
            current = new_classes.get(cls["name"], {})
            for kind in ("attributes", "methods"):
                members = {m["name"]: m for m in current.get(kind, [])}
                for member in cls.get(kind, []):
                    target = members.get(member["name"])
                    lost_write = (
                        target is not None
                        and "write_type" in member
                        and "write_type" not in target
                    )
                    if target is not None and not lost_write:
                        continue
                    pattern = re.compile(r"\." + re.escape(member["name"]) + r"\b")
                    hits = [
                        {
                            "path": str(p.relative_to(ROOT)),
                            "line": i,
                            "text": line.strip(),
                        }
                        for p, lines in sources.items()
                        for i, line in enumerate(lines, 1)
                        if pattern.search(line)
                    ]
                    if hits:
                        changes.append(
                            {
                                "member": cls["name"] + "." + member["name"],
                                "change": "write removed" if lost_write else "removed",
                                "hits": hits,
                            }
                        )
        result = {
            "baseline": old["application_version"],
            "candidate": new["application_version"],
            "description": "Lexical member-name hits; receiver types require manual review",
            "changes": changes,
        }
        if args.report:
            args.report.write_text(json.dumps(result, indent=2) + "\n")
        print(
            json.dumps(
                [
                    {**c, "hits": len(c["hits"]), "examples": c["hits"][:2]}
                    for c in changes
                ],
                indent=2,
            )
        )
        return
    if args.planner_schema_witness:
        sys.path.insert(0, str(ROOT))
        from tools.analyze_factorio_prereqs import (
            describe_recipes,
            deterministic_amount,
            TestFailure,
        )

        fixture = json.loads(args.planner_schema_witness.read_text())
        recipe = describe_recipes(fixture, ["candidate-schema-witness"])[0]
        try:
            amount = deterministic_amount(recipe["results"][0])
        except TestFailure:
            amount = "rejected probabilistic result"
        compatible = (
            recipe.get("categories") == ["chemistry"]
            and amount == "rejected probabilistic result"
        )
        print(
            json.dumps(
                {
                    "compatible": compatible,
                    "expected_categories": ["chemistry"],
                    "observed_category": recipe.get("category"),
                    "observed_categories": recipe.get("categories"),
                    "expected_result": "rejected probabilistic result",
                    "observed_result": amount,
                },
                indent=2,
            )
        )
        raise SystemExit(0 if compatible else 1)
    if args.apply_probe_edits:
        if args.destination is None:
            parser.error("--destination is required for probe edits")
        checkout = args.destination.resolve() / "repo"
        if checkout == ROOT or not (checkout / "nullius-star" / "info.json").is_file():
            raise ValueError("Probe edits require an isolated staged checkout")
        for edit in json.loads(args.apply_probe_edits.read_text()):
            path = checkout / edit["path"]
            source = path.read_text()
            if source.count(edit["old"]) != edit["count"]:
                raise ValueError(f"Unexpected probe edit count: {edit['path']}")
            path.write_text(source.replace(edit["old"], edit["new"]))
        return
    if args.source_audit:
        config = json.loads(args.source_audit.read_text())
        report = {"description": config["description"], "rules": {}}
        for name, rule in config["rules"].items():
            pattern = re.compile(rule["pattern"])
            hits = []
            for root in rule["roots"]:
                for path in sorted((ROOT / root).rglob("*")):
                    if path.suffix not in (".lua", ".py"):
                        continue
                    for number, line in enumerate(path.read_text().splitlines(), 1):
                        if pattern.search(line):
                            hits.append(
                                {
                                    "path": str(path.relative_to(ROOT)),
                                    "line": number,
                                    "text": line.strip(),
                                }
                            )
            report["rules"][name] = {
                "lines": len(hits),
                "files": len({h["path"] for h in hits}),
                "hits": hits,
            }
        if args.report:
            args.report.write_text(json.dumps(report, indent=2) + "\n")
        print(
            json.dumps(
                {
                    n: {
                        "lines": r["lines"],
                        "files": r["files"],
                        "examples": r["hits"][:3],
                    }
                    for n, r in report["rules"].items()
                },
                indent=2,
            )
        )
        return
    if args.portal_only:
        with ThreadPoolExecutor(max_workers=4) as pool:
            print(
                json.dumps(
                    list(
                        pool.map(
                            lambda n: portal_versions(n, args.factorio_version),
                            DEPENDENCIES,
                        )
                    ),
                    indent=2,
                )
            )
        return
    if args.destination is None:
        parser.error("--destination is required for staging")
    source_overrides = {}
    for override in args.dependency_source:
        name, separator, path = override.partition("=")
        if not separator or not path or name not in DEPENDENCIES:
            parser.error(f"Invalid dependency source: {override}")
        if name in source_overrides:
            parser.error(f"Duplicate dependency source: {name}")
        source_overrides[name] = Path(path).expanduser().resolve()
    destination = args.destination.resolve()
    destination.mkdir()  # Never overwrite an assessment or a live installation.
    checkout = destination / "repo"
    checkout.mkdir()
    for name in ("nullius-star", "tests", "tools", "docs", ".agents"):
        shutil.copytree(
            ROOT / name,
            checkout / name,
            ignore=shutil.ignore_patterns("__pycache__", ".pytest_cache"),
        )
    for name in ("nullius-star", "tests/factorio-test-support"):
        path = checkout / name / "info.json"
        info = json.loads(path.read_text())
        info["factorio_version"] = args.factorio_version
        path.write_text(json.dumps(info, indent=2) + "\n")
    dependencies = destination / "mods"
    dependencies.mkdir()
    inventory = []
    credentials = (
        json.loads(args.player_data.read_text())
        if args.download_target_releases
        else None
    )
    for name in DEPENDENCIES:
        if name in source_overrides:
            inventory.append(stage_source_dependency(
                name, source_overrides[name], args.factorio_version, dependencies))
            continue
        if credentials is not None:
            inventory.append(
                download_release(name, args.factorio_version, dependencies, credentials)
            )
            continue
        archives = list(args.dependency_mod_directory.glob(f"{name}_*.zip"))
        if len(archives) != 1:
            raise ValueError(
                f"Expected one installed archive for {name}, found {archives}"
            )
        with (
            zipfile.ZipFile(archives[0]) as source,
            zipfile.ZipFile(dependencies / archives[0].name, "w") as target,
        ):
            manifests = [
                m
                for m in source.namelist()
                if len(Path(m).parts) == 2 and m.endswith("/info.json")
            ]
            if len(manifests) != 1:
                raise ValueError(f"Expected one root manifest in {archives[0]}")
            for entry in source.infolist():
                contents = source.read(entry.filename)
                if entry.filename == manifests[0]:
                    info = json.loads(contents)
                    inventory.append(
                        {
                            "name": info["name"],
                            "version": info["version"],
                            "factorio_version": info["factorio_version"],
                        }
                    )
                    info["factorio_version"] = args.factorio_version
                    contents = (json.dumps(info, indent=2) + "\n").encode()
                target.writestr(entry.filename, contents)
    report = {
        "candidate": args.factorio_version,
        "checkout": str(checkout),
        "dependencies": inventory,
        "changes": (
            "Unspecified dependencies use published target releases; source overrides use committed native manifests"
            if credentials is not None
            else "Unspecified dependency manifests retargeted; source overrides use committed native manifests"
        ),
    }
    if args.portal:
        with ThreadPoolExecutor(max_workers=4) as pool:
            report["portal"] = list(
                pool.map(
                    lambda n: portal_versions(n, args.factorio_version), DEPENDENCIES
                )
            )
    (destination / "inventory.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
