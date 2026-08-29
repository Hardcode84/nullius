#!/usr/bin/env python3
"""Trace production prerequisites from Factorio's resolved prototypes."""

from __future__ import annotations

import argparse
from collections import defaultdict, deque
import json
import math
from pathlib import Path
import re
import shutil
import sys
import tempfile
from typing import Any

from run_factorio_tests import (
    TestFailure,
    default_dependency_mods,
    default_factorio,
    prepare_config,
    prepare_mods,
    run_factorio,
    tail,
)


Prototype = dict[str, Any]
IGNORED_RECIPE_CATEGORIES = {"recycling", "recycling-or-hand-crafting"}
NATURAL_MINABLE_PROTOTYPE_TYPES = {
    "fish",
    "resource",
    "simple-entity",
    "tree",
}

ENERGY_PREFIXES = {
    "": 1.0,
    "k": 1_000.0,
    "M": 1_000_000.0,
    "G": 1_000_000_000.0,
}


def parse_target(value: str) -> tuple[str, float]:
    if "=" not in value:
        return value, 1.0
    name, raw_count = value.rsplit("=", 1)
    try:
        count = float(raw_count)
    except ValueError as error:
        raise argparse.ArgumentTypeError("expected ITEM or ITEM=COUNT") from error
    if not name or not math.isfinite(count) or count <= 0:
        raise argparse.ArgumentTypeError("target count must be finite and positive")
    return name, count


def parse_name_assignment(value: str) -> tuple[str, str]:
    try:
        name, assigned = value.split("=", 1)
    except ValueError as error:
        raise argparse.ArgumentTypeError("expected NAME=VALUE") from error
    if not name or not assigned:
        raise argparse.ArgumentTypeError("expected nonempty NAME=VALUE")
    return name, assigned


def parse_energy(value: str | None, expected_unit: str) -> float | None:
    if value is None:
        return None
    match = re.fullmatch(r"([0-9]+(?:\.[0-9]+)?)([kMG]?)([JW])", value)
    if match is None or match.group(3) != expected_unit:
        raise TestFailure(f"unsupported energy value: {value}")
    return float(match.group(1)) * ENERGY_PREFIXES[match.group(2)]


def deterministic_amount(entry: Prototype) -> float:
    probability = float(entry.get("probability", 1))
    if probability != 1:
        raise TestFailure(
            f"probabilistic amount is not an exact contract: {entry['name']}"
        )
    if "amount" in entry:
        return float(entry["amount"])
    if entry.get("amount_min") == entry.get("amount_max"):
        return float(entry["amount_min"])
    raise TestFailure(f"ranged amount is not an exact contract: {entry['name']}")


def merge_prototype_overlay(data: Prototype, path: Path | None) -> None:
    if path is None:
        return
    overlay = json.loads(path.expanduser().resolve().read_text(encoding="utf-8"))
    if not isinstance(overlay, dict):
        raise TestFailure("prototype overlay root must be an object")
    for prototype_type, prototypes in overlay.items():
        if not isinstance(prototypes, dict):
            raise TestFailure(f"prototype overlay {prototype_type} must be an object")
        destination = data.setdefault(prototype_type, {})
        if not isinstance(destination, dict):
            raise TestFailure(f"resolved prototype type {prototype_type} is not an object")
        for prototype_name, prototype in prototypes.items():
            if prototype_name in destination:
                raise TestFailure(
                    f"prototype overlay refuses to replace existing {prototype_type} "
                    f"{prototype_name}"
                )
            if not isinstance(prototype, dict):
                raise TestFailure(
                    f"prototype overlay {prototype_type}.{prototype_name} must be an object"
                )
            destination[prototype_name] = prototype


def parse_assignment(value: str) -> tuple[str, float]:
    try:
        name, raw_number = value.split("=", 1)
        return name, float(raw_number)
    except ValueError as error:
        raise argparse.ArgumentTypeError("expected NAME=NUMBER") from error


def dump_resolved_data(args: argparse.Namespace) -> tuple[Prototype, Path | None]:
    if args.data_raw is not None:
        path = args.data_raw.expanduser().resolve()
        return json.loads(path.read_text(encoding="utf-8")), None

    run_directory = Path(tempfile.mkdtemp(prefix="factorio-prerequisites-"))
    try:
        factorio = args.factorio.expanduser().resolve()
        dependency_mods = args.dependency_mod_directory.expanduser().resolve()
        if not factorio.is_file():
            raise TestFailure(f"Factorio executable not found: {factorio}")
        if not dependency_mods.is_dir():
            raise TestFailure(
                f"dependency mod directory not found: {dependency_mods}"
            )
        for directory in ("saves", "script-output", "temp"):
            (run_directory / directory).mkdir(parents=True)
        config = prepare_config(run_directory, factorio)
        run_mods = run_directory / "mods"
        prepare_mods(run_mods, dependency_mods)
        log_path = run_directory / "dump.log"
        completed = run_factorio(
            [
                str(factorio),
                "--config",
                str(config),
                "--mod-directory",
                str(run_mods),
                "--disable-audio",
                "--dump-data",
            ],
            log_path,
            args.timeout_seconds,
        )
        if completed.returncode != 0:
            raise TestFailure(
                f"Factorio prototype dump exited {completed.returncode}\n"
                f"{tail(log_path)}"
            )
        dump_path = run_directory / "script-output" / "data-raw-dump.json"
        if not dump_path.is_file():
            raise TestFailure(f"Factorio did not create {dump_path}")
        return json.loads(dump_path.read_text(encoding="utf-8")), run_directory
    except BaseException:
        shutil.rmtree(run_directory, ignore_errors=True)
        raise


def recipe_results(recipe: Prototype) -> list[Prototype]:
    if recipe.get("results"):
        return recipe["results"]
    if recipe.get("result"):
        return [
            {
                "type": "item",
                "name": recipe["result"],
                "amount": recipe.get("result_count", 1),
            }
        ]
    return []


def recipe_primary_products(recipe: Prototype) -> list[str]:
    """Return products that may implicitly select this recipe as their route."""
    main_product = recipe.get("main_product")
    if main_product:
        return [main_product]
    results = recipe_results(recipe)
    if len(results) == 1:
        return [results[0]["name"]]
    return []


def describe_recipes(data: Prototype, names: list[str]) -> list[Prototype]:
    recipes: dict[str, Prototype] = data.get("recipe", {})
    unlockers: dict[str, list[str]] = defaultdict(list)
    for technology_name, technology in data.get("technology", {}).items():
        for effect in technology.get("effects") or []:
            if effect.get("type") == "unlock-recipe":
                unlockers[effect["recipe"]].append(technology_name)

    descriptions = []
    for name in names:
        recipe = recipes.get(name)
        if recipe is None:
            raise TestFailure(f"recipe prototype not found: {name}")
        descriptions.append(
            {
                "name": name,
                "enabled": bool(recipe.get("enabled")),
                "category": recipe.get("category", "crafting"),
                "energy_required": float(recipe.get("energy_required", 0.5)),
                "allow_productivity": bool(recipe.get("allow_productivity")),
                "maximum_productivity": recipe.get("maximum_productivity"),
                "ingredients": recipe.get("ingredients") or [],
                "results": recipe_results(recipe),
                "surface_conditions": recipe.get("surface_conditions") or [],
                "unlock_technologies": sorted(unlockers.get(name, [])),
            }
        )
    return descriptions


def describe_products(data: Prototype, names: list[str]) -> list[Prototype]:
    known_products: set[str] = set()
    for prototype_type in ("item", "fluid", "tool"):
        known_products.update(data.get(prototype_type, {}))
    producers: dict[str, list[str]] = defaultdict(list)
    for recipe_name, recipe in data.get("recipe", {}).items():
        for result in recipe_results(recipe):
            producers[result["name"]].append(recipe_name)
            known_products.add(result["name"])

    unknown = sorted(set(names) - known_products)
    if unknown:
        raise TestFailure(
            "product prototypes not found: " + ", ".join(unknown)
        )

    descriptions = []
    for name in names:
        recipe_names = sorted(producers.get(name, []))
        descriptions.append(
            {
                "name": name,
                "producers": describe_recipes(data, recipe_names),
            }
        )
    return descriptions


def describe_category_executors(data: Prototype, category: str) -> list[Prototype]:
    executors = []
    for prototype_type in ("assembling-machine", "furnace", "rocket-silo"):
        for name, machine in data.get(prototype_type, {}).items():
            if category not in (machine.get("crafting_categories") or []):
                continue
            energy_source = machine.get("energy_source") or {}
            executors.append(
                {
                    "kind": "machine",
                    "name": name,
                    "prototype_type": prototype_type,
                    "energy_source_type": energy_source.get("type"),
                }
            )
    for name, character in data.get("character", {}).items():
        if category in (character.get("crafting_categories") or []):
            executors.append(
                {
                    "kind": "character",
                    "name": name,
                    "prototype_type": "character",
                    "energy_source_type": None,
                }
            )
    return sorted(
        executors,
        key=lambda executor: (
            executor["kind"], executor["name"], executor["prototype_type"]
        ),
    )


def describe_consumers(data: Prototype, names: list[str]) -> list[Prototype]:
    known_products: set[str] = set()
    for prototype_type in ("item", "fluid", "tool"):
        known_products.update(data.get(prototype_type, {}))

    unknown = sorted(set(names) - known_products)
    if unknown:
        raise TestFailure(
            "product prototypes not found: " + ", ".join(unknown)
        )

    consumers: dict[str, list[str]] = defaultdict(list)
    for recipe_name, recipe in data.get("recipe", {}).items():
        for ingredient in recipe.get("ingredients") or []:
            if ingredient["name"] in known_products:
                consumers[ingredient["name"]].append(recipe_name)

    descriptions = []
    for name in names:
        recipe_names = sorted(set(consumers.get(name, [])))
        recipes = describe_recipes(data, recipe_names)
        for recipe in recipes:
            input_amount = sum(
                deterministic_amount(ingredient)
                for ingredient in recipe["ingredients"]
                if ingredient["name"] == name
            )
            returned_amount = sum(
                deterministic_amount(result)
                for result in recipe["results"]
                if result["name"] == name
            )
            recipe["input_amount"] = input_amount
            recipe["returned_amount"] = returned_amount
            recipe["net_consumption"] = input_amount - returned_amount
            recipe["executors"] = describe_category_executors(
                data, recipe["category"]
            )
            recipe["electricity_required"] = (
                all(
                    executor["energy_source_type"] == "electric"
                    for executor in recipe["executors"]
                )
                if recipe["executors"]
                else None
            )
        descriptions.append({"name": name, "consumers": recipes})
    return descriptions


def describe_technologies(data: Prototype, names: list[str]) -> list[Prototype]:
    technologies: dict[str, Prototype] = data.get("technology", {})
    descriptions = []
    for name in names:
        technology = technologies.get(name)
        if technology is None:
            raise TestFailure(f"technology prototype not found: {name}")
        descriptions.append(
            {
                "name": name,
                "prerequisites": sorted(technology.get("prerequisites") or []),
                "unit": technology.get("unit"),
                "research_trigger": technology.get("research_trigger"),
                "effects": technology.get("effects") or [],
                "max_level": technology.get("max_level"),
            }
        )
    return descriptions


def find_electric_required_paths(
    targets: list[str], selected_recipes: list[Prototype]
) -> list[Prototype]:
    """Find selected production steps that require an electric executor."""
    steps = {step["product"]: step for step in selected_recipes}
    matches: list[Prototype] = []

    for target in targets:
        pending = deque([(target, [])])
        visited: set[str] = set()
        while pending:
            product, path = pending.popleft()
            if product in visited:
                continue
            visited.add(product)
            step = steps.get(product)
            if step is None or step.get("producer", "").startswith("<spoil:"):
                continue
            executor = step.get("executor") or {}
            if (executor.get("energy_source") or {}).get("type") == "electric":
                matches.append(
                    {
                        "target": target,
                        "product": product,
                        "producer": step["producer"],
                        "executor": executor["name"],
                        "path": path,
                    }
                )
            dependencies = [
                ingredient["name"] for ingredient in step.get("ingredients", [])
            ]
            provider = step.get("provider")
            if provider and not provider.startswith("<"):
                dependencies.append(provider)
            for dependency in dependencies:
                pending.append(
                    (
                        dependency,
                        [
                            *path,
                            {
                                "product": product,
                                "producer": step["producer"],
                                "dependency": dependency,
                            },
                        ],
                    )
                )
    return matches


def minable_results(prototype: Prototype) -> list[Prototype]:
    minable = prototype.get("minable") or {}
    if minable.get("results"):
        return minable["results"]
    if minable.get("result"):
        return [{"type": "item", "name": minable["result"], "amount": 1}]
    return []


def allowed_on_surface(
    recipe: Prototype, surface_properties: dict[str, float]
) -> bool:
    for condition in recipe.get("surface_conditions") or []:
        value = surface_properties.get(condition["property"])
        if value is None:
            continue
        if value < condition.get("min", float("-inf")):
            return False
        if value > condition.get("max", float("inf")):
            return False
    return True


def technology_closure(
    technologies: dict[str, Prototype], names: set[str]
) -> set[str]:
    closure: set[str] = set()
    pending = list(names)
    while pending:
        name = pending.pop()
        if name in closure:
            continue
        closure.add(name)
        technology = technologies.get(name)
        if technology is not None:
            pending.extend(technology.get("prerequisites") or [])
    return closure


def find_dependency_paths(
    data: Prototype,
    args: argparse.Namespace,
    dependencies: list[str],
) -> Prototype:
    """Find shortest structural recipe paths from targets to dependencies."""
    recipes: dict[str, Prototype] = data.get("recipe", {})
    technologies: dict[str, Prototype] = data.get("technology", {})
    assumed_technologies = technology_closure(
        technologies, set(args.technology)
    )
    surface_properties = dict(args.surface_property)
    forbidden_categories = set(getattr(args, "forbid_category", []))
    recipe_categories = {
        recipe.get("category", "crafting") for recipe in recipes.values()
    }
    unknown_forbidden_categories = sorted(
        forbidden_categories - recipe_categories
    )
    if unknown_forbidden_categories:
        raise TestFailure(
            "unknown forbidden crafting categories: "
            + ", ".join(unknown_forbidden_categories)
        )

    unlockers: dict[str, list[str]] = defaultdict(list)
    for technology_name, technology in technologies.items():
        for effect in technology.get("effects") or []:
            if effect.get("type") == "unlock-recipe":
                unlockers[effect["recipe"]].append(technology_name)

    def available_at_boundary(recipe_name: str) -> bool:
        recipe = recipes[recipe_name]
        if recipe.get("enabled"):
            return True
        return any(
            technology_closure(technologies, {technology_name})
            <= assumed_technologies
            for technology_name in unlockers.get(recipe_name, [])
        )

    producers: dict[str, list[str]] = defaultdict(list)
    eligible_recipes: set[str] = set()
    known_products: set[str] = set()
    for prototype_type in ("item", "fluid", "tool"):
        known_products.update(data.get(prototype_type, {}))
    for recipe_name, recipe in recipes.items():
        for ingredient in recipe.get("ingredients") or []:
            known_products.add(ingredient["name"])
        for result in recipe_results(recipe):
            known_products.add(result["name"])
        category = recipe.get("category", "crafting")
        if (
            category in IGNORED_RECIPE_CATEGORIES
            or category in forbidden_categories
            or recipe.get("hidden")
            or not allowed_on_surface(recipe, surface_properties)
            or not available_at_boundary(recipe_name)
        ):
            continue
        eligible_recipes.add(recipe_name)
        for product in recipe_primary_products(recipe):
            producers[product].append(recipe_name)

    unknown_targets = sorted(set(args.targets) - known_products)
    if unknown_targets:
        raise TestFailure(
            "dependency query targets are unknown: " + ", ".join(unknown_targets)
        )
    unknown_dependencies = sorted(set(dependencies) - known_products)
    if unknown_dependencies:
        raise TestFailure(
            "dependency query products are unknown: "
            + ", ".join(unknown_dependencies)
        )

    recipe_overrides = dict(getattr(args, "recipe", []))
    for product, recipe_name in recipe_overrides.items():
        recipe = recipes.get(recipe_name)
        if recipe is None:
            raise TestFailure(
                f"dependency-query recipe does not exist: {recipe_name}"
            )
        if product not in {
            result["name"] for result in recipe_results(recipe)
        }:
            raise TestFailure(
                f"dependency-query recipe {recipe_name} does not produce {product}"
            )
        if recipe_name not in eligible_recipes:
            raise TestFailure(
                f"recipe {recipe_name} is not available for dependency-query "
                f"product {product} at the declared boundary"
            )
        if recipe_name not in producers[product]:
            producers[product].append(recipe_name)

    boundaries = set(getattr(args, "available", [])) | set(
        getattr(args, "raw", [])
    )
    edges: dict[str, list[Prototype]] = defaultdict(list)
    for product, candidate_names in producers.items():
        if product in boundaries:
            continue
        selected_names = candidate_names
        if product in recipe_overrides:
            selected_names = [recipe_overrides[product]]
        for recipe_name in selected_names:
            for ingredient in recipes[recipe_name].get("ingredients") or []:
                edges[product].append(
                    {
                        "product": product,
                        "producer": recipe_name,
                        "ingredient": ingredient["name"],
                    }
                )
        edges[product].sort(
            key=lambda edge: (edge["ingredient"], edge["producer"])
        )

    matches = []
    missing = []
    for target in args.targets:
        for dependency in dependencies:
            if target == dependency:
                matches.append(
                    {"target": target, "dependency": dependency, "path": []}
                )
                continue
            pending: deque[tuple[str, list[Prototype]]] = deque([(target, [])])
            visited = {target}
            match_path: list[Prototype] | None = None
            while pending and match_path is None:
                product, path = pending.popleft()
                for edge in edges.get(product, []):
                    next_product = edge["ingredient"]
                    next_path = [*path, edge]
                    if next_product == dependency:
                        match_path = next_path
                        break
                    if next_product not in visited:
                        visited.add(next_product)
                        pending.append((next_product, next_path))
            if match_path is None:
                missing.append({"target": target, "dependency": dependency})
            else:
                matches.append(
                    {
                        "target": target,
                        "dependency": dependency,
                        "path": match_path,
                    }
                )

    return {
        "targets": list(args.targets),
        "dependencies": list(dependencies),
        "assumed_technologies": sorted(assumed_technologies),
        "available": sorted(set(getattr(args, "available", []))),
        "raw": sorted(set(getattr(args, "raw", []))),
        "forbidden_categories": sorted(forbidden_categories),
        "matches": matches,
        "missing": missing,
    }


def analyze(data: Prototype, args: argparse.Namespace) -> Prototype:
    recipes: dict[str, Prototype] = data.get("recipe", {})
    technologies: dict[str, Prototype] = data.get("technology", {})
    assumed_technologies = technology_closure(
        technologies, set(args.technology)
    )
    surface_properties = dict(args.surface_property)
    forbidden_categories = set(getattr(args, "forbid_category", []))
    recipe_categories = {
        recipe.get("category", "crafting") for recipe in recipes.values()
    }
    unknown_forbidden_categories = sorted(
        forbidden_categories - recipe_categories
    )
    if unknown_forbidden_categories:
        raise TestFailure(
            "unknown forbidden crafting categories: "
            + ", ".join(unknown_forbidden_categories)
        )

    producers: dict[str, list[str]] = defaultdict(list)
    eligible_recipes: set[str] = set()
    unlockers: dict[str, list[str]] = defaultdict(list)
    extraction_sources: dict[str, list[str]] = defaultdict(list)
    machine_items: dict[str, list[str]] = defaultdict(list)
    category_machine_entities: dict[str, dict[str, list[tuple[str, str]]]] = (
        defaultdict(lambda: defaultdict(list))
    )

    for recipe_name, recipe in recipes.items():
        category = recipe.get("category", "crafting")
        if (
            category in IGNORED_RECIPE_CATEGORIES
            or category in forbidden_categories
        ):
            continue
        if recipe.get("hidden") or not allowed_on_surface(recipe, surface_properties):
            continue
        eligible_recipes.add(recipe_name)
        for result in recipe_results(recipe):
            producers[result["name"]].append(recipe_name)

    for technology_name, technology in technologies.items():
        for effect in technology.get("effects") or []:
            if effect.get("type") == "unlock-recipe":
                unlockers[effect["recipe"]].append(technology_name)

    def missing_technologies(recipe_name: str) -> set[str] | None:
        recipe = recipes[recipe_name]
        if recipe.get("enabled"):
            return set()
        choices = [
            technology_closure(technologies, {technology_name})
            - assumed_technologies
            for technology_name in unlockers.get(recipe_name, [])
        ]
        if not choices:
            return None
        return min(choices, key=lambda choice: (len(choice), sorted(choice)))

    for prototype_type in NATURAL_MINABLE_PROTOTYPE_TYPES:
        prototypes = data.get(prototype_type, {})
        for prototype_name, prototype in prototypes.items():
            if not isinstance(prototype, dict):
                continue
            for result in minable_results(prototype):
                extraction_sources[result["name"]].append(
                    f"{prototype_type}:{prototype_name}"
                )

    for prototypes in data.values():
        if not isinstance(prototypes, dict):
            continue
        for prototype_name, prototype in prototypes.items():
            if not isinstance(prototype, dict):
                continue
            place_result = prototype.get("place_result")
            if place_result:
                machine_items[place_result].append(prototype_name)

    for prototype_type in ("assembling-machine", "furnace", "rocket-silo"):
        for machine_name, machine in data.get(prototype_type, {}).items():
            for result in minable_results(machine):
                machine_items[machine_name].append(result["name"])

    category_machines: dict[str, list[str]] = defaultdict(list)
    for prototype_type in ("assembling-machine", "furnace", "rocket-silo"):
        for machine_name, machine in data.get(prototype_type, {}).items():
            for category in machine.get("crafting_categories") or []:
                items = machine_items.get(machine_name) or []
                for item_name in items:
                    category_machines[category].append(item_name)
                    category_machine_entities[category][item_name].append(
                        (prototype_type, machine_name)
                    )

    for lab_name in data.get("lab", {}):
        for item_name in machine_items.get(lab_name) or []:
            category_machines["<research>"].append(item_name)

    character_categories: dict[str, list[str]] = defaultdict(list)
    for character_name, character in data.get("character", {}).items():
        for category in character.get("crafting_categories") or []:
            character_categories[category].append(character_name)

    available = set(args.available)
    available_machines = set(getattr(args, "available_machine", []))
    executor_overrides = dict(getattr(args, "executor", []))
    recipe_overrides = dict(getattr(args, "recipe", []))
    machine_only_categories = set(getattr(args, "machine_category", []))
    raw = set(getattr(args, "raw", []))
    invalid_raw = sorted(raw - set(extraction_sources))
    pending = deque(args.targets)
    visited: set[str] = set()
    selected_recipes: dict[str, str] = {}
    alternatives: dict[str, list[str]] = {}
    raw_sources: dict[str, list[str]] = {}
    unresolved: list[str] = []
    categories: set[str] = set()
    required_technologies: set[str] = set()

    def executor_contract(category: str, provider_name: str) -> Prototype:
        if provider_name.startswith("<character:"):
            character_name = provider_name.removeprefix("<character:").removesuffix(
                ">"
            )
            character = data.get("character", {}).get(character_name, {})
            return {
                "kind": "character",
                "name": character_name,
                "crafting_speed": float(character.get("crafting_speed", 1)),
                "alternatives": sorted(
                    set(character_categories.get(category, []))
                ),
            }

        item_name = provider_name
        if provider_name.startswith("<available:"):
            item_name = provider_name.removeprefix("<available:").removesuffix(">")
        candidates = sorted(
            set(category_machine_entities.get(category, {}).get(item_name, [])),
            key=lambda candidate: (candidate[1] != item_name, candidate),
        )
        override = executor_overrides.get(category)
        if override is not None:
            matching = [candidate for candidate in candidates if candidate[1] == override]
            if not matching:
                rendered = ", ".join(name for _, name in candidates) or "none"
                raise TestFailure(
                    f"executor {override} cannot run {category} with item {item_name}; "
                    f"candidates: {rendered}"
                )
            selected_type, selected_name = matching[0]
        elif candidates:
            selected_type, selected_name = candidates[0]
        else:
            raise TestFailure(
                f"no entity executor for {category} with item {item_name}"
            )
        machine = data[selected_type][selected_name]
        energy_source = machine.get("energy_source") or {}
        return {
            "kind": "machine",
            "item": item_name,
            "prototype_type": selected_type,
            "name": selected_name,
            "crafting_speed": float(machine.get("crafting_speed", 1)),
            "energy_usage": machine.get("energy_usage"),
            "energy_source": {
                "type": energy_source.get("type"),
                "effectivity": float(energy_source.get("effectivity", 1)),
                "minimum_working_temperature": energy_source.get(
                    "min_working_temperature"
                ),
                "maximum_temperature": energy_source.get("max_temperature"),
            },
            "alternatives": [name for _, name in candidates],
            "explicit_override": override is not None,
        }

    spoil_sources: dict[str, list[str]] = defaultdict(list)
    for item_name, item in data.get("item", {}).items():
        if item.get("spoil_result"):
            spoil_sources[item["spoil_result"]].append(item_name)

    production_state: dict[str, tuple[frozenset[str], int]] = {
        product: (frozenset(), 0)
        for product in (set(available) | raw)
    }

    def state_key(state: tuple[frozenset[str], int]) -> tuple[int, int, list[str]]:
        technologies_needed, depth = state
        return len(technologies_needed), depth, sorted(technologies_needed)

    def best_provider(
        category: str,
        states: dict[str, tuple[frozenset[str], int]],
    ) -> tuple[str, tuple[frozenset[str], int]] | None:
        characters = sorted(set(character_categories.get(category, [])))
        if characters and category not in machine_only_categories:
            return f"<character:{characters[0]}>", (frozenset(), 0)
        candidates: list[tuple[str, tuple[frozenset[str], int]]] = []
        for item_name in sorted(set(category_machines.get(category, []))):
            if item_name in available_machines:
                candidates.append(
                    (f"<available:{item_name}>", (frozenset(), 0))
                )
            elif item_name in states:
                candidates.append((item_name, states[item_name]))
        if not candidates:
            return None
        return min(candidates, key=lambda candidate: state_key(candidate[1]))

    changed = True
    while changed:
        changed = False
        for result, sources in spoil_sources.items():
            for source in sources:
                if source not in production_state:
                    continue
                source_technologies, source_depth = production_state[source]
                candidate_state = (source_technologies, source_depth + 1)
                if result not in production_state or state_key(candidate_state) < state_key(
                    production_state[result]
                ):
                    production_state[result] = candidate_state
                    changed = True
        for recipe_name in eligible_recipes:
            recipe = recipes[recipe_name]
            recipe_technologies = missing_technologies(recipe_name)
            if recipe_technologies is None:
                continue
            ingredients = recipe.get("ingredients") or []
            if not all(
                ingredient["name"] in production_state
                for ingredient in ingredients
            ):
                continue
            provider = best_provider(
                recipe.get("category", "crafting"), production_state
            )
            if provider is None:
                continue
            ingredient_states = [
                production_state[ingredient["name"]] for ingredient in ingredients
            ]
            provider_state = provider[1]
            combined_technologies = frozenset(recipe_technologies).union(
                provider_state[0], *(state[0] for state in ingredient_states)
            )
            candidate_state = (
                combined_technologies,
                1 + max(
                    (state[1] for state in [provider_state, *ingredient_states]),
                    default=-1,
                ),
            )
            for result in recipe_results(recipe):
                product = result["name"]
                if product not in production_state or state_key(
                    candidate_state
                ) < state_key(production_state[product]):
                    production_state[product] = candidate_state
                    changed = True

    def recipe_score(
        recipe_name: str, product: str
    ) -> tuple[int, int, int, int, int, str]:
        recipe = recipes[recipe_name]
        technology_requirements = missing_technologies(recipe_name)
        product_state = production_state.get(product)
        ingredient_states = [
            production_state.get(ingredient["name"])
            for ingredient in recipe.get("ingredients") or []
        ]
        provider = best_provider(recipe.get("category", "crafting"), production_state)
        if technology_requirements is not None and all(
            state is not None for state in ingredient_states
        ) and provider is not None:
            provider_state = provider[1]
            candidate_technologies = frozenset(technology_requirements).union(
                provider_state[0],
                *(state[0] for state in ingredient_states if state is not None),
            )
            candidate_depth = 1 + max(
                (
                    state[1]
                    for state in [provider_state, *ingredient_states]
                    if state is not None
                ),
                default=-1,
            )
            candidate_state = (candidate_technologies, candidate_depth)
        else:
            candidate_state = None
        establishes_product = candidate_state == product_state
        return (
            0 if recipe_overrides.get(product) == recipe_name else 1,
            0 if establishes_product else 1,
            0 if recipe.get("enabled") else 1,
            state_key(candidate_state)[0]
            if candidate_state is not None
            else len(technologies) + 1,
            state_key(candidate_state)[1]
            if candidate_state is not None
            else len(recipes) + 1,
            recipe_name,
        )

    while pending:
        product = pending.popleft()
        if product in visited or product in available:
            continue
        visited.add(product)

        if product in raw:
            raw_sources[product] = sorted(set(extraction_sources[product]))
            continue

        candidates = sorted(
            set(producers.get(product, [])),
            key=lambda recipe_name: recipe_score(recipe_name, product),
        )
        requested_recipe = recipe_overrides.get(product)
        if requested_recipe is not None and requested_recipe not in candidates:
            rendered = ", ".join(candidates) or "none"
            raise TestFailure(
                f"recipe {requested_recipe} does not produce {product}; "
                f"candidates: {rendered}"
            )
        product_state = production_state.get(product)
        product_spoil_sources = sorted(
            source
            for source in spoil_sources.get(product, [])
            if source in production_state
            and product_state
            == (production_state[source][0], production_state[source][1] + 1)
        )
        recipe_establishes_product = bool(
            candidates and recipe_score(candidates[0], product)[1] == 0
        )
        if (
            product_spoil_sources
            and not recipe_establishes_product
            and requested_recipe is None
        ):
            source = product_spoil_sources[0]
            selected_recipes[product] = f"<spoil:{source}>"
            alternatives[product] = [
                f"<spoil:{name}>" for name in product_spoil_sources
            ] + candidates
            pending.append(source)
            continue
        if (
            not candidates
            or product not in production_state
            or missing_technologies(candidates[0]) is None
        ):
            if product_spoil_sources:
                source = product_spoil_sources[0]
                selected_recipes[product] = f"<spoil:{source}>"
                alternatives[product] = [
                    f"<spoil:{name}>" for name in product_spoil_sources
                ]
                pending.append(source)
            else:
                unresolved.append(product)
            continue

        recipe_name = candidates[0]
        recipe = recipes[recipe_name]
        provider = best_provider(recipe.get("category", "crafting"), production_state)
        if provider is None:
            unresolved.append(product)
            continue
        selected_recipes[product] = recipe_name
        alternatives[product] = candidates
        categories.add(recipe.get("category", "crafting"))
        for ingredient in recipe.get("ingredients") or []:
            pending.append(ingredient["name"])
        provider_name = provider[0]
        if not provider_name.startswith("<"):
            pending.append(provider_name)

        technology_requirements = missing_technologies(recipe_name)
        if technology_requirements:
            required_technologies.update(technology_requirements)

    selected = []
    for product, recipe_name in sorted(selected_recipes.items()):
        if recipe_name.startswith("<spoil:"):
            source = recipe_name.removeprefix("<spoil:").removesuffix(">")
            selected.append(
                {
                    "product": product,
                    "producer": recipe_name,
                    "category": "<spoil>",
                    "ingredients": [{"type": "item", "name": source}],
                    "results": [
                        {"type": "item", "name": product, "amount": 1}
                    ],
                    "spoil_ticks": data.get("item", {})
                    .get(source, {})
                    .get("spoil_ticks"),
                    "rank": production_state[product][1],
                    "alternatives": alternatives[product],
                }
            )
            continue
        recipe = recipes[recipe_name]
        provider_name = best_provider(
            recipe.get("category", "crafting"), production_state
        )[0]
        selected.append(
            {
                "product": product,
                "producer": recipe_name,
                "category": recipe.get("category", "crafting"),
                "provider": provider_name,
                "executor": executor_contract(
                    recipe.get("category", "crafting"), provider_name
                ),
                "ingredients": recipe.get("ingredients") or [],
                "results": recipe_results(recipe),
                "energy_required": float(recipe.get("energy_required", 0.5)),
                "rank": production_state[product][1],
                "unlock_technologies": sorted(unlockers.get(recipe_name, [])),
                "alternatives": alternatives[product],
            }
        )

    report = {
        "targets": args.targets,
        "assumed_technologies": sorted(assumed_technologies),
        "available": sorted(available),
        "available_machines": sorted(available_machines),
        "raw": sorted(raw),
        "forbidden_categories": sorted(forbidden_categories),
        "selected_recipes": selected,
        "required_technologies": sorted(required_technologies),
        "crafting_categories": {
            category: {
                "machine_items": sorted(
                    set(category_machines.get(category, []))
                ),
                "characters": sorted(
                    set(character_categories.get(category, []))
                ),
            }
            for category in sorted(categories)
        },
        "raw_sources": raw_sources,
        "invalid_raw": invalid_raw,
        "unresolved": sorted(set(unresolved)),
    }
    report["electric_required_paths"] = find_electric_required_paths(
        args.targets, selected
    )
    return report


def add_raw_bootstrap_for_execution(
    steps: list[Prototype],
    raw_inputs: dict[str, float],
    available_inputs: dict[str, float],
    initial_stock: dict[str, float],
    raw_products: set[str],
) -> dict[str, float]:
    ledger: dict[str, float] = defaultdict(float)
    for source in (raw_inputs, available_inputs, initial_stock):
        for name, amount in source.items():
            ledger[name] += amount
    remaining = [float(step["cycles"]) for step in steps]
    added: dict[str, float] = defaultdict(float)

    while any(amount > 1e-9 for amount in remaining):
        ready: list[int] = []
        for index in range(len(steps) - 1, -1, -1):
            if remaining[index] <= 1e-9:
                continue
            step = steps[index]
            atomic = bool(step.get("spoil_ticks"))
            divisor = 1 if atomic else float(step["cycles"])
            ingredients = [
                (ingredient["name"], float(ingredient["amount"]) / divisor)
                for ingredient in step["ingredients"]
            ]
            fuel = step.get("fuel")
            if fuel:
                ingredients.append((fuel["name"], float(fuel["amount_per_cycle"])))
            if any(ledger[name] + 1e-9 < amount for name, amount in ingredients):
                continue
            ready.append(index)

        if ready:
            selected = ready[0]
            step = steps[selected]
            atomic = bool(step.get("spoil_ticks"))
            divisor = 1 if atomic else float(step["cycles"])
            for ingredient in step["ingredients"]:
                ledger[ingredient["name"]] -= float(ingredient["amount"]) / divisor
            fuel = step.get("fuel")
            if fuel:
                ledger[fuel["name"]] -= float(fuel["amount_per_cycle"])
            for output in step["outputs"]:
                ledger[output["name"]] += float(output["amount"]) / divisor
            remaining[selected] = 0 if atomic else remaining[selected] - 1
            continue

        candidates: list[tuple[float, str]] = []
        for index, step in enumerate(steps):
            if remaining[index] <= 1e-9:
                continue
            divisor = 1 if step.get("spoil_ticks") else float(step["cycles"])
            for ingredient in step["ingredients"]:
                name = ingredient["name"]
                if name not in raw_products:
                    continue
                required = float(ingredient["amount"]) / divisor
                deficit = required - ledger[name]
                if deficit > 1e-9:
                    candidates.append((deficit, name))
        if not candidates:
            blocked = [
                steps[index]["producer"]
                for index, amount in enumerate(remaining)
                if amount > 1e-9
            ]
            raise TestFailure(
                "quantified production manifest is not executable; blocked steps: "
                + ", ".join(blocked)
            )
        deficit, name = min(candidates)
        ledger[name] += deficit
        raw_inputs[name] += deficit
        added[name] += deficit

    return dict(sorted(added.items()))


def build_production_manifest(
    data: Prototype,
    report: Prototype,
    target_quantities: dict[str, float],
    fuel_name: str | None,
    initial_stock: dict[str, float] | None = None,
) -> Prototype:
    if report["unresolved"] or report["invalid_raw"]:
        raise TestFailure("cannot quantify an unresolved prerequisite graph")

    steps_by_product = {
        step["product"]: step for step in report["selected_recipes"]
    }
    demands: dict[str, float] = defaultdict(float, target_quantities)
    for step in report["selected_recipes"]:
        provider = step.get("provider")
        if provider and not provider.startswith("<"):
            demands[provider] = max(demands[provider], 1)

    stock: dict[str, float] = defaultdict(float, initial_stock or {})
    deferred_surplus: dict[str, float] = defaultdict(float)
    raw_inputs: dict[str, float] = defaultdict(float)
    available_inputs: dict[str, float] = defaultdict(float)
    fuel_consumption: dict[str, float] = defaultdict(float)
    quantified_steps: list[Prototype] = []
    processed: set[str] = set()
    raw = set(report["raw"])
    available = set(report["available"])

    fuel_value = None
    fuel_dependency_products: set[str] = set()
    if fuel_name is not None:
        fuel = data.get("fluid", {}).get(fuel_name)
        if fuel is None:
            raise TestFailure(f"fuel fluid prototype not found: {fuel_name}")
        fuel_value = parse_energy(fuel.get("fuel_value"), "J")
        if not fuel_value:
            raise TestFailure(f"fluid has no positive fuel value: {fuel_name}")
        pending_fuel_products = [fuel_name]
        while pending_fuel_products:
            dependency = pending_fuel_products.pop()
            if dependency in fuel_dependency_products:
                continue
            fuel_dependency_products.add(dependency)
            dependency_step = steps_by_product.get(dependency)
            if dependency_step is None:
                continue
            pending_fuel_products.extend(
                ingredient["name"]
                for ingredient in dependency_step["ingredients"]
            )

    while demands:
        product = max(
            demands,
            key=lambda name: (
                name not in fuel_dependency_products,
                steps_by_product.get(name, {}).get("rank", 0),
                name,
            ),
        )
        requested = demands.pop(product)
        if requested <= 1e-9:
            continue
        if product in processed:
            raise TestFailure(
                f"production ordering reintroduced already processed product: {product}"
            )
        processed.add(product)

        from_stock = min(stock[product], requested)
        stock[product] -= from_stock
        required = requested - from_stock
        if required <= 1e-9:
            continue
        if product in raw:
            raw_inputs[product] += required
            continue
        if product in available:
            available_inputs[product] += required
            continue

        step = steps_by_product.get(product)
        if step is None:
            raise TestFailure(f"quantitative route has no producer for {product}")
        if step["category"] == "<spoil>":
            source = step["ingredients"][0]["name"]
            demands[source] += required
            quantified_steps.append(
                {
                    "product": product,
                    "producer": step["producer"],
                    "requested": requested,
                    "from_stock": from_stock,
                    "cycles": required,
                    "ingredients": [
                        {"type": "item", "name": source, "amount": required}
                    ],
                    "outputs": [
                        {"type": "item", "name": product, "amount": required}
                    ],
                    "spoil_ticks": step["spoil_ticks"],
                }
            )
            continue

        product_results = [
            result for result in step["results"] if result["name"] == product
        ]
        if not product_results:
            raise TestFailure(f"selected recipe does not produce {product}")
        output_per_cycle = sum(
            deterministic_amount(result) for result in product_results
        )
        if output_per_cycle <= 0:
            raise TestFailure(f"selected recipe has no positive output for {product}")

        executor = step["executor"]
        crafting_speed = float(executor["crafting_speed"])
        if crafting_speed <= 0:
            raise TestFailure(
                f"executor has nonpositive crafting speed: {executor['name']}"
            )
        seconds_per_cycle = float(step["energy_required"]) / crafting_speed
        ticks_per_cycle = math.ceil(seconds_per_cycle * 60 - 1e-12)
        energy_usage_watts = parse_energy(executor.get("energy_usage"), "W")
        energy_per_cycle_joules = (
            energy_usage_watts * seconds_per_cycle
            if energy_usage_watts is not None
            else None
        )
        energy_source = executor.get("energy_source") or {}
        fuel_per_cycle = None
        if energy_source.get("type") == "fluid":
            if fuel_name is None or fuel_value is None:
                raise TestFailure(
                    f"fluid-powered executor {executor['name']} requires --fuel"
                )
            effectivity = float(energy_source.get("effectivity", 1))
            if effectivity <= 0 or energy_per_cycle_joules is None:
                raise TestFailure(
                    f"cannot calculate fuel for executor {executor['name']}"
                )
            fuel_per_cycle = energy_per_cycle_joules / effectivity / fuel_value

        effective_output_per_cycle = output_per_cycle
        if product == fuel_name and fuel_per_cycle is not None:
            effective_output_per_cycle -= fuel_per_cycle
            if effective_output_per_cycle <= 0:
                raise TestFailure(
                    f"fuel recipe {step['producer']} does not power itself"
                )
        cycles = math.ceil((required / effective_output_per_cycle) - 1e-12)

        result_per_cycle: dict[str, float] = defaultdict(float)
        for result in step["results"]:
            result_per_cycle[result["name"]] += deterministic_amount(result)

        ingredients = []
        catalyst_products: set[str] = set()
        for ingredient in step["ingredients"]:
            amount_per_cycle = deterministic_amount(ingredient)
            amount = amount_per_cycle * cycles
            ingredients.append(
                {
                    "type": ingredient.get("type", "item"),
                    "name": ingredient["name"],
                    "amount": amount,
                }
            )
            returned_per_cycle = result_per_cycle.get(ingredient["name"], 0)
            if returned_per_cycle > 0:
                reusable = min(amount_per_cycle, returned_per_cycle)
                demands[ingredient["name"]] += (
                    amount - reusable * (cycles - 1)
                )
                deferred_surplus[ingredient["name"]] += (
                    returned_per_cycle * cycles - reusable * (cycles - 1)
                )
                catalyst_products.add(ingredient["name"])
            else:
                demands[ingredient["name"]] += amount

        outputs = []
        for result in step["results"]:
            amount = deterministic_amount(result) * cycles
            outputs.append(
                {
                    "type": result.get("type", "item"),
                    "name": result["name"],
                    "amount": amount,
                }
            )
            if result["name"] not in catalyst_products:
                stock[result["name"]] += amount
        stock[product] -= required
        if fuel_per_cycle is not None and fuel_name is not None:
            total_fuel = fuel_per_cycle * cycles
            fuel_consumption[fuel_name] += total_fuel
            if product == fuel_name:
                stock[product] -= total_fuel
            else:
                demands[fuel_name] += total_fuel

        quantified_steps.append(
            {
                "product": product,
                "producer": step["producer"],
                "requested": requested,
                "from_stock": from_stock,
                "cycles": cycles,
                "ingredients": ingredients,
                "outputs": outputs,
                "executor": executor,
                "seconds_per_cycle": seconds_per_cycle,
                "ticks_per_cycle": ticks_per_cycle,
                "total_ticks_single_executor": ticks_per_cycle * cycles,
                "energy_per_cycle_joules": energy_per_cycle_joules,
                "fuel": (
                    {
                        "name": fuel_name,
                        "amount_per_cycle": fuel_per_cycle,
                        "total_amount": fuel_per_cycle * cycles,
                    }
                    if fuel_per_cycle is not None
                    else None
                ),
                "heat": (
                    {
                        "minimum_working_temperature": energy_source.get(
                            "minimum_working_temperature"
                        ),
                        "maximum_temperature": energy_source.get(
                            "maximum_temperature"
                        ),
                        "energy_per_cycle_joules": energy_per_cycle_joules,
                    }
                    if energy_source.get("type") == "heat"
                    else None
                ),
            }
        )

    for name, amount in deferred_surplus.items():
        stock[name] += amount

    bootstrap_raw_inputs = add_raw_bootstrap_for_execution(
        quantified_steps,
        raw_inputs,
        available_inputs,
        initial_stock or {},
        raw,
    )
    for name, amount in bootstrap_raw_inputs.items():
        stock[name] += amount

    return {
        "targets": target_quantities,
        "initial_stock": dict(sorted((initial_stock or {}).items())),
        "steps": quantified_steps,
        "raw_inputs": dict(sorted(raw_inputs.items())),
        "bootstrap_raw_inputs": bootstrap_raw_inputs,
        "available_inputs": dict(sorted(available_inputs.items())),
        "fuel_consumption": dict(sorted(fuel_consumption.items())),
        "surplus": {
            name: amount
            for name, amount in sorted(stock.items())
            if amount > 1e-9
        },
    }


def print_human(report: Prototype) -> None:
    print("Targets: " + ", ".join(report["targets"]))
    forbidden = ", ".join(report["forbidden_categories"]) or "none"
    print("Forbidden crafting categories: " + forbidden)
    print(f"Selected production steps: {len(report['selected_recipes'])}")
    for step in report["selected_recipes"]:
        ingredients = ", ".join(
            ingredient["name"] for ingredient in step["ingredients"]
        ) or "none"
        print(
            f"  {step['product']} <- {step['producer']} "
            f"[{step['category']} via {step.get('provider', 'n/a')}] ({ingredients})"
        )

    print("\nCrafting categories:")
    for category, providers in report["crafting_categories"].items():
        machines = ", ".join(providers["machine_items"]) or "none"
        characters = ", ".join(providers["characters"]) or "none"
        print(f"  {category}: machines={machines}; characters={characters}")

    print("\nRequired technologies beyond assumptions:")
    for technology in report["required_technologies"]:
        print(f"  {technology}")
    if not report["required_technologies"]:
        print("  none")

    print("\nExtracted/raw boundaries:")
    for product, sources in sorted(report["raw_sources"].items()):
        print(f"  {product}: {', '.join(sources)}")
    if not report["raw_sources"]:
        print("  none")

    print("\nUnresolved products:")
    for product in report["unresolved"]:
        print(f"  {product}")
    if not report["unresolved"]:
        print("  none")

    print("\nInvalid declared raw products:")
    for product in report["invalid_raw"]:
        print(f"  {product}")
    if not report["invalid_raw"]:
        print("  none")

    print("\nElectric-required paths:")
    for match in report["electric_required_paths"]:
        chain = [match["target"]]
        chain.extend(edge["dependency"] for edge in match["path"])
        print(
            f"  {' -> '.join(chain)}: {match['producer']} "
            f"requires {match['executor']}"
        )
    if not report["electric_required_paths"]:
        print("  none")

    manifest = report.get("production_manifest")
    if manifest is not None:
        print("\nProduction manifest:")
        for step in manifest["steps"]:
            if "spoil_ticks" in step:
                print(
                    f"  {step['product']}: spoil {step['ingredients'][0]['amount']:g} "
                    f"{step['ingredients'][0]['name']} for {step['spoil_ticks']} ticks"
                )
                continue
            inputs = ", ".join(
                f"{entry['amount']:g} {entry['name']}"
                for entry in step["ingredients"]
            ) or "none"
            outputs = ", ".join(
                f"{entry['amount']:g} {entry['name']}"
                for entry in step["outputs"]
            ) or "none"
            fuel = step.get("fuel")
            fuel_text = (
                f"; fuel={fuel['total_amount']:g} {fuel['name']}"
                if fuel is not None
                else ""
            )
            heat = step.get("heat")
            heat_text = (
                "; heat="
                f"{heat['minimum_working_temperature']}.."
                f"{heat['maximum_temperature']} C, "
                f"{heat['energy_per_cycle_joules']:g} J/cycle"
                if heat is not None
                else ""
            )
            print(
                f"  {step['product']}: {step['cycles']} x {step['producer']} "
                f"on {step['executor']['name']} "
                f"({step['total_ticks_single_executor']} ticks); "
                f"inputs={inputs}; outputs={outputs}{fuel_text}{heat_text}"
            )
        for boundary in (
            "initial_stock",
            "raw_inputs",
            "available_inputs",
            "fuel_consumption",
            "surplus",
        ):
            values = ", ".join(
                f"{amount:g} {name}"
                for name, amount in manifest[boundary].items()
            ) or "none"
            print(f"  {boundary}: {values}")


def print_dependency_paths(report: Prototype) -> None:
    matches = {
        (match["target"], match["dependency"]): match
        for match in report["matches"]
    }
    print("Dependency paths:")
    for target in report["targets"]:
        for dependency in report["dependencies"]:
            match = matches.get((target, dependency))
            if match is None:
                print(f"  {target} -> {dependency}: no")
                continue
            print(f"  {target} -> {dependency}: yes")
            if not match["path"]:
                print(f"    {target} is {dependency}")
                continue
            for edge in match["path"]:
                print(
                    f"    {edge['product']} --{edge['producer']}--> "
                    f"{edge['ingredient']}"
                )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Trace item prerequisites through resolved Factorio prototypes.",
        fromfile_prefix_chars="@",
    )
    parser.add_argument(
        "targets", nargs="*", metavar="ITEM[=COUNT]", type=parse_target
    )
    parser.add_argument("--data-raw", type=Path)
    parser.add_argument(
        "--prototype-overlay",
        type=Path,
        help="add planned prototypes without replacing resolved prototypes",
    )
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument(
        "--dependency-mod-directory", type=Path, default=default_dependency_mods()
    )
    parser.add_argument("--timeout-seconds", type=int, default=300)
    parser.add_argument("--technology", action="append", default=[])
    parser.add_argument("--available", action="append", default=[])
    parser.add_argument(
        "--raw",
        action="append",
        default=[],
        help="item or fluid accepted from a natural minable prototype",
    )
    parser.add_argument(
        "--available-machine",
        action="append",
        default=[],
        help="machine item available for recipe execution but not as an item input",
    )
    parser.add_argument(
        "--executor",
        type=parse_name_assignment,
        action="append",
        default=[],
        metavar="CATEGORY=ENTITY",
        help="select the exact runtime entity for a crafting category",
    )
    parser.add_argument(
        "--recipe",
        type=parse_name_assignment,
        action="append",
        default=[],
        metavar="PRODUCT=RECIPE",
        help="select an exact producer when a product has multiple routes",
    )
    parser.add_argument(
        "--machine-category",
        action="append",
        default=[],
        metavar="CATEGORY",
        help="require a placeable machine even when a character can craft the category",
    )
    parser.add_argument(
        "--forbid-category",
        action="append",
        default=[],
        metavar="CATEGORY",
        help="exclude a crafting category unavailable at the campaign boundary",
    )
    parser.add_argument(
        "--fuel",
        help="fluid fuel used by fluid-powered executors in --manifest mode",
    )
    parser.add_argument(
        "--stock",
        type=parse_assignment,
        action="append",
        default=[],
        metavar="ITEM=COUNT",
        help="finite starting stock consumed before production is expanded",
    )
    parser.add_argument(
        "--manifest",
        action="store_true",
        help="calculate exact batches, inputs, outputs, ticks, fuel, and heat",
    )
    parser.add_argument(
        "--surface-property", type=parse_assignment, action="append", default=[]
    )
    parser.add_argument(
        "--require-no-additional-technologies",
        action="store_true",
        help="fail if the selected route needs technology outside --technology",
    )
    parser.add_argument(
        "--require-no-electricity",
        action="store_true",
        help="fail if any selected production step requires an electric executor",
    )
    parser.add_argument("--json", action="store_true", dest="json_output")
    parser.add_argument(
        "--describe-recipe",
        action="append",
        default=[],
        metavar="RECIPE",
        help="describe an exact resolved recipe prototype without tracing it",
    )
    parser.add_argument(
        "--describe-product",
        action="append",
        default=[],
        metavar="ITEM",
        help="describe every resolved recipe that produces an item or fluid",
    )
    parser.add_argument(
        "--describe-consumers",
        action="append",
        default=[],
        metavar="ITEM",
        help="describe every resolved recipe that consumes an item or fluid",
    )
    parser.add_argument(
        "--describe-technology",
        action="append",
        default=[],
        metavar="TECHNOLOGY",
        help="describe a resolved technology's prerequisites, cost, trigger, and effects",
    )
    parser.add_argument(
        "--find-dependency",
        action="append",
        default=[],
        metavar="ITEM",
        help=(
            "find shortest recursive ingredient paths from each target to ITEM "
            "using recipes available at the declared technology and surface boundary"
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    run_directory: Path | None = None
    try:
        data, run_directory = dump_resolved_data(args)
        merge_prototype_overlay(data, args.prototype_overlay)
        if (
            args.describe_recipe
            or args.describe_product
            or args.describe_consumers
            or args.describe_technology
        ):
            if args.targets:
                raise TestFailure(
                    "prototype inspection cannot be combined with prerequisite targets"
                )
            inspection_modes = sum(
                bool(values)
                for values in (
                    args.describe_recipe,
                    args.describe_product,
                    args.describe_consumers,
                    args.describe_technology,
                )
            )
            if inspection_modes != 1:
                raise TestFailure(
                    "choose exactly one prototype inspection mode"
                )
            if args.describe_recipe:
                descriptions = describe_recipes(data, args.describe_recipe)
            elif args.describe_product:
                descriptions = describe_products(data, args.describe_product)
            elif args.describe_consumers:
                descriptions = describe_consumers(data, args.describe_consumers)
            else:
                descriptions = describe_technologies(
                    data, args.describe_technology
                )
            if args.json_output:
                print(json.dumps(descriptions, indent=2, sort_keys=True))
            elif args.describe_technology:
                for technology in descriptions:
                    prerequisites = ", ".join(technology["prerequisites"])
                    print(f"{technology['name']}:")
                    print(f"  prerequisites: {prerequisites or 'none'}")
                    print(
                        "  unit: "
                        + json.dumps(technology["unit"], sort_keys=True)
                    )
                    print(
                        "  research_trigger: "
                        + json.dumps(
                            technology["research_trigger"], sort_keys=True
                        )
                    )
                    print(
                        "  effects: "
                        + json.dumps(technology["effects"], sort_keys=True)
                    )
            elif args.describe_product or args.describe_consumers:
                for product in descriptions:
                    print(f"{product['name']}:")
                    recipes = product.get("producers", product.get("consumers", []))
                    if not recipes:
                        label = "producers" if args.describe_product else "consumers"
                        print(f"  {label}: none")
                    for recipe in recipes:
                        print(
                            f"  {recipe['name']}: {recipe['energy_required']:g}s "
                            f"[{recipe['category']}]"
                        )
                        if args.describe_consumers:
                            print(
                                f"    consumption: {recipe['input_amount']:g} in, "
                                f"{recipe['returned_amount']:g} returned, "
                                f"{recipe['net_consumption']:g} net"
                            )
                            executors = ", ".join(
                                f"{executor['name']}"
                                f"[{executor['energy_source_type'] or executor['kind']}]"
                                for executor in recipe["executors"]
                            )
                            print(f"    executors: {executors or 'none'}")
                            print(
                                "    electricity_required: "
                                + (
                                    "unknown"
                                    if recipe["electricity_required"] is None
                                    else str(recipe["electricity_required"]).lower()
                                )
                            )
                        print(
                            "    inputs: "
                            + ", ".join(
                                f"{entry.get('amount', 1):g} {entry['name']}"
                                for entry in recipe["ingredients"]
                            )
                        )
                        print(
                            "    outputs: "
                            + ", ".join(
                                f"{entry.get('amount', 1):g} {entry['name']}"
                                for entry in recipe["results"]
                            )
                        )
                        unlocks = ", ".join(recipe["unlock_technologies"])
                        print(f"    unlocks: {unlocks or 'enabled'}")
            else:
                for recipe in descriptions:
                    print(
                        f"{recipe['name']}: {recipe['energy_required']:g}s "
                        f"[{recipe['category']}]"
                    )
                    print(
                        "  inputs: "
                        + ", ".join(
                            f"{entry.get('amount', 1):g} {entry['name']}"
                            for entry in recipe["ingredients"]
                        )
                    )
                    print(
                        "  outputs: "
                        + ", ".join(
                            f"{entry.get('amount', 1):g} {entry['name']}"
                            for entry in recipe["results"]
                        )
                    )
            return 0
        if not args.targets:
            raise TestFailure(
                "provide at least one prerequisite target or prototype inspection"
            )
        target_quantities: dict[str, float] = defaultdict(float)
        target_names: list[str] = []
        for target_name, target_count in args.targets:
            if target_name not in target_quantities:
                target_names.append(target_name)
            target_quantities[target_name] += target_count
        if args.manifest and args.fuel and args.fuel not in target_names:
            target_names.append(args.fuel)
        args.targets = target_names
        if args.find_dependency:
            report = find_dependency_paths(data, args, args.find_dependency)
            if args.json_output:
                print(json.dumps(report, indent=2, sort_keys=True))
            else:
                print_dependency_paths(report)
            return 0
        report = analyze(data, args)
        if args.manifest:
            initial_stock: dict[str, float] = defaultdict(float)
            for stock_name, stock_count in args.stock:
                if not math.isfinite(stock_count) or stock_count <= 0:
                    raise TestFailure(
                        f"initial stock must be finite and positive: {stock_name}"
                    )
                initial_stock[stock_name] += stock_count
            report["production_manifest"] = build_production_manifest(
                data,
                report,
                dict(target_quantities),
                args.fuel,
                dict(initial_stock),
            )
        if args.json_output:
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            print_human(report)
        failed_technology_contract = (
            args.require_no_additional_technologies
            and bool(report["required_technologies"])
        )
        failed_electricity_contract = (
            args.require_no_electricity
            and bool(report["electric_required_paths"])
        )
        return (
            1
            if report["unresolved"]
            or report["invalid_raw"]
            or failed_technology_contract
            or failed_electricity_contract
            else 0
        )
    except (TestFailure, OSError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    finally:
        if run_directory is not None:
            shutil.rmtree(run_directory)


if __name__ == "__main__":
    raise SystemExit(main())
