#!/usr/bin/env python3
"""Unit tests for resolved recipe UI comparison."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from audit_recipe_ui import boxed_counterpart, compare_recipe_sets, ui_neighbors


def recipe(
    name: str,
    *,
    group: str = "intermediate-products",
    subgroup: str = "fluid",
    order: str = "a",
    category: str = "chemistry",
    products: tuple[str, ...] = (),
    hidden: bool = False,
) -> dict[str, object]:
    return {
        "name": name,
        "group": group,
        "subgroup": subgroup,
        "order": order,
        "category": category,
        "additional_categories": [],
        "products": [{"name": product, "type": "item"} for product in products],
        "main_product": products[0] if len(products) == 1 else None,
        "enabled": False,
        "hidden": hidden,
        "hidden_from_player_crafting": False,
        "unlock_technologies": ["technology"],
    }


class AuditRecipeUiTest(unittest.TestCase):
    def test_pairs_boxed_and_unboxed_recipes(self) -> None:
        recipes = {
            "nullius-resin": recipe("nullius-resin"),
            "nullius-box-resin": recipe("nullius-box-resin"),
        }
        self.assertEqual(
            boxed_counterpart("nullius-resin", recipes), "nullius-box-resin"
        )
        self.assertEqual(
            boxed_counterpart("nullius-box-resin", recipes), "nullius-resin"
        )

    def test_reports_added_recipe_with_existing_product_route(self) -> None:
        base = {
            "nullius-resin": recipe(
                "nullius-resin", order="b", products=("nullius-resin",)
            )
        }
        head = dict(base)
        head["nullius-hot-resin"] = recipe(
            "nullius-hot-resin", order="c", products=("nullius-resin",)
        )

        report = compare_recipe_sets(base, head)

        self.assertEqual(report["added_recipe_count"], 1)
        added = report["added_recipes"][0]
        self.assertEqual(added["name"], "nullius-hot-resin")
        self.assertEqual(
            [candidate["name"] for candidate in added["existing_product_recipes"]],
            ["nullius-resin"],
        )
        self.assertEqual(report["placements"][0]["subgroup"], "fluid")
        self.assertTrue(added["ui_placement_consistent"])

    def test_flags_main_product_ui_mismatch(self) -> None:
        base = {
            "nullius-explosive": recipe(
                "nullius-explosive",
                group="equipment",
                subgroup="demolitions",
                products=("cliff-explosives",),
            )
        }
        head = dict(base)
        head["nullius-thermite"] = recipe(
            "nullius-thermite",
            group="intermediate-products",
            subgroup="concrete",
            products=("cliff-explosives",),
        )

        added = compare_recipe_sets(base, head)["added_recipes"][0]

        self.assertFalse(added["ui_placement_consistent"])
        self.assertEqual(
            added["expected_ui_placements"],
            [{"group": "equipment", "subgroup": "demolitions"}],
        )
        self.assertEqual(
            added["review_reasons"],
            ["differs-from-existing-product-route"],
        )

    def test_flags_fallback_group_and_new_product_for_review(self) -> None:
        added = compare_recipe_sets(
            {},
            {
                "radiator": recipe(
                    "radiator",
                    group="other",
                    subgroup="other",
                    products=("radiator",),
                )
            },
        )["added_recipes"][0]

        self.assertEqual(
            added["review_reasons"],
            ["fallback-group:other", "new-product-without-reference-route"],
        )

    def test_excludes_hidden_recipes_by_default(self) -> None:
        hidden = recipe("hidden", hidden=True)
        self.assertEqual(
            compare_recipe_sets({}, {"hidden": hidden})["added_recipe_count"], 0
        )
        self.assertEqual(
            compare_recipe_sets({}, {"hidden": hidden}, include_hidden=True)[
                "added_recipe_count"
            ],
            1,
        )

    def test_neighbors_follow_resolved_ui_order(self) -> None:
        existing = {
            "first": recipe("first", order="a"),
            "second": recipe("second", order="c"),
            "other": recipe("other", subgroup="solid", order="b"),
        }
        target = recipe("target", order="b")

        self.assertEqual(
            [entry["name"] for entry in ui_neighbors(target, existing)],
            ["first", "second"],
        )


if __name__ == "__main__":
    unittest.main()
