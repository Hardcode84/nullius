"""Correlation contracts reject missing planets, media loss, and productivity."""
import copy
import itertools
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_astronomy import PLANETS, ladder_violations


class CorrelationTests(unittest.TestCase):
    def setUp(self):
        self.data = {'recipe': {}}
        for size in range(1, 4):
            for planets in itertools.combinations(PLANETS, size):
                count = 20 if size == 1 else 10
                self.data['recipe']['nullius-correlate-' + '-'.join(planets)] = {
                    'ingredients': [{'name': f'nullius-{p}-interferometric-recording', 'amount': count} for p in planets],
                    'results': [{'name': 'nullius-astronomy-pack', 'amount': 1 if size == 1 else 5 * size * (size - 1)},
                                {'name': 'nullius-blank-recording-module', 'amount': count * size}],
                    'maximum_productivity': 0,
                }

    def test_ladder(self):
        self.assertEqual(ladder_violations(self.data), [])

    def test_contract_mutations(self):
        name = 'nullius-correlate-fulgora-nauvis'
        for mutation in ('repeated', 'blank-loss', 'productivity', 'missing'):
            with self.subTest(mutation=mutation):
                data = copy.deepcopy(self.data)
                recipe = data['recipe'][name]
                if mutation == 'repeated':
                    recipe['ingredients'][1]['name'] = recipe['ingredients'][0]['name']
                elif mutation == 'blank-loss':
                    recipe['results'][1]['amount'] -= 1
                elif mutation == 'productivity':
                    recipe['maximum_productivity'] = 1
                else:
                    del data['recipe'][name]
                self.assertTrue(ladder_violations(data))
