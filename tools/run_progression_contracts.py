#!/usr/bin/env python3
"""Run the release progression contracts on the checkout.

The release build runs the same contracts on its packaged archive. This entry
point creates one resolved prototype dump of the checkout and runs every
contract against it, instead of one fresh dump per contract.
"""
import argparse
import shutil
import sys

import analyze_factorio_prereqs as prereqs
from build_release import run_progression_contracts

TIMEOUT_SECONDS = 300


def main() -> int:
    argparse.ArgumentParser(description=__doc__).parse_args()
    _, temporary = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
    try:
        count = run_progression_contracts(temporary / "script-output" / "data-raw-dump.json", TIMEOUT_SECONDS)
    finally:
        shutil.rmtree(temporary)
    print(f"{count} progression contracts passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
