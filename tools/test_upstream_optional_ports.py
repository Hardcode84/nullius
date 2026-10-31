#!/usr/bin/env python3
"""Check optional resource, item visibility, and YAFC contracts on Factorio 2.1."""
import argparse
from pathlib import Path
import tempfile

from run_factorio_tests import default_dependency_mods, prepare_mods
from test_vulcanus_processing_compatibility import ROOT, command


def run(engine, dependencies):
    work = Path(tempfile.mkdtemp(prefix="upstream-optional-ports-"))
    prepare_mods(work / "mods", dependencies)
    mod = work / "mods/nullius-star"
    for target, source in (
        ("optional-port-fixture.lua", "tests/compatibility/upstream-optional-ports.lua"),
    ):
        (mod / target).symlink_to(ROOT / source)
    for name, source, prefix in (
        ("optional-final", "override_mod_final", 'local mods=fixture.mods\nlocal settings=fixture.settings\n'),
        ("optional-yafc", "yafc", ''),
    ):
        (mod / f"{name}.lua").write_text(
            'return function(fixture)\nlocal data=fixture.data\n' + prefix +
            (ROOT / f"nullius-star/prototypes/{source}.lua").read_text() + '\nend\n')
    final = mod / "data-final-fixes.lua"
    source = final.read_text()
    final.unlink()
    final.write_text(source + '\nrequire("optional-port-fixture")\n')
    command(work, engine, ["--dump-data", "--check-unused-prototype-data"], "dump")
    print(f"PASS optional-port contracts; {work}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", type=Path, required=True)
    parser.add_argument("--dependency-mod-directory", type=Path, default=default_dependency_mods())
    args = parser.parse_args()
    run(args.factorio.expanduser().resolve(), args.dependency_mod_directory)
