"""Regression tests for the asteroid mining removal check."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_asteroid_removal import violations

RECON = 'nullius-reconnaissance-3'
ROCKET = 'nullius-rocket-science-3'
BATTERY = 'nullius-battery-storage-5'


def tree():
    """Return the rewired tree: each dependent requires the removed branch's prerequisites."""
    parents = {
        'nullius-astronomy': [], 'nullius-mining-productivity-20': [], 'nullius-land-fill-5': [],
        'nullius-wildlife-management-2': [], 'nullius-air-separation-5': [], 'nullius-checkpoint-android-2': [],
        'nullius-checkpoint-solar-panel': [],
        RECON: ['nullius-astronomy', 'nullius-mining-productivity-20', 'nullius-land-fill-5'],
        ROCKET: ['nullius-wildlife-management-2', 'nullius-checkpoint-android-2'],
        BATTERY: ['nullius-air-separation-5', 'nullius-wildlife-management-2', 'nullius-checkpoint-solar-panel'],
        'nullius-robot-speed-5': [RECON],
    }
    technologies = {name: {'name': name, 'prerequisites': list(p), 'effects': []} for name, p in parents.items()}
    return {'technology': technologies, 'item': {'nullius-probe': {}}}


class AsteroidRemovalTest(unittest.TestCase):
    def test_rewired_tree_passes(self):
        self.assertEqual(violations(tree()), [])

    def test_remaining_prototype_is_rejected(self):
        data = tree()
        data['item']['nullius-guide-drone-iron-1'] = {}
        self.assertEqual(violations(data), ['removed prototype exists: item nullius-guide-drone-iron-1'])

    def test_remaining_technology_is_rejected(self):
        data = tree()
        data['technology']['nullius-asteroid-mining-2'] = {'name': 'nullius-asteroid-mining-2',
                                                           'prerequisites': [], 'effects': []}
        self.assertEqual(violations(data), ['removed technology exists: nullius-asteroid-mining-2'])

    def test_dropped_prerequisite_is_rejected(self):
        data = tree()
        data['technology'][BATTERY]['prerequisites'].remove('nullius-wildlife-management-2')
        self.assertTrue(any(message.startswith(f'{BATTERY} closure') for message in violations(data)))

    def test_gained_prerequisite_is_rejected(self):
        data = tree()
        data['technology'][ROCKET]['prerequisites'].append('nullius-air-separation-5')
        self.assertTrue(any(message.startswith(f'{ROCKET} closure') for message in violations(data)))


if __name__ == '__main__':
    unittest.main()
