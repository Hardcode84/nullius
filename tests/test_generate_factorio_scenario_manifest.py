"""Bounded native-crafting stages preserve the complete production contract."""
import copy
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from generate_factorio_scenario_manifest import split_contract, write_stages


def recipe(name, cycles, inputs, outputs, ticks=600, fuel=None):
    return dict(producer=name, product=next(iter(outputs)), cycles=cycles,
                executor=dict(kind='machine', item='machine', name='machine'),
                ingredients=[dict(name=n, amount=q, type='item') for n, q in inputs.items()],
                outputs=[dict(name=n, amount=q, type='item') for n, q in outputs.items()],
                ticks_per_cycle=ticks, total_ticks_single_executor=ticks * cycles,
                fuel=None if fuel is None else dict(name='gas', amount_per_cycle=fuel,
                                                    total_amount=fuel * cycles))


class CampaignStagesTest(unittest.TestCase):
    def setUp(self):
        self.config = dict(parallelism=2, fixture={'machine': 2}, batch_ticks=1500)
        self.contract = dict(schema=1, assumed_technologies=[],
                             raw_inputs={'ore': 8}, initial_stock={},
                             steps=[recipe('smelt', 8, {'ore': 8}, {'plate': 8})],
                             targets={'plate': 8}, surplus={}, fuel_consumption={})

    def test_stages_copy_stock_and_preserve_every_cycle(self):
        before = copy.deepcopy(self.contract)
        stages = split_contract(self.contract, self.config)
        self.assertEqual(self.contract, before)
        self.assertEqual(len(stages), 2)
        self.assertEqual(stages[0]['targets'], stages[1]['initial_stock'])
        self.assertEqual(stages[-1]['targets'], {'plate': 8})
        self.assertEqual(sum(s['cycles'] for stage in stages for s in stage['steps']), 8)
        self.assertTrue(all(stage['deadline'] <= 2400 for stage in stages))

    def test_fuel_prime_cannot_be_replaced_by_net_positive_output(self):
        self.contract.update(raw_inputs={'ore': 8}, initial_stock={'gas': 1},
                             steps=[recipe('gas', 8, {'ore': 8}, {'gas': 16}, fuel=1)],
                             targets={'gas': 9}, fuel_consumption={'gas': 8})
        stages = split_contract(self.contract, self.config)
        self.assertEqual(stages[0]['initial_stock']['gas'], 1)
        self.assertEqual(sum(s['fuel_consumption']['gas'] for s in stages), 8)
        self.contract['initial_stock'] = {}
        self.contract['targets']['gas'] = 8
        with self.assertRaisesRegex(ValueError, 'no executable batch'):
            split_contract(self.contract, self.config)

    def test_spoilage_is_one_atomic_batch(self):
        self.contract['steps'] = [dict(producer='<spoil:ore>', product='plate', cycles=8,
                                      spoil_ticks=600, ingredients=[dict(name='ore', amount=8)],
                                      outputs=[dict(name='plate', amount=8)])]
        stages = split_contract(self.contract, self.config)
        self.assertEqual(len(stages), 1)
        self.assertEqual(stages[0]['steps'][0]['cycles'], 8)
        self.assertEqual(stages[0]['steps'][0]['total_ticks_single_executor'], 600)
        self.assertEqual(stages[0]['targets'], {'plate': 8})

    def test_recovered_executor_is_accounted_separately_from_targets(self):
        self.contract['steps'].append(recipe('crusher', 1, {'plate': 1}, {'crusher': 1}))
        self.contract['targets'] = {'plate': 7}
        self.contract['executor_stock'] = {'crusher': 1}
        stages = split_contract(self.contract, self.config)
        self.assertEqual(stages[-1]['targets'], {'plate': 7, 'crusher': 1})

    def test_wrong_output_or_fuel_contract_fails(self):
        self.contract['targets']['plate'] = 9
        with self.assertRaisesRegex(ValueError, 'does not conserve plate'):
            split_contract(self.contract, self.config)
        self.contract['targets']['plate'] = 8
        self.contract['fuel_consumption'] = {'gas': 1}
        with self.assertRaisesRegex(ValueError, 'fuel does not conserve gas'):
            split_contract(self.contract, self.config)

    def test_regeneration_removes_obsolete_generated_stages(self):
        self.config['case'] = 'campaign'
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_stages(self.contract, self.config, root, False)
            self.assertTrue((root / 'campaign-smelt' / 'control.lua').is_file())
            write_stages(self.contract, self.config, root, True)
            self.config['batch_ticks'] = 3000
            with self.assertRaisesRegex(RuntimeError, 'stale'):
                write_stages(self.contract, self.config, root, True)
            write_stages(self.contract, self.config, root, False)
            self.assertFalse((root / 'campaign-smelt').exists())
            write_stages(self.contract, self.config, root, True)

    def test_unbounded_single_cycle_is_rejected(self):
        self.contract['steps'][0]['ticks_per_cycle'] = 32000
        with self.assertRaisesRegex(ValueError, 'single cycle exceeds'):
            split_contract(self.contract, self.config)
