"""Fixed starter-fleet timing bounds and explicit uncertainty contracts."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from plan_factorio_bootstrap import batch_bound, expected_catalog, character_catalog, fleet_placements, buffer_capacities
from plan_factorio_factory import TestFailure


def recipe(name, machine, seconds, flows):
    return dict(recipe=name, machine=machine, seconds=seconds, flows=flows,
                joules=0, native_productivity=0, uncertain_outputs=[])


class BootstrapPlannerTest(unittest.TestCase):
    def test_fleet_mode_requires_the_same_supplied_item(self):
        data = {'item': {'assembler': {'place_result': 'normal'}},
                'assembling-machine': {
                    'overcharged': {'name': 'overcharged', 'placeable_by': {'item': 'assembler', 'count': 1}},
                    'other': {'name': 'other', 'placeable_by': {'item': 'other-item', 'count': 1}}}}
        self.assertEqual(fleet_placements(data, {'assembler': 2}, {}), {'assembler': 'normal'})
        self.assertEqual(fleet_placements(data, {'assembler': 2}, {'assembler': 'overcharged'}),
                         {'assembler': 'overcharged'})
        with self.assertRaisesRegex(TestFailure, 'build item'):
            fleet_placements(data, {'assembler': 2}, {'assembler': 'other'})
        with self.assertRaisesRegex(TestFailure, 'supplied fleet item'):
            fleet_placements(data, {}, {'assembler': 'overcharged'})

    def test_shared_machine_work_is_summed(self):
        catalog = [recipe('smelt', 'machine', 2, {'ore': -1, 'plate': 1}),
                   recipe('shape', 'machine', 3, {'plate': -1, 'gear': 1})]
        r = batch_bound(catalog, {'gear': 12}, ['ore'], {'machine': 2}, {}, set())
        self.assertAlmostEqual(r['production_minutes_lower_bound'], .5, places=6)
        self.assertAlmostEqual(r['machine_utilization']['machine'], 1, places=6)

    def test_different_machines_overlap_and_duty_scales(self):
        catalog = [recipe('a', 'a', 2, {'ore': -1, 'plate': 1}),
                   recipe('b', 'b', 3, {'plate': -1, 'gear': 1})]
        r = batch_bound(catalog, {'gear': 10}, ['ore'], {'a': 1, 'b': 1}, {}, set(), .5)
        self.assertAlmostEqual(r['production_minutes_lower_bound'], 1, places=6)

    def test_liquid_surplus_cannot_disappear(self):
        catalog = [recipe('joint', 'a', 1, {'ore': -1, 'plate': 1, 'waste': 2})]
        args = (catalog, {'plate': 10}, ['ore'], {'a': 1})
        self.assertEqual(batch_bound(*args, {'waste': 19}, set())['status'], 'infeasible')
        r = batch_bound(*args, {'waste': 20}, set())
        self.assertEqual(r['stored_surplus'], {'waste': 20})

    def test_unavailable_machine_cannot_supply_product(self):
        catalog = [recipe('smelt', 'furnace', 2, {'ore': -1, 'plate': 1})]
        r = batch_bound(catalog, {'plate': 10}, ['ore'], {'assembler': 1}, {}, set())
        self.assertEqual(r['status'], 'infeasible')

    def test_independent_probability_is_opt_in_and_version_neutral(self):
        for key in ('probability', 'independent_probability'):
            row = recipe('random', 'filter', 2, {'ore': 0})
            row['uncertain_outputs'] = [{'name': 'ore', 'amount': 1, key: .25}]
            self.assertEqual(expected_catalog([row], ['random'])[0]['flows']['ore'], .25)
            self.assertEqual(row['flows']['ore'], 0)
            self.assertEqual(expected_catalog([row], [])[0]['flows']['ore'], 0)

    def test_recovery_experiment_scales_outputs_without_scaling_sludge_or_time(self):
        rows = []
        for name, scale in [('ordinary', 1), ('boxed', 5)]:
            row = recipe(name, 'filter', 2 * scale, {'sludge': -50 * scale, name: 0})
            row['uncertain_outputs'] = [{'name': name, 'amount': 1, 'independent_probability': .25}]
            rows.append(row)
        scaled = expected_catalog(rows, ['ordinary', 'boxed'], 4)
        for row, scale in zip(scaled, [1, 5]):
            self.assertEqual(row['flows'][row['recipe']], 1)
            self.assertEqual(row['flows']['sludge'], -50 * scale)
            self.assertEqual(row['seconds'], 2 * scale)
        # Increasing mineral yield must retain downstream processing work.
        mineral = recipe('random', 'filter', 1, {'sludge': -1, 'ore': 0})
        mineral['uncertain_outputs'] = [{'name': 'ore', 'amount': 1, 'probability': .25}]
        smelt = recipe('smelt', 'filter', 2, {'ore': -1, 'plate': 1})
        args = ({'plate': 10}, ['sludge'], {'filter': 1}, {}, set())
        original = batch_bound(expected_catalog([mineral, smelt], ['random']), *args)
        changed = batch_bound(expected_catalog([mineral, smelt], ['random'], 4), *args)
        self.assertAlmostEqual(original['production_minutes_lower_bound'], 1, places=6)
        self.assertAlmostEqual(changed['production_minutes_lower_bound'], .5, places=6)
        self.assertEqual(rows[0]['flows']['ordinary'], 0)
        for invalid in (0, -1, .5, True):
            with self.assertRaises(TestFailure):
                expected_catalog(rows, ['ordinary', 'boxed'], invalid)

    def test_absolute_recovery_amount_survives_shipping_a_new_baseline(self):
        row = recipe('random', 'filter', 2, {'ore': 0})
        row['uncertain_outputs'] = [{'name': 'ore', 'amount': 3, 'probability': .25}]
        self.assertEqual(expected_catalog([row], ['random'])[0]['flows']['ore'], .75)
        self.assertEqual(expected_catalog([row], ['random'], 1)[0]['flows']['ore'], .25)
        self.assertEqual(expected_catalog([row], ['random'], 3)[0]['flows']['ore'], .75)

    def test_handcrafting_uses_android_categories_and_rejects_fluids(self):
        data = {'character': {'android': {'crafting_categories': ['large-crafting'], 'crafting_speed': 2}},
                'technology': {}, 'fluid': {'gas': {'fuel_value': '1kJ'}},
                'recipe': {'machine': {'name': 'machine', 'category': 'large-crafting',
                           'ingredients': [{'name': 'plate', 'amount': 1}],
                           'results': [{'name': 'machine', 'amount': 1}], 'energy_required': 6},
                           'fluid': {'name': 'fluid', 'category': 'large-crafting', 'ingredients': {},
                           'results': [{'type': 'fluid', 'name': 'gas', 'amount': 1}]}}}
        boundary = {'technologies': [], 'surface': {}, 'fuel': 'gas',
                    'forbid_categories': [], 'uncertain_outputs': 'guaranteed',
                    'heat_contract': {'MAX_HEAT': 500}, 'extractors': {}}
        name, rows = character_catalog(data, boundary, 'android')
        self.assertEqual([r['recipe'] for r in rows], ['machine'])
        self.assertEqual(rows[0]['seconds'], 3)
        result = batch_bound(rows, {'machine': 20}, ['plate'], {name: 1}, {}, set(), .5)
        self.assertAlmostEqual(result['production_minutes_lower_bound'], 1, places=6)

    def test_shared_or_ranged_outputs_cannot_silently_be_averaged(self):
        for product in ({'name': 'ore', 'amount': 1, 'shared_probability': {'min': 0, 'max': .5}},
                        {'name': 'ore', 'amount_min': 1, 'amount_max': 4}):
            row = recipe('random', 'filter', 2, {'ore': 0})
            row['uncertain_outputs'] = [product]
            with self.assertRaises(TestFailure):
                expected_catalog([row], ['random'])
        with self.assertRaises(TestFailure):
            expected_catalog([], ['missing'])


if __name__ == '__main__':
    unittest.main()

class BufferCapacityTest(unittest.TestCase):
    def test_mixed_tanks_and_separate_fluids(self):
        data = {'fluid': {'oil': {}, 'water': {}}, 'storage-tank': {
            'small': {'fluid_box': {'volume': 10}},
            'medium': {'fluid_box': {'volume': 100}}}}
        self.assertEqual(buffer_capacities(data, {'oil': {'small': 2, 'medium': 2},
                                                  'water': {'small': 1}}), {'oil': 220, 'water': 10})
        with self.assertRaises(TestFailure):
            buffer_capacities(data, {'oil': {'small': -1}})
        with self.assertRaises(TestFailure):
            buffer_capacities(data, {'oil': {'unknown': 1}})
