"""Forbidden materials must fail even when available at the research boundary."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
from contextlib import redirect_stdout
from io import StringIO
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from analyze_factorio_prereqs import analyze, parse_arguments, TestFailure, main

class ForbiddenProductsTest(unittest.TestCase):
    def test_available_material_is_still_a_dependency(self):
        data = {'item': {n: {'stack_size': 10} for n in ('science', 'titanium')},
                'character': {'character': {'crafting_categories': ['crafting'], 'crafting_speed': 1}},
                'recipe': {'science': {'name': 'science', 'enabled': True, 'category': 'crafting',
                    'ingredients': [{'type': 'item', 'name': 'titanium', 'amount': 1}],
                    'results': [{'type': 'item', 'name': 'science', 'amount': 1}]}},
                'technology': {}}
        args = parse_arguments(['--available', 'titanium', '--forbid-product', 'titanium', 'science'])
        args.targets = ['science']
        report = analyze(data, args)
        self.assertFalse(report['unresolved'])
        self.assertEqual(report['forbidden_dependencies'], ['titanium'])
        with patch('sys.argv', ['analyzer', '--available', 'titanium',
                                '--forbid-product', 'titanium', 'science']), \
             patch('analyze_factorio_prereqs.dump_resolved_data', return_value=(data, None)), \
             redirect_stdout(StringIO()):
            self.assertEqual(main(), 1)
        args.forbid_product = ['unknown']
        with self.assertRaisesRegex(TestFailure, 'unknown forbidden products'):
            analyze(data, args)
        args.forbid_product = []
        self.assertEqual(analyze(data, args)['forbidden_dependencies'], [])
