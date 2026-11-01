import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from audit_recipe_unlocks import audit


class RecipeUnlockAuditTest(unittest.TestCase):
    def fixture(self):
        return {
            'recipe': {'ordinary': {'enabled': False}, 'bulk': {'enabled': False}},
            'technology': {
                'planet': {'unit': {'ingredients': [['em', 1]]}},
                'ordinary-tech': {'prerequisites': ['planet'], 'effects': [
                    {'type': 'unlock-recipe', 'recipe': 'ordinary'}]},
                'bulk-tech': {'prerequisites': ['ordinary-tech'], 'effects': [
                    {'type': 'unlock-recipe', 'recipe': 'bulk'}]},
            },
        }

    def config(self):
        return {'scope': 'test', 'recipes': [
            {'name': 'bulk', 'ordinary': 'ordinary', 'classification': 'bulk', 'requires': ['planet']}],
            'absent': ['removed']}

    def test_transitive_prerequisites_and_science(self):
        result = audit(self.fixture(), self.config())
        self.assertEqual(result['findings'], [])
        self.assertEqual(result['recipes'][0]['gates'][0]['science'], ['em'])

    def test_planet_gate_does_not_imply_ordinary_gate(self):
        data = self.fixture()
        data['technology']['bulk-tech']['prerequisites'] = ['planet']
        findings = audit(data, self.config())['findings']
        self.assertEqual([f['kind'] for f in findings], ['bulk_bypasses_ordinary'])

    def test_alternative_unlock_can_bypass_planet(self):
        data = self.fixture()
        data['technology']['bypass'] = {'effects': [{'type': 'unlock-recipe', 'recipe': 'bulk'}]}
        findings = audit(data, self.config())['findings']
        self.assertEqual({f['kind'] for f in findings}, {'missing_research_gate', 'bulk_bypasses_ordinary'})
        self.assertTrue(all(f['technology'] == 'bypass' for f in findings))

    def test_enabled_missing_and_removed(self):
        data = self.fixture()
        data['recipe']['bulk']['enabled'] = True
        data['recipe']['removed'] = {}
        data['technology']['bulk-tech']['effects'] = []
        self.assertEqual({f['kind'] for f in audit(data, self.config())['findings']},
                         {'enabled_without_research', 'missing_unlock', 'unexpected_recipe'})

    def test_unknown_names_fail(self):
        config = self.config()
        config['recipes'][0]['requires'] = ['typo']
        with self.assertRaisesRegex(ValueError, 'Unknown required technology'):
            audit(self.fixture(), config)
        config = self.config()
        config['recipes'][0]['ordinary'] = 'typo'
        with self.assertRaisesRegex(ValueError, 'Unknown ordinary recipe'):
            audit(self.fixture(), config)

    def test_duplicate_inventory_fails(self):
        config = self.config()
        config['recipes'] *= 2
        with self.assertRaisesRegex(ValueError, 'Duplicate audited recipe'):
            audit(self.fixture(), config)


if __name__ == '__main__':
    unittest.main()
