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

The initial two-stage test proves the JSON handoff before covering more of the
technology tree.

1. On a fixed map, complete `nullius-geology-1` and produce the exact building
   and material budget required by stage 2. The result records the research,
   inventory budget, and elapsed ticks.
2. On another fixed map, construct the stage-2 production layout through Lua.
   The setup fails if it needs more than stage 1 produced. Infinity chests and
   pipes supply only resources declared as inputs from outside this stage. Run
   the real machines and logistics until the declared output quantity and next
   research milestone are reached.

Later stages follow the same pattern at research or production boundaries.
Alternative routes receive the same input budget and compare completion ticks
and remaining materials.
