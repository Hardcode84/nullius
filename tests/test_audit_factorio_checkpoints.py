"""Checkpoint production, consumption, and placement are distinct actions."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from audit_factorio_checkpoints import action_rows


class CheckpointActionsTest(unittest.TestCase):
    def test_production_does_not_prove_consumption(self):
        data = {'recipe': {'use': {'ingredients': [{'name': 'part', 'amount': 1}]}}}
        products = {'part': {'source': 'make'}}
        req = [[1, 2, 8, [['part']]]]
        self.assertFalse(action_rows(data, {}, req, products, set(), set())[0]['witnesses'])
        self.assertEqual(action_rows(data, {}, req, products, {'use'}, set())[0]['witnesses'][0]['recipe'], 'use')

    def test_alternative_ratio_rounds_up(self):
        row = action_rows({'recipe': {}}, {}, [[1, 1, 400, [['crushed', 1.2]]]],
                          {'crushed': {'source': 'local extraction'}}, set(), set())[0]
        self.assertEqual(row['witnesses'][0]['count'], 334)

    def test_craftable_building_must_allow_surface(self):
        entity = dict(name='well', minable={'result': 'well'},
                      surface_conditions=[{'property': 'magnetic-field', 'max': 98}])
        data = {'recipe': {}, 'assembling-machine': {'well': entity}}
        req = [[3, 3, 1, [['well']]]]
        products = {'well': {'source': 'make'}}
        self.assertFalse(action_rows(data, {'magnetic-field': 99}, req, products, set(), set())[0]['witnesses'])
        self.assertTrue(action_rows(data, {'magnetic-field': 90}, req, products, set(), set())[0]['witnesses'])

    def test_hidden_statistics_do_not_satisfy_checkpoint(self):
        data = {'recipe': {'box': {'hide_from_stats': True,
                                  'ingredients': [{'name': 'part', 'amount': 1}],
                                  'results': [{'name': 'boxed', 'amount': 1}]}}}
        products = {'part': {'source': 'raw'}, 'boxed': {'source': 'box'}}
        for kind, material in ((1, 'boxed'), (2, 'part')):
            row = action_rows(data, {}, [[1, kind, 1, [[material]]]], products, {'box'}, set())[0]
            self.assertFalse(row['witnesses'])


if __name__ == '__main__':
    unittest.main()
