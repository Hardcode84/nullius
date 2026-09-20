"""Normalize supported Factorio prototype schemas at the analysis boundary."""

import math

from run_factorio_tests import TestFailure


def recipe_categories(recipe):
    """Return alternative executor categories, not a single preferred category."""
    if "categories" in recipe:
        if "category" in recipe or "additional_categories" in recipe:
            raise TestFailure("recipe mixes 2.0 and 2.1 category fields")
        values = recipe["categories"]
    else:
        additional = recipe.get("additional_categories", [])
        if not isinstance(additional, list):
            raise TestFailure("additional_categories must be a list of names")
        values = [recipe.get("category", "crafting"), *additional]
    if not isinstance(values, list) or not values or any(not isinstance(v, str) or not v for v in values):
        raise TestFailure("recipe categories must be a nonempty list of names")
    return tuple(dict.fromkeys(values))


def deterministic_product(entry):
    """Validate probability fields and report whether the product is certain."""
    if "probability" in entry and "independent_probability" in entry:
        raise TestFailure("product mixes probability and independent_probability")
    shared = entry.get("shared_probability", {"min": 0, "max": 1})
    if not isinstance(shared, dict) or set(shared) != {"min", "max"}:
        raise TestFailure("shared_probability must contain min and max")
    probability = entry.get("independent_probability", entry.get("probability", 1))
    for value in (probability, shared["min"], shared["max"]):
        if (isinstance(value, bool) or not isinstance(value, (int, float))
                or not math.isfinite(value) or not 0 <= value <= 1):
            raise TestFailure("product probability must be finite and between 0 and 1")
    if shared["min"] > shared["max"]:
        raise TestFailure("shared_probability min must not exceed max")
    return probability == 1 and shared == {"min": 0, "max": 1}
