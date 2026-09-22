#!/usr/bin/env python3
"""Build development ZIPs for Factorio 2.1 (default), 2.0, or both."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIREMENTS = {
    "2.0": {"base": "2.0.73", "space-age": "2.0.73", "elevated-rails": "2.0",
            "boblogistics": "2.0.6", "boblibrary": "1.1.4", "configurable-valves": "0.3.3"},
    "2.1": {"base": "2.1.19", "space-age": "2.1.19", "elevated-rails": "2.1.19",
            "boblogistics": "3.0.1", "boblibrary": "3.0.0", "configurable-valves": "2.0.2"},
}


def engine_series(factorio):
    info = json.loads((factorio.resolve().parents[2] / "data/base/info.json").read_text())
    version = ".".join(info["version"].split(".")[:2])
    if version not in REQUIREMENTS:
        raise ValueError(f"Unsupported Factorio series: {version}")
    return version


def workspace_target(factorio, subject):
    """Retarget only this checkout; external directories and ZIPs stay exact."""
    return engine_series(factorio) if subject.resolve() == ROOT / "nullius-star" else None


def package_metadata(source, version):
    if version not in REQUIREMENTS:
        raise ValueError(f"Unsupported Factorio series: {version}")
    requirements = REQUIREMENTS[version]
    dependencies = []
    for dependency in source["dependencies"]:
        head, separator, minimum = dependency.partition(" >= ")
        name = head.split()[-1]
        if separator and name in requirements:
            dependency = head + " >= " + requirements[name]
        dependencies.append(dependency)
    return {**source, "factorio_version": version, "dependencies": dependencies}


def retarget_manifest(path, version):
    metadata = package_metadata(json.loads(path.read_text()), version)
    if path.is_symlink():
        path.unlink()
    path.write_text(json.dumps(metadata, indent=2) + "\n")


def build_packages(destination, version="2.1"):
    if __package__:
        from .build_release import build_archive, read_metadata
    else:
        from build_release import build_archive, read_metadata
    source = read_metadata()
    versions = tuple(REQUIREMENTS) if version == "both" else (version,)
    return [build_archive(destination / target, package_metadata(source, target))
            for target in versions]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio-version", choices=(*REQUIREMENTS, "both"), default="2.1")
    parser.add_argument("--output-directory", type=Path, default=ROOT / "release/packages")
    args = parser.parse_args()
    for archive in build_packages(args.output_directory.expanduser().resolve(), args.factorio_version):
        print(archive)
