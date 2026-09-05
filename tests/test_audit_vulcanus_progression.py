"""Tests for research boundaries and batch capacity estimates."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from audit_vulcanus_progression import research_cost, rate_sizing, runtime_summary, pre_physics_technologies


class ProgressionAuditTest(unittest.TestCase):
    def test_research_deduplicates_prerequisites_and_excludes_entrance(self):
        def tech(parents, pack, count):
            return {"prerequisites": parents, "unit": {
                "count": count, "time": 30, "ingredients": [[pack, 2]]}}
        data = {"technology": {
            "entrance": tech([], "science", 100),
            "common": tech(["entrance"], "science", 10),
            "left": tech(["common"], "science", 5),
            "right": tech(["common"], "nullius-checkpoint", 1)}}
        result = research_cost(data, ["left", "right"], ["entrance"])
        self.assertEqual(result["packs"], {"science": 30})
        self.assertEqual(result["checkpoint_tokens"], {"nullius-checkpoint": 2})
        self.assertEqual(result["lab_hours_at_speed_one"], 450 / 3600)

    def test_pre_physics_boundary_excludes_descendants_but_keeps_unlock(self):
        technologies = {
            "physics-unlock": {"unit": {"ingredients": [["chemistry", 1]]}},
            "post-physics": {"unit": {"ingredients": [["nullius-physics-pack", 1]]}},
            "trigger": {"prerequisites": ["post-physics"]},
            "descendant": {"prerequisites": ["trigger"]}}
        self.assertEqual(pre_physics_technologies(technologies), {"physics-unlock"})

    def test_formula_cost_is_reported_as_unquantified(self):
        data = {"technology": {"formula": {"unit": {
            "count_formula": "2^L", "time": 30, "ingredients": [["science", 1]]}}}}
        result = research_cost(data, ["formula"], [])
        self.assertEqual(result["unquantified"][0]["technology"], "formula")
        self.assertEqual(result["packs"], {})

    def test_capacity_rounds_each_recipe_and_retains_catalyst(self):
        stage = {"targets": {"science": 10}, "workload": {
            "recipe_seconds": {"a": 450, "b": 300, "hand": 700},
            "machines": [
                {"name": "machine", "kind": "machine", "recipes": ["a", "b"],
                 "seconds": 750, "energy_joules": 6000000, "energy_type": "heat"},
                {"name": "character", "kind": "character", "seconds": 700}]},
            "manifest": {"raw_inputs": {"catalyst": 1, "ore": 20}, "steps": [
                {"ingredients": [{"name": "catalyst", "amount": 10}, {"name": "ore", "amount": 20}],
                 "outputs": [{"name": "catalyst", "amount": 10}]}]}}
        row = rate_sizing(stage, [1])[0]
        self.assertEqual(row["dedicated_stations"], 2)
        self.assertEqual(row["machines"][0]["pooled_capacity"], 1.25)
        self.assertEqual(row["net_raw_per_minute"], {"catalyst": 0, "ore": 2})
        self.assertGreater(row["manual_crafting_utilization"], 1)

    def test_runtime_counts_all_placement_sources(self):
        row = {"case": "test", "tick": 3600, "minutes": 1, "observations": {
            "terminal": {"fixture_placed": {"machine": 2},
                         "parallel_fixture_placed": {"machine": 3},
                         "production_placed": {"machine": 1}}}}
        self.assertEqual(runtime_summary(row)["placed_items"], {"machine": 6})


if __name__ == "__main__":
    unittest.main()
