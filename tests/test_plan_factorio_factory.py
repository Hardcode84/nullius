"""Production-flow, fuel, thermal, startup and output-bound planner contracts."""
from pathlib import Path
import sys
import json
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from plan_factorio_factory import (TestFailure, amount, solve_flow, size_factory,
                                  startup_reachability, fluid_ports_fit, read_heat_contract,
                                  research_schedule, validate_config, recipe_catalog, material_consumption, research_supply_hours, analyze_science_scale, write_executor_fixture)


def recipe(name, flows, seconds=1, inputs=None, **kwargs):
    return dict(recipe=name, machine=name, item=name, seconds=seconds, flows=flows,
                inputs=inputs or {n: -v for n, v in flows.items() if v < 0},
                joules=0, energy_type="void", fuel=0, uncertain_outputs=[], **kwargs)


class FactoryPlannerTest(unittest.TestCase):
    def test_hypothetical_overlay_cannot_claim_shipping_execution(self):
        with self.assertRaisesRegex(TestFailure, "hypothetical prototypes"):
            write_executor_fixture({"provenance": {"prototype_overlay_sha256": "experiment"}},
                                   "candidate", Path("unused.lua"))

    def test_science_candidate_boxed_material_and_time_parity(self):
        path = Path(__file__).resolve().parents[1] / "tests/progression/planner/vulcanus-science-tier2-overlay.json"
        recipes = json.loads(path.read_text())["recipe"]
        def unpack(entries):
            result = {}
            for entry in entries:
                name = entry["name"]
                boxed = name.startswith("nullius-box-")
                name = name.replace("nullius-box-", "nullius-", 1) if boxed else name
                result[name] = entry["amount"] * (5 if boxed else 1)
            return result
        for pack in ("geology", "climatology"):
            ordinary = recipes[f"nullius-experiment-{pack}-vulcanus-2"]
            boxed = recipes[f"nullius-experiment-boxed-{pack}-vulcanus-2"]
            self.assertEqual(boxed["energy_required"], ordinary["energy_required"] * 5)
            for field in ("ingredients", "results"):
                self.assertEqual(unpack(boxed[field]), {k: v * 5 for k, v in unpack(ordinary[field]).items()})

    def test_fixture_keeps_entrance_prerequisites(self):
        row = dict(recipe("make", {"pack": 1}), validation_ingredients=[], validation_outputs=[],
                   native_productivity=0)
        stage = {"name": "restricted", "allowed_technologies": ["entrance-parent", "root"],
                 "boundary": {"fuel": "gas", "surface": {"nullius-ambient-temperature": 200},
                              "allow_all_pre_physics": False, "technologies": ["root"]},
                 "plans": [{"flow": {"status": "optimal", "recipes": [row]},
                            "research": {"technologies": [{"name": "root"}]}}]}
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "fixture.lua"
            write_executor_fixture({"stages": [stage]}, "restricted", output)
            self.assertIn('"entrance-parent"', output.read_text())

    def test_electric_grid_is_explicit_and_counts_installed_drain(self):
        data = {"technology": {}, "fluid": {"gas": {"fuel_value": "1kJ"}},
                "assembling-machine": {"m": {"name": "m", "type": "assembling-machine",
                    "crafting_speed": 1, "crafting_categories": ["crafting"],
                    "energy_usage": "1MW", "energy_source": {"type": "electric", "drain": "10kW"},
                    "minable": {"result": "m"}}},
                "recipe": {"plate": {"name": "plate", "energy_required": 1,
                    "ingredients": [{"name": "ore", "amount": 1}],
                    "results": [{"name": "plate", "amount": 1}]}}}
        boundary = {"technologies": [], "surface": {}, "fuel": "gas", "machines": ["m"],
                    "forbid_categories": [], "uncertain_outputs": "exact",
                    "heat_contract": {"MAX_HEAT": 500}, "extractors": {}}
        with self.assertRaisesRegex(TestFailure, "explicit supplied electric_grid"):
            recipe_catalog(data, boundary)
        boundary["electric_grid"] = True
        rows, _, _ = recipe_catalog(data, boundary)
        result = solve_flow(rows, {"plate": 90}, ["ore"], [])
        sized = size_factory(result)
        self.assertEqual(sized["process_machines"], 2)
        self.assertAlmostEqual(sized["electric_grid_mw"], 1.52)
        self.assertEqual(sized["fuel_per_minute"], 0)
        self.assertEqual(result["raw_per_minute"], {"ore": 90})

    def test_electric_extractor_counts_actual_mining_time(self):
        data = {"technology": {}, "recipe": {}, "fluid": {"gas": {"fuel_value": "1kJ"}},
                "mining-drill": {"miner": {"name": "miner", "type": "mining-drill",
                    "resource_categories": ["basic-solid"], "mining_speed": .5,
                    "energy_usage": "100kW", "energy_source": {"type": "electric"},
                    "minable": {"result": "miner"}}},
                "resource": {"ore": {"minable": {"mining_time": 2, "result": "ore"}}}}
        boundary = {"technologies": [], "surface": {}, "fuel": "gas", "machines": [],
                    "forbid_categories": [], "uncertain_outputs": "exact", "electric_grid": True,
                    "heat_contract": {"MAX_HEAT": 500},
                    "extractors": {"ore": {"resource": "ore", "machine": "miner", "yield_fraction": 1}}}
        rows, _, _ = recipe_catalog(data, boundary)
        sized = size_factory(solve_flow(rows, {"ore": 90}, ["@resource:ore"], []))
        self.assertEqual(sized["process_machines"], 6)
        self.assertAlmostEqual(sized["electric_grid_mw"], .6)
        self.assertEqual(sized["fuel_per_minute"], 0)
        data["resource"]["ore"]["minable"]["required_fluid"] = "acid"
        with self.assertRaisesRegex(TestFailure, "mining fluid"):
            recipe_catalog(data, boundary)

    def test_exclusion_changes_the_available_production_route(self):
        data = {"technology": {}, "fluid": {"gas": {"fuel_value": "1kJ"}},
                "assembling-machine": {"m": {"name": "m", "type": "assembling-machine",
                    "crafting_speed": 1, "crafting_categories": ["casting"],
                    "energy_source": {"type": "void"}, "minable": {"result": "m"}}},
                "recipe": {name: {"name": name, "category": "casting",
                    "ingredients": [{"name": "ore", "amount": 1}],
                    "results": [{"name": "plate", "amount": count}]}
                    for name, count in (("dry", 1), ("wet", 2))}}
        boundary = {"technologies": [], "surface": {}, "fuel": "gas", "machines": ["m"],
                    "forbid_categories": [], "uncertain_outputs": "exact",
                    "heat_contract": {"MAX_HEAT": 500}, "extractors": {}, "excluded_recipes": ["wet"]}
        catalog, excluded, _ = recipe_catalog(data, boundary)
        result = solve_flow(catalog, {"plate": 60}, ["ore"], [])
        self.assertEqual(result["raw_per_minute"], {"ore": 60})
        self.assertEqual(excluded["configured"], ["wet"])
        boundary["excluded_recipes"] = []
        catalog, _, _ = recipe_catalog(data, boundary)
        self.assertEqual(solve_flow(catalog, {"plate": 60}, ["ore"], [])["raw_per_minute"], {"ore": 30})
        boundary["excluded_recipes"] = ["typo"]
        with self.assertRaisesRegex(TestFailure, "unknown excluded recipes"):
            recipe_catalog(data, boundary)

    def test_comparison_reports_gross_circulation(self):
        plan = {"flow": {"recipes": [dict(recipe("loop", {"water": -1}, inputs={"water": 10}),
                                         cycles_per_minute=2)]}}
        self.assertEqual(material_consumption(plan, "water"), 20)

    def test_science_scale_counts_entrance_and_converts_time(self):
        data = {"technology": {
            "entrance": {"unit": {"count": 1000, "time": 1, "ingredients": [["geo", 1]]}},
            "physics": {"prerequisites": ["entrance"], "unit": {
                "count": 240, "time": 1, "ingredients": [["geo", 1], ["climate", 2]]}}}}
        spec = {"research_roots": {"unlock": ["physics"]}, "factory_stages": [],
                "packs": ["geo", "climate"], "rates": [60, 120], "hours": [4, 8]}
        result = analyze_science_scale(data, {"stages": []}, spec, ["entrance"])
        packs = result["budgets"][0]["packs"]
        self.assertEqual(packs["geo"]["total"], 240)
        self.assertEqual(packs["climate"]["supply_hours"]["60"], 8 / 60)
        self.assertEqual(packs["climate"]["required_rate_per_minute"]["8"], 1)
        self.assertEqual(packs["geo"]["top_technologies"], [{"technology": "physics", "packs": 240}])

    def test_research_bound_requires_actual_science_supply(self):
        self.assertIsNone(research_supply_hours({"pack": 60}, {"plate": 60}))
        self.assertEqual(research_supply_hours({"a": 60, "b": 120}, {"a": 60, "b": 30}), 4 / 60)

    def test_research_schedule_uses_supply_and_labs(self):
        data = {"lab": {"lab": {"researching_speed": 1}}, "technology": {
            "a": {"unit": {"time": 60, "ingredients": [["pack", 1]]}},
            "b": {"prerequisites": ["a"], "unit": {"time": 60, "ingredients": [["pack", 1]]}}}}
        cost = {"packs": {"pack": 120}, "technologies": [
            {"name": name, "packs": {"pack": 60}, "lab_seconds_at_speed_one": 3600}
            for name in ("b", "a")]}
        result = research_schedule(data, cost, {"pack": 60}, "lab")
        self.assertEqual(result["lab_count"], 60)
        self.assertEqual(result["hours"], 120 / 3600)
        self.assertEqual([r["technology"] for r in result["schedule"]], ["a", "b"])
        self.assertEqual(research_schedule(data, cost, {}, "lab")["status"], "missing_science_supply")

    def test_configuration_rejects_invalid_rate(self):
        config = {"schema": 1, "uncertain_outputs": "exact",
                  "science_rates_per_minute": [-1], "stages": [{"name": "a", "products": {"pack": 1}}]}
        with self.assertRaises(TestFailure):
            validate_config(config)

    def test_coproduct_replaces_separate_supply(self):
        rows = [recipe("joint", {"ore": -1, "a": 1, "b": 1}),
                recipe("a-only", {"ore": -1, "a": 1}),
                recipe("b-only", {"ore": -1, "b": 1})]
        result = solve_flow(rows, {"a": 60, "b": 60}, ["ore"], [])
        self.assertEqual(result["status"], "optimal")
        self.assertEqual(result["raw_per_minute"], {"ore": 60})
        self.assertEqual([r["recipe"] for r in result["recipes"]], ["joint"])

    def test_fuel_supply_includes_its_own_consumption(self):
        rows = [recipe("gas", {"lava": -50, "gas": 65 - 24}, 2),
                recipe("science", {"gas": -41, "pack": 1})]
        result = solve_flow(rows, {"pack": 1}, ["lava"], [])
        self.assertEqual(result["raw_per_minute"], {"lava": 50})
        self.assertEqual(result["recipes"][0]["cycles_per_minute"], 1)

    def test_fluid_waste_needs_a_real_sink(self):
        rows = [recipe("process", {"ore": -1, "pack": 1, "waste": 1})]
        self.assertEqual(solve_flow(rows, {"pack": 1}, ["ore"], [])["status"], "infeasible")
        rows.append(recipe("outfall", {"waste": -1}))
        self.assertEqual(solve_flow(rows, {"pack": 1}, ["ore"], [])["status"], "optimal")

    def test_heat_balance_requires_more_source_capacity(self):
        rows = [recipe("source", {"gas": -1, "@heat:500": 2}),
                recipe("consumer", {"ore": -1, "@heat:500": -6, "pack": 1})]
        result = solve_flow(rows, {"pack": 1}, ["ore", "gas"], [])
        self.assertEqual(result["raw_per_minute"]["gas"], 3)
        rows[0]["flows"] = {"gas": -1, "@heat:200": 2}
        self.assertEqual(solve_flow(rows, {"pack": 1}, ["ore", "gas"], ["@heat:200"])["status"], "infeasible")

    def test_raw_capacity_is_enforced(self):
        rows = [recipe("make", {"ore": -1, "pack": 1})]
        self.assertEqual(solve_flow(rows, {"pack": 10}, ["ore"], [], {"ore": 9})["status"], "infeasible")

    def test_unknown_probability_is_not_averaged(self):
        entry = {"name": "barrel", "amount": 1, "probability": .9}
        self.assertEqual(amount(entry, "guaranteed"), 0)
        with self.assertRaises(TestFailure):
            amount(entry, "exact")
        self.assertEqual(amount({"name": "ore", "amount_min": 2, "amount_max": 5}, "guaranteed"), 2)

    def test_productive_cycle_does_not_prove_startup(self):
        rows = [recipe("loop", {"seed": 1}, inputs={"seed": 1})]
        self.assertEqual(solve_flow(rows, {"seed": 1}, [], [])["status"], "optimal")
        self.assertNotIn("seed", startup_reachability(rows, {}, []))
        self.assertIn("seed", startup_reachability(rows, {"seed": 1}, []))

    def test_station_rounding_and_spoilage_buffer(self):
        result = {"status": "optimal", "recipes": [
            dict(recipe("station", {"ore": -1, "pack": 1}, seconds=2), cycles_per_minute=31),
            dict(recipe("cool", {"hot": -1, "cold": 1}, seconds=0),
                 machine=None, energy_type="spoil", residence_seconds=40, cycles_per_minute=30)]}
        sized = size_factory(result)
        self.assertEqual(sized["process_machines"], 2)
        self.assertEqual(sized["spoilage_buffers"][0]["items_in_transit"], 20)

    def test_fluid_filters_exclude_wrong_machine(self):
        recipe_data = {"ingredients": [{"type": "fluid", "name": "acid", "amount": 1}], "results": []}
        self.assertFalse(fluid_ports_fit(recipe_data, {"fluid_boxes": [{"production_type": "input", "filter": "water"}]}))
        self.assertTrue(fluid_ports_fit(recipe_data, {"fluid_boxes": [{"production_type": "input", "filter": "acid"}]}))

    def test_shared_fluid_port_cannot_hold_two_fluids(self):
        data = {"ingredients": [{"type": "fluid", "name": "acid"}],
                "results": [{"type": "fluid", "name": "water", "amount": 1}]}
        port = {"production_type": "input-output"}
        self.assertFalse(fluid_ports_fit(data, {"fluid_boxes": [port]}))
        self.assertTrue(fluid_ports_fit(data, {"fluid_boxes": [port, port]}))

    def test_heat_source_contract_rejects_expression_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "heat.lua"
            path.write_text("local NUM_BUCKETS = unknown -- changed\n")
            with self.assertRaises(TestFailure):
                read_heat_contract(path)


if __name__ == "__main__":
    unittest.main()
