#!/usr/bin/env python3
"""Plan continuous Factorio production from resolved recipes and declared boundaries."""
from __future__ import annotations

import argparse
from collections import defaultdict
from copy import deepcopy
import hashlib
import json
import math
import re
from pathlib import Path
import shutil
import subprocess
import sys

import numpy as np
from scipy.optimize import linprog
from scipy.sparse import coo_matrix

import analyze_factorio_prereqs as prereqs
from audit_vulcanus_progression import pre_physics_technologies, research_cost

ROOT = Path(__file__).resolve().parents[1]
TestFailure = prereqs.TestFailure


def validate_config(config):
    if config.get("schema") != 1:
        raise TestFailure("planner configuration requires schema 1")
    if config.get("uncertain_outputs") not in ("exact", "guaranteed"):
        raise TestFailure("uncertain_outputs must be exact or guaranteed")
    rates = config.get("science_rates_per_minute", [])
    stages = config.get("stages", [])
    if not rates or not stages:
        raise TestFailure("planner configuration needs rates and stages")
    names = [stage["name"] for stage in stages]
    if len(set(names)) != len(names):
        raise TestFailure("stage names must be unique")
    quantities = list(rates)
    for stage in stages:
        if not stage.get("products"):
            raise TestFailure("each stage needs production targets")
        quantities.extend(stage["products"].values())
    if any(isinstance(value, bool) or not isinstance(value, (float, int))
           or not math.isfinite(value) or value <= 0 for value in quantities):
        raise TestFailure("production rates and target multipliers must be finite and positive")


def amount(entry, policy):
    """Use exact output or an explicitly requested guaranteed-output bound."""
    probability = entry.get("probability", 1)
    if probability != 1:
        if policy != "guaranteed":
            raise TestFailure(f"probabilistic output: {entry['name']}")
        return 0.0
    if "amount" in entry:
        return float(entry["amount"])
    if entry.get("amount_min") == entry.get("amount_max"):
        return float(entry["amount_min"])
    if policy == "guaranteed" and "amount_min" in entry:
        return float(entry["amount_min"])
    raise TestFailure(f"ranged output: {entry['name']}")


def entity(data, name):
    for kind in ("assembling-machine", "furnace", "lab", "mining-drill", "heat-interface", "resource"):
        if name in data.get(kind, {}):
            return kind, data[kind][name]
    raise TestFailure(f"unknown planner executor: {name}")


def place_item(data, machine):
    if machine.get("placeable_by"):
        spec = machine["placeable_by"]
        if not isinstance(spec, dict) or spec.get("count", 1) != 1:
            raise TestFailure(f"unsupported placement contract: {machine['name']}")
        return spec["item"]
    products = prereqs.minable_results(machine)
    if len(products) == 1 and amount(products[0], "exact") == 1:
        return products[0]["name"]
    names = [name for kind in ("item", "item-with-entity-data")
             for name, item in data.get(kind, {}).items()
             if item.get("place_result") == machine["name"]]
    if len(names) != 1:
        raise TestFailure(f"ambiguous placement item: {machine['name']}")
    return names[0]


def fluid_ports_fit(recipe, machine):
    inputs = [i for i in recipe.get("ingredients", []) if i.get("type") == "fluid"]
    outputs = [i for i in prereqs.recipe_results(recipe) if i.get("type") == "fluid"]
    ports = machine.get("fluid_boxes", [])
    if not isinstance(ports, list):
        ports = [p for p in ports.values() if isinstance(p, dict)]
    requests = [(direction, fluid) for direction, fluids in
                (("input", inputs), ("output", outputs)) for fluid in fluids]
    used = set()

    def match(index):
        if index == len(requests):
            return True
        direction, fluid = requests[index]
        available = [(i, p) for i, p in enumerate(ports)
                     if p.get("production_type", "input-output") in (direction, "input-output")]
        for local_index, (port_index, port) in enumerate(available, 1):
            if port_index in used or port.get("filter", fluid["name"]) != fluid["name"]:
                continue
            if fluid.get("fluidbox_index") and fluid["fluidbox_index"] != local_index:
                continue
            used.add(port_index)
            if match(index + 1):
                return True
            used.remove(port_index)
        return False

    return match(0)


def read_heat_contract(path):
    source = path.read_text()
    result = {}
    for name in ("NUM_BUCKETS", "MAX_HEAT", "HEAT_DIVISOR"):
        match = re.search(r"local " + name + r" = ([0-9]+) +--", source)
        if not match:
            raise TestFailure(f"unsupported runtime heat constant: {name}")
        result[name] = int(match[1])
    match = re.search(r"if heat_delta < ([0-9]+) then heat_delta = ([0-9]+) end", source)
    if not match or match[1] != match[2]:
        raise TestFailure("unsupported runtime minimum heat increment")
    result["minimum_delta"] = int(match[1])
    result["source_sha256"] = hashlib.sha256(source.encode()).hexdigest()
    return result


def heat_output(data, machine, seconds, contract):
    if not machine["name"].endswith("-pneumatic") or machine["type"] in ("pump", "inserter"):
        return 0
    if machine["name"] == "nullius-boxer-pneumatic":
        return 0
    box = machine["collision_box"]
    half = max(abs(box[0][0]), abs(box[0][1]))
    size = "small" if half <= .8 else "medium" if half <= 1.4 else "medium2" if half <= 1.9 else "large"
    buffer = data["heat-interface"]["nullius-pneumatic-heat-" + size]["heat_buffer"]
    specific = prereqs.parse_energy(buffer["specific_heat"], "J")
    watts = prereqs.parse_energy(machine["energy_usage"], "W")
    delta = max(watts / 60 / contract["HEAT_DIVISOR"], contract["minimum_delta"])
    generated_watts = delta * specific * 60 / contract["NUM_BUCKETS"]
    transfer = prereqs.parse_energy(buffer["max_transfer"], "W")
    return min(generated_watts, transfer) * seconds / 1e6


def recipe_catalog(data, boundary):
    """Compile the cold planning path; never add hand-crafting executors."""
    technologies = set(boundary["technologies"])
    if boundary.get("allow_all_pre_physics"):
        technologies = pre_physics_technologies(data["technology"])
    else:
        technologies = prereqs.technology_closure(data["technology"], technologies)
    unlocked = {effect["recipe"] for name in technologies
                for effect in data["technology"][name].get("effects", [])
                if effect.get("type") == "unlock-recipe"}
    catalog = []
    excluded = defaultdict(list)
    machines = []
    for name in boundary["machines"]:
        kind, machine = entity(data, name)
        if not prereqs.allowed_on_surface(machine, boundary["surface"]):
            raise TestFailure(f"executor surface restriction: {name}")
        machines.append((kind, machine))
    heat_contract = boundary["heat_contract"]
    fuel_name = boundary["fuel"]
    fuel_value = prereqs.parse_energy(data["fluid"][fuel_name]["fuel_value"], "J")
    for name, recipe in sorted(data["recipe"].items()):
        if recipe.get("hidden") or recipe.get("category", "crafting") in boundary["forbid_categories"]:
            continue
        if not recipe.get("enabled", True) and name not in unlocked:
            continue
        if not prereqs.allowed_on_surface(recipe, boundary["surface"]):
            excluded["surface"].append(name)
            continue
        category = recipe.get("category", "crafting")
        if category in prereqs.IGNORED_RECIPE_CATEGORIES:
            continue
        if any(any(key in ingredient for key in ("temperature", "minimum_temperature", "maximum_temperature"))
               for ingredient in recipe.get("ingredients", [])):
            excluded["unsupported_fluid_temperature"].append(name)
            continue
        candidates = [(kind, machine) for kind, machine in machines
                      if category in machine.get("crafting_categories", [])
                      and fluid_ports_fit(recipe, machine)]
        if not candidates:
            excluded["executor"].append(name)
            continue
        for kind, machine in candidates:
            source = machine.get("energy_source", {})
            source_type = source.get("type")
            if source_type not in ("void", "fluid", "heat"):
                raise TestFailure(f"unsupported energy source {source_type}: {machine['name']}")
            effects = machine.get("effect_receiver", {}).get("base_effect", {})
            speed = machine["crafting_speed"] * (1 + effects.get("speed", 0))
            seconds = recipe.get("energy_required", 0.5) / speed
            watts = prereqs.parse_energy(machine.get("energy_usage", "0W"), "W")
            joules = seconds * watts * (1 + effects.get("consumption", 0))
            productivity = effects.get("productivity", 0) if recipe.get("allow_productivity") else 0
            productivity = min(productivity, recipe.get("maximum_productivity", productivity))
            flows = defaultdict(float)
            inputs = {}
            for ingredient in recipe.get("ingredients", []):
                quantity = amount(ingredient, "exact")
                flows[ingredient["name"]] -= quantity
                inputs[ingredient["name"]] = quantity
            uncertain = []
            for product in prereqs.recipe_results(recipe):
                quantity = amount(product, boundary["uncertain_outputs"])
                if product.get("probability", 1) != 1 or "amount_min" in product:
                    uncertain.append(product)
                bonus = max(0, quantity - product.get("ignored_by_productivity", 0)) * productivity
                flows[product["name"]] += quantity + bonus
            fuel = 0
            if source_type == "fluid":
                if source.get("fluid_box", {}).get("filter", fuel_name) != fuel_name or not source.get("burns_fluid"):
                    raise TestFailure(f"unsupported fluid fuel contract: {machine['name']}")
                fuel = joules / source.get("effectivity", 1) / fuel_value
                flows[fuel_name] -= fuel
                inputs[fuel_name] = inputs.get(fuel_name, 0) + fuel
            drain = prereqs.parse_energy(source.get("drain", "0W"), "W")
            if drain:
                raise TestFailure(f"idle drain needs installed-count model: {machine['name']}")
            generated_heat = heat_output(data, machine, seconds, heat_contract)
            if generated_heat:
                flows["@heat:" + str(heat_contract["MAX_HEAT"])] += generated_heat
            if source_type == "heat":
                flows["@heat:" + str(source["min_working_temperature"])] -= joules / 1e6
            catalog.append({"recipe": name, "machine": machine["name"], "item": place_item(data, machine),
                            "category": category, "seconds": seconds, "flows": dict(flows), "inputs": inputs,
                            "validation_ingredients": recipe.get("ingredients", []),
                            "validation_outputs": prereqs.recipe_results(recipe),
                            "joules": joules, "energy_type": source_type, "fuel": fuel,
                            "heat_minimum": source.get("min_working_temperature") if source_type == "heat" else None,
                            "generated_heat_mj": generated_heat, "native_productivity": productivity, "uncertain_outputs": uncertain,
                            "unlock_technologies": [] if recipe.get("enabled", True) else sorted(t for t in technologies if any(
                                e.get("type") == "unlock-recipe" and e["recipe"] == name
                                for e in data["technology"][t].get("effects", [])))})
    for product, spec in boundary["extractors"].items():
        _, machine = entity(data, spec["machine"])
        resource = data["resource"][spec["resource"]]
        if resource.get("category", "basic-solid") not in machine["resource_categories"]:
            raise TestFailure(f"extractor cannot mine {spec['resource']}")
        yield_factor = spec["yield_fraction"]
        if resource.get("infinite") and yield_factor < resource["minimum"] / resource["normal"]:
            raise TestFailure("declared extraction yield is below the prototype minimum")
        seconds = resource["minable"]["mining_time"] / machine["mining_speed"]
        joules = seconds * prereqs.parse_energy(machine["energy_usage"], "W")
        source = machine["energy_source"]
        if source["type"] != "fluid" or not source.get("burns_fluid"):
            raise TestFailure("extractor needs the declared fluid-fuel model")
        fuel = joules / source.get("effectivity", 1) / fuel_value
        natural = "@resource:" + spec["resource"]
        flows = {natural: -1, fuel_name: -fuel}
        products = prereqs.minable_results(resource)
        for output in products:
            flows[output["name"]] = amount(output, "exact") * yield_factor
        if product not in flows:
            raise TestFailure(f"resource does not yield {product}")
        generated_heat = heat_output(data, machine, seconds, heat_contract)
        flows["@heat:" + str(heat_contract["MAX_HEAT"])] = generated_heat
        catalog.append({"recipe": "<mine:" + spec["resource"] + ">", "machine": machine["name"],
                        "item": place_item(data, machine), "seconds": seconds, "flows": flows,
                        "inputs": {natural: 1}, "joules": joules, "energy_type": "fluid", "fuel": fuel,
                        "generated_heat_mj": generated_heat, "native_productivity": 0,
                        "uncertain_outputs": [], "unlock_technologies": []})
    heat_names = {name for recipe in catalog for name in recipe["flows"] if name.startswith("@heat:")}
    supply = "@heat:" + str(heat_contract["MAX_HEAT"])
    for name in sorted(heat_names):
        if name != supply and float(name.split(":")[1]) < heat_contract["MAX_HEAT"]:
            catalog.append({"recipe": "<heat-delivery:" + name + ">", "machine": None, "item": None,
                            "seconds": 0, "flows": {supply: -1, name: 1}, "inputs": {},
                            "joules": 0, "energy_type": "heat-transfer", "fuel": 0,
                            "native_productivity": 0, "uncertain_outputs": [], "unlock_technologies": []})
    for name, item in data.get("item", {}).items():
        if item.get("spoil_result"):
            catalog.append({"recipe": "<spoil:" + name + ">", "machine": None, "item": None,
                            "seconds": 0, "residence_seconds": item["spoil_ticks"] / 60,
                            "flows": {name: -1, item["spoil_result"]: 1}, "inputs": {name: 1},
                            "joules": 0, "energy_type": "spoil", "fuel": 0,
                            "native_productivity": 0, "uncertain_outputs": [], "unlock_technologies": []})
    return catalog, dict(excluded), technologies


def solve_flow(catalog, demands, raw, discard, caps=None):
    """Minimize active machine time with coupled material and fuel conservation."""
    products = sorted(set(demands) | set(raw) | {p for recipe in catalog for p in recipe["flows"]})
    indexes = {name: index for index, name in enumerate(products)}
    columns = [("recipe", row) for row in catalog]
    columns += [("raw", name) for name in sorted(raw)]
    columns += [("discard", name) for name in sorted(set(discard) & set(products))]
    rows, cols, values, costs, bounds = [], [], [], [], []
    for column, (kind, entry) in enumerate(columns):
        if kind == "recipe":
            flows = entry["flows"]
            costs.append(entry["seconds"] + 1e-6)
            bounds.append((0, None))
        elif kind == "raw":
            flows = {entry: 1}
            costs.append(1e-7)
            bounds.append((0, (caps or {}).get(entry)))
        else:
            flows = {entry: -1}
            costs.append(1e-7)
            bounds.append((0, None))
        for name, quantity in flows.items():
            if quantity:
                rows.append(indexes[name]); cols.append(column); values.append(quantity)
    matrix = coo_matrix((values, (rows, cols)), shape=(len(products), len(columns))).tocsc()
    rhs = np.array([demands.get(name, 0) for name in products])
    result = linprog(costs, A_eq=matrix, b_eq=rhs, bounds=bounds, method="highs")
    if not result.success:
        if result.status == 2:
            return {"status": "infeasible", "solver": result.message}
        raise TestFailure(f"planner solver failed: {result.message}")
    residual = matrix @ result.x - rhs
    if np.max(np.abs(residual), initial=0) > 1e-5:
        raise TestFailure(f"material conservation residual: {np.max(np.abs(residual))}")
    recipes, supplies, waste = [], {}, {}
    for (kind, entry), count in zip(columns, result.x):
        if count <= 1e-8:
            continue
        if kind == "recipe":
            recipes.append(dict(entry, cycles_per_minute=float(count)))
        elif kind == "raw":
            supplies[entry] = float(count)
        else:
            waste[entry] = float(count)
    return {"status": "optimal", "recipes": recipes, "raw_per_minute": supplies,
            "discard_per_minute": waste, "conservation_max_error": float(np.max(np.abs(residual), initial=0)),
            "objective_machine_seconds_per_minute": float(result.fun)}


def size_factory(solution):
    if solution["status"] != "optimal":
        return {}
    machines = defaultdict(lambda: {"count": 0, "active_equivalents": 0, "recipes": []})
    heat = defaultdict(float)
    gas = 0
    items = defaultdict(int)
    uncertain = []
    spoilage = []
    for row in solution["recipes"]:
        if row["machine"] is None:
            if row["energy_type"] != "spoil":
                continue
            spoilage.append({"recipe": row["recipe"], "items_in_transit": row["cycles_per_minute"] * row["residence_seconds"] / 60})
            continue
        active = row["cycles_per_minute"] * row["seconds"] / 60
        count = math.ceil(active - 1e-9)
        machine = machines[row["machine"]]
        machine["count"] += count
        machine["active_equivalents"] += active
        machine["recipes"].append({"name": row["recipe"], "count": count,
                                   "cycles_per_minute": row["cycles_per_minute"]})
        items[row["item"]] += count
        gas += row["fuel"] * row["cycles_per_minute"]
        if row["energy_type"] == "heat":
            heat[str(row["heat_minimum"])] += row["joules"] * row["cycles_per_minute"] / 60 / 1e6
        if row["uncertain_outputs"]:
            uncertain.append(row["recipe"])
    return {"process_machines": sum(m["count"] for m in machines.values()),
            "machines": dict(machines), "placement_items": dict(items), "fuel_per_minute": gas,
            "heat_demand_mw_by_minimum_temperature": dict(heat),
            "guaranteed_output_recipes": sorted(set(uncertain)), "spoilage_buffers": spoilage}


def startup_reachability(catalog, stock, raw):
    """Check material startup separately from steady-state circulation."""
    reachable = set(stock) | set(raw)
    while True:
        expanded = reachable | {name for row in catalog if set(row["inputs"]) <= reachable
                                for name, quantity in row["flows"].items() if quantity > 0}
        if expanded == reachable:
            return reachable
        reachable = expanded


def blocked_inputs(catalog, targets, reachable):
    producers = defaultdict(list)
    for recipe in catalog:
        for name, quantity in recipe["flows"].items():
            if quantity > 0:
                producers[name].append(recipe)
    pending = list(set(targets) - reachable)
    seen = set()
    result = []
    while pending:
        name = pending.pop()
        if name in seen:
            continue
        seen.add(name)
        if not producers[name]:
            result.append({"product": name, "recipe": None})
        for recipe in producers[name]:
            missing = sorted(set(recipe["inputs"]) - reachable)
            result.append({"product": name, "recipe": recipe["recipe"], "missing": missing})
            pending.extend(missing)
    return result


def boundary_from_config(data, config, stage):
    args = prereqs.parse_arguments(["@" + str(ROOT / stage["contract"])])
    machines = set(dict(args.executor).values())
    machines.update(stage.get("extra_machines", []))
    # Explicit machine catalog; every hand category must have a real executor.
    return {"technologies": stage.get("technologies", args.technology),
            "allow_all_pre_physics": stage.get("allow_all_pre_physics", False),
            "surface": stage.get("surface", dict(args.surface_property)),
            "fuel": config["fuel"], "machines": sorted(machines),
            "forbid_categories": args.forbid_category,
            "uncertain_outputs": config["uncertain_outputs"],
            "heat_contract": read_heat_contract(ROOT / config["heat_controller"]),
            "extractors": config["extractors"]}


def research_schedule(data, cost, supplies, lab_name):
    lab = data["lab"][lab_name]
    speed = lab["researching_speed"]
    pending = {r["name"]: r for r in cost["technologies"]}
    max_labs = 0
    for name, row in pending.items():
        unit = data["technology"][name].get("unit", {})
        ingredients = [(p, q) for p, q in unit.get("ingredients", []) if p in cost["packs"]]
        if ingredients:
            if any(supplies.get(p, 0) <= 0 for p, _ in ingredients):
                return {"status": "missing_science_supply", "technology": name}
            units_per_second = min(supplies[p] / 60 / q for p, q in ingredients)
            max_labs = max(max_labs, math.ceil(unit["time"] * units_per_second / speed - 1e-9))
    stocks = defaultdict(float)
    elapsed = 0
    schedule = []
    while pending:
        ready = sorted(name for name in pending if not set(data["technology"][name].get("prerequisites", [])) & set(pending))
        if not ready:
            raise TestFailure("cyclic research prerequisites")
        name = ready[0]
        row = pending.pop(name)
        packs = {p: amount for p, amount in row["packs"].items() if p in cost["packs"]}
        duration = 0
        if packs:
            duration = max(row["lab_seconds_at_speed_one"] / (max_labs * speed),
                           max(max(0, amount - stocks[p]) / (supplies[p] / 60) for p, amount in packs.items()))
        for p, rate in supplies.items():
            stocks[p] += duration * rate / 60 - packs.get(p, 0)
        elapsed += duration
        schedule.append({"technology": name, "finish_seconds": elapsed})
    return {"status": "scheduled", "lab": lab_name, "lab_count": max_labs,
            "hours": elapsed / 3600, "schedule": schedule,
            "interpretation": "Configured science lines and labs are online at time zero. Script checkpoints and research triggers are assumed satisfied when reached. No human construction time is inferred."}


def analyze_stage(data, config, stage):
    boundary = boundary_from_config(data, config, stage)
    catalog, excluded, technologies = recipe_catalog(data, boundary)
    raw = list(stage.get("raw", config["raw"]))
    raw += ["@resource:" + spec["resource"] for spec in boundary["extractors"].values()]
    reachable = startup_reachability(catalog, config["prime_stock"], raw)
    research = research_cost(data, stage.get("research_roots", boundary["technologies"]), config["entrance_technologies"])
    if research["unquantified"]:
        raise TestFailure(f"unquantified research: {research['unquantified']}")
    result = {"name": stage["name"], "boundary": boundary, "research": research,
              "executor_cycles": stage.get("executor_cycles", {}),
              "executor_transfers": stage.get("executor_transfers", []),
              "allowed_technologies": sorted(technologies), "eligible_recipe_executors": len(catalog), "excluded": excluded,
              "unreachable_targets": sorted(set(stage["products"]) - reachable),
              "blocked_inputs": blocked_inputs(catalog, stage["products"], reachable), "plans": []}
    result["blocked_leaves"] = sorted({row["product"] for row in result["blocked_inputs"] if row["recipe"] is None})
    discard = list(config["solid_discard"])
    if set(discard) - set(data.get("item", {})):
        raise TestFailure("solid_discard must name resolved solid items")
    discard += ["@heat:" + str(boundary["heat_contract"]["MAX_HEAT"])]
    # Exclude seedless material loops before the flow solve.
    catalog = [row for row in catalog if set(row["inputs"]) <= reachable]
    # Fluid waste requires an actual void recipe and compatible executor.
    for rate in config["science_rates_per_minute"]:
        demands = {name: rate * amount for name, amount in stage["products"].items()}
        research_roots = set(stage.get("research_roots", boundary["technologies"]))
        while True:
            research = research_cost(data, list(research_roots), config["entrance_technologies"])
            schedule = research_schedule(data, research, demands, config["lab"])
            solve_catalog = list(catalog)
            solve_demands = dict(demands)
            if schedule["status"] == "scheduled" and schedule["lab_count"]:
                lab = data["lab"][config["lab"]]
                count = schedule["lab_count"]
                joules = prereqs.parse_energy(lab["energy_usage"], "W") * 60 * count
                fuel = joules / prereqs.parse_energy(data["fluid"][config["fuel"]]["fuel_value"], "J")
                solve_catalog.append({"recipe": "<research-power>", "machine": config["lab"],
                    "item": place_item(data, lab), "seconds": 60 * count, "flows": {"@research-power": 1, config["fuel"]: -fuel},
                    "inputs": {}, "joules": joules, "energy_type": "fluid", "fuel": fuel,
                    "native_productivity": 0, "uncertain_outputs": [], "unlock_technologies": []})
                solve_demands["@research-power"] = 1
            solution = solve_flow(solve_catalog, solve_demands, raw, discard)
            if solution["status"] == "infeasible":
                relaxed = solve_flow(solve_catalog, solve_demands, raw, list(data.get("item", {})) + discard)
                solution["relaxed_solid_disposal"] = {"status": relaxed["status"], "discard_per_minute": relaxed.get("discard_per_minute")}
            plan = {"rate_per_minute": rate, "demands_per_minute": demands,
                    "flow": solution, "factory": size_factory(solution), "research_schedule": schedule}
            if solution["status"] == "optimal":
                machine_items = plan["factory"]["placement_items"]
                build = {name: max(0, count - config["wreck_machines"].get(name, 0))
                         for name, count in machine_items.items()}
                build = {name: count for name, count in build.items() if count}
                construction = solve_flow(catalog, build, raw, discard)
                plan["construction"] = {"items": build, "flow": construction,
                                        "blocked_inputs": blocked_inputs(catalog, build, reachable),
                                        "interpretation": "Continuous construction-flow lower bound. Flow amounts are batch totals, not rates. Fractional crafts and productivity credits are not a finite build schedule."}
                used_technologies = set(research_roots)
                for recipe in solution["recipes"] + construction.get("recipes", []):
                    if recipe["unlock_technologies"]:
                        choices = [prereqs.technology_closure(data["technology"], {t}) for t in recipe["unlock_technologies"]]
                        used_technologies.update(min(choices, key=lambda s: (len(s), sorted(s))))
                plan["research"] = research_cost(data, list(used_technologies), config["entrance_technologies"])
                packs = plan["research"]["packs"]
                plan["base_research_supply_hours"] = max(packs.values(), default=0) / rate / 60
                plan["startup_unreachable_recipe_inputs"] = sorted({p for r in solution["recipes"] for p in r["inputs"] if p not in reachable})
            if solution["status"] != "optimal" or used_technologies <= research_roots:
                break
            research_roots.update(used_technologies)
        result["plans"].append(plan)
    return result


def overview(report):
    return [{"name": stage["name"], "unreachable_targets": stage["unreachable_targets"],
             "plans": [{"rate": plan["rate_per_minute"], "status": plan["flow"]["status"],
                        "machines": plan["factory"].get("process_machines"),
                        "fuel_per_minute": plan["factory"].get("fuel_per_minute"),
                        "heat_mw": plan["factory"].get("heat_demand_mw_by_minimum_temperature"),
                        "raw_per_minute": plan["flow"].get("raw_per_minute"),
                        "research_hours": plan.get("base_research_supply_hours"),
                        "scheduled_research_hours": plan.get("research_schedule", {}).get("hours"),
                        "labs": plan.get("research_schedule", {}).get("lab_count"),
                        "construction_status": plan.get("construction", {}).get("flow", {}).get("status")}
                       for plan in stage["plans"]]} for stage in report["stages"]]


def compare_argon(data, spec):
    allowed = pre_physics_technologies(data["technology"])
    rows = prereqs.describe_recipes(data, spec["recipes"])
    for row in rows:
        row["available_before_physics"] = row["enabled"] or bool(set(row["unlock_technologies"]) & allowed)
        row["surface_availability"] = {str(t): prereqs.allowed_on_surface(data["recipe"][row["name"]],
            {"nullius-ambient-temperature": t}) for t in spec["surface_temperatures"]}
    return rows


def write_executor_fixture(report, stage_name, path):
    from generate_factorio_scenario_manifest import lua
    stage = next(s for s in report["stages"] if s["name"] == stage_name)
    plan = stage["plans"][0]
    if plan["flow"]["status"] != "optimal":
        raise TestFailure("executor fixture requires a feasible flow")
    rows = []
    for row in plan["flow"]["recipes"]:
        if not row["machine"] or row["recipe"].startswith("<"):
            continue
        rows.append({"recipe": row["recipe"], "machine": row["machine"], "cycles": stage.get("executor_cycles", {}).get(row["recipe"], 5),
                     "seconds_per_cycle": row["seconds"], "ingredients": row["validation_ingredients"],
                     "outputs": row["validation_outputs"], "fuel_per_cycle": row["fuel"],
                     "heat": row["energy_type"] == "heat", "productivity": row["native_productivity"]})
    fixture = {"schema": 1, "fuel": stage["boundary"]["fuel"], "executors": rows,
               "transfers": stage.get("executor_transfers", []),
               "boundary_technologies": stage["allowed_technologies"],
               "deadline": math.ceil(max(r["seconds_per_cycle"] * r["cycles"] for r in rows) * 60) + 3600}
    if not stage["boundary"]["allow_all_pre_physics"]:
        fixture["boundary_technologies"] = sorted(set(stage["boundary"]["technologies"]) |
            {r["name"] for r in plan["research"]["technologies"]})
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("-- Generated by tools/plan_factorio_factory.py.\nreturn " + lua(fixture) + "\n")


def compact(report):
    return {"schema": 1, "provenance": report["provenance"], "assumptions": report["assumptions"],
            "argon_comparison": report["argon_comparison"],
            "stages": [{"name": stage["name"], "unreachable_targets": stage["unreachable_targets"],
                "plans": [{"rate_per_minute": plan["rate_per_minute"], "status": plan["flow"]["status"],
                    "factory": plan["factory"], "raw_per_minute": plan["flow"].get("raw_per_minute"),
                    "discard_per_minute": plan["flow"].get("discard_per_minute"),
                    "base_research_supply_hours": plan.get("base_research_supply_hours"),
                    "construction_status": plan.get("construction", {}).get("flow", {}).get("status"),
                    "construction_blocked_inputs": plan.get("construction", {}).get("blocked_inputs"),
                    "research_schedule": {k: v for k, v in plan.get("research_schedule", {}).items() if k != "schedule"},
                    "startup_unreachable_recipe_inputs": plan.get("startup_unreachable_recipe_inputs")}
                    for plan in stage["plans"]]} for stage in report["stages"]]}


def write_markdown(report, path):
    lines = ["# Vulcanus factory capacity", "", "Generated by `tools/plan_factorio_factory.py`.", "",
             "Rates apply to each science type in the stage. Stages are separate capacity comparisons.",
             "Do not add their research times. A flow result does not prove a connected factory.", "",
             "| Stage | Packs/min | Flow | Machines | Labs | Research supply h | Scheduled research h | Construction |",
             "|---|---:|---|---:|---:|---:|---:|---|"]
    def number(value):
        return "—" if value is None else f"{value:,.2f}"
    for stage in overview(report):
        for plan in stage["plans"]:
            lines.append(f"| {stage['name']} | {plan['rate']:g} | {plan['status']} | "
                         f"{plan['machines'] or '—'} | {plan['labs'] or '—'} | "
                         f"{number(plan['research_hours'])} | {number(plan['scheduled_research_hours'])} | "
                         f"{plan['construction_status'] or '—'} |")
    lines += ["", "## Fuel and heat", "",
              "| Stage | Packs/min | Fuel units/min | Heat demand MW | Geyser extraction cycles/min |",
              "|---|---:|---:|---:|---:|"]
    for stage in overview(report):
        for plan in stage["plans"]:
            heat = sum(plan["heat_mw"].values()) if plan["heat_mw"] else None
            raw = (plan["raw_per_minute"] or {}).get("@resource:sulfuric-acid-geyser")
            lines.append(f"| {stage['name']} | {plan['rate']:g} | {number(plan['fuel_per_minute'])} | "
                         f"{number(heat)} | {number(raw)} |")
    lines += ["", "## Largest machine groups", "",
              "Counts include station rounding. Each row lists the five largest groups.", "",
              "| Stage | Packs/min | Machine counts |", "|---|---:|---|"]
    for stage in report["stages"]:
        for plan in stage["plans"]:
            groups = sorted(plan["factory"].get("machines", {}).items(),
                            key=lambda pair: (-pair[1]["count"], pair[0]))[:5]
            entries = "; ".join(f"{name}: {row['count']}" for name, row in groups)
            lines.append(f"| {stage['name']} | {plan['rate_per_minute']:g} | {entries or '—'} |")
    lines += ["", "## Construction failures", ""]
    failures = {(stage["name"], row["product"]) for stage in report["stages"]
                for plan in stage["plans"]
                for row in plan.get("construction", {}).get("blocked_inputs", [])}
    if failures:
        lines += [f"- `{stage}` cannot produce `{product}` under its construction boundary."
                  for stage, product in sorted(failures)]
        lines += ["", "Open the required construction research or supply the missing equipment before",
                  "using these rows as factory expansion contracts."]
    else:
        lines += ["No blocked construction inputs were reported. Check flow status for balance failures."]
    lines += ["", "## Model boundary", ""]
    lines += [f"- **{name}:** {value}" for name, value in report["assumptions"].items()]
    lines += ["", "Seed reachability checks material presence. It does not prove that finite seed quantities",
              "can start all selected machines. Construction is a continuous material-flow lower bound;",
              "fractional crafts and productivity credits do not define a finite construction schedule.",
              "Recipes with constrained fluid temperatures are excluded and listed in the full report.",
              "Transport, storage, heat delivery, and manual construction time need a connected scenario.", "",
              "## First physics", "",
              "Upstream ordinary air separation supplies residual gas before physics science.",
              "Fork commit `ecc2e04d7a947f0fc0bb6d9212b0d3f44c3af208` restricted that route",
              "on Vulcanus and added an atmosphere recipe without residual gas. The current restrictions",
              "use ambient temperature. The local residual-gas recipe restores a pre-physics route",
              "at air separation 2 without producing oxygen. Its three outputs fit the first distillery.", "",
              "| Recipe | Before physics | Surface 0 | Surface 200 |",
              "|---|---|---|---|"]
    for row in report["argon_comparison"]:
        surfaces = row["surface_availability"]
        lines.append(f"| {row['name']} | {row['available_before_physics']} | {surfaces.get('0')} | {surfaces.get('200')} |")
    lines += ["", "The first-physics row includes all six earlier science lines at the same rate.",
              "The basic-science row includes volcanism 1 to permit extractor construction.", "",
              "## Reproduce", "", "```bash",
              "python tools/plan_factorio_factory.py --overview --summary-output docs/data/vulcanus-factory-plan.json --markdown-output docs/VULCANUS_FACTORY_PLAN.md", "```", "",
              "Use the [factory planner skill](../.agents/skills/factorio-factory-planner/SKILL.md)",
              "for configuration, query commands, and executor validation.", "",
              f"Prototype SHA256: `{report['provenance']['dump_sha256']}`.", ""]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "tests/progression/planner/vulcanus.json")
    parser.add_argument("--output", type=Path, default=Path("/tmp/vulcanus-factory-plan.json"))
    parser.add_argument("--data-raw", type=Path, help="Reuse a matching prototype snapshot")
    parser.add_argument("--read-plan", type=Path)
    parser.add_argument("--stage")
    parser.add_argument("--inspect-entity", action="append", default=[])
    parser.add_argument("--field")
    parser.add_argument("--overview", action="store_true")
    parser.add_argument("--rate", type=float)
    parser.add_argument("--recipe")
    parser.add_argument("--product", help="Filter blocked-input diagnostics to one product")
    parser.add_argument("--summary-output", type=Path)
    parser.add_argument("--markdown-output", type=Path)
    parser.add_argument("--executor-fixture", type=Path)
    args = parser.parse_args()
    if args.read_plan:
        report = json.loads(args.read_plan.read_text())
    else:
        config = json.loads(args.config.read_text())
        validate_config(config)
        if args.stage and args.stage not in {s["name"] for s in config["stages"]}:
            raise TestFailure(f"unknown stage: {args.stage}")
        dump_args = prereqs.parse_arguments([])
        directory = None
        try:
            if args.data_raw:
                dump_path = args.data_raw
                data = json.loads(dump_path.read_text())
            else:
                data, directory = prereqs.dump_resolved_data(dump_args)
                dump_path = directory / "script-output/data-raw-dump.json"
            if args.inspect_entity:
                print(json.dumps({name: {key: value for key, value in entity(data, name)[1].items()
                    if key in ("name", "energy_source", "energy_usage", "crafting_speed", "fluid_boxes", "crafting_categories", "minable", "placeable_by", "heat_buffer", "infinite", "normal", "minimum", "mining_speed", "resource_categories", "category")}
                    for name in args.inspect_entity}, indent=2))
                return
            report = {"schema": 1, "provenance": {
                "planner_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                "config_sha256": hashlib.sha256(args.config.read_bytes()).hexdigest(),
                "revision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "dump_sha256": hashlib.sha256(dump_path.read_bytes()).hexdigest(),
                "config": str(args.config.relative_to(ROOT)), "snapshot_reused": bool(args.data_raw)},
                "assumptions": config["assumptions"], "argon_comparison": compare_argon(data, config["argon_comparison"]), "stages": []}
            for stage in config["stages"]:
                if args.stage and stage["name"] != args.stage:
                    continue
                print("Plan " + stage["name"], file=sys.stderr, flush=True)
                report["stages"].append(analyze_stage(data, config, stage))
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        finally:
            if directory:
                shutil.rmtree(directory)
    if args.executor_fixture:
        if not args.stage:
            raise TestFailure("--executor-fixture requires --stage")
        write_executor_fixture(report, args.stage, args.executor_fixture)
    if args.markdown_output:
        write_markdown(report, args.markdown_output)
    if args.summary_output:
        args.summary_output.parent.mkdir(parents=True, exist_ok=True)
        args.summary_output.write_text(json.dumps(compact(report), indent=2, sort_keys=True) + "\n")
    selected = report
    if args.stage:
        selected = next(row for row in report["stages"] if row["name"] == args.stage)
    if args.rate is not None:
        selected = next(p for p in selected["plans"] if p["rate_per_minute"] == args.rate)
    if args.recipe:
        selected = [r for r in selected["flow"]["recipes"] if r["recipe"] == args.recipe]
    if args.product:
        selected = [row for row in selected["blocked_inputs"] if row["product"] == args.product]
    if args.field:
        for key in args.field.split("."):
            if not isinstance(selected, dict) or key not in selected:
                raise TestFailure(f"unknown plan field: {args.field}")
            selected = selected[key]
    elif not args.product and not args.recipe:
        selected = compact(report)
    if args.overview:
        selected = overview(report)
    print(json.dumps(selected, indent=2, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (TestFailure, OSError, ValueError, StopIteration) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
