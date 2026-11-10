#!/usr/bin/env python3
"""Check that asteroid mining is gone and that every technology keeps its former
research closure minus the removed branch."""
import argparse
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs
import removed_research

REMOVED = removed_research.ASTEROID_MINING
# Prerequisites of the technologies that required the removed branch directly.
# Companionship exists only with the optional Companion Drones mod.
FORMER_PREREQUISITES = {
    'nullius-reconnaissance-3': ['nullius-asteroid-mining-1', 'nullius-land-fill-5'],
    'nullius-rocket-science-3': ['nullius-asteroid-mining-2', 'nullius-checkpoint-android-2'],
    'nullius-battery-storage-5': ['nullius-asteroid-mining-3', 'nullius-checkpoint-solar-panel'],
    'nullius-companionship': ['nullius-artificial-intelligence-2', 'nullius-asteroid-mining-2'],
}
# Asteroid miners, guide drones, guide remotes, flares, and projectiles.
PROTOTYPE_PREFIXES = ('nullius-asteroid-miner', 'nullius-guide-')


def former_prerequisites(technologies):
    """Return the former prerequisites of the rewired technologies present in the tree."""
    return {name: parents for name, parents in FORMER_PREREQUISITES.items() if name in technologies}


def violations(data):
    """Return remaining removed prototypes and closure changes beyond the removed branch."""
    technologies = data['technology']
    errors = [f'removed technology exists: {name}' for name in sorted(REMOVED.keys() & technologies.keys())]
    for kind, prototypes in sorted(data.items()):
        if isinstance(prototypes, dict):
            errors.extend(f'removed prototype exists: {kind} {name}' for name in sorted(prototypes)
                          if name.startswith(PROTOTYPE_PREFIXES))
    if errors:
        return errors
    return prereqs.moved_research_violations(removed_research.with_removed(technologies),
                                             former_prerequisites(technologies), set(REMOVED), frozenset(REMOVED))


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
            raise prereqs.TestFailure('Asteroid removal violations:\n' + '\n'.join(errors))
        technologies = data['technology']
        changes = prereqs.moved_research_changes(removed_research.with_removed(technologies),
                                                 former_prerequisites(technologies), set(REMOVED))
        print(json.dumps({'released_closures': {name: sorted(lost) for name, (lost, _) in changes.items()}},
                         indent=2))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
