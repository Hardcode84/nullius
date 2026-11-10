#!/usr/bin/env python3
"""Check the copper research move, its unlocks, and that deep copper supply
stays without productivity."""
import argparse
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs
import removed_research

COPPER = 'nullius-copper-production'
# Copper Production's former prerequisite, removed with asteroid mining.
ORE = 'nullius-checkpoint-copper-ore'
ROOTS = ['nullius-astronomy', 'nullius-primitive-filtration', 'nullius-overcharged-assembly-2']
DEEP_RECIPES = ['deep-drilling', 'deep-slurry-filtration', 'boxed-deep-slurry-filtration', 'copper-roasting',
                'boxed-copper-roasting', 'copper-leaching', 'boxed-copper-leaching', 'box-copper-concentrate',
                'unbox-copper-concentrate', 'box-copper-calcine', 'unbox-copper-calcine']
# Remaining asteroid patches and later crustal fracturing use the ore route.
ORE_RECIPES = ['box-copper-ore', 'unbox-copper-ore', 'crushed-copper-ore', 'boxed-crushed-copper-ore',
               'box-crushed-copper-ore', 'unbox-crushed-copper-ore', 'copper-solution', 'boxed-copper-solution']
EXEMPT = set(removed_research.REMOVED)
# Productivity on these would multiply a vent's fixed deep supply.
FIXED_SUPPLY = ['nullius-deep-drilling', 'nullius-deep-slurry-filtration',
                'nullius-boxed-deep-slurry-filtration']


def productivity_violations(data):
    """Return fixed-supply recipes that permit or receive productivity."""
    errors = [f'{name} permits productivity' for name in FIXED_SUPPLY
              if data['recipe'][name].get('allow_productivity', False)]
    for technology, prototype in sorted(data['technology'].items()):
        for effect in prototype.get('effects') or []:
            if effect['type'] == 'change-recipe-productivity' and effect['recipe'] in FIXED_SUPPLY:
                errors.append(f'{technology} changes {effect["recipe"]} productivity')
    return errors


def violations(data):
    """Return incorrect prerequisites, unlocks, and dependent research closures.

    The technology table must contain the removed technologies, restored from
    the catalog, so the former tree resolves.
    """
    technologies = data['technology']
    errors = []
    if sorted(technologies[COPPER].get('prerequisites', [])) != sorted(ROOTS):
        errors.append('Copper Production prerequisites changed')
    released = frozenset(prereqs.technology_closure(technologies, {ORE}))
    gained = frozenset(prereqs.technology_closure(technologies, set(ROOTS)))
    errors.extend(prereqs.moved_research_violations(technologies, {COPPER: [ORE]}, EXEMPT, released, gained))
    for recipe in DEEP_RECIPES + ORE_RECIPES:
        unlockers = prereqs.recipe_unlockers(technologies, 'nullius-' + recipe)
        if unlockers != [COPPER]:
            errors.append(f'{recipe}: expected {COPPER}, found {unlockers}')
    return errors + productivity_violations(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        data['technology'] = removed_research.with_removed(data['technology'])
        errors = violations(data)
        if errors:
            raise prereqs.TestFailure('\n'.join(errors))
        changes = prereqs.moved_research_changes(data['technology'], {COPPER: [ORE]}, EXEMPT)
        print(json.dumps({'changed_closures': {name: {'lost': sorted(lost), 'gained': sorted(gained)}
                                             for name, (lost, gained) in changes.items()}}, indent=2))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
