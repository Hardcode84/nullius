#!/usr/bin/env python3
"""Unit tests for the resolved-prototype prerequisite analyzer."""

from __future__ import annotations

from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))

from analyze_factorio_prereqs import analyze


class AnalyzePrerequisitesTest(unittest.TestCase):
    def test_selects_renewable_route_and_reports_technology_and_machine(self) -> None:
        data = {
            "item": {
                "target": {"name": "target"},
                "ore": {"name": "ore"},
                "broken-machine": {"name": "broken-machine"},
                "machine-item": {
                    "name": "machine-item",
                    "place_result": "machine",
                },
            },
            "recipe": {
                "repair-target": {
                    "name": "repair-target",
                    "enabled": True,
                    "category": "crafting",
                    "ingredients": [
                        {"type": "item", "name": "broken-machine", "amount": 1}
                    ],
                    "results": [{"type": "item", "name": "target", "amount": 1}],
                },
                "make-target": {
                    "name": "make-target",
                    "enabled": False,
                    "category": "crafting",
                    "ingredients": [{"type": "item", "name": "ore", "amount": 2}],
                    "results": [{"type": "item", "name": "target", "amount": 1}],
                },
            },
            "technology": {
                "prerequisite-tech": {
                    "name": "prerequisite-tech",
                    "prerequisites": [],
                },
                "target-tech": {
                    "name": "target-tech",
                    "prerequisites": ["prerequisite-tech"],
                    "effects": [
                        {"type": "unlock-recipe", "recipe": "make-target"}
                    ],
                },
            },
            "simple-entity": {
                "ore-rock": {
                    "name": "ore-rock",
                    "minable": {"result": "ore"},
                }
            },
            "container": {
                "wreck": {
                    "name": "wreck",
                    "minable": {"result": "broken-machine"},
                }
            },
            "assembling-machine": {
                "machine": {
                    "name": "machine",
                    "crafting_categories": ["crafting"],
                    "minable": {"result": "machine-item"},
                }
            },
            "character": {
                "character": {
                    "name": "character",
                    "crafting_categories": ["crafting"],
                }
            },
        }
        args = SimpleNamespace(
            targets=["target"],
            technology=["prerequisite-tech"],
            surface_property=[],
            available=[],
            raw=["ore"],
        )

        report = analyze(data, args)

        self.assertEqual(report["unresolved"], [])
        self.assertEqual(
            report["selected_recipes"][0]["producer"], "make-target"
        )
        self.assertEqual(report["required_technologies"], ["target-tech"])
        self.assertEqual(report["raw_sources"], {"ore": ["simple-entity:ore-rock"]})
        self.assertEqual(
            report["crafting_categories"]["crafting"],
            {"machine_items": ["machine-item"], "characters": ["character"]},
        )

    def test_missing_product_fails_closed(self) -> None:
        args = SimpleNamespace(
            targets=["missing"],
            technology=[],
            surface_property=[],
            available=[],
            raw=[],
        )
        report = analyze({}, args)
        self.assertEqual(report["unresolved"], ["missing"])

    def test_recipe_requires_an_executor(self) -> None:
        data = {
            "item": {
                "chemical-plant": {
                    "name": "chemical-plant",
                    "place_result": "chemical-plant",
                }
            },
            "recipe": {
                "make-fluid": {
                    "name": "make-fluid",
                    "enabled": True,
                    "category": "chemistry",
                    "ingredients": [],
                    "results": [{"type": "fluid", "name": "fluid", "amount": 1}],
                }
            },
            "assembling-machine": {
                "chemical-plant": {
                    "name": "chemical-plant",
                    "crafting_categories": ["chemistry"],
                    "minable": {"result": "chemical-plant"},
                }
            },
        }
        args = SimpleNamespace(
            targets=["fluid"],
            technology=[],
            surface_property=[],
            available=[],
            available_machine=[],
            raw=[],
        )

        self.assertEqual(analyze(data, args)["unresolved"], ["fluid"])

        args.available_machine = ["chemical-plant"]
        report = analyze(data, args)
        self.assertEqual(report["unresolved"], [])
        self.assertEqual(
            report["selected_recipes"][0]["provider"],
            "<available:chemical-plant>",
        )


if __name__ == "__main__":
    unittest.main()
