import unittest

from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from analyze_fulgora_power import minimum_demand


class TripDemandTest(unittest.TestCase):
    def test_strict_boundaries(self):
        for power, required in ((0, 0), (1e6, 0), (1.5e6, 0.5e6), (2e6, 1e6), (100e6, 50e6)):
            with self.subTest(power=power):
                demand = minimum_demand(power, 2, 1e6)
                self.assertEqual(demand, required)
                self.assertFalse(power > 2 * demand and power - demand > 1e6)
                if demand:
                    self.assertTrue(power > 2 * (demand - 1) and power - (demand - 1) > 1e6)


if __name__ == '__main__':
    unittest.main()
