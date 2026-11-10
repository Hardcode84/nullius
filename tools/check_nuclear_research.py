#!/usr/bin/env python3
"""Check the nuclear reactor split, the fission branch, and antiproton capture research placement."""
import argparse
import functools
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs
import removed_research

REACTOR = 'nullius-nuclear-reactor'
FUSION = 'nullius-nuclear-power-1'
SEAWATER = 'nullius-seawater-uranium-adsorption'
FLUORINE = 'nullius-fluorine-chemistry'
URANIUM = 'nullius-uranium-processing'
ENRICHMENT = 'nullius-uranium-enrichment'
FISSION = 'nullius-nuclear-power-4'
ANTIMATTER = 'nullius-antimatter-containment'
URANIUM_ORE = 'nullius-checkpoint-uranium-ore'
ISOTOPES = 'nullius-isotope-separation'
ASTRONOMY = 'nullius-astronomy'
WILDLIFE = 'nullius-wildlife-management-1'
# Prerequisites before the split. The reactor research is the part split from
# Nuclear Power 1, so it stays in that technology's former closure.
FORMER_PREREQUISITES = {
    FUSION: ['nullius-checkpoint-tritium', 'nullius-checkpoint-thermal-tank', 'nullius-empiricism-5', REACTOR],
    URANIUM: [URANIUM_ORE, 'nullius-nuclear-power-3'],
    FISSION: [URANIUM, 'nullius-checkpoint-breeder-cell', 'nullius-boiling-4'],
    ANTIMATTER: ['nullius-solar-power-3', 'nullius-checkpoint-enriched-uranium'],
    WILDLIFE: ['nullius-checkpoint-copper-ingot', URANIUM, 'nullius-checkpoint-worm', 'nullius-personal-storage-3'],
}
PREREQUISITES = {
    REACTOR: ['nullius-checkpoint-thermal-tank', 'nullius-empiricism-5'],
    FUSION: [REACTOR, 'nullius-checkpoint-tritium'],
    SEAWATER: ['nullius-biochemistry-4'],
    FLUORINE: ['nullius-electrolysis-4'],
    URANIUM: [SEAWATER, FLUORINE],
    ENRICHMENT: [URANIUM],
    FISSION: [ENRICHMENT, REACTOR],
    # Uranium comes only from enrichment tails, so its consumers follow enrichment.
    WILDLIFE: ['nullius-checkpoint-copper-ingot', ENRICHMENT, 'nullius-checkpoint-worm', 'nullius-personal-storage-3'],
    # Antiproton capture is Fulgora orbit research; Solar Power 3 makes the
    # empty trap's processors, batteries, and copper wire.
    ANTIMATTER: ['nullius-orbital-construction', 'nullius-supercapacitors', 'nullius-solar-power-3'],
}
# Antimatter Containment required these before antiproton capture replaced
# antimatter made from nuclear cells.
REMOVED_ANTIMATTER_PREREQUISITES = ['nullius-checkpoint-enriched-uranium', 'nullius-checkpoint-breeder-cell',
                                    'nullius-boiling-4']
ANTIMATTER_ITEMS = ('nullius-antimatter', 'nullius-antimatter-trap')
RECIPE_UNLOCKS = {
    'nullius-reactor': REACTOR,
    'nullius-portable-reactor': REACTOR,
    'nullius-fusion-cell': FUSION,
    'nullius-fusion-recycling': FUSION,
    'nullius-uranyl-binding-fiber': SEAWATER,
    'nullius-loaded-uranyl-fiber': SEAWATER,
    'nullius-uranyl-solution': SEAWATER,
    'nullius-yellowcake-precipitation': SEAWATER,
    # The ore route keeps remaining patches usable after asteroid mining removal.
    'nullius-crushed-uranium-ore': URANIUM,
    'nullius-yellowcake': URANIUM,
    'nullius-fluorite': FLUORINE,
    'nullius-hydrogen-fluoride': FLUORINE,
    'nullius-hydrogen-fluoride-electrolysis': FLUORINE,
    'nullius-uranium-dioxide': URANIUM,
    'nullius-uranium-tetrafluoride': URANIUM,
    'nullius-uf6-cylinder': URANIUM,
    'nullius-natural-uf6': URANIUM,
    'nullius-centrifuge': ENRICHMENT,
    'nullius-low-enriched-uf6': ENRICHMENT,
    'nullius-reactor-grade-uf6': ENRICHMENT,
    'nullius-enriched-uranium-deconversion': ENRICHMENT,
    'nullius-uranium-deconversion': ENRICHMENT,
    'nullius-fission-cell': FISSION,
    'nullius-fission-recycling': FISSION,
    'nullius-antimatter-trap': ANTIMATTER,
    'nullius-antiproton-collector': ANTIMATTER,
    'nullius-antiproton-capture': ANTIMATTER,
    'nullius-antimatter-recharge': ANTIMATTER,
}
# Fission no longer passes through the fusion ladder or Astronomy. Its
# technologies are checked by their prerequisites.
FISSION_BRANCH = {SEAWATER, FLUORINE, URANIUM, ENRICHMENT, FISSION}
# Placement of these is checked by their prerequisites, not their closures.
EXEMPT = FISSION_BRANCH | {REACTOR, ANTIMATTER} | set(removed_research.REMOVED)


def closure_rules(technologies):
    """Return (released, gained) research for uranium consumers and for antimatter dependents.

    Consumers of Uranium Processing reached breeder research and the uranium ore
    checkpoint only through it, and now reach enrichment and its closure.
    Research after Antimatter Containment may also drop what only its removed
    nuclear prerequisites reached, and reach its new prerequisites.
    """
    closure = functools.partial(prereqs.technology_closure, technologies)
    uranium = (frozenset({'nullius-nuclear-power-3'} | closure({URANIUM_ORE})), frozenset(closure({ENRICHMENT})))
    antimatter = (frozenset(closure(set(REMOVED_ANTIMATTER_PREREQUISITES))),
                  frozenset(closure(set(PREREQUISITES[ANTIMATTER]))))
    return uranium, antimatter


def closure_violations(technologies):
    """Return closure changes that neither the uranium nor the antimatter rule allows."""
    uranium, antimatter = closure_rules(technologies)
    violations = []
    for name, (lost, gained) in prereqs.moved_research_changes(technologies, FORMER_PREREQUISITES, EXEMPT).items():
        released, reached = uranium
        if ANTIMATTER in prereqs.technology_closure(technologies, {name}):
            released, reached = released | antimatter[0], reached | antimatter[1]
        if lost - released or gained - reached:
            violations.append(f'{name} closure: lost {sorted(lost)}, gained {sorted(gained)}')
    return violations


def antimatter_consumer_violations(technologies, recipes):
    """Return research that unlocks a trap consumer without reaching Antimatter Containment."""
    violations = []
    for name, recipe in sorted(recipes.items()):
        if not any(ingredient['name'] in ANTIMATTER_ITEMS for ingredient in recipe.get('ingredients') or []):
            continue
        for technology in prereqs.recipe_unlockers(technologies, name):
            if ANTIMATTER not in prereqs.technology_closure(technologies, {technology}):
                violations.append(f'{technology} unlocks {name} without {ANTIMATTER}')
    return violations


def research_violations(technologies, recipes):
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
    violations.extend(closure_violations(technologies))
    violations.extend(antimatter_consumer_violations(technologies, recipes))
    return violations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        technologies = removed_research.with_removed(data['technology'])
        violations = research_violations(technologies, data['recipe'])
        if violations:
            raise prereqs.TestFailure('Nuclear research violations:\n' + '\n'.join(violations))
        changes = prereqs.moved_research_changes(technologies, FORMER_PREREQUISITES, EXEMPT)
        print(json.dumps({
            'unchanged_research_closures': len(technologies.keys() - EXEMPT - changes.keys()),
            'changed_research_closures': {name: {'lost': sorted(lost), 'gained': sorted(gained)}
                                          for name, (lost, gained) in changes.items()},
        }, indent=2))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
