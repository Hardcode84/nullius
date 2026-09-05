#!/usr/bin/env python3
"""Audit declared Vulcanus stages against one resolved prototype snapshot."""
from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools import analyze_factorio_prereqs as prereqs
TestFailure = prereqs.TestFailure


def research_cost(data, roots, entrance):
    technologies = data["technology"]
    initial = prereqs.technology_closure(technologies, set(entrance))
    required = prereqs.technology_closure(technologies, set(roots)) - initial
    packs = defaultdict(float)
    tokens = defaultdict(float)
    lab_seconds = 0
    rows = []
    errors = []
    for name in sorted(required):
        technology = technologies[name]
        unit = technology.get("unit")
        row = {"name": name, "trigger": technology.get("research_trigger"), "packs": {}}
        if unit:
            count = unit.get("count")
            if not isinstance(count, (int, float)) or count < 0:
                errors.append({"technology": name, "unit": unit})
            else:
                for ingredient in unit["ingredients"]:
                    amount = count * ingredient[1]
                    target = tokens if ingredient[0] == "nullius-checkpoint" or ingredient[0].startswith("nullius-requirement-") else packs
                    target[ingredient[0]] += amount
                    row["packs"][ingredient[0]] = amount
                row["lab_seconds_at_speed_one"] = count * unit["time"]
                if any(name in packs for name in row["packs"]):
                    lab_seconds += row["lab_seconds_at_speed_one"]
        rows.append(row)
    return {"technology_count": len(required), "packs": dict(packs),
            "lab_hours_at_speed_one": lab_seconds / 3600, "checkpoint_tokens": dict(tokens),
            "unquantified": errors, "technologies": rows,
            "checkpoint_technologies": [r["name"] for r in rows if r["name"].startswith("nullius-checkpoint-")],
            "physics_pack_consumers": [r["name"] for r in rows if r["packs"].get("nullius-physics-pack")]}


def pre_physics_technologies(technologies):
    blocked = {name for name, tech in technologies.items()
               if any(i[0] == "nullius-physics-pack" for i in tech.get("unit", {}).get("ingredients", []))}
    while True:
        expanded = blocked | {name for name, tech in technologies.items()
                              if set(tech.get("prerequisites", [])) & blocked}
        if expanded == blocked:
            return set(technologies) - blocked
        blocked = expanded


def contract_report(data, path, config, targets=None, technology=None, quantify=True, boundary_only=False, pre_physics=False, recipe_overrides=()):
    args = prereqs.parse_arguments(["@" + str(ROOT / path)])
    quantities = defaultdict(float)
    for name, count in (targets if targets is not None else args.targets):
        quantities[name] += count
    args.targets = list(quantities)
    if technology is not None:
        args.technology = technology
    args.fuel = config["fuel"]
    if args.fuel not in args.targets:
        args.targets.append(args.fuel)
    args.recipe = [pair for pair in args.recipe if pair[0] not in dict(recipe_overrides)] + list(recipe_overrides)
    excluded_overrides = []
    if boundary_only or pre_physics:
        closure = prereqs.technology_closure(data["technology"], set(args.technology))
        if pre_physics:
            closure = pre_physics_technologies(data["technology"])
        unlocked = {effect["recipe"] for name in closure for effect in data["technology"][name].get("effects", [])
                    if effect.get("type") == "unlock-recipe"}
        data = dict(data, recipe={name: recipe for name, recipe in data["recipe"].items()
                                 if recipe.get("enabled") or name in unlocked})
        excluded_overrides = [pair for pair in args.recipe if pair[1] not in data["recipe"]]
        args.recipe = [pair for pair in args.recipe if pair[1] in data["recipe"]]
    report = prereqs.analyze(data, args)
    result = {"contract": path, "targets": dict(quantities),
              "boundary": {"technology_roots": args.technology, "available": args.available,
                           "available_machines": args.available_machine, "raw": args.raw,
                           "stock": dict(args.stock), "surface": dict(args.surface_property)},
              "research": research_cost(data, args.technology, config["entrance_technologies"]),
              "required_technologies": report["required_technologies"],
              "unresolved": report["unresolved"], "blocked_recipes": report["blocked_recipes"], "invalid_raw": report["invalid_raw"],
              "electric_required_paths": report["electric_required_paths"],
              "recipe_count": len(report["selected_recipes"]),
              "recipes": report["selected_recipes"]}
    result["research_with_recipe_requirements"] = research_cost(data, list(set(args.technology) | set(report["required_technologies"])), config["entrance_technologies"])
    result["excluded_unavailable_overrides"] = excluded_overrides
    result["boundary_recipe_gaps"] = [{"product": row["product"], "recipe": row["producer"],
                                      "unlocks": row["unlock_technologies"]}
        for row in report["selected_recipes"] if row.get("unlock_technologies")
        and not set(row["unlock_technologies"]) & set(report["assumed_technologies"])
        and not data["recipe"][row["producer"]].get("enabled")]
    result["machine_types"] = sorted({step["executor"]["name"] for step in report["selected_recipes"]
                                      if step.get("executor", {}).get("kind") == "machine"})
    result["assumed_extra_machine_items"] = sorted(set(args.available_machine) - set(config["wreck_machines"]))
    if quantify:
        try:
            stock = dict(args.stock)
            for name, amount in config["prime_stock"].items():
                stock.setdefault(name, amount)
            manifest = prereqs.build_production_manifest(data, report, dict(quantities), args.fuel, stock)
            result["manifest"] = manifest
            result["workload"] = summarize_workload(data, manifest)
        except TestFailure as error:
            result["quantification_error"] = str(error)
    return result


def summarize_workload(data, manifest):
    machines = {}
    recipes = defaultdict(float)
    spoil = []
    for step in manifest["steps"]:
        if "spoil_ticks" in step:
            spoil.append({"product": step["product"], "ticks": step["spoil_ticks"], "amount": step["cycles"]})
            continue
        executor = step["executor"]
        name = executor["name"]
        if name not in machines:
            prototype = data.get(executor.get("prototype_type", "character"), {}).get(name, {})
            machines[name] = {"name": name, "item": executor.get("item"), "kind": executor["kind"],
                              "seconds": 0, "energy_joules": 0, "recipes": [],
                              "energy_type": executor.get("energy_source", {}).get("type"),
                              "heat_minimum": executor.get("energy_source", {}).get("minimum_working_temperature"),
                              "native_effects": prototype.get("effect_receiver", {}).get("base_effect", {}),
                              "collision_box": prototype.get("collision_box")}
        row = machines[name]
        seconds = step["total_ticks_single_executor"] / 60
        row["seconds"] += seconds
        row["energy_joules"] += (step.get("energy_per_cycle_joules") or 0) * step["cycles"]
        if step["producer"] not in row["recipes"]:
            row["recipes"].append(step["producer"])
        recipes[step["producer"]] += seconds
    return {"machine_hours": sum(r["seconds"] for r in machines.values()) / 3600,
            "one_of_each_type_lower_bound_hours": max((r["seconds"] for r in machines.values()), default=0) / 3600,
            "machines": sorted(machines.values(), key=lambda r: -r["seconds"]),
            "recipe_seconds": dict(sorted(recipes.items(), key=lambda r: -r[1])), "spoilage": spoil,
            "interpretation": "Zero-productivity batch workload, with perfect input delivery; not an elapsed campaign time."}


def rate_sizing(stage, rates):
    """Size dedicated recipe stations for repetition of the declared batch."""
    if "workload" not in stage:
        return []
    counts = list(stage["targets"].values())
    if len(counts) != 1:
        return []
    batch = counts[0]
    rows = []
    for rate in rates:
        window = batch * 60 / rate
        machines = []
        manual = 0
        for machine in stage["workload"]["machines"]:
            if machine["kind"] == "character":
                manual += machine["seconds"] / window
                continue
            dedicated = sum(math.ceil(stage["workload"]["recipe_seconds"][recipe] / window)
                            for recipe in machine["recipes"])
            machines.append({"name": machine["name"], "dedicated_stations": dedicated,
                             "pooled_capacity": machine["seconds"] / window,
                             "energy_type": machine["energy_type"],
                             "average_mw": machine["energy_joules"] / window / 1e6})
        rows.append({"target_per_minute": rate, "batch": batch, "machines": machines,
                     "dedicated_stations": sum(m["dedicated_stations"] for m in machines),
                     "manual_crafting_utilization": manual,
                     "gross_raw_per_minute": {k: v * rate / batch for k, v in stage["manifest"]["raw_inputs"].items()},
                     "net_raw_per_minute": {name: max(0, sum(i["amount"] for step in stage["manifest"]["steps"]
                         for i in step.get("ingredients", []) if i["name"] == name) - sum(i["amount"] for step in stage["manifest"]["steps"]
                         for i in step.get("outputs", []) if i["name"] == name)) * rate / batch
                         for name in stage["manifest"]["raw_inputs"]},
                     "interpretation": "Repeat the zero-productivity batch. Exclude station construction, logistics, heat loss and warmup. This is a capacity estimate, not a sustained runtime test."})
    return rows


def runtime_summary(row):
    observation = row.get("observations") or {}
    terminal = observation.get("terminal", {})
    placed = defaultdict(int)
    for key in ("fixture_placed", "parallel_fixture_placed", "production_placed"):
        for name, count in terminal.get(key, {}).items():
            placed[name] += count
    return {"case": row["case"], "minutes": row["minutes"], "tick": row["tick"],
            "placed_items": dict(placed), "heat_mode": observation.get("initial", {}).get("heat_mode"),
            "fuel_consumed": terminal.get("fuel_consumed")}


def summary(report):
    if report.get("report_type") == "vulcanus-balance-summary":
        return report
    return {"schema": 1, "report_type": "vulcanus-balance-summary", "provenance": report["provenance"], "stages": [{
        "name": stage["name"], "targets": stage["targets"], "recipes": stage["recipe_count"],
        "machine_types": len(stage["machine_types"]), "extra_machine_items": stage["assumed_extra_machine_items"],
        "research_packs": stage["research"]["packs"],
        "post_physics_research": stage["research"]["physics_pack_consumers"],
        "manifest_error": stage.get("quantification_error"), "unresolved": stage["unresolved"],
        "machine_hours": stage.get("workload", {}).get("machine_hours"),
        "bottlenecks": [{"name": r["name"], "hours": r["seconds"] / 3600}
                        for r in stage.get("workload", {}).get("machines", [])[:3]],
        "raw_inputs": stage.get("manifest", {}).get("raw_inputs"),
        "fuel": stage.get("manifest", {}).get("fuel_consumption"),
        "rate_sizing": stage.get("rate_sizing", []) if stage["name"] == "chemical-science" else [],
    } for stage in report["stages"]], "runtime": [runtime_summary(r) for r in report.get("runtime", [])],
        "research_boundaries": {name: {"packs": row["packs"], "lab_hours_at_speed_one": row["lab_hours_at_speed_one"],
            "supply_hours": row.get("supply_hours"), "checkpoint_tokens": row["checkpoint_tokens"], "checkpoint_technologies": row.get("checkpoint_technologies", [])}
            for name, row in report.get("research_boundaries", {}).items()}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "tests/progression/balance/vulcanus.json")
    parser.add_argument("--output", type=Path, default=Path("/tmp/vulcanus-balance-report.json"))
    parser.add_argument("--read-report", type=Path)
    parser.add_argument("--export-summary", type=Path)
    parser.add_argument("--runtime-results", type=Path)
    parser.add_argument("--section", choices=["summary", "stages", "products", "technologies", "runtime", "research_boundaries"], default="summary")
    parser.add_argument("--stage")
    parser.add_argument("--field", help="Select a dot-separated field from the selected section or stage")
    parser.add_argument("--product")
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        config = json.loads(args.config.read_text())
        dump_args = prereqs.parse_arguments([])
        data, directory = prereqs.dump_resolved_data(dump_args)
        try:
            dump_path = directory / "script-output/data-raw-dump.json"
            retained = args.output.with_suffix(".resolved.json")
            shutil.copyfile(dump_path, retained)
            report = {"schema": 1, "provenance": {
                "revision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "factorio": subprocess.check_output([str(dump_args.factorio), "--version"], text=True).splitlines()[0],
                "generated_utc": datetime.now(timezone.utc).isoformat(),
                "dump_sha256": hashlib.sha256(dump_path.read_bytes()).hexdigest(),
                "config": str(args.config.relative_to(ROOT)),
            }, "stages": []}
            for stage in config["stages"]:
                print("Audit " + stage["name"], file=sys.stderr, flush=True)
                row = contract_report(data, stage["contract"], config, targets=stage.get("targets"), technology=stage.get("technology_roots"), boundary_only=stage.get("boundary_only", False), pre_physics=stage.get("pre_physics", False), recipe_overrides=stage.get("recipe_overrides", []))
                row["name"] = stage["name"]
                row["rate_sizing"] = rate_sizing(row, config["science_rates_per_minute"])
                report["stages"].append(row)
            report["research_boundaries"] = {name: research_cost(data, roots, config["entrance_technologies"])
                for name, roots in config.get("research_boundaries", {}).items()}
            for row in report["research_boundaries"].values():
                row["supply_hours"] = {str(rate): max(row["packs"].values(), default=0) / rate / 60
                    for rate in config["science_rates_per_minute"]}
            report["products"] = prereqs.describe_products(data, config["inspect_products"])
            report["technologies"] = prereqs.describe_technologies(data, config["inspect_technologies"])
            if args.runtime_results:
                runtime = json.loads(args.runtime_results.read_text())
                if runtime["status"] != "pass":
                    raise TestFailure("runtime suite did not pass")
                cases = [r["case"] for r in runtime["results"]]
                if sorted(cases) != sorted(config["runtime_cases"]):
                    raise TestFailure("runtime cases do not match the audit configuration")
                report["runtime"] = [{"case": r["case"], "tick": r["tick"],
                                      "minutes": r["tick"] / 3600, "observations": r.get("observations")}
                                     for r in runtime["results"]]
            args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        finally:
            shutil.rmtree(directory)
    if args.export_summary:
        args.export_summary.parent.mkdir(parents=True, exist_ok=True)
        args.export_summary.write_text(json.dumps(summary(report), indent=2, sort_keys=True) + "\n")
    result = summary(report) if args.section == "summary" else report.get(args.section)
    if args.stage:
        result = next(stage for stage in report["stages"] if stage["name"] == args.stage)
    if args.product:
        result = next(row for row in report["products"] if row["name"] == args.product)
    if args.field:
        for key in args.field.split("."):
            if not isinstance(result, dict) or key not in result:
                raise TestFailure(f"field does not exist in selected result: {args.field}")
            result = result[key]
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (TestFailure, OSError, ValueError, StopIteration) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
