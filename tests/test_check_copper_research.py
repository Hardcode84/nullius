"""Regression tests for staged copper research independence."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_copper_research import ASTEROID_FREE, COPPER, ORE, ROOTS, violations


def tree():
    parents = {name: [] for name in ROOTS}
    parents.update({COPPER: ROOTS, ORE: ['nullius-asteroid-mining-1'],
                    'nullius-asteroid-mining-1': [ROOTS[0]],
                    'nullius-reconnaissance-3': ['nullius-asteroid-mining-1'],
                    'nullius-robot-speed-5': [COPPER, 'nullius-reconnaissance-3'],
                    'nullius-wildlife-management-1': [COPPER, 'nullius-reconnaissance-3']})
    parents.update({name: [COPPER] for name in ASTEROID_FREE if name != COPPER})
    technologies = {name: {'name': name, 'prerequisites': list(prerequisites), 'effects': []}
                    for name, prerequisites in parents.items()}
    recipes = ['deep-drilling', 'deep-slurry-filtration', 'boxed-deep-slurry-filtration',
               'copper-roasting', 'boxed-copper-roasting', 'copper-leaching', 'boxed-copper-leaching',
               'box-copper-concentrate', 'unbox-copper-concentrate', 'box-copper-calcine', 'unbox-copper-calcine']
    for name in recipes:
        technologies[COPPER]['effects'].append({'type': 'unlock-recipe', 'recipe': 'nullius-' + name})
    for name in ('copper-solution', 'boxed-copper-solution'):
        technologies[ORE]['effects'].append({'type': 'unlock-recipe', 'recipe': 'nullius-' + name})
    return {'technology': technologies}


class CopperResearchTest(unittest.TestCase):
    def test_independent_asteroid_branch_is_retained(self):
        self.assertEqual(violations(tree()), [])

    def test_asteroid_gate_on_antimatter_is_rejected(self):
        data = tree()
        data['technology']['nullius-antimatter-containment']['prerequisites'].append('nullius-reconnaissance-3')
        self.assertTrue(any('antimatter-containment requires' in message for message in violations(data)))

    def test_early_removal_of_independent_gate_is_rejected(self):
        data = tree()
        data['technology']['nullius-reconnaissance-3']['prerequisites'] = []
        self.assertTrue(any('robot-speed-5 lost' in message for message in violations(data)))

    def test_ore_recipe_stays_with_ore_checkpoint(self):
        data = tree()
        data['technology'][COPPER]['effects'].append(data['technology'][ORE]['effects'].pop())
        self.assertTrue(any('boxed-copper-solution:' in message for message in violations(data)))
