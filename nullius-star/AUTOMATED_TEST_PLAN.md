# Nullius Star Automated Test Plan

The generic test architecture is defined in
[`AUTONOMOUS_MOD_DEVELOPMENT.md`](../AUTONOMOUS_MOD_DEVELOPMENT.md). This file
contains only the cases and progression milestones specific to Nullius Star.

## First feature tests

### Strict prototype load

Load the complete mod set with `--check-unused-prototype-data`. Any warning that
names a Nullius Star prototype fails unless its exact text is explicitly
accepted.

### Gas-vent lifecycle

Build a vent through its production placement path and check that its visible
shell and hidden drill/resource components are created exactly once. Verify gas
production, diminishing returns with a second vent, cleanup after every
supported removal path, and successful rebuilding at the same position.

### Pneumatic-heat lifecycle

Build an eligible pneumatic machine through its production placement path.
Check that one correctly sized hidden heat interface is created, heat rises
while the machine works, input stops when work stops, and removal destroys the
owned interface without leaving duplicates or stale state.

## First campaign slice

The initial two-chunk test is intentionally small. It exists to prove the
checkpoint contract before scripting longer progression.

1. Start the real campaign, obtain a placeable early-game machine through the
   normal progression path, place and configure it from player inventory, then
   verify its ownership and save the checkpoint.
2. Convert that checkpoint into the next scenario, reload it, run the machine,
   collect its output through normal player interaction, and verify that the
   player inventory, research, mod storage, entity configuration, and elapsed
   ticks continued from chunk 1.

After this passes, split the playable progression at research or location
milestones. Every required route must reach each declared milestone through
normal production; route comparisons use total ticks and resource ledgers from
their common checkpoint.
