"""Research bills and checkpoint gates use native research state."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from audit_factorio_research import audit, costs


class ResearchAuditTests(unittest.TestCase):
    def test_native_formula_count_and_automatic_checkpoint_cost(self):
        data = {'technology': {
            'research': {'unit': {'count_formula': 'L*10', 'time': 60,
                                  'ingredients': [['science', 2]]}},
            'nullius-checkpoint-test': {'unit': {'count': 999, 'time': 60,
                                                'ingredients': [['science', 10]]}},
        }}
        bill = costs(data, {'research': {'count': 30, 'level': 3}}, data['technology'])
        self.assertEqual(bill['packs'], {'science': 60})
        self.assertEqual(bill['lab_hours_at_speed_one'], 0.5)
        self.assertEqual(bill['formula_levels'][0]['level'], 3)

    def test_pack_cannot_unlock_itself_and_character_has_placement_item(self):
        data = {
            'technology': {
                'science': {'unit': {'count': 1, 'time': 1, 'ingredients': [['pack', 1]]},
                            'effects': [{'type': 'unlock-recipe', 'recipe': 'pack'}]},
                'nullius-checkpoint-body': {},
            },
            'recipe': {
                'pack': {'name': 'pack', 'results': [{'name': 'pack', 'amount': 1}]},
                'body': {'name': 'body', 'results': [{'name': 'body-item', 'amount': 1}]},
            },
            'item': {'body-item': {'place_result': 'body'}},
            'character': {'body': {}},
        }
        runtime = {
            'factorio_version': 'test', 'enabled_recipes': ['body'],
            'research': {n: {'enabled': True, 'count': 1, 'level': 1} for n in data['technology']},
            'definitions': {'body': [[3, 1, 1, [['body']]]]},
        }
        report = audit(data, runtime, {'milestones': [], 'supply_rates_per_minute': [120], 'largest_costs': 1})
        self.assertEqual(report['science_gate_gaps'][0]['technology'], 'science')
        self.assertEqual(report['checkpoint_gaps'], [])
        self.assertEqual(report['checkpoints'][0]['status'], 'gate_open')


if __name__ == '__main__':
    unittest.main()
