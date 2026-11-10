"""Regression tests for the copper research move and deep copper supply."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_copper_research import (COPPER, DEEP_RECIPES, FIXED_SUPPLY, ORE, ORE_RECIPES, ROOTS,
                                   violations)

INGOT = 'nullius-checkpoint-copper-ingot'


def tree():
    # The ore checkpoint stands for the removed branch restored from the catalog.
    parents = {name: [] for name in ROOTS}
    parents.update({'nullius-asteroid-mining-1': [ROOTS[0]], ORE: ['nullius-asteroid-mining-1'],
                    COPPER: ROOTS, INGOT: [COPPER]})
    technologies = {name: {'name': name, 'prerequisites': list(prerequisites), 'effects': []}
                    for name, prerequisites in parents.items()}
    technologies[COPPER]['effects'] = [{'type': 'unlock-recipe', 'recipe': 'nullius-' + name}
                                       for name in DEEP_RECIPES + ORE_RECIPES]
    recipes = {name: {'name': name, 'allow_productivity': False} for name in FIXED_SUPPLY}
    return {'technology': technologies, 'recipe': recipes}


class CopperResearchTest(unittest.TestCase):
    def test_moved_tree_passes(self):
        self.assertEqual(violations(tree()), [])

    def test_changed_copper_prerequisites_are_rejected(self):
        data = tree()
        data['technology'][COPPER]['prerequisites'].append(ORE)
        self.assertIn('Copper Production prerequisites changed', violations(data))

    def test_ore_route_outside_copper_production_is_rejected(self):
        data = tree()
        data['technology'][ORE]['effects'].append({'type': 'unlock-recipe', 'recipe': 'nullius-copper-solution'})
        self.assertIn(f'copper-solution: expected {COPPER}, found {sorted([COPPER, ORE])}', violations(data))

    def test_deep_filtration_productivity_is_rejected(self):
        data = tree()
        data['recipe']['nullius-deep-slurry-filtration']['allow_productivity'] = True
        self.assertIn('nullius-deep-slurry-filtration permits productivity', violations(data))

    def test_productivity_research_on_deep_supply_is_rejected(self):
        data = tree()
        data['technology'][ROOTS[0]]['effects'].append(
            {'type': 'change-recipe-productivity', 'recipe': 'nullius-boxed-deep-slurry-filtration', 'change': 0.01})
        self.assertIn(f'{ROOTS[0]} changes nullius-boxed-deep-slurry-filtration productivity', violations(data))


if __name__ == '__main__':
    unittest.main()
