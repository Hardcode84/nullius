# Building gallery

Build a separate inspection save with the current mod and its dependencies:

```bash
python tools/prepare_building_gallery.py \
  --factorio /path/to/factorio-2.1 \
  --dependency-mod-directory /path/to/dependencies \
  --destination release/building-gallery
./release/building-gallery/launch.sh
```

Dismiss the normal introduction with **Tab**. Use the building selector or
arrow buttons to move between displays. Each group shows north, east, south,
and west. A direction note identifies rotations that
the engine maps to the same direction. Labels use prototype names.

The gallery includes all Nullius building prototypes, including hidden helpers,
and base buildings placed by Nullius items or produced by Nullius recipes.
Buildings are idle and disabled.
The surface has permanent daylight. The player can move without a character.

The preparation command checks every placement and retained direction. It
writes `result.json`, a save, and `launch.sh` in the selected directory.
Use a new destination to rebuild. Keep that directory and the source checkout
available: the mod overlay links to the current source and dependency archives.
