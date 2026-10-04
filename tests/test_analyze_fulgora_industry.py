"""Storage bounds must satisfy discharge power as well as stored energy."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from analyze_fulgora_industry import power_requirement


class FulgoraIndustryTest(unittest.TestCase):
    def test_short_gap_is_discharge_limited(self):
        result = power_requirement(10, 15, .5, 200, 10)
        self.assertEqual(result['minimum_full_batteries'], 20)
        self.assertEqual(result['ideal_captured_strikes_per_minute'], 3)

    def test_long_gap_is_energy_limited(self):
        self.assertEqual(power_requirement(10, 15, .5, 200, 60)['minimum_full_batteries'], 40)
        self.assertEqual(power_requirement(0, 15, .5, 200, 60)['minimum_full_batteries'], 0)

    def test_invalid_power_boundary_fails(self):
        with self.assertRaises(ValueError):
            power_requirement(10, 15, 0, 200, 60)
