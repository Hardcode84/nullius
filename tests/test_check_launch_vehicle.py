#!/usr/bin/env python3
"""Unit tests for the launch vehicle research and cost checks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

from check_launch_vehicle import research_violations, split_raw


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
    }
    return {name: {"name": name, "prerequisites": list(parents)}
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

    def test_late_launch_research_is_rejected(self):
        technologies = launch_tree()
        technologies["nullius-rocket-science-1"]["prerequisites"].append("nullius-demolitions-2")
        violations = research_violations(technologies)
        self.assertEqual(len(violations), 1)
        self.assertIn("nullius-rocket-science-1 prerequisites", violations[0])


class SplitRawTest(unittest.TestCase):
    def test_imports_are_not_nauvis_input(self):
        split = split_raw({"iron-ore": 10, "nullius-volcanic-gas": 100, "nullius-rutile": 4},
                          {"iron-ore", "nullius-volcanic-gas"}, {"nullius-volcanic-gas": {}})
        self.assertEqual(split, {"ore": 10.0, "gas": 100.0, "imports": {"nullius-rutile": 4}})


if __name__ == "__main__":
    unittest.main()
