#!/usr/bin/env python3
"""Check the nuclear reactor split and the fission branch research placement."""
import argparse
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs

REACTOR = 'nullius-nuclear-reactor'
FUSION = 'nullius-nuclear-power-1'
SEAWATER = 'nullius-seawater-uranium-adsorption'
URANIUM = 'nullius-uranium-processing'
FISSION = 'nullius-nuclear-power-4'
ANTIMATTER = 'nullius-antimatter-containment'
URANIUM_ORE = 'nullius-checkpoint-uranium-ore'
ISOTOPES = 'nullius-isotope-separation'
ASTRONOMY = 'nullius-astronomy'
# Prerequisites before the split. The reactor research is the part split from
# Nuclear Power 1, so it stays in that technology's former closure.
FORMER_PREREQUISITES = {
    FUSION: ['nullius-checkpoint-tritium', 'nullius-checkpoint-thermal-tank', 'nullius-empiricism-5', REACTOR],
    URANIUM: [URANIUM_ORE, 'nullius-nuclear-power-3'],
    FISSION: [URANIUM, 'nullius-checkpoint-breeder-cell', 'nullius-boiling-4'],
    ANTIMATTER: ['nullius-solar-power-3', 'nullius-checkpoint-enriched-uranium'],
}
PREREQUISITES = {
    REACTOR: ['nullius-checkpoint-thermal-tank', 'nullius-empiricism-5'],
    FUSION: [REACTOR, 'nullius-checkpoint-tritium'],
    SEAWATER: ['nullius-biochemistry-4'],
    # Tritium enrichment needs Isotope Separation until enrichment replaces it.
    URANIUM: [SEAWATER, ISOTOPES],
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
    'nullius-uranyl-binding-fiber': SEAWATER,
    'nullius-loaded-uranyl-fiber': SEAWATER,
    'nullius-uranyl-solution': SEAWATER,
    'nullius-yellowcake-precipitation': SEAWATER,
    # Ore yellowcake stays with its ore, which Uranium Processing no longer requires.
    'nullius-crushed-uranium-ore': URANIUM_ORE,
    'nullius-yellowcake': URANIUM_ORE,
    'nullius-uranium': URANIUM,
    'nullius-enriched-uranium': URANIUM,
    'nullius-fission-cell': FISSION,
    'nullius-fission-recycling': FISSION,
}
# Fission no longer passes through the fusion ladder or Astronomy. Its
# technologies and the fission checkpoint are checked by their prerequisites.
FISSION_BRANCH = {SEAWATER, URANIUM, FISSION, 'nullius-checkpoint-enriched-uranium'}


def closure_rules(technologies):
    """Return the research uranium consumers may drop and gain.

    Consumers of Uranium Processing reached breeder research and the uranium
    ore checkpoint only through it, and now reach its new prerequisites.
    """
    released = frozenset({'nullius-nuclear-power-3'} | prereqs.technology_closure(technologies, {URANIUM_ORE}))
    gained = frozenset(prereqs.technology_closure(technologies, set(PREREQUISITES[URANIUM])))
    return released, gained


def research_violations(technologies):
    """Return nuclear research placement and closure violations."""
    violations = [f'{name} prerequisites: expected {expected}, found {technologies[name].get("prerequisites")}'
                  for name, expected in PREREQUISITES.items()
                  if sorted(technologies[name].get('prerequisites') or []) != sorted(expected)]
    for recipe, expected in RECIPE_UNLOCKS.items():
        unlockers = prereqs.recipe_unlockers(technologies, recipe)
        if unlockers != [expected]:
            violations.append(f'{recipe} unlocked by {unlockers}, expected {expected}')
    violations.extend(f'{name} requires {ASTRONOMY}' for name in sorted(FISSION_BRANCH)
                      if ASTRONOMY in prereqs.technology_closure(technologies, {name}))
    released, gained = closure_rules(technologies)
    violations.extend(prereqs.moved_research_violations(technologies, FORMER_PREREQUISITES,
                                                        FISSION_BRANCH | {REACTOR}, released, gained))
    return violations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        technologies = data['technology']
        violations = research_violations(technologies)
        if violations:
            raise prereqs.TestFailure('Nuclear research violations:\n' + '\n'.join(violations))
        changes = prereqs.moved_research_changes(technologies, FORMER_PREREQUISITES, FISSION_BRANCH | {REACTOR})
        print(json.dumps({
            'unchanged_research_closures': len(technologies.keys() - FISSION_BRANCH - {REACTOR} - changes.keys()),
            'changed_uranium_consumers': {name: {'lost': sorted(lost), 'gained': sorted(gained)}
                                          for name, (lost, gained) in changes.items()},
        }, indent=2))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
