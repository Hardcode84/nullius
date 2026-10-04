"""Material and executor cycles must not count as a bootstrap route."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from audit_factorio_building_bootstrap import audit
from run_factorio_tests import TestFailure


def recipe(name, inputs, outputs, category='crafting', **extra):
    return dict(name=name, categories=[category], ingredients=[dict(name=n, amount=1) for n in inputs],
                results=[dict(name=n, amount=1) for n in outputs], **extra)


class BuildingBootstrapTest(unittest.TestCase):
    def setUp(self):
        self.config = dict(surface={}, raw={}, starter_items=['nullius-lab'], character='character',
                           entrance_technologies=[], forbid_categories=[], probabilistic_recipes=[], checkpoint_products={})
        self.data = {'technology': {}, 'character': {'character': {'crafting_categories': ['crafting']}},
                     'item': {'nullius-machine': {'place_result': 'nullius-machine'}},
                     'assembling-machine': {'nullius-machine': dict(name='nullius-machine',
                         minable={'result': 'nullius-machine'}, crafting_categories=['machine-work'], energy_source={'type':'electric'})},
                     'lab': {'nullius-lab': dict(name='nullius-lab', minable={'result':'nullius-lab'}, inputs=['science'])},
                     'recipe': {}}

    def check_result(self, targets, roots=()):
        for name in targets:
            self.data['item'].setdefault(name, {})
        return audit(self.data, self.config, targets, roots)

    def test_machine_cannot_build_itself(self):
        self.data['recipe']['machine'] = recipe('machine', [], ['nullius-machine'], 'machine-work')
        self.assertEqual(self.check_result(['nullius-machine'])['blocked_targets'], ['nullius-machine'])
        self.config['starter_items'].append('nullius-machine')
        self.assertEqual(self.check_result(['nullius-machine'])['blocked_targets'], [])

    def test_research_cannot_supply_its_own_science(self):
        self.data['technology']['research'] = dict(unit={'ingredients':[['science',1]]}, effects=[{'type':'unlock-recipe','recipe':'science'}])
        self.data['recipe']['science'] = recipe('science', [], ['science'], enabled=False)
        self.assertEqual(self.check_result(['science'], ['research'])['unreached_research'], ['research'])
        self.data['recipe']['early-science'] = recipe('early-science', [], ['science'])
        self.assertEqual(self.check_result(['science'], ['research'])['unreached_research'], [])

    def test_checkpoint_needs_material_before_unlock(self):
        tech = 'nullius-checkpoint-example'
        self.data['technology'][tech] = dict(unit={'ingredients':[['nullius-checkpoint',1]]}, effects=[])
        with self.assertRaisesRegex(TestFailure, 'Missing checkpoint'):
            self.check_result([], [tech])
        self.config['checkpoint_products'][tech] = [['part']]
        self.assertEqual(self.check_result([], [tech])['unreached_research'], [tech])
        self.data['recipe']['part'] = recipe('part', [], ['part'])
        self.assertEqual(self.check_result([], [tech])['unreached_research'], [])

    def test_burnt_result_requires_fuel_and_burner(self):
        self.data['item']['fuel'] = dict(burnt_result='spent', fuel_categories=['chemical'])
        self.data['locomotive'] = {'engine': dict(name='engine', minable={'result':'engine'},
                                               burner={'fuel_categories':['chemical']})}
        self.data['recipe']['fuel'] = recipe('fuel', [], ['fuel'])
        self.assertEqual(self.check_result(['spent'])['blocked_targets'], ['spent'])
        self.config['starter_items'].append('engine')
        self.assertEqual(self.check_result(['spent'])['blocked_targets'], [])

    def test_random_minerals_require_explicit_policy(self):
        self.data['recipe']['ore'] = recipe('ore', [], ['ore'])
        self.data['recipe']['ore']['results'][0]['probability'] = .25
        self.assertEqual(self.check_result(['ore'])['blocked_targets'], ['ore'])
        self.config['probabilistic_recipes'].append('ore')
        self.assertEqual(self.check_result(['ore'])['blocked_targets'], [])

    def test_disallowed_machine_surface(self):
        self.config['surface'] = {'magnetic-field':99}
        self.data['assembling-machine']['nullius-machine']['surface_conditions'] = [{'property':'magnetic-field','max':98}]
        self.config['starter_items'].append('nullius-machine')
        self.data['recipe']['part'] = recipe('part', [], ['part'], 'machine-work')
        self.assertEqual(self.check_result(['part'])['blocked_targets'], ['part'])

    def test_missing_fluid_port(self):
        self.config['starter_items'].append('nullius-machine')
        self.data['assembling-machine']['nullius-source'] = dict(name='nullius-source',
            minable={'result':'nullius-source'}, crafting_categories=['pumping'],
            energy_source={'type':'electric'}, fluid_boxes=[{'production_type':'output'}])
        self.config['starter_items'].append('nullius-source')
        self.data['recipe']['water'] = recipe('water', [], ['water'], 'pumping')
        self.data['recipe']['water']['results'][0]['type'] = 'fluid'
        self.data['recipe']['part'] = recipe('part', ['water'], ['part'], 'machine-work')
        self.data['recipe']['part']['ingredients'][0]['type'] = 'fluid'
        report = self.check_result(['part'])
        self.assertIn('water', report['products'])
        self.assertEqual(report['blocked_targets'], ['part'])
        self.data['assembling-machine']['nullius-machine']['fluid_boxes'] = [{'production_type':'input'}]
        self.assertEqual(self.check_result(['part'])['blocked_targets'], [])


if __name__ == '__main__':
    unittest.main()
