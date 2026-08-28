#!/usr/bin/env python3
"""Unit tests for the resolved-prototype prerequisite analyzer."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))

from analyze_factorio_prereqs import (
    TestFailure,
    analyze,
    build_production_manifest,
    merge_prototype_overlay,
    parse_target,
)


class AnalyzePrerequisitesTest(unittest.TestCase):
    def test_selects_renewable_route_and_reports_technology_and_machine(self) -> None:
        data = {
            "item": {
                "target": {"name": "target"},
                "ore": {"name": "ore"},
                "catalyst": {"name": "catalyst"},
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

    def test_quantifies_batches_byproducts_ticks_and_fluid_fuel(self) -> None:
        data = {
            "item": {
                "ore": {"name": "ore"},
                "machine-item": {
                    "name": "machine-item",
                    "place_result": "machine-fluid",
                },
            },
            "fluid": {"fuel": {"name": "fuel", "fuel_value": "10kJ"}},
            "recipe": {
                "make-product": {
                    "name": "make-product",
                    "enabled": True,
                    "category": "chemistry",
                    "energy_required": 2,
                    "ingredients": [
                        {"type": "item", "name": "ore", "amount": 2},
                        {"type": "item", "name": "catalyst", "amount": 1},
                    ],
                    "results": [
                        {"type": "item", "name": "product", "amount": 2},
                        {"type": "item", "name": "byproduct", "amount": 1},
                        {"type": "item", "name": "catalyst", "amount": 1},
                    ],
                }
            },
            "simple-entity": {
                "ore-rock": {
                    "name": "ore-rock",
                    "minable": {"result": "ore"},
                },
                "catalyst-rock": {
                    "name": "catalyst-rock",
                    "minable": {"result": "catalyst"},
                },
            },
            "assembling-machine": {
                "machine-fluid": {
                    "name": "machine-fluid",
                    "crafting_categories": ["chemistry"],
                    "crafting_speed": 1,
                    "energy_usage": "100kW",
                    "energy_source": {"type": "fluid", "effectivity": 1},
                    "minable": {"result": "machine-item"},
                }
            },
        }
        args = SimpleNamespace(
            targets=["product"],
            technology=[],
            surface_property=[],
            available=["fuel"],
            available_machine=["machine-item"],
            executor=[("chemistry", "machine-fluid")],
            raw=["ore", "catalyst"],
        )

        report = analyze(data, args)
        manifest = build_production_manifest(
            data, report, {"product": 3}, "fuel"
        )

        self.assertEqual(manifest["raw_inputs"], {"catalyst": 1, "ore": 4})
        self.assertEqual(manifest["fuel_consumption"], {"fuel": 40})
        self.assertEqual(manifest["available_inputs"], {"fuel": 40})
        self.assertEqual(
            manifest["surplus"],
            {"byproduct": 2, "catalyst": 1, "product": 1},
        )
        step = manifest["steps"][0]
        self.assertEqual(step["cycles"], 2)
        self.assertEqual(step["ticks_per_cycle"], 120)
        self.assertEqual(step["total_ticks_single_executor"], 240)
        self.assertEqual(step["fuel"]["amount_per_cycle"], 20)

    def test_fuel_recipe_is_quantified_by_net_output(self) -> None:
        data = {
            "item": {
                "hydro": {"name": "hydro", "place_result": "hydro-fluid"},
                "lava": {"name": "lava"},
            },
            "fluid": {"gas": {"name": "gas", "fuel_value": "20kJ"}},
            "recipe": {
                "extract-gas": {
                    "name": "extract-gas",
                    "enabled": True,
                    "category": "treatment",
                    "energy_required": 2,
                    "ingredients": [
                        {"type": "item", "name": "lava", "amount": 50}
                    ],
                    "results": [
                        {"type": "fluid", "name": "gas", "amount": 60}
                    ],
                }
            },
            "simple-entity": {
                "lava-source": {
                    "name": "lava-source",
                    "minable": {"result": "lava"},
                }
            },
            "assembling-machine": {
                "hydro-fluid": {
                    "name": "hydro-fluid",
                    "crafting_categories": ["treatment"],
                    "crafting_speed": 1,
                    "energy_usage": "240kW",
                    "energy_source": {"type": "fluid"},
                    "minable": {"result": "hydro"},
                }
            },
        }
        args = SimpleNamespace(
            targets=["gas"],
            technology=[],
            surface_property=[],
            available=[],
            available_machine=["hydro"],
            executor=[("treatment", "hydro-fluid")],
            raw=["lava"],
        )

        report = analyze(data, args)
        manifest = build_production_manifest(data, report, {"gas": 40}, "gas")

        self.assertEqual(manifest["raw_inputs"], {"lava": 100})
        self.assertEqual(manifest["fuel_consumption"], {"gas": 48})
        self.assertEqual(manifest["surplus"], {"gas": 32})
        self.assertEqual(manifest["steps"][0]["cycles"], 2)

        primed = build_production_manifest(
            data, report, {"gas": 40}, "gas", {"gas": 24}
        )
        self.assertEqual(primed["initial_stock"], {"gas": 24})
        self.assertEqual(primed["raw_inputs"], {"lava": 50})
        self.assertEqual(primed["fuel_consumption"], {"gas": 24})
        self.assertEqual(primed["surplus"], {"gas": 20})
        self.assertEqual(primed["steps"][0]["cycles"], 1)

    def test_recipe_override_selects_the_declared_route(self) -> None:
        data = {
            "item": {
                "ore-a": {"name": "ore-a"},
                "ore-b": {"name": "ore-b"},
            },
            "recipe": {
                "route-a": {
                    "name": "route-a",
                    "enabled": True,
                    "ingredients": [{"name": "ore-a", "amount": 1}],
                    "results": [{"name": "product", "amount": 1}],
                },
                "route-b": {
                    "name": "route-b",
                    "enabled": True,
                    "ingredients": [{"name": "ore-b", "amount": 1}],
                    "results": [{"name": "product", "amount": 1}],
                },
            },
            "simple-entity": {
                "rock-a": {"minable": {"result": "ore-a"}},
                "rock-b": {"minable": {"result": "ore-b"}},
            },
            "character": {
                "character": {"crafting_categories": ["crafting"]},
            },
        }
        args = SimpleNamespace(
            targets=["product"],
            technology=[],
            surface_property=[],
            available=[],
            available_machine=[],
            recipe=[("product", "route-b")],
            raw=["ore-a", "ore-b"],
        )

        report = analyze(data, args)

        self.assertEqual(report["unresolved"], [])
        self.assertEqual(report["selected_recipes"][0]["producer"], "route-b")
        self.assertEqual(report["raw_sources"], {"ore-b": ["simple-entity:rock-b"]})

    def test_forbidden_category_excludes_impossible_machine_mode(self) -> None:
        data = {
            "item": {
                "intake": {"name": "intake", "place_result": "seawater-intake"},
            },
            "recipe": {
                "seawater": {
                    "name": "seawater",
                    "enabled": True,
                    "category": "seawater-pumping",
                    "ingredients": [],
                    "results": [{"name": "seawater", "amount": 1}],
                },
                "lava": {
                    "name": "lava",
                    "enabled": True,
                    "category": "lava-pumping",
                    "ingredients": [],
                    "results": [{"name": "lava", "amount": 1}],
                },
                "a-normal-pack": {
                    "name": "a-normal-pack",
                    "enabled": True,
                    "ingredients": [{"name": "seawater", "amount": 1}],
                    "results": [{"name": "pack", "amount": 1}],
                },
                "b-volcanic-pack": {
                    "name": "b-volcanic-pack",
                    "enabled": True,
                    "ingredients": [{"name": "lava", "amount": 1}],
                    "results": [{"name": "pack", "amount": 1}],
                },
            },
            "assembling-machine": {
                "seawater-intake": {
                    "name": "seawater-intake",
                    "crafting_categories": ["seawater-pumping"],
                    "minable": {"result": "intake"},
                },
                "lava-intake": {
                    "name": "lava-intake",
                    "crafting_categories": ["lava-pumping"],
                    "minable": {"result": "intake"},
                },
            },
            "character": {
                "character": {"crafting_categories": ["crafting"]},
            },
        }
        args = SimpleNamespace(
            targets=["pack"],
            technology=[],
            surface_property=[],
            available=[],
            available_machine=["intake"],
            raw=[],
            forbid_category=["seawater-pumping"],
        )

        report = analyze(data, args)

        self.assertEqual(report["unresolved"], [])
        self.assertEqual(report["forbidden_categories"], ["seawater-pumping"])
        selected = {
            step["product"]: step["producer"]
            for step in report["selected_recipes"]
        }
        self.assertEqual(selected["pack"], "b-volcanic-pack")
        self.assertEqual(selected["lava"], "lava")
        self.assertNotIn("seawater", selected)

        args.forbid_category = ["typo-pumping"]
        with self.assertRaisesRegex(
            TestFailure, "unknown forbidden crafting categories: typo-pumping"
        ):
            analyze(data, args)

    def test_target_counts_and_overlay_fail_closed(self) -> None:
        self.assertEqual(parse_target("item"), ("item", 1))
        self.assertEqual(parse_target("item=2.5"), ("item", 2.5))

        data = {"item": {"existing": {"name": "existing"}}}
        overlay = self.create_temp_file(
            '{"item": {"added": {"name": "added"}}}'
        )
        merge_prototype_overlay(data, overlay)
        self.assertIn("added", data["item"])

        replacement = self.create_temp_file(
            '{"item": {"existing": {"name": "replacement"}}}'
        )
        with self.assertRaisesRegex(TestFailure, "refuses to replace"):
            merge_prototype_overlay(data, replacement)

    def create_temp_file(self, contents: str) -> Path:
        handle = tempfile.NamedTemporaryFile(mode="w", delete=False)
        self.addCleanup(Path(handle.name).unlink, missing_ok=True)
        with handle:
            handle.write(contents)
        return Path(handle.name)


if __name__ == "__main__":
    unittest.main()
