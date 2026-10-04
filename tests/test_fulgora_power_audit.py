"""Check native electrical delivery against requested energy, not buffer snapshots."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from fulgora_power_audit import summarize_native


class NativePowerAuditTest(unittest.TestCase):
    def test_delivery_and_grounding_units(self):
        phase=dict(ticks=36000,secondary_J=600e6,surge_J=150e6,captures=30,
                   collector_J=1200e6,coil_J=450e6,trips=0,secondary_gaps=10,
                   surge_gaps=20,battery_MJ=15)
        case=dict(factorio_version='test',observations=[dict(name='grid',secondary_MW=2,
                  surge_MW=1,day=phase,night=phase)])
        result=summarize_native(case)['rows'][0]
        self.assertEqual(result['secondary_delivered_percent'],50)
        self.assertEqual(result['surge_delivered_percent'],25)
        self.assertEqual(result['capture_per_minute'],3)
        self.assertEqual(result['collector_output_MW'],2)
        self.assertEqual(result['grounding_MW'],.75)
        self.assertEqual(result['secondary_gap_seconds'],5)

    def test_switch_samples_and_capacitor_charge(self):
        phase=dict(ticks=120,secondary_J=2e6,surge_J=1e6,captures=1,
                   collector_J=3e6,coil_J=0,trips=2,secondary_gaps=0,
                   surge_gaps=0,battery_MJ=0,switch_on=1,sensor_sum=240,sensor_high=2)
        case=dict(factorio_version='test',observations=[dict(name='switched',
                  secondary_MW=1,surge_MW=1,day=phase,night=phase,first_trip=90)])
        result=summarize_native(case)['rows'][0]
        self.assertEqual(result['grounding_switch_on_percent'],25)
        self.assertEqual(result['sensor_mean_percent'],60)
        self.assertEqual(result['sensor_above_80_percent'],50)
        self.assertEqual(result['first_trip_tick'],90)
        self.assertEqual(result['trip_samples'],2)

    def test_absent_surge_is_not_reported_as_full_supply(self):
        phase=dict(ticks=60,secondary_J=1e6,surge_J=0,captures=0,
                   collector_J=0,coil_J=0,trips=0,secondary_gaps=0,surge_gaps=0,battery_MJ=14)
        result=summarize_native(dict(factorio_version='test',observations=[dict(
            name='battery',secondary_MW=1,surge_MW=0,day=phase,night=phase)]))
        self.assertIsNone(result['rows'][0]['surge_delivered_percent'])
        self.assertEqual(result['rows'][0]['secondary_delivered_percent'],100)


if __name__=='__main__':unittest.main()
