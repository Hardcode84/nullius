#!/usr/bin/env python3
"""Resolved-prototype contract for Nauvis epoxy and Vulcanus resin."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
ANALYZER = REPOSITORY / "tools" / "analyze_factorio_prereqs.py"
PHYSICS_CONTRACT = (
    REPOSITORY / "tests" / "progression" / "vulcanus-physics-production.args"
)
NAUVIS_ONLY_RECIPES = (
    "nullius-bpa",
    "nullius-pressure-bpa",
    "nullius-boxed-bpa",
    "nullius-boxed-pressure-bpa",
    "nullius-epoxy",
    "nullius-boxed-epoxy",
)
UNBOX_RECIPE = "nullius-unbox-bpa"
HOT_RECIPE = "nullius-high-temperature-resin"


class VulcanusResinContractTest(unittest.TestCase):
    def test_surface_and_material_contract(self) -> None:
        command = [sys.executable, str(ANALYZER)]
        for recipe in (*NAUVIS_ONLY_RECIPES, UNBOX_RECIPE, HOT_RECIPE):
            command.extend(("--describe-recipe", recipe))
        command.append("--json")
        completed = subprocess.run(
            command,
            cwd=REPOSITORY,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=300,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        recipes = {recipe["name"]: recipe for recipe in json.loads(completed.stdout)}

        nauvis_only = [{
            "property": "nullius-nauvis-environment",
            "min": 1,
            "max": 1,
        }]
        for name in NAUVIS_ONLY_RECIPES:
            self.assertEqual(recipes[name]["surface_conditions"], nauvis_only)
        self.assertEqual(recipes[UNBOX_RECIPE]["surface_conditions"], [])

        hot = recipes[HOT_RECIPE]
        self.assertEqual(hot["surface_conditions"], [{
            "property": "nullius-ambient-temperature",
            "min": 200,
        }])
        self.assertEqual(hot["unlock_technologies"], ["nullius-organic-chemistry-5"])
        self.assertEqual(
            {(item["name"], item["amount"]) for item in hot["ingredients"]},
            {
                ("nullius-acrylonitrile-barrel", 2),
                ("nullius-ammonia-barrel", 1),
                ("nullius-alumina", 1),
                ("nullius-benzene", 30),
                ("nullius-oxygen", 100),
                ("nullius-solvent", 10),
            },
        )
        products = {item["name"]: item for item in hot["results"]}
        self.assertEqual(products["nullius-epoxy"]["amount"], 40)
        self.assertEqual(products["nullius-epoxy"]["temperature"], 200)
        self.assertEqual(products["nullius-wastewater"]["amount"], 50)
        self.assertEqual(products["barrel"]["ignored_by_productivity"], 3)
        self.assertEqual(products["nullius-alumina"]["ignored_by_productivity"], 1)

    def test_pc_abs_cannot_synthesize_local_bpa(self) -> None:
        completed = subprocess.run(
            [
                sys.executable,
                str(ANALYZER),
                f"@{PHYSICS_CONTRACT}",
                "--surface-property",
                "nullius-nauvis-environment=0",
                "--recipe",
                "nullius-plastic=nullius-plastic-pc-abs",
                "--json",
            ],
            cwd=REPOSITORY,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=300,
            check=False,
        )
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn(
            "selected recipe nullius-plastic-pc-abs is not available",
            completed.stderr,
        )


if __name__ == "__main__":
    unittest.main()
