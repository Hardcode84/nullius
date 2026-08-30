#!/usr/bin/env python3
"""Resolved-prototype regression contract for Vulcanus physics production."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
ANALYZER = REPOSITORY / "tools" / "analyze_factorio_prereqs.py"
CONTRACT = REPOSITORY / "tests" / "progression" / "vulcanus-physics-production.args"


class VulcanusPhysicsContractTest(unittest.TestCase):
    def test_physics_production_requires_no_electricity(self) -> None:
        completed = subprocess.run(
            [sys.executable, str(ANALYZER), f"@{CONTRACT}", "--json"],
            cwd=REPOSITORY,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=300,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads(completed.stdout)
        self.assertEqual(report["required_technologies"], [])
        self.assertEqual(report["unresolved"], [])
        self.assertEqual(report["invalid_raw"], [])
        self.assertEqual(report["electric_required_paths"], [])


if __name__ == "__main__":
    unittest.main()
