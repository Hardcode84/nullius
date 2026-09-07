"""Reject incomplete or infeasible planet comparisons."""
from copy import deepcopy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from compare_factorio_factory_plans import compare_plans, markdown, TestFailure


class PlanetComparisonTest(unittest.TestCase):
    def test_comparison_requires_feasible_matching_rates_and_construction(self):
        plan = {'rate_per_minute': 120, 'flow': {'status': 'optimal', 'raw_per_minute': {}},
                'construction': {'flow': {'status': 'optimal'}},
                'factory': {'machines': {}, 'process_machines': 10, 'electric_grid_mw': 2,
                            'fuel_per_minute': 0, 'heat_demand_mw_by_minimum_temperature': {}},
                'demands_per_minute': {'science': 120}, 'research': {'packs': {'science': 600}},
                'base_research_supply_hours': 1 / 12, 'research_schedule': {'hours': 1 / 12}}
        report = {'stages': [{'name': 'science', 'plans': [plan]}], 'provenance': {}, 'assumptions': {}}
        reports = {'a': report, 'b': deepcopy(report)}
        spec = {'stages': ['science'], 'rates': [120]}
        reports['b']['stages'][0]['plans'][0]['factory']['process_machines'] = 25
        self.assertEqual(compare_plans(reports, spec)['rows'][0]['machine_ratio_second_to_first'], 2.5)
        result = compare_plans(reports, spec)
        result['science_analysis'] = {p: {'production_lines': []} for p in reports}
        document = markdown(result, dict(spec, title='Capacity', notes=[], research_stage=None, detail_rate=120))
        self.assertNotIn('Research budget', document)
        self.assertNotIn('Physics unlock alone', document)
        spec['rates'] = [60]
        with self.assertRaisesRegex(TestFailure, 'expected one rate'):
            compare_plans(reports, spec)
        spec['rates'] = [120]
        plan['construction']['flow']['status'] = 'infeasible'
        with self.assertRaisesRegex(TestFailure, 'construction must be optimal'):
            compare_plans(reports, spec)


if __name__ == '__main__':
    unittest.main()
