#!/usr/bin/env python3
"""Unit tests for the nuclear reactor split and fission branch checks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

import analyze_factorio_prereqs as prereqs
from check_nuclear_research import (ANTIMATTER, ASTRONOMY, ENRICHMENT, FISSION, FISSION_BRANCH, FLUORINE,
                                    FORMER_PREREQUISITES, FUSION, ISOTOPES, PREREQUISITES, REACTOR, RECIPE_UNLOCKS,
                                    SEAWATER, URANIUM, URANIUM_ORE, WILDLIFE, closure_rules, research_violations)


def nuclear_tree():
    prerequisites = {
        "nullius-empiricism-5": [],
        "nullius-checkpoint-thermal-tank": [],
        "nullius-electrolysis-4": [],
        ISOTOPES: ["nullius-electrolysis-4"],
        FLUORINE: ["nullius-electrolysis-4"],
        "nullius-checkpoint-tritium": [ISOTOPES],
        "nullius-biochemistry-4": [],
        SEAWATER: ["nullius-biochemistry-4"],
        REACTOR: ["nullius-checkpoint-thermal-tank", "nullius-empiricism-5"],
        FUSION: [REACTOR, "nullius-checkpoint-tritium"],
        "nullius-boiling-3": [FUSION],
        ASTRONOMY: ["nullius-boiling-3"],
        "nullius-nuclear-power-3": [ASTRONOMY],
        "nullius-checkpoint-breeder-cell": ["nullius-nuclear-power-3"],
        "nullius-checkpoint-pressure-steam": ["nullius-nuclear-power-3"],
        "nullius-boiling-4": ["nullius-checkpoint-pressure-steam"],
        URANIUM_ORE: [ASTRONOMY],
        URANIUM: [SEAWATER, FLUORINE],
        ENRICHMENT: [URANIUM],
        "nullius-checkpoint-copper-ingot": [],
        "nullius-checkpoint-worm": [],
        "nullius-personal-storage-3": [],
        WILDLIFE: PREREQUISITES[WILDLIFE],
        FISSION: [ENRICHMENT, REACTOR],
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
        self.assertIn(f"{FISSION} prerequisites", violations[0])
        self.assertEqual(violations[1:], [f"nullius-checkpoint-enriched-uranium requires {ASTRONOMY}",
                                          f"{FISSION} requires {ASTRONOMY}"])

    def test_uranium_through_astronomy_is_rejected(self):
        technologies = nuclear_tree()
        technologies[SEAWATER]["prerequisites"].append(URANIUM_ORE)
        violations = research_violations(technologies)
        self.assertIn(f"{SEAWATER} prerequisites", violations[0])
        self.assertEqual(violations[1:], [f"{name} requires {ASTRONOMY}" for name in sorted(FISSION_BRANCH - {FLUORINE})])

    def test_reactor_unlocked_with_fusion_cells_is_rejected(self):
        technologies = nuclear_tree()
        technologies[FUSION]["effects"].append({"type": "unlock-recipe", "recipe": "nullius-reactor"})
        self.assertEqual(research_violations(technologies), [
            f"nullius-reactor unlocked by ['{FUSION}', '{REACTOR}'], expected {REACTOR}"])

    def test_ore_yellowcake_at_uranium_processing_is_rejected(self):
        technologies = nuclear_tree()
        technologies[URANIUM]["effects"].append({"type": "unlock-recipe", "recipe": "nullius-yellowcake"})
        self.assertEqual(research_violations(technologies), [
            f"nullius-yellowcake unlocked by ['{URANIUM_ORE}', '{URANIUM}'], expected {URANIUM_ORE}"])

    def test_uranium_consumers_trade_ore_research_for_enrichment(self):
        technologies = nuclear_tree()
        exempt = FISSION_BRANCH | {REACTOR}
        lost, gained = prereqs.moved_research_changes(technologies, FORMER_PREREQUISITES, exempt)[WILDLIFE]
        self.assertEqual(sorted(gained), ["nullius-biochemistry-4", FLUORINE, SEAWATER, ENRICHMENT])
        self.assertIn(URANIUM_ORE, lost)
        self.assertEqual(prereqs.moved_research_violations(technologies, FORMER_PREREQUISITES, exempt,
                                                           *closure_rules(technologies)), [])

    def test_uranium_consumer_before_enrichment_is_rejected(self):
        technologies = nuclear_tree()
        prerequisites = technologies[WILDLIFE]["prerequisites"]
        prerequisites[prerequisites.index(ENRICHMENT)] = URANIUM
        # Its closure change stays within the released and gained research, so
        # only the pinned prerequisites catch it.
        self.assertEqual(research_violations(technologies), [
            f"{WILDLIFE} prerequisites: expected {PREREQUISITES[WILDLIFE]}, found {prerequisites}"])

    def test_antimatter_without_the_fusion_ladder_loses_closure(self):
        technologies = nuclear_tree()
        technologies[ANTIMATTER]["prerequisites"].remove("nullius-boiling-4")
        violations = research_violations(technologies)
        lost = (f"closure: lost ['nullius-boiling-4', 'nullius-checkpoint-pressure-steam', '{URANIUM_ORE}'], "
                f"gained ['nullius-biochemistry-4', '{FLUORINE}', '{SEAWATER}', '{ENRICHMENT}']")
        self.assertEqual(len(violations), 3)
        self.assertIn(f"{ANTIMATTER} prerequisites", violations[0])
        self.assertEqual(violations[1:], [f"{ANTIMATTER} {lost}", f"nullius-rocket-science-3 {lost}"])


if __name__ == "__main__":
    unittest.main()
