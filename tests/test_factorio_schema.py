"""Contracts shared by both Factorio prototype schemas."""
import copy
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from factorio_schema import recipe_categories, deterministic_product, TestFailure
from analyze_factorio_prereqs import analyze, deterministic_amount
from plan_factorio_factory import amount, recipe_catalog, fluid_ports_fit


class SchemaTests(unittest.TestCase):
    def test_category_forms(self):
        self.assertEqual(recipe_categories({}), ("crafting",))
        for recipe in ({"category": "a", "additional_categories": ["b", "a"]},
                       {"categories": ["a", "b", "a"]}):
            self.assertEqual(recipe_categories(recipe), ("a", "b"))
        for recipe in ({"categories": []}, {"categories": "a"},
                       {"categories": ["a"], "category": "a"},
                       {"additional_categories": None}):
            with self.assertRaises(TestFailure):
                recipe_categories(recipe)

    def test_exact_and_guaranteed_probability(self):
        for fields in ({}, {"probability": 1}, {"independent_probability": 1},
                       {"shared_probability": {"min": 0, "max": 1}}):
            product = dict(name="p", amount=2, **fields)
            self.assertTrue(deterministic_product(product))
            self.assertEqual(deterministic_amount(product), 2)
        for fields in ({"probability": .5}, {"independent_probability": .5},
                       {"shared_probability": {"min": .25, "max": .75}}):
            product = dict(name="p", amount=2, **fields)
            with self.assertRaises(TestFailure):
                deterministic_amount(product)
            with self.assertRaises(TestFailure):
                amount(product, "exact")
            self.assertEqual(amount(product, "guaranteed"), 0)
        for fields in ({"shared_probability": .5}, {"independent_probability": float("nan")},
                       {"probability": 1, "independent_probability": 1},
                       {"shared_probability": {"min": .8, "max": .2}}):
            with self.assertRaises(TestFailure):
                deterministic_product(fields)

    def test_alternative_executor_and_forbidden_category(self):
        data = {"item": {"m": {"name": "m", "place_result": "m"}}, "technology": {},
                "fluid": {"gas": {"fuel_value": "1MJ"}},
                "assembling-machine": {"m": {"name": "m", "type": "assembling-machine",
                    "crafting_categories": ["a", "b"], "crafting_speed": 1,
                    "minable": {"result": "m"}, "energy_source": {"type": "void"}}},
                "recipe": {"make-p": {"name": "make-p", "ingredients": [{"name": "raw", "amount": 1}],
                                      "results": [{"name": "p", "amount": 2}]}}}
        args = SimpleNamespace(targets=["p"], technology=[], surface_property=[],
                               available=[], available_machine=["m"], raw=["raw"],
                               forbid_category=["a"])
        boundary = {"technologies": [], "surface": {}, "fuel": "gas", "machines": ["m"],
                    "forbid_categories": ["a"], "uncertain_outputs": "exact",
                    "heat_contract": {"MAX_HEAT": 500}, "extractors": {}}
        for categories in ({"category": "a", "additional_categories": ["b"]},
                           {"categories": ["a", "b"]}):
            fixture = copy.deepcopy(data)
            fixture["recipe"]["make-p"].update(categories)
            report = analyze(fixture, args)
            self.assertEqual(report["unresolved"], [])
            self.assertEqual(report["selected_recipes"][0]["category"], "b")
            rows, _, _ = recipe_catalog(fixture, boundary)
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["category"], "b")
            unrestricted = dict(boundary, forbid_categories=[])
            self.assertEqual(len(recipe_catalog(fixture, unrestricted)[0]), 1)

    def test_optional_fluid_ports_reserve_existing_indexes(self):
        machine = {"fluid_boxes": [{"production_type": "input"}, {"production_type": "input"}]}
        water = {"type": "fluid", "name": "water", "amount": 1, "fluidbox_index": 1,
                 "optional_fluidbox_indexes": [2, 99]}
        self.assertTrue(fluid_ports_fit({"ingredients": [water]}, machine))
        self.assertFalse(fluid_ports_fit({"ingredients": [water,
            {"type": "fluid", "name": "oil", "amount": 1}]}, machine))


if __name__ == "__main__":
    unittest.main()
