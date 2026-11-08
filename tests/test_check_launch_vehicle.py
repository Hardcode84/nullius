#!/usr/bin/env python3
"""Unit tests for the launch vehicle research and cost checks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from check_launch_vehicle import (research_violations, split_raw, co2_research_violations,
                                  fuel_cost_violations, CO2_TECH)


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
        "nullius-volcanic-titanium-metallurgy": ["nullius-physics"],
        "nullius-titanium-rocket-structures": ["nullius-rocket-science-2",
                                               "nullius-volcanic-titanium-metallurgy"],
    }
    unlocks = {
        "nullius-rocket-science-2": "nullius-rocket-stage",
        "nullius-titanium-rocket-structures": "nullius-titanium-rocket-stage",
    }
    return {name: {"name": name, "prerequisites": list(parents),
                   "effects": [{"type": "unlock-recipe", "recipe": unlocks[name]}] if name in unlocks else []}
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
        technologies["nullius-titanium-rocket-structures"]["prerequisites"] = ["nullius-rocket-science-2"]
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 1)
        self.assertIn("nullius-titanium-rocket-structures prerequisites", violations[0])


class FuelContractsTest(unittest.TestCase):
    def test_energy_floor_checks_each_route_and_equality(self):
        for energy, expected in ((61, []), (60, ['vulcanus co2 machine energy 60 J/fuel <= 60'])):
            costs = {'vulcanus': {'co2': {'energy_joules': {'heat': energy * 300}}}}
            self.assertEqual(fuel_cost_violations(costs, 60, 300), expected)

    def test_off_planet_penalty_keeps_solid_and_fluid_classes_separate(self):
        def cost(ore, gas):
            return {'energy_joules': {'electric': 100}, 'ore': ore, 'gas': gas,
                    'raw_inputs': {'nullius-bauxite': ore}}
        routes = {'default': cost(10, 100), 'rp1': cost(5, 10), 'co2': cost(20, 11)}
        self.assertEqual(fuel_cost_violations({'nauvis': routes}, 1, 1), [])
        routes['co2']['gas'] = 10
        self.assertEqual(fuel_cost_violations({'nauvis': routes}, 1, 1),
                         ['nauvis CO2 gas cost must exceed RP-1'])
        routes['co2']['raw_inputs']['nullius-bauxite'] = 19
        self.assertIn('nauvis CO2 fuel requires less than twice the default bauxite',
                      fuel_cost_violations({'nauvis': routes}, 1, 1))

    def test_research_requires_planet_science_probe_and_both_unlocks(self):
        technologies = {
            'nullius-probe-vulcanus': {},
            'nullius-pneumatic-technology': {'prerequisites': ['nullius-probe-vulcanus']},
            'nullius-rocket-science-1': {},
            CO2_TECH: {'prerequisites': ['nullius-rocket-science-1', 'nullius-pneumatic-technology'],
                      'unit': {'ingredients': [['nullius-metallurgic-pack', 20]]},
                      'effects': [{'type': 'unlock-recipe', 'recipe': recipe} for recipe in
                                  ('nullius-aluminum-co2-rocket-fuel', 'nullius-boxed-aluminum-co2-rocket-fuel')]}}
        self.assertEqual(co2_research_violations(technologies), [])
        technologies[CO2_TECH]['unit']['ingredients'] = [['nullius-electromagnetic-pack', 20]]
        technologies['nullius-pneumatic-technology']['prerequisites'] = []
        technologies[CO2_TECH]['effects'].pop()
        errors = co2_research_violations(technologies)
        self.assertEqual(len(errors), 3)
        self.assertTrue(any('metallurgic' in error for error in errors))
        self.assertTrue(any('probe' in error for error in errors))
        self.assertTrue(any('boxed' in error for error in errors))


class SplitRawTest(unittest.TestCase):
    def test_imports_are_not_nauvis_input(self):
        split = split_raw({"iron-ore": 10, "nullius-volcanic-gas": 100, "nullius-rutile": 4},
                          {"iron-ore", "nullius-volcanic-gas"}, {"nullius-volcanic-gas": {}})
        self.assertEqual(split, {"ore": 10.0, "gas": 100.0, "imports": {"nullius-rutile": 4}})


if __name__ == "__main__":
    unittest.main()
