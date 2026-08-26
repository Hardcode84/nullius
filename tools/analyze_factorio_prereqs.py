#!/usr/bin/env python3
"""Trace production prerequisites from Factorio's resolved prototypes."""

from __future__ import annotations

import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
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


def analyze(data: Prototype, args: argparse.Namespace) -> Prototype:
    recipes: dict[str, Prototype] = data.get("recipe", {})
    technologies: dict[str, Prototype] = data.get("technology", {})
    assumed_technologies = technology_closure(
        technologies, set(args.technology)
    )
    surface_properties = dict(args.surface_property)

    producers: dict[str, list[str]] = defaultdict(list)
    eligible_recipes: set[str] = set()
    unlockers: dict[str, list[str]] = defaultdict(list)
    extraction_sources: dict[str, list[str]] = defaultdict(list)
    machine_items: dict[str, list[str]] = defaultdict(list)

    for recipe_name, recipe in recipes.items():
        if recipe.get("category", "crafting") in IGNORED_RECIPE_CATEGORIES:
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

    for lab_name in data.get("lab", {}):
        for item_name in machine_items.get(lab_name) or []:
            category_machines["<research>"].append(item_name)

    character_categories: dict[str, list[str]] = defaultdict(list)
    for character_name, character in data.get("character", {}).items():
        for category in character.get("crafting_categories") or []:
            character_categories[category].append(character_name)

    available = set(args.available)
    available_machines = set(getattr(args, "available_machine", []))
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
        if characters:
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
    ) -> tuple[int, int, int, int, str]:
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
        product_state = production_state.get(product)
        product_spoil_sources = sorted(
            source
            for source in spoil_sources.get(product, [])
            if source in production_state
            and product_state
            == (production_state[source][0], production_state[source][1] + 1)
        )
        recipe_establishes_product = bool(
            candidates and recipe_score(candidates[0], product)[0] == 0
        )
        if product_spoil_sources and not recipe_establishes_product:
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
                    "alternatives": alternatives[product],
                }
            )
            continue
        recipe = recipes[recipe_name]
        selected.append(
            {
                "product": product,
                "producer": recipe_name,
                "category": recipe.get("category", "crafting"),
                "provider": best_provider(
                    recipe.get("category", "crafting"), production_state
                )[0],
                "ingredients": recipe.get("ingredients") or [],
                "unlock_technologies": sorted(unlockers.get(recipe_name, [])),
                "alternatives": alternatives[product],
            }
        )

    return {
        "targets": args.targets,
        "assumed_technologies": sorted(assumed_technologies),
        "available": sorted(available),
        "available_machines": sorted(available_machines),
        "raw": sorted(raw),
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


def print_human(report: Prototype) -> None:
    print("Targets: " + ", ".join(report["targets"]))
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


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Trace item prerequisites through resolved Factorio prototypes."
    )
    parser.add_argument("targets", nargs="+", metavar="ITEM")
    parser.add_argument("--data-raw", type=Path)
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
        "--surface-property", type=parse_assignment, action="append", default=[]
    )
    parser.add_argument(
        "--require-no-additional-technologies",
        action="store_true",
        help="fail if the selected route needs technology outside --technology",
    )
    parser.add_argument("--json", action="store_true", dest="json_output")
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    run_directory: Path | None = None
    try:
        data, run_directory = dump_resolved_data(args)
        report = analyze(data, args)
        if args.json_output:
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            print_human(report)
        failed_technology_contract = (
            args.require_no_additional_technologies
            and bool(report["required_technologies"])
        )
        return (
            1
            if report["unresolved"]
            or report["invalid_raw"]
            or failed_technology_contract
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
