#!/usr/bin/env python3
"""Unit tests for the Factorio-backed prototype locale audit."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from check_factorio_locale import (
    LocaleEntry,
    audit_locale,
    collect_locale_references,
    default_locale_key,
    prototype_type_domains,
    parse_locale_catalog,
    recipe_uses_product_name,
    requires_resolved_name,
    resolved_prototype_tables,
    visible_in_ui,
)


class CheckFactorioLocaleTest(unittest.TestCase):
    def test_parses_catalogue_with_locations(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            locale = Path(temporary)
            path = locale / "items.cfg"
            path.write_text(
                "root=Root\n; comment\n[item-name]\nnullius-a=Alpha\n",
                encoding="utf-8",
            )

            entries = parse_locale_catalog(locale)

        self.assertEqual(entries["item-name.nullius-a"].path, path)
        self.assertEqual(entries["root"].line, 1)
        self.assertEqual(entries["item-name.nullius-a"].line, 4)

    def test_collects_nested_localised_string_keys(self) -> None:
        references = collect_locale_references(
            {
                "localised_name": [
                    "",
                    ["item-name.nullius-a"],
                    " ",
                    ["recipe-name.nullius-format", ["fluid-name.nullius-water"]],
                ]
            }
        )

        self.assertEqual(
            set(references),
            {
                "item-name.nullius-a",
                "recipe-name.nullius-format",
                "fluid-name.nullius-water",
            },
        )

    def test_discards_non_prototype_tables(self) -> None:
        tables = resolved_prototype_tables(
            {
                "item": {
                    "nullius-a": {
                        "type": "item",
                        "name": "nullius-a",
                    }
                },
                "utility-constants": {"default": {"type": "utility-constants"}},
            }
        )

        self.assertEqual(set(tables), {"item"})

    def test_recipe_name_follows_factorio_product_rules(self) -> None:
        same_product = {
            "results": [{"type": "item", "name": "nullius-a", "amount": 1}]
        }
        alternate_product = {
            "results": [{"type": "item", "name": "nullius-a", "amount": 1}]
        }
        self.assertTrue(recipe_uses_product_name("nullius-a", same_product))
        self.assertFalse(
            requires_resolved_name("nullius-a", same_product, "recipe")
        )
        self.assertFalse(
            recipe_uses_product_name("nullius-a-vulcanus", alternate_product)
        )
        self.assertTrue(
            requires_resolved_name(
                "nullius-a-vulcanus", alternate_product, "recipe"
            )
        )
        self.assertTrue(
            requires_resolved_name(
                "nullius-a",
                {"main_product": "", "results": same_product["results"]},
                "recipe",
            )
        )
        self.assertFalse(
            requires_resolved_name(
                "nullius-a",
                {
                    "main_product": "nullius-a",
                    "results": [
                        {"name": "nullius-a"},
                        {"name": "nullius-byproduct"},
                    ],
                },
                "recipe",
            )
        )
        self.assertTrue(
            requires_resolved_name(
                "nullius-a",
                {"results": [{"name": "a"}, {"name": "b"}]},
                "recipe",
            )
        )
        self.assertTrue(
            requires_resolved_name(
                "nullius-a",
                {"localised_name": ["recipe-name.nullius-a"]},
                "recipe",
            )
        )
        self.assertTrue(requires_resolved_name("nullius-a", {}, "item"))

    def test_disabled_technology_is_not_visible(self) -> None:
        self.assertFalse(visible_in_ui({"enabled": False}, "technology"))
        self.assertTrue(visible_in_ui({"enabled": False}, "recipe"))

    def test_numbered_technology_uses_base_locale_key(self) -> None:
        self.assertEqual(
            default_locale_key(
                "technology-name",
                "nullius-actuation-3",
                "technology",
            ),
            "technology-name.nullius-actuation",
        )
        self.assertEqual(
            default_locale_key(
                "technology-name",
                "nullius-example-3",
                "technology",
            ),
            "technology-name.nullius-example",
        )

    def test_maps_factorio_prototype_inheritance_to_locale_domains(self) -> None:
        self.assertEqual(
            prototype_type_domains(
                {
                    "prototypes": [
                        {
                            "name": "EntityPrototype",
                            "parent": "Prototype",
                            "abstract": True,
                        },
                        {
                            "name": "MachinePrototype",
                            "typename": "machine",
                            "parent": "EntityPrototype",
                        },
                        {
                            "name": "RecipePrototype",
                            "typename": "recipe",
                            "parent": "Prototype",
                        },
                        {
                            "name": "CustomInputPrototype",
                            "typename": "custom-input",
                            "parent": "Prototype",
                        },
                    ]
                }
            ),
            {
                "machine": "entity",
                "recipe": "recipe",
                "bool-setting": "mod-setting",
                "double-setting": "mod-setting",
                "int-setting": "mod-setting",
                "string-setting": "mod-setting",
            },
        )

    def test_reports_missing_and_unused_entries(self) -> None:
        data_raw = {
            "item": {
                "nullius-good": {
                    "type": "item",
                    "name": "nullius-good",
                },
                "nullius-explicit": {
                    "type": "item",
                    "name": "nullius-explicit",
                    "localised_name": ["item-name.nullius-missing-key"],
                },
                "nullius-format": {
                    "type": "item",
                    "name": "nullius-format",
                    "localised_name": ["nullius.missing-format"],
                },
                "nullius-missing-prototype": {
                    "type": "item",
                    "name": "nullius-missing-prototype",
                },
            },
            "recipe": {
                "nullius-same-product": {
                    "type": "recipe",
                    "name": "nullius-same-product",
                    "results": [{"name": "nullius-same-product"}],
                },
                "nullius-alternate": {
                    "type": "recipe",
                    "name": "nullius-alternate",
                    "results": [{"name": "nullius-same-product"}],
                },
            },
        }
        dumps = {
            domain: {"names": {}, "descriptions": {}}
            for domain in __import__("check_factorio_locale").LOCALE_DOMAINS
        }
        dumps["item"]["names"] = {
            "nullius-good": "Good",
            "nullius-explicit": "Explicit",
            "nullius-format": "Format",
        }
        catalog = {
            "item-name.nullius-good": LocaleEntry(
                "item-name.nullius-good", Path("item.cfg"), 1
            ),
            "item-name.nullius-unused": LocaleEntry(
                "item-name.nullius-unused", Path("item.cfg"), 2
            ),
        }

        report = audit_locale(
            data_raw,
            dumps,
            catalog,
            "nullius-",
            {"item": "item", "recipe": "recipe"},
        )

        self.assertEqual(
            report["missing_prototypes"],
            [
                {
                    "prototype_type": "item",
                    "name": "nullius-missing-prototype",
                    "domain": "item",
                },
                {
                    "prototype_type": "recipe",
                    "name": "nullius-alternate",
                    "domain": "recipe",
                },
            ],
        )
        self.assertEqual(
            [entry["key"] for entry in report["missing_keys"]],
            ["item-name.nullius-missing-key", "nullius.missing-format"],
        )
        self.assertEqual(
            [entry["key"] for entry in report["unused_keys"]],
            ["item-name.nullius-unused"],
        )


if __name__ == "__main__":
    unittest.main()
