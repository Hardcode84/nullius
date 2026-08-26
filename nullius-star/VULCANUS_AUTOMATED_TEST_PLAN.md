# Vulcanus Automated Test Plan

The generic test architecture is defined in
[`AUTONOMOUS_MOD_DEVELOPMENT.md`](../AUTONOMOUS_MOD_DEVELOPMENT.md). This file
contains only the Nullius Star cases and progression milestones for Vulcanus.

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

The initial two stage tests establish the fixture-and-goal pattern before
covering more of the technology tree. They are independent and run in parallel.

1. On a fixed Vulcanus map, complete `nullius-geology-1` and produce the exact
   building and material inventory expected at this boundary. The result
   records the research, inventory, and elapsed ticks.
2. On another fixed Vulcanus map, construct the stage-2 production layout
   through Lua. Its fixture assumes the inventory expected from stage 1; it
   does not read or validate stage 1's result. Infinity chests and pipes supply
   only resources declared as inputs from outside this stage. Run the real
   machines and logistics until the declared output quantity and next research
   milestone are reached.

Later stages follow the same pattern at research or production boundaries.
Alternative routes receive the same starting fixture and compare completion
ticks and remaining materials.
