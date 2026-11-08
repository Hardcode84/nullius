#!/usr/bin/env python3
"""Unit tests for the launch vehicle research and cost checks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from check_launch_vehicle import (CO2_PROPELLANT, TITANIUM_STRUCTURES, fuel_cost_violations,
                                  research_violations, split_raw)


def launch_tree():
    inherited = ["nullius-demolitions-2", "nullius-freight-transportation-3",
                 "nullius-high-pressure-chemistry-2"]
    prerequisites = {
        "nullius-physics": [],
        "nullius-composites-2": ["nullius-physics"],
        "nullius-demolitions-2": ["nullius-physics"],
        "nullius-freight-transportation-3": ["nullius-physics"],
        "nullius-high-pressure-chemistry-2": ["nullius-physics"],
        "nullius-cybernetics-5": ["nullius-physics"],
        "nullius-personal-transportation-4": ["nullius-cybernetics-5"],
        "nullius-rocket-science-1": ["nullius-physics"],
        "nullius-checkpoint-rocket-fuel": ["nullius-rocket-science-1"],
        "nullius-braking-8": ["nullius-checkpoint-rocket-fuel", "nullius-cybernetics-5", *inherited],
        "nullius-empiricism-6": ["nullius-rocket-science-1", *inherited],
        "nullius-rocket-science-2": ["nullius-checkpoint-rocket-fuel", "nullius-composites-2"],
        "nullius-broadcasting-4": ["nullius-composites-2"],
        "nullius-astronomy": ["nullius-rocket-science-2", "nullius-braking-8",
                              "nullius-personal-transportation-4", "nullius-broadcasting-4"],
        "nullius-probe-vulcanus": ["nullius-physics"],
        "nullius-pneumatic-technology": ["nullius-probe-vulcanus"],
        "nullius-volcanic-titanium-metallurgy": ["nullius-pneumatic-technology"],
        TITANIUM_STRUCTURES: ["nullius-rocket-science-2", "nullius-volcanic-titanium-metallurgy"],
        CO2_PROPELLANT: ["nullius-rocket-science-1", "nullius-pneumatic-technology"],
    }
    unlocks = {
        "nullius-rocket-science-2": ["nullius-rocket-stage"],
        TITANIUM_STRUCTURES: ["nullius-titanium-rocket-stage"],
        CO2_PROPELLANT: ["nullius-aluminum-co2-rocket-fuel", "nullius-boxed-aluminum-co2-rocket-fuel"],
    }
    vulcanus_unit = {"ingredients": [["nullius-metallurgic-pack", 20], ["nullius-physics-pack", 2]]}
    return {name: {"name": name, "prerequisites": list(parents), "unit": vulcanus_unit,
                   "effects": [{"type": "unlock-recipe", "recipe": recipe} for recipe in unlocks.get(name, [])]}
            for name, parents in prerequisites.items()}


class ResearchViolationsTest(unittest.TestCase):
    def test_inherited_prerequisites_preserve_former_closures(self):
        self.assertEqual(research_violations(launch_tree()), [])

    def test_dependent_without_inherited_prerequisite_loses_closure(self):
        technologies = launch_tree()
        technologies["nullius-astronomy"]["prerequisites"].remove("nullius-personal-transportation-4")
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 1)
        self.assertIn("nullius-astronomy closure: lost", violations[0])
        self.assertIn("nullius-personal-transportation-4", violations[0])

    def test_new_rp1_research_has_no_former_closure(self):
        technologies = launch_tree()
        technologies['nullius-rp1-fuel'] = {'name': 'nullius-rp1-fuel',
                                           'prerequisites': ['nullius-rocket-science-1']}
        self.assertEqual(research_violations(technologies), [])

    def test_late_launch_research_is_rejected(self):
        technologies = launch_tree()
        technologies["nullius-rocket-science-1"]["prerequisites"].append("nullius-demolitions-2")
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 1)
        self.assertIn("nullius-rocket-science-1 prerequisites", violations[0])


    def test_titanium_stage_unlocked_with_the_default_is_rejected(self):
        technologies = launch_tree()
        technologies["nullius-rocket-science-2"]["effects"].append(
            {"type": "unlock-recipe", "recipe": "nullius-titanium-rocket-stage"})
        violations = research_violations(technologies)
        self.assertEqual(violations, [
            "nullius-titanium-rocket-stage unlocked by ['nullius-rocket-science-2', "
            "'nullius-titanium-rocket-structures'], expected nullius-titanium-rocket-structures"])

    def test_titanium_structures_without_vulcanus_research_are_rejected(self):
        technologies = launch_tree()
        technologies[TITANIUM_STRUCTURES]["prerequisites"] = ["nullius-rocket-science-2"]
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 2)
        self.assertIn(f"{TITANIUM_STRUCTURES} prerequisites", violations[0])
        self.assertEqual(violations[1], f"{TITANIUM_STRUCTURES} does not require the Vulcanus probe")


class VulcanusResearchTest(unittest.TestCase):
    def test_fuel_research_without_vulcanus_science_or_probe_is_rejected(self):
        technologies = launch_tree()
        technologies[CO2_PROPELLANT]["unit"] = {"ingredients": [["nullius-electromagnetic-pack", 20]]}
        technologies["nullius-pneumatic-technology"]["prerequisites"] = []
        self.assertEqual(research_violations(technologies), [
            f"{TITANIUM_STRUCTURES} does not require the Vulcanus probe",
            f"{CO2_PROPELLANT} does not require metallurgic science",
            f"{CO2_PROPELLANT} does not require the Vulcanus probe"])

    def test_boxed_fuel_unlocked_elsewhere_is_rejected(self):
        technologies = launch_tree()
        technologies[CO2_PROPELLANT]["effects"].pop()
        technologies["nullius-rocket-science-1"]["effects"].append(
            {"type": "unlock-recipe", "recipe": "nullius-boxed-aluminum-co2-rocket-fuel"})
        self.assertEqual(research_violations(technologies), [
            "nullius-boxed-aluminum-co2-rocket-fuel unlocked by ['nullius-rocket-science-1'], "
            f"expected {CO2_PROPELLANT}"])


class FuelCostTest(unittest.TestCase):
    def test_off_planet_penalty_keeps_solid_and_fluid_classes_separate(self):
        def cost(ore, gas):
            return {"ore": ore, "gas": gas, "raw_inputs": {"nullius-bauxite": ore}}
        routes = {"default": cost(10, 100), "rp1": cost(5, 10), "co2": cost(20, 11)}
        self.assertEqual(fuel_cost_violations({"nauvis": routes}), [])
        routes["co2"]["gas"] = 10
        self.assertEqual(fuel_cost_violations({"nauvis": routes}),
                         ["nauvis CO2 gas cost must exceed RP-1"])
        routes["co2"]["raw_inputs"]["nullius-bauxite"] = 19
        self.assertIn("nauvis CO2 fuel requires less than twice the default bauxite",
                      fuel_cost_violations({"nauvis": routes}))

    def test_fulgora_compares_supplied_minerals(self):
        def cost(bauxite):
            return {"ore": bauxite, "gas": 100, "mineral_inputs": {"nullius-crushed-bauxite": bauxite}}
        routes = {"default": cost(10), "rp1": cost(5), "co2": cost(19)}
        self.assertEqual(fuel_cost_violations({"fulgora": routes}),
                         ["fulgora CO2 fuel requires less than twice the default bauxite",
                          "fulgora CO2 gas cost must exceed RP-1"])


class SplitRawTest(unittest.TestCase):
    def test_imports_are_not_local_input(self):
        split = split_raw({"iron-ore": 10, "nullius-volcanic-gas": 100, "nullius-rutile": 4},
                          {"iron-ore", "nullius-volcanic-gas"}, {"nullius-volcanic-gas": {}})
        self.assertEqual(split, {"ore": 10.0, "gas": 100.0, "imports": {"nullius-rutile": 4}})


if __name__ == "__main__":
    unittest.main()
