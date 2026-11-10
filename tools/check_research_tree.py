#!/usr/bin/env python3
"""Check the structure of the resolved Nullius research tree.

Scope is the Nullius tree that hidden.lua leaves visible: a technology whose
name or order starts with "nullius-". Checkpoints complete by script, so their
packs only mark a tier; trigger technologies complete by an action; every other
technology is paid in labs.

Violations:
  unavailable_packs: a lab technology needs a pack with no recipe enabled or
    unlocked by its prerequisite closure on a planet that closure reaches.
  checkpoint_markers: a checkpoint marks a pack tier that its prerequisite
    closure cannot produce. Script-only checkpoint packs have no recipe.
  foreign_prerequisites: a Nullius technology depends on one outside the tree.
  effectless: a lab technology shows no effect; a scripted gate needs a
    "nothing" effect that describes it.
  orphan_checkpoints: a checkpoint gates no technology.
  detached_series: a numbered level outside its predecessor's dependents.
  tier_regressions: a series level that requires its predecessor needs only
    packs below one of the predecessor's packs. Pack A is below pack B when
    the earliest research unlocking A precedes the earliest unlocking B.
  hidden_unlocks: research unlocks a hidden recipe.
  redundant_unlocks: research unlocks a recipe that its own prerequisites
    already unlock. Independent unlockers are alternative entry points.
  never_unlocked: a disabled, visible Nullius recipe that no research unlocks.
"""
import argparse
import json
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

import analyze_factorio_prereqs as prereqs

PREFIX = 'nullius-'
CHECKPOINT_PREFIX = 'nullius-checkpoint-'
STARTING_PLANET = 'nauvis'
SERIES = re.compile(r'^(?P<base>.+)-(?P<level>\d+)$')
# Numbered levels that deliberately do not follow their predecessor.
DETACHED_LEVELS = {
    # Fission cells follow uranium enrichment, not breeder cells and Astronomy.
    'nullius-nuclear-power-4',
}


def in_tree(technology):
    return technology['name'].startswith(PREFIX) or (technology.get('order') or '').startswith(PREFIX)


def is_checkpoint(name):
    return name.startswith(CHECKPOINT_PREFIX)


def unit_packs(technology):
    unit = technology.get('unit')
    return {} if unit is None else dict(unit['ingredients'])


class Tree:
    def __init__(self, data):
        self.all = data['technology']
        self.recipes = data['recipe']
        self.names = sorted(n for n, t in self.all.items() if in_tree(t))
        self.closures = {n: prereqs.technology_closure(self.all, {n}) for n in self.all}
        self.children = defaultdict(list)
        for name in self.names:
            for prerequisite in self.all[name].get('prerequisites') or []:
                self.children[prerequisite].append(name)
        self.owners = defaultdict(list)
        for name in self.names:
            for effect in self.all[name].get('effects') or []:
                if effect['type'] == 'unlock-recipe':
                    self.owners[effect['recipe']].append(name)
        self.makers = defaultdict(list)
        for name in sorted(self.recipes):
            for product in prereqs.recipe_results(self.recipes[name]):
                self.makers[product['name']].append(name)
        self.planets = {name: prereqs.resolve_surface(data, planet.get('surface_properties') or {})
                        for name, planet in data.get('planet', {}).items()}
        self.labs = [n for n in self.names if not is_checkpoint(n) and self.all[n].get('unit')]
        self.packs = sorted({p for n in self.labs for p in unit_packs(self.all[n])})
        self.first_unlocks = {pack: self.earliest_unlocks(pack) for pack in self.packs}

    def earliest_unlocks(self, item):
        """Return unlockers of item recipes that require no other unlocker."""
        unlockers = {o for r in self.makers.get(item, []) for o in self.owners.get(r, [])}
        return sorted(u for u in unlockers if not any(o in self.closures[u] - {u} for o in unlockers))

    def reachable_planets(self, technologies):
        """Return the surfaces of the starting planet and the planets these technologies unlock."""
        names = {STARTING_PLANET} | {effect['space_location'] for t in technologies
                                     for effect in self.all[t].get('effects') or []
                                     if effect['type'] == 'unlock-space-location'}
        return [self.planets[n] for n in sorted(names & self.planets.keys())]

    def available_before(self, item, name):
        """Return whether research before name makes item on a planet it can reach."""
        earlier = self.closures[name] - {name}
        planets = self.reachable_planets(earlier)
        return any((self.recipes[r].get('enabled', True) or earlier.intersection(self.owners.get(r, [])))
                   and any(prereqs.allowed_on_surface(self.recipes[r], planet) for planet in planets)
                   for r in self.makers.get(item, []))

    def pack_at_most(self, lower, upper):
        return lower == upper or any(u in self.closures[v] for u in self.first_unlocks[lower]
                                     for v in self.first_unlocks[upper])


def series_pairs(tree):
    """Yield (level, predecessor) for each numbered lab technology whose predecessor exists."""
    for name in tree.labs:
        match = SERIES.match(name)
        previous = match and f"{match['base']}-{int(match['level']) - 1}"
        if previous and previous in tree.all:
            yield name, previous


def tier_regressions(tree):
    rows = []
    for name, previous in series_pairs(tree):
        if previous not in tree.closures[name]:
            continue
        current, prior = unit_packs(tree.all[name]), unit_packs(tree.all[previous])
        above = sorted(p for p in prior if all(q != p and tree.pack_at_most(q, p) for q in current))
        if above:
            rows.append({'technology': name, 'previous': previous, 'higher_previous_packs': above,
                         'packs': sorted(current)})
    return rows


def violations(data):
    tree = Tree(data)
    technologies = tree.all
    checkpoints = [n for n in tree.names if is_checkpoint(n)]
    unavailable = []
    for pack in tree.packs:
        users = [n for n in tree.labs if pack in unit_packs(technologies[n])]
        unavailable += [{'technology': n, 'pack': pack} for n in users
                        if not any(u in tree.closures[n] - {n} for u in users)
                        and not tree.available_before(pack, n)]
    return {
        'unavailable_packs': unavailable,
        'checkpoint_markers': [{'checkpoint': n, 'packs': packs} for n in checkpoints
                               if (packs := sorted(p for p in unit_packs(technologies[n])
                                                   if tree.makers.get(p)
                                                   and not tree.available_before(p, n)))],
        'foreign_prerequisites': [{'technology': n, 'prerequisites': foreign} for n in tree.names
                                  if (foreign := sorted(p for p in technologies[n].get('prerequisites') or []
                                                        if not in_tree(technologies[p])))],
        'effectless': [n for n in tree.labs if not technologies[n].get('effects')],
        'orphan_checkpoints': [n for n in checkpoints if not tree.children.get(n)],
        'detached_series': [{'technology': n, 'previous': p} for n, p in series_pairs(tree)
                            if p not in tree.closures[n] and n not in DETACHED_LEVELS],
        'tier_regressions': tier_regressions(tree),
        'hidden_unlocks': sorted(r for r in tree.owners if tree.recipes[r].get('hidden')),
        'redundant_unlocks': [{'recipe': r, 'unlocked_by': o, 'redundant': later}
                              for r, o in sorted(tree.owners.items())
                              if (later := [a for a in o if any(b in tree.closures[a] - {a} for b in o)])],
        'never_unlocked': sorted(n for n, r in tree.recipes.items()
                                 if n.startswith(PREFIX) and r.get('enabled', True) is False
                                 and not r.get('hidden') and n not in tree.owners),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        found = {kind: rows for kind, rows in violations(data).items() if rows}
    finally:
        if temporary:
            shutil.rmtree(temporary)
    if found:
        raise prereqs.TestFailure('Research tree violations:\n' + json.dumps(found, indent=2))
    print(json.dumps({'technologies': len([n for n, t in data['technology'].items() if in_tree(t)]),
                      'violations': 0}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
