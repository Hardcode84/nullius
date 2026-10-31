import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from compare_factorio_recipe_prototypes import differences


class PrototypeParityTests(unittest.TestCase):
    def test_reports_changed_ingredient_amount(self):
        before = {"recipe": {"motor": {"ingredients": [{"name": "wire", "amount": 2}]}}}
        after = {"recipe": {"motor": {"ingredients": [{"name": "wire", "amount": 3}]}}}
        self.assertEqual(list(differences(before, after)), [
            {"path": "/recipe/motor/ingredients/0/amount", "before": 2, "after": 3}])

    def test_detects_removed_restriction_and_added_unlock(self):
        before = {"recipe": {"surface_conditions": [{"min": 100}]}, "technology": {}}
        after = {"recipe": {}, "technology": {"effects": ["unlock"]}}
        self.assertEqual(list(differences(before, after)), [
            {"path": "/recipe/surface_conditions", "removed": [{"min": 100}]},
            {"path": "/technology/effects", "added": ["unlock"]}])

    def test_detects_false_versus_zero(self):
        self.assertEqual(list(differences({"enabled": False}, {"enabled": 0})), [
            {"path": "/enabled", "before": False, "after": 0}])

    def test_detects_added_output(self):
        self.assertEqual(len(list(differences([{"name": "iron"}],
                                             [{"name": "iron"}, {"name": "slag"}]))), 1)

    def test_equivalent_numbers_and_key_order(self):
        self.assertEqual(list(differences({"amount": 5, "name": "iron"},
                                         {"name": "iron", "amount": 5.0})), [])

    def test_distinguishes_empty_table_shapes(self):
        self.assertEqual(len(list(differences([], {}))), 1)


if __name__ == "__main__":
    unittest.main()
