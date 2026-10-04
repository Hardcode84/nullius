"""Check island boundaries, obstructed area, and configurable factory blocks."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from analyze_fulgora_area import terrain, compare, dimensions


class FulgoraAreaTest(unittest.TestCase):
    def test_disconnected_land_and_cliff_bounds(self):
        row = dict(
            seed=0,
            center=[0, 0],
            size=8,
            vents=0,
            land_rows=[[[0, 2]]] * 2 + [[]] + [[[4, 6]]] * 2 + [[]] * 3,
            cliffs=[[4, 3, 5, 4], [-5, -5, -2, -2]],
            landing=[4, 3],
        )
        result, _, _ = terrain(row, dict(block_size=2, minimum_island_tiles=1))
        self.assertEqual(result["land_tiles"], 8)
        self.assertEqual(result["cliff_free_tiles"], 7)
        self.assertEqual(result["block_tiles"], 4)
        self.assertEqual(result["complete_island_median"], 4)
        self.assertFalse(result["landing"]["clipped"])
        self.assertEqual(result["landing"]["cliff_free_tiles"], 3)
        self.assertTrue(any(i["clipped"] for i in result["islands"]))

    def test_block_size_and_insufficient_space(self):
        factory = dict(layouts={"test": dict(required_blocks=3, island_site_tiles=11)})
        site = dict(
            seed=0,
            center=[0, 0],
            land_tiles=16,
            landing={"block_tiles": 8},
            islands=[{"block_tiles": 8}, {"block_tiles": 4}],
        )
        result = compare(factory, [site], 2)[0]
        self.assertEqual(result["minimum_islands_by_blocks"], 2)
        self.assertFalse(result["landing_fits_by_area"])
        factory["layouts"]["test"]["required_blocks"] = 4
        self.assertIsNone(compare(factory, [site], 2)[0]["minimum_islands_by_blocks"])

    def test_tile_footprint_rounds_up(self):
        self.assertEqual(
            dimensions({"collision_box": [[-1.4, -2.4], [1.4, 2.4]]}), (3, 5)
        )

    def test_malformed_mask_fails(self):
        with self.assertRaisesRegex(ValueError, "incomplete terrain mask"):
            terrain(dict(size=2, land_rows=[]), {})
