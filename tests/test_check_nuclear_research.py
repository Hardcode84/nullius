#!/usr/bin/env python3
"""Unit tests for the nuclear reactor split and fission branch checks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

import analyze_factorio_prereqs as prereqs
from check_nuclear_research import (ANTIMATTER, FISSION, FISSION_BRANCH, FORMER_PREREQUISITES, FUSION,
                                    REACTOR, RECIPE_UNLOCKS, RELEASED, URANIUM, research_violations)


def nuclear_tree():
    prerequisites = {
        "nullius-empiricism-5": [],
        "nullius-checkpoint-thermal-tank": [],
        "nullius-isotope-separation": [],
        "nullius-checkpoint-tritium": ["nullius-isotope-separation"],
        REACTOR: ["nullius-checkpoint-thermal-tank", "nullius-empiricism-5"],
        FUSION: [REACTOR, "nullius-checkpoint-tritium"],
        "nullius-boiling-3": [FUSION],
        "nullius-astronomy": ["nullius-boiling-3"],
        "nullius-nuclear-power-3": ["nullius-astronomy"],
        "nullius-checkpoint-breeder-cell": ["nullius-nuclear-power-3"],
        "nullius-checkpoint-pressure-steam": ["nullius-nuclear-power-3"],
        "nullius-boiling-4": ["nullius-checkpoint-pressure-steam"],
        "nullius-checkpoint-uranium-ore": ["nullius-astronomy"],
        URANIUM: ["nullius-checkpoint-uranium-ore"],
        "nullius-wildlife-management-1": [URANIUM],
        FISSION: [URANIUM, REACTOR],
        "nullius-checkpoint-enriched-uranium": [FISSION],
        "nullius-solar-power-3": [],
        ANTIMATTER: ["nullius-solar-power-3", "nullius-checkpoint-enriched-uranium",
                     "nullius-checkpoint-breeder-cell", "nullius-boiling-4"],
        "nullius-rocket-science-3": [ANTIMATTER],
    }
    unlocks = {}
    for recipe, technology in RECIPE_UNLOCKS.items():
        unlocks.setdefault(technology, []).append(recipe)
    return {name: {"name": name, "prerequisites": list(parents),
                   "effects": [{"type": "unlock-recipe", "recipe": recipe} for recipe in unlocks.get(name, [])]}
            for name, parents in prerequisites.items()}


class NuclearResearchTest(unittest.TestCase):
    def test_split_tree_preserves_former_closures(self):
        self.assertEqual(research_violations(nuclear_tree()), [])

    def test_fission_through_breeder_research_is_rejected(self):
        technologies = nuclear_tree()
        technologies[FISSION]["prerequisites"].append("nullius-checkpoint-breeder-cell")
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 1)
        self.assertIn(f"{FISSION} prerequisites", violations[0])

    def test_reactor_unlocked_with_fusion_cells_is_rejected(self):
        technologies = nuclear_tree()
        technologies[FUSION]["effects"].append({"type": "unlock-recipe", "recipe": "nullius-reactor"})
        self.assertEqual(research_violations(technologies), [
            f"nullius-reactor unlocked by ['{FUSION}', '{REACTOR}'], expected {REACTOR}"])

    def test_released_breeder_research_may_leave_uranium_consumers(self):
        technologies = nuclear_tree()
        exempt = FISSION_BRANCH | {REACTOR}
        self.assertEqual(prereqs.moved_research_violations(technologies, FORMER_PREREQUISITES, exempt), [
            "nullius-wildlife-management-1 closure: lost ['nullius-nuclear-power-3'], gained []"])
        self.assertEqual(prereqs.moved_research_violations(technologies, FORMER_PREREQUISITES, exempt,
                                                           RELEASED), [])

    def test_antimatter_without_the_fusion_ladder_loses_closure(self):
        technologies = nuclear_tree()
        technologies[ANTIMATTER]["prerequisites"].remove("nullius-boiling-4")
        violations = research_violations(technologies)
        lost = "closure: lost ['nullius-boiling-4', 'nullius-checkpoint-pressure-steam'], gained []"
        self.assertEqual(len(violations), 3)
        self.assertIn(f"{ANTIMATTER} prerequisites", violations[0])
        self.assertEqual(violations[1:], [f"{ANTIMATTER} {lost}", f"nullius-rocket-science-3 {lost}"])


if __name__ == "__main__":
    unittest.main()
