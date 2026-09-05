"""Production-flow, fuel, thermal, startup and output-bound planner contracts."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from plan_factorio_factory import (TestFailure, amount, solve_flow, size_factory,
                                  startup_reachability, fluid_ports_fit, read_heat_contract,
                                  research_schedule, validate_config)


def recipe(name, flows, seconds=1, inputs=None, **kwargs):
    return dict(recipe=name, machine=name, item=name, seconds=seconds, flows=flows,
                inputs=inputs or {n: -v for n, v in flows.items() if v < 0},
                joules=0, energy_type="void", fuel=0, uncertain_outputs=[], **kwargs)


class FactoryPlannerTest(unittest.TestCase):
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
