#!/usr/bin/env python3
"""Build a separate Bob's Logistics 3.0.1 archive with corrected tungsten prerequisites."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile

PATCH = Path(__file__).resolve().parent / "patches/boblogistics-tungsten-prerequisites.patch"


def patch_archive(source, destination):
    with tempfile.TemporaryDirectory(prefix="boblogistics-tungsten-") as temporary:
        work = Path(temporary)
        with zipfile.ZipFile(source) as archive:
            roots = {Path(name).parts[0] for name in archive.namelist() if Path(name).parts}
            if len(roots) != 1 or not roots <= {"boblogistics", "boblogistics_3.0.1"}:
                raise ValueError(f"Unexpected archive roots: {roots}")
            prefix = roots.pop()
            for entry in archive.infolist():
                path = Path(entry.filename)
                if path.is_absolute() or ".." in path.parts or path.parts[0] != prefix:
                    raise ValueError(f"Unexpected archive member: {entry.filename}")
            info = json.loads(archive.read(prefix + "/info.json"))
            if (info["name"], info["version"], info["factorio_version"]) != ("boblogistics", "3.0.1", "2.1"):
                raise ValueError("Expected native Bob's Logistics 3.0.1 for Factorio 2.1")
            archive.extractall(work)
        mod = work / "boblogistics"
        if prefix != "boblogistics":
            (work / prefix).rename(mod)
        subprocess.run(["git", "apply", "--check", str(PATCH)], cwd=work, check=True)
        subprocess.run(["git", "apply", str(PATCH)], cwd=work, check=True)
        with zipfile.ZipFile(destination, "x", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(mod.rglob("*")):
                if path.is_file():
                    archive.write(path, Path("boblogistics_3.0.1") / path.relative_to(mod))
    return {"source": str(source), "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "patch_sha256": hashlib.sha256(PATCH.read_bytes()).hexdigest(), "output": str(destination)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(patch_archive(args.source.resolve(), args.output.resolve()), indent=2))
