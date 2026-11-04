import tempfile
import json
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.audit_factorio_test_duration import audit


class DurationAuditTest(unittest.TestCase):
    def test_measured_runtime_is_separate_from_deadline_and_missing_runs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            metadata = {'slow': {'until_tick': 20000},
                        'slack': {'until_tick': 120000},
                        'missing': {'until_tick': 1, 'timeout_seconds': 900}}
            for name, value in metadata.items():
                (root / name).mkdir()
                (root / name / 'test.json').write_text(json.dumps(value))
            result = {'wall_time_seconds': 301, 'results': [
                {'case': 'slow', 'status': 'pass', 'tick': 15000, 'duration_seconds': 200},
                {'case': 'slack', 'status': 'pass', 'tick': 300, 'duration_seconds': 5}]}
            with patch('tools.audit_factorio_test_duration.SCENARIOS', root):
                report = audit(result, 9000, 300)
            self.assertFalse(report['suite_within_budget'])
            self.assertEqual([row['case'] for row in report['long_runs']], ['slow'])
            self.assertEqual(len(report['long_deadlines']), 2)
            self.assertEqual(report['missing'], ['missing'])
            self.assertEqual([row['case'] for row in report['excessive_timeouts']], ['missing'])

    def test_unknown_scenario_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary, \
             patch('tools.audit_factorio_test_duration.SCENARIOS', Path(temporary)):
            with self.assertRaisesRegex(ValueError, 'undiscovered scenarios'):
                audit({'wall_time_seconds': 1, 'results': [{'case': 'removed'}]}, 9000, 300)
