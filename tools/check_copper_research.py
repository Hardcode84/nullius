#!/usr/bin/env python3
"""Check the copper research move, its retained asteroid dependencies, and
that deep copper supply stays without productivity."""
import argparse
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs

COPPER = 'nullius-copper-production'
ORE = 'nullius-checkpoint-copper-ore'
ROOTS = ['nullius-astronomy', 'nullius-primitive-filtration', 'nullius-overcharged-assembly-2']
ASTEROID_FREE = [COPPER, 'nullius-checkpoint-copper-ingot', 'nullius-electronics-4',
                 'nullius-solar-power-3', 'nullius-braking-9', 'nullius-antimatter-containment']
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
    """Return incorrect prerequisites, unlocks, and dependent research closures."""
    technologies = data['technology']
    errors = []
    if sorted(technologies[COPPER].get('prerequisites', [])) != sorted(ROOTS):
        errors.append('Copper Production prerequisites changed')
    released = frozenset(prereqs.technology_closure(technologies, {ORE}))
    gained = frozenset(prereqs.technology_closure(technologies, set(ROOTS)))
    errors.extend(prereqs.moved_research_violations(technologies, {COPPER: [ORE]}, set(), released, gained))
    for name in ASTEROID_FREE:
        asteroids = {t for t in prereqs.technology_closure(technologies, {name})
                     if t.startswith('nullius-asteroid-mining-')}
        if asteroids:
            errors.append(f'{name} requires {sorted(asteroids)}')
    for name in ('nullius-robot-speed-5', 'nullius-wildlife-management-1'):
        if 'nullius-asteroid-mining-1' not in prereqs.technology_closure(technologies, {name}):
            errors.append(f'{name} lost its independent asteroid prerequisite')
    recipes = ['deep-drilling', 'deep-slurry-filtration', 'copper-roasting', 'copper-leaching']
    recipes += ['boxed-' + name for name in recipes[1:]]
    recipes += [prefix + name for name in ('copper-concentrate', 'copper-calcine')
                for prefix in ('box-', 'unbox-')]
    for recipe, owner in [(r, COPPER) for r in recipes] + [('copper-solution', ORE), ('boxed-copper-solution', ORE)]:
        unlockers = prereqs.recipe_unlockers(technologies, 'nullius-' + recipe)
        if unlockers != [owner]:
            errors.append(f'{recipe}: expected {owner}, found {unlockers}')
    return errors + productivity_violations(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        errors = violations(data)
        if errors:
            raise prereqs.TestFailure('\n'.join(errors))
        changes = prereqs.moved_research_changes(data['technology'], {COPPER: [ORE]}, set())
        print(json.dumps({'changed_closures': {name: {'lost': sorted(lost), 'gained': sorted(gained)}
                                             for name, (lost, gained) in changes.items()}}, indent=2))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
