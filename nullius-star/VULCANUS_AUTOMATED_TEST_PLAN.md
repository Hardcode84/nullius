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

The first runnable slice covers production-event creation, the single-vent seam
amount, and scripted shell-destruction cleanup:

```bash
python3 tools/run_factorio_tests.py vulcanus-gas-vent-smoke
```

### Pneumatic-heat lifecycle

Build an eligible pneumatic machine through its production placement path.
Check that one correctly sized hidden heat interface is created, heat rises
while the machine works, input stops when work stops, and removal destroys the
owned interface without leaving duplicates or stale state.

The runnable geometry slice covers small, medium, medium2, and large machines.
It places heat pipes at tick 5, proves heat reaches every hidden interface, and
checks removal cleanup:

```bash
python3 tools/run_factorio_tests.py vulcanus-pneumatic-heat
```

## First campaign slice

The first campaign slice is defined in
[`VULCANUS_PROGRESSION_PLAN.md`](VULCANUS_PROGRESSION_PLAN.md). It begins with
probe activation and ends when a second, locally manufactured production cell
sustains metallurgic-pack output.

```bash
python3 tools/run_factorio_tests.py vulcanus-activation vulcanus-vent-prime vulcanus-gas-self-power
```

Its independent scenario stages are:

1. `activation`;
2. `vent-prime` and `gas-self-power`;
3. `lava-separation` and `bloom-cooldown`;
4. `aluminum-reduction`, `sulfur-catalysis`, and `pneumatic-heat`;
5. `metallurgic-pack-recipe`;
6. `construction-closure`;
7. `metallurgic-pack-10`; and
8. `campaign-through-metallurgic-science`.

Each stage declares the preceding milestone as its fixture and validates its own
production through real machines. No stage consumes another stage's result, so
the suite runs in parallel. The full slice does not inject lava products,
graphite, rutile, sulfur, ingots, construction intermediates, equipment, or the
finished pack. Wreck machines are permitted bootstrap executors, but equipment
placed in the second cell must be matched by post-activation production counts.

Before the campaign scenarios are authored, the resolved prerequisite query
must pass for the complete equipment target set. Its declared raw boundaries
and wreck-machine executors are the same contract used by the scenarios; the
query fails on unresolved products, inaccessible crafting categories, cyclic
repair routes, or additional recipe research.
