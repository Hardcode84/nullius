#!/usr/bin/env python3
"""Compare resolved Factorio recipe UI placement between two mod revisions."""

from __future__ import annotations

import argparse
from collections import defaultdict
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
from typing import Any

from run_factorio_tests import (
    BUILTIN_MODS,
    DEPENDENCY_MODS,
    TestFailure,
    default_dependency_mods,
    default_factorio,
    find_archive,
    prepare_config,
    run_factorio,
    tail,
)


REPOSITORY = Path(__file__).resolve().parents[1]
DEFAULT_HEAD_MOD = REPOSITORY / "nullius-star"
AUDIT_MOD_NAME = "recipe-ui-audit-support"
AUDIT_RESULT = "recipe-ui-audit.json"

Recipe = dict[str, Any]
RecipeMap = dict[str, Recipe]


AUDIT_CONTROL = r'''
local RESULT = "recipe-ui-audit.json"

local function product_list(recipe)
  local result = {}
  for _, product in pairs(recipe.products) do
    result[#result + 1] = {name = product.name, type = product.type}
  end
  table.sort(result, function(a, b)
    if a.type == b.type then return a.name < b.name end
    return a.type < b.type
  end)
  return result
end

local function unlock_map()
  local result = {}
  for technology_name, technology in pairs(prototypes.technology) do
    for _, effect in pairs(technology.effects) do
      if effect.type == "unlock-recipe" then
        local recipes = result[effect.recipe]
        if not recipes then
          recipes = {}
          result[effect.recipe] = recipes
        end
        recipes[#recipes + 1] = technology_name
      end
    end
  end
  for _, technologies in pairs(result) do table.sort(technologies) end
  return result
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local unlocks = unlock_map()
  local recipes = {}
  for name, recipe in pairs(prototypes.recipe) do
    recipes[name] = {
      name = name,
      group = recipe.group.name,
      subgroup = recipe.subgroup.name,
      order = recipe.order,
      category = recipe.category,
      additional_categories = recipe.additional_categories,
      products = product_list(recipe),
      main_product = recipe.main_product and recipe.main_product.name or nil,
      enabled = recipe.enabled,
      hidden = recipe.hidden,
      hidden_from_player_crafting = recipe.hidden_from_player_crafting,
      unlock_technologies = unlocks[name] or {},
    }
  end
  helpers.write_file(RESULT, helpers.table_to_json({
    schema = 1,
    factorio_version = script.active_mods.base,
    recipes = recipes,
  }), false)
end)
'''


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare runtime-resolved recipe UI groups, subgroups, order, "
            "crafting categories, products, and technology unlocks."
        )
    )
    parser.add_argument("--base-ref", required=True)
    parser.add_argument("--base-mod-path", default="nullius-star")
    parser.add_argument("--head-mod", type=Path, default=DEFAULT_HEAD_MOD)
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument(
        "--dependency-mod-directory",
        type=Path,
        default=default_dependency_mods(),
    )
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--include-hidden", action="store_true")
    parser.add_argument("--json", action="store_true", dest="json_output")
    parser.add_argument(
        "--detail-recipe",
        action="append",
        default=[],
        metavar="NAME",
        help="show comparison routes and UI neighbors for an added recipe",
    )
    parser.add_argument(
        "--details-only",
        action="store_true",
        help="omit placement and added-recipe listings; requires --detail-recipe",
    )
    return parser.parse_args()


def extract_git_directory(ref: str, source: str, destination: Path) -> Path:
    completed = subprocess.run(
        ["git", "archive", "--format=tar", ref, source],
        cwd=REPOSITORY,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise TestFailure(
            f"git archive failed for {ref}:{source}: "
            f"{completed.stderr.decode('utf-8', errors='replace').strip()}"
        )
    with tarfile.open(fileobj=io.BytesIO(completed.stdout), mode="r:") as archive:
        archive.extractall(destination, filter="data")
    extracted = destination / source
    if not (extracted / "info.json").is_file():
        raise TestFailure(f"archived mod has no info.json: {ref}:{source}")
    return extracted


def read_mod_name(mod_directory: Path) -> str:
    info_path = mod_directory / "info.json"
    try:
        info = json.loads(info_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise TestFailure(f"cannot read mod metadata {info_path}: {error}") from error
    name = info.get("name")
    if not isinstance(name, str) or not name:
        raise TestFailure(f"mod metadata has no valid name: {info_path}")
    return name


def write_audit_support(mods: Path, subject_mod: str) -> None:
    support = mods / AUDIT_MOD_NAME
    scenario = support / "scenarios" / "audit"
    scenario.mkdir(parents=True)
    (support / "info.json").write_text(
        json.dumps(
            {
                "name": AUDIT_MOD_NAME,
                "version": "1.0.0",
                "factorio_version": "2.0",
                "title": "Recipe UI audit support",
                "author": "Nullius Star test harness",
                "dependencies": ["base >= 2.0.73", subject_mod],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    (scenario / "control.lua").write_text(AUDIT_CONTROL, encoding="utf-8")


def prepare_audit_mods(
    mods: Path, dependency_mods: Path, subject_directory: Path
) -> str:
    mods.mkdir(parents=True)
    enabled = list(BUILTIN_MODS)
    for dependency in DEPENDENCY_MODS:
        archive = find_archive(dependency_mods, dependency)
        (mods / archive.name).symlink_to(archive)
        enabled.append(dependency)

    subject_name = read_mod_name(subject_directory)
    (mods / subject_name).symlink_to(subject_directory.resolve(), target_is_directory=True)
    enabled.append(subject_name)
    write_audit_support(mods, subject_name)
    enabled.append(AUDIT_MOD_NAME)
    (mods / "mod-list.json").write_text(
        json.dumps(
            {"mods": [{"name": name, "enabled": True} for name in enabled]},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return subject_name


def resolve_recipes(
    label: str,
    mod_directory: Path,
    factorio: Path,
    dependency_mods: Path,
    timeout_seconds: int,
) -> tuple[RecipeMap, str]:
    run_directory = Path(tempfile.mkdtemp(prefix=f"recipe-ui-audit-{label}-"))
    try:
        for directory in ("saves", "script-output", "temp"):
            (run_directory / directory).mkdir(parents=True)
        config = prepare_config(run_directory, factorio)
        mods = run_directory / "mods"
        prepare_audit_mods(mods, dependency_mods, mod_directory)
        common = [
            str(factorio),
            "--config",
            str(config),
            "--mod-directory",
            str(mods),
            "--disable-audio",
        ]
        compile_log = run_directory / "compile.log"
        compiled = run_factorio(
            [*common, "--scenario2map", f"{AUDIT_MOD_NAME}/audit"],
            compile_log,
            timeout_seconds,
        )
        if compiled.returncode != 0:
            raise TestFailure(
                f"{label} audit scenario compilation exited {compiled.returncode}\n"
                f"{tail(compile_log)}"
            )
        save = run_directory / "saves" / AUDIT_MOD_NAME / "audit.zip"
        if not save.is_file():
            raise TestFailure(f"{label} audit did not create {save}")

        run_log = run_directory / "run.log"
        executed = run_factorio(
            [*common, "--load-game", str(save), "--until-tick", "2"],
            run_log,
            timeout_seconds,
        )
        result_path = run_directory / "script-output" / AUDIT_RESULT
        if executed.returncode != 0 or not result_path.is_file():
            raise TestFailure(
                f"{label} audit execution exited {executed.returncode}\n"
                f"{tail(run_log)}"
            )
        report = json.loads(result_path.read_text(encoding="utf-8"))
        if report.get("schema") != 1 or not isinstance(report.get("recipes"), dict):
            raise TestFailure(f"{label} audit returned an invalid report")
        return report["recipes"], report["factorio_version"]
    finally:
        shutil.rmtree(run_directory, ignore_errors=True)


def boxed_counterpart(name: str, recipes: RecipeMap) -> str | None:
    box_prefix = "nullius-box-"
    ordinary_prefix = "nullius-"
    if name.startswith(box_prefix):
        candidate = ordinary_prefix + name[len(box_prefix) :]
    elif name.startswith(ordinary_prefix):
        candidate = box_prefix + name[len(ordinary_prefix) :]
    else:
        return None
    return candidate if candidate in recipes else None


def product_names(recipe: Recipe) -> set[str]:
    return {product["name"] for product in recipe["products"]}


def reference_products(recipe: Recipe) -> set[str]:
    main_product = recipe.get("main_product")
    if main_product:
        return {main_product}
    products = product_names(recipe)
    return products if len(products) == 1 else set()


def compact_recipe(recipe: Recipe) -> Recipe:
    return {
        key: recipe[key]
        for key in (
            "name",
            "group",
            "subgroup",
            "order",
            "category",
            "products",
        )
    }


def ui_neighbors(recipe: Recipe, existing: RecipeMap, radius: int = 2) -> list[Recipe]:
    peers = sorted(
        (
            candidate
            for candidate in existing.values()
            if candidate["group"] == recipe["group"]
            and candidate["subgroup"] == recipe["subgroup"]
            and not candidate["hidden"]
        ),
        key=lambda candidate: (candidate["order"], candidate["name"]),
    )
    insertion_key = (recipe["order"], recipe["name"])
    index = 0
    while index < len(peers) and (
        peers[index]["order"], peers[index]["name"]
    ) < insertion_key:
        index += 1
    return [
        compact_recipe(candidate)
        for candidate in peers[max(0, index - radius) : index + radius]
    ]


def compare_recipe_sets(
    base: RecipeMap,
    head: RecipeMap,
    include_hidden: bool = False,
) -> dict[str, Any]:
    added_names = sorted(set(head) - set(base))
    removed_names = sorted(set(base) - set(head))
    existing = {name: head[name] for name in set(head).intersection(base)}
    records = []
    for name in added_names:
        recipe = head[name]
        if not include_hidden and recipe["hidden"]:
            continue
        products = product_names(recipe)
        references = reference_products(recipe)
        same_products = sorted(
            (
                candidate
                for candidate in existing.values()
                if products.intersection(product_names(candidate))
            ),
            key=lambda candidate: candidate["name"],
        )
        reference_routes = [
            candidate
            for candidate in same_products
            if references.intersection(product_names(candidate))
        ]
        expected_placements = sorted(
            {
                (candidate["group"], candidate["subgroup"])
                for candidate in reference_routes
            }
        )
        expected_categories = sorted(
            {candidate["category"] for candidate in reference_routes}
        )
        record = dict(recipe)
        record["boxed_counterpart"] = boxed_counterpart(name, head)
        record["existing_product_recipes"] = [
            compact_recipe(candidate) for candidate in same_products
        ]
        record["reference_products"] = sorted(references)
        record["expected_ui_placements"] = [
            {"group": group, "subgroup": subgroup}
            for group, subgroup in expected_placements
        ]
        record["ui_placement_consistent"] = (
            not expected_placements
            or (recipe["group"], recipe["subgroup"]) in expected_placements
        )
        record["existing_crafting_categories"] = expected_categories
        record["ui_neighbors"] = ui_neighbors(recipe, existing)
        review_reasons = []
        if not record["ui_placement_consistent"]:
            review_reasons.append("differs-from-existing-product-route")
        if recipe["group"] in {"other", "unused"}:
            review_reasons.append(f"fallback-group:{recipe['group']}")
        if not reference_routes:
            review_reasons.append("new-product-without-reference-route")
        record["review_reasons"] = review_reasons
        records.append(record)

    counts: dict[tuple[str, str], int] = defaultdict(int)
    for recipe in records:
        counts[(recipe["group"], recipe["subgroup"])] += 1
    placements = [
        {"group": group, "subgroup": subgroup, "count": count}
        for (group, subgroup), count in sorted(counts.items())
    ]
    return {
        "schema": 1,
        "base_recipe_count": len(base),
        "head_recipe_count": len(head),
        "added_recipe_count": len(records),
        "removed_recipes": removed_names,
        "placements": placements,
        "added_recipes": records,
    }


def render_recipe_detail(recipe: Recipe) -> None:
    print(f"\nDetail: {recipe['name']}")
    print(
        f"  placement: {recipe['group']}/{recipe['subgroup']} "
        f"order={recipe['order']} craft={recipe['category']}"
    )
    print(f"  reference products: {','.join(recipe['reference_products']) or '-'}")
    print("  existing product routes:")
    if not recipe["existing_product_recipes"]:
        print("    -")
    for candidate in recipe["existing_product_recipes"]:
        print(
            f"    {candidate['name']} | "
            f"{candidate['group']}/{candidate['subgroup']} | "
            f"order={candidate['order']} | craft={candidate['category']}"
        )
    print("  resolved UI neighbors:")
    if not recipe["ui_neighbors"]:
        print("    -")
    for candidate in recipe["ui_neighbors"]:
        print(
            f"    {candidate['name']} | order={candidate['order']} | "
            f"craft={candidate['category']}"
        )


def render_human(
    report: dict[str, Any], detail_recipes: list[str] | None = None,
    details_only: bool = False,
) -> None:
    print(
        f"Resolved recipes: {report['base_recipe_count']} base, "
        f"{report['head_recipe_count']} head, "
        f"{report['added_recipe_count']} added"
    )
    if not details_only:
        print("\nUI placements:")
        for placement in report["placements"]:
            print(
                f"  {placement['group']}/{placement['subgroup']}: "
                f"{placement['count']}"
            )
        print("\nAdded recipes:")
        for recipe in report["added_recipes"]:
            unlocks = ",".join(recipe["unlock_technologies"]) or "enabled"
            products = ",".join(product["name"] for product in recipe["products"])
            print(
                f"  {recipe['name']} | {recipe['group']}/{recipe['subgroup']} | "
                f"order={recipe['order']} | craft={recipe['category']} | "
                f"products={products or '-'} | unlock={unlocks}"
            )
    mismatches = [
        recipe
        for recipe in report["added_recipes"]
        if not recipe["ui_placement_consistent"]
    ]
    if not details_only:
        print(f"\nUI placement mismatches: {len(mismatches)}")
        for recipe in mismatches:
            expected = ",".join(
                f"{placement['group']}/{placement['subgroup']}"
                for placement in recipe["expected_ui_placements"]
            )
            print(
                f"  {recipe['name']}: {recipe['group']}/{recipe['subgroup']} "
                f"-> {expected}"
            )
        review = [
            recipe for recipe in report["added_recipes"] if recipe["review_reasons"]
        ]
        print(f"\nManual review candidates: {len(review)}")
        for recipe in review:
            print(
                f"  {recipe['name']} | {recipe['group']}/{recipe['subgroup']} | "
                f"{','.join(recipe['review_reasons'])}"
            )

    records = {recipe["name"]: recipe for recipe in report["added_recipes"]}
    for name in detail_recipes or []:
        recipe = records.get(name)
        if recipe is None:
            raise TestFailure(f"added recipe not found in report: {name}")
        render_recipe_detail(recipe)


def main() -> int:
    args = parse_arguments()
    archive_root: Path | None = None
    try:
        factorio = args.factorio.expanduser().resolve()
        dependency_mods = args.dependency_mod_directory.expanduser().resolve()
        head_mod = args.head_mod.expanduser().resolve()
        if not factorio.is_file():
            raise TestFailure(f"Factorio executable not found: {factorio}")
        if not dependency_mods.is_dir():
            raise TestFailure(f"dependency mod directory not found: {dependency_mods}")
        if not (head_mod / "info.json").is_file():
            raise TestFailure(f"head mod directory not found: {head_mod}")
        if args.details_only and not args.detail_recipe:
            raise TestFailure("--details-only requires --detail-recipe")

        archive_root = Path(tempfile.mkdtemp(prefix="recipe-ui-audit-base-source-"))
        base_mod = extract_git_directory(
            args.base_ref, args.base_mod_path, archive_root
        )
        base, base_factorio = resolve_recipes(
            "base", base_mod, factorio, dependency_mods, args.timeout_seconds
        )
        head, head_factorio = resolve_recipes(
            "head", head_mod, factorio, dependency_mods, args.timeout_seconds
        )
        if base_factorio != head_factorio:
            raise TestFailure(
                f"Factorio versions differ: base {base_factorio}, head {head_factorio}"
            )
        report = compare_recipe_sets(base, head, args.include_hidden)
        report["base_ref"] = args.base_ref
        report["base_mod_path"] = args.base_mod_path
        report["head_mod"] = str(head_mod)
        report["factorio_version"] = head_factorio
        if args.json_output:
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            render_human(report, args.detail_recipe, args.details_only)
        return 0
    except (TestFailure, OSError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    finally:
        if archive_root is not None:
            shutil.rmtree(archive_root, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
