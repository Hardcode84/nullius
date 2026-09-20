# Personal auto-crafting

## Controls

Automatic handcrafting is off by default. When character logistic requests are
enabled, use the top-left **Auto-craft** checkbox or the shortcut to toggle it.
Both controls show the same state.

The **Automatic handcrafting** Tips and Tricks entry becomes available when
Primitive Robotics or Logistic Robotics first unlocks personal logistic requests.

Disabling character logistic requests stops automatic handcrafting, hides the
checkbox, and prevents shortcut activation. Cancelling a craft also stops
automatic handcrafting.

Automatic handcrafting also works in remote view. It uses the physical
character's requests, inventory, and crafting queue without leaving remote view.

## Crafting rules

- Check personal logistic requests every 30 ticks (0.5 seconds).
- After a craft completes, check again on the next tick, when its output is in
  the inventory. One shared pending flag schedules a check of connected players.
- Queue work only when the current crafting queue is empty.
- Use active requests and their minimum quantities. Skip satisfied requests.
- Select an enabled recipe that the character can handcraft with available
  materials. Queue one recipe execution; this can produce more than one item.
- Let Factorio check and queue intermediate crafts. Do not use a separate
  prerequisite planner.
- Use normal handcrafting speed, material costs, and Nullius crafting equipment.
- Skip quality requests that cannot accept normal-quality output.

## Validation

`personal-autocraft` uses a real multiplayer client. It checks research and
request gating, both controls, native recursive crafting, batch output, an
occupied manual queue, cancellation, missing ingredients, quality filters,
disabled request sections, and crafting during remote view.

```bash
python tools/run_factorio_tests.py personal-autocraft -n auto
```
