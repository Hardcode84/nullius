"""Technologies removed from the game, with the prerequisites they had.

Moved-research checks compare the resolved tree with the tree before a move.
That former tree still contains removed technologies, so the checks restore them
from this catalog before restoring moved prerequisites.
"""

# Asteroid mining and the checkpoints only it supplied.
ASTEROID_MINING = {
    'nullius-asteroid-mining-1': ['nullius-astronomy', 'nullius-mining-productivity-20'],
    'nullius-asteroid-mining-2': ['nullius-wildlife-management-2'],
    'nullius-checkpoint-asteroid-mining': ['nullius-asteroid-mining-2'],
    'nullius-asteroid-mining-3': ['nullius-checkpoint-asteroid-mining', 'nullius-air-separation-5'],
    'nullius-checkpoint-copper-ore': ['nullius-asteroid-mining-1'],
    'nullius-checkpoint-uranium-ore': ['nullius-asteroid-mining-1'],
}
REMOVED = {**ASTEROID_MINING}


def with_removed(technologies):
    """Return a copy of a resolved technology table with the removed technologies restored.

    A removed technology still present in the table is a failed removal, not a
    technology to overwrite.
    """
    present = sorted(REMOVED.keys() & technologies.keys())
    if present:
        raise ValueError(f'removed technologies still exist: {present}')
    restored = dict(technologies)
    for name, prerequisites in REMOVED.items():
        restored[name] = {'name': name, 'prerequisites': list(prerequisites), 'effects': []}
    return restored
