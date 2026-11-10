"""Unit tests for the research tree structure check."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import check_research_tree as tree_check



def technology(name, prerequisites=(), packs=('nullius-low-pack',), effects=None, count=10):
    """Return a lab technology that by default unlocks a recipe of its own."""
    return {'name': name, 'prerequisites': list(prerequisites),
            'effects': unlock(name + '-recipe') if effects is None else list(effects),
            'unit': {'count': count, 'time': 5, 'ingredients': [[pack, 1] for pack in packs]}}


def recipe(name, enabled=False, **fields):
    return {'name': name, 'enabled': enabled, 'results': [{'type': 'item', 'name': name, 'amount': 1}], **fields}


def unlock(name):
    return [{'type': 'unlock-recipe', 'recipe': name}]


def violations(*technologies, recipes=()):
    """Return the violations of a tree with low, middle, and side packs unlocked in that order."""
    base = [
        technology('nullius-low-science', packs=(), effects=unlock('nullius-low-pack')),
        technology('nullius-middle-science', ['nullius-low-science'], effects=unlock('nullius-middle-pack')),
        technology('nullius-side-science', ['nullius-low-science'], effects=unlock('nullius-side-pack')),
    ]
    all_technologies = [*base, *technologies]
    unlocked = {e['recipe'] for t in all_technologies for e in t['effects'] if e['type'] == 'unlock-recipe'}
    data = {'planet': {'nauvis': {}, 'nullius-hot': {'surface_properties': {'heat': 200}}},
            'surface-property': {'heat': {'default_value': 15}},
            'technology': {t['name']: t for t in all_technologies},
            'recipe': {r['name']: r for r in [*(recipe(name) for name in sorted(unlocked)), *recipes]}}
    return {kind: rows for kind, rows in tree_check.violations(data).items() if rows}


class ResearchTreeCheckTest(unittest.TestCase):
    def test_reference_tree_passes(self):
        self.assertEqual(violations(technology('nullius-work', ['nullius-middle-science'], ['nullius-middle-pack'])), {})

    def test_pack_unlocked_only_by_a_later_technology_is_unavailable(self):
        self.assertEqual(violations(technology('nullius-early', [], ['nullius-middle-pack'])),
                         {'unavailable_packs': [{'technology': 'nullius-early', 'pack': 'nullius-middle-pack'}]})

    def test_pack_made_only_on_an_unreached_planet_is_unavailable(self):
        hot = [{'property': 'heat', 'min': 100}]
        reach = [{'type': 'unlock-space-location', 'space_location': 'nullius-hot'}]
        found = violations(
            technology('nullius-hot-science', ['nullius-low-science'], effects=unlock('nullius-hot-pack')),
            technology('nullius-hot-probe', ['nullius-low-science'], effects=reach),
            technology('nullius-early', ['nullius-hot-science'], ['nullius-hot-pack']),
            technology('nullius-later', ['nullius-hot-science', 'nullius-hot-probe'], ['nullius-hot-pack']),
            recipes=[recipe('nullius-hot-pack', surface_conditions=hot)])
        self.assertEqual(found, {'unavailable_packs': [{'technology': 'nullius-early', 'pack': 'nullius-hot-pack'}]})

    def test_checkpoint_marker_needs_its_pack_in_the_closure(self):
        self.assertEqual(violations(
            technology('nullius-checkpoint-early', ['nullius-low-science'], ['nullius-middle-pack'], effects=[]),
            technology('nullius-after', ['nullius-checkpoint-early'])),
            {'checkpoint_markers': [{'checkpoint': 'nullius-checkpoint-early', 'packs': ['nullius-middle-pack']}]})

    def test_effectless_lab_technology_is_a_violation_but_checkpoint_and_trigger_are_not(self):
        trigger = technology('nullius-trigger', effects=[])
        del trigger['unit']
        trigger['research_trigger'] = {'type': 'mine-entity', 'entities': ['wreck']}
        self.assertEqual(violations(
            trigger,
            technology('nullius-gate', ['nullius-low-science'], effects=[]),
            technology('nullius-checkpoint-gate', ['nullius-low-science'], effects=[]),
            technology('nullius-after', ['nullius-gate', 'nullius-checkpoint-gate', 'nullius-trigger'])),
            {'effectless': ['nullius-gate']})

    def test_checkpoint_without_dependents_is_orphaned(self):
        self.assertEqual(violations(technology('nullius-checkpoint-alone', ['nullius-low-science'], effects=[])),
                         {'orphan_checkpoints': ['nullius-checkpoint-alone']})

    def test_series_level_with_only_lower_packs_regresses(self):
        self.assertEqual(violations(
            technology('nullius-series-1', ['nullius-middle-science'], ['nullius-middle-pack']),
            technology('nullius-series-2', ['nullius-series-1'], ['nullius-low-pack'])),
            {'tier_regressions': [{'technology': 'nullius-series-2', 'previous': 'nullius-series-1',
                                   'higher_previous_packs': ['nullius-middle-pack'],
                                   'packs': ['nullius-low-pack']}]})

    def test_series_level_with_a_sibling_pack_does_not_regress(self):
        self.assertEqual(violations(
            technology('nullius-series-1', ['nullius-middle-science'], ['nullius-middle-pack']),
            technology('nullius-series-2', ['nullius-series-1', 'nullius-side-science'], ['nullius-side-pack'])), {})

    def test_series_level_outside_its_predecessor_closure_is_detached(self):
        self.assertEqual(violations(
            technology('nullius-series-1', ['nullius-middle-science'], ['nullius-middle-pack']),
            technology('nullius-series-2', ['nullius-low-science'], ['nullius-low-pack'])),
            {'detached_series': [{'technology': 'nullius-series-2', 'previous': 'nullius-series-1'}]})

    def test_exempt_detached_level_passes(self):
        name = next(iter(tree_check.DETACHED_LEVELS))
        previous = name.rsplit('-', 1)[0] + '-' + str(int(name.rsplit('-', 1)[1]) - 1)
        self.assertEqual(violations(technology(previous, ['nullius-low-science']),
                                    technology(name, ['nullius-low-science'])), {})

    def test_technology_outside_the_tree_is_ignored_and_reported_as_a_prerequisite(self):
        self.assertEqual(violations(
            technology('vanilla-gate', [], ['vanilla-pack'], effects=[]),
            technology('nullius-after-vanilla', ['vanilla-gate', 'nullius-low-science'])),
            {'foreign_prerequisites': [{'technology': 'nullius-after-vanilla', 'prerequisites': ['vanilla-gate']}]})

    def test_unlock_after_another_unlock_of_the_same_recipe_is_redundant(self):
        # Independent unlockers of the side pack are alternative entry points.
        self.assertEqual(violations(
            technology('nullius-again', ['nullius-middle-science'], effects=unlock('nullius-middle-pack')),
            technology('nullius-elsewhere', ['nullius-low-science'], effects=unlock('nullius-side-pack'))),
            {'redundant_unlocks': [{'recipe': 'nullius-middle-pack',
                                    'unlocked_by': ['nullius-again', 'nullius-middle-science'],
                                    'redundant': ['nullius-again']}]})

    def test_hidden_and_never_unlocked_recipes(self):
        self.assertEqual(violations(
            technology('nullius-hides', ['nullius-low-science'], effects=unlock('nullius-hidden')),
            recipes=[recipe('nullius-hidden', hidden=True), recipe('nullius-orphan')]),
            {'hidden_unlocks': ['nullius-hidden'], 'never_unlocked': ['nullius-orphan']})


if __name__ == "__main__":
    unittest.main()
