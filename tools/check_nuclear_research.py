#!/usr/bin/env python3
"""Check the nuclear reactor split and the fission branch research placement."""
import argparse
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs

REACTOR = 'nullius-nuclear-reactor'
FUSION = 'nullius-nuclear-power-1'
URANIUM = 'nullius-uranium-processing'
FISSION = 'nullius-nuclear-power-4'
ANTIMATTER = 'nullius-antimatter-containment'
# Prerequisites before the split. The reactor research is the part split from
# Nuclear Power 1, so it stays in that technology's former closure.
FORMER_PREREQUISITES = {
    FUSION: ['nullius-checkpoint-tritium', 'nullius-checkpoint-thermal-tank', 'nullius-empiricism-5', REACTOR],
    URANIUM: ['nullius-checkpoint-uranium-ore', 'nullius-nuclear-power-3'],
    FISSION: [URANIUM, 'nullius-checkpoint-breeder-cell', 'nullius-boiling-4'],
    ANTIMATTER: ['nullius-solar-power-3', 'nullius-checkpoint-enriched-uranium'],
}
PREREQUISITES = {
    REACTOR: ['nullius-checkpoint-thermal-tank', 'nullius-empiricism-5'],
    FUSION: [REACTOR, 'nullius-checkpoint-tritium'],
    URANIUM: ['nullius-checkpoint-uranium-ore'],
    FISSION: [URANIUM, REACTOR],
    # Antimatter traps consume breeder and fission cells; the fusion ladder that
    # fission dropped is required again where the branches meet.
    ANTIMATTER: ['nullius-solar-power-3', 'nullius-checkpoint-enriched-uranium',
                 'nullius-checkpoint-breeder-cell', 'nullius-boiling-4'],
}
RECIPE_UNLOCKS = {
    'nullius-reactor': REACTOR,
    'nullius-portable-reactor': REACTOR,
    'nullius-fusion-cell': FUSION,
    'nullius-fusion-recycling': FUSION,
    'nullius-yellowcake': URANIUM,
    'nullius-uranium': URANIUM,
    'nullius-enriched-uranium': URANIUM,
    'nullius-fission-cell': FISSION,
    'nullius-fission-recycling': FISSION,
}
# Fission no longer passes through the fusion ladder. Its technologies and the
# fission checkpoint lose the breeder research they consumed nothing from.
FISSION_BRANCH = {URANIUM, FISSION, 'nullius-checkpoint-enriched-uranium'}
# Uranium consumers reached breeder research only through Uranium Processing.
RELEASED = frozenset({'nullius-nuclear-power-3'})


def research_violations(technologies):
    """Return nuclear research placement and closure violations."""
    violations = [f'{name} prerequisites: expected {expected}, found {technologies[name].get("prerequisites")}'
                  for name, expected in PREREQUISITES.items()
                  if sorted(technologies[name].get('prerequisites') or []) != sorted(expected)]
    for recipe, expected in RECIPE_UNLOCKS.items():
        unlockers = prereqs.recipe_unlockers(technologies, recipe)
        if unlockers != [expected]:
            violations.append(f'{recipe} unlocked by {unlockers}, expected {expected}')
    violations.extend(prereqs.moved_research_violations(technologies, FORMER_PREREQUISITES,
                                                        FISSION_BRANCH | {REACTOR}, RELEASED))
    return violations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        violations = research_violations(data['technology'])
        if violations:
            raise prereqs.TestFailure('Nuclear research violations:\n' + '\n'.join(violations))
        print(json.dumps({'unchanged_research_closures':
                          len(data['technology'].keys() - FISSION_BRANCH - {REACTOR})}))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
