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
python3 tools/run_factorio_tests.py -n auto
```

Its independent scenario stages are:

1. `activation`;
2. `vent-prime` and `gas-self-power`;
3. `lava-separation` and `bloom-cooldown`;
4. `aluminum-reduction`, `sulfur-catalysis`, and `pneumatic-heat`;
5. `metallurgic-pack-recipe`;
6. `construction-closure`;
7. `metallurgic-pack-10`.

Each stage declares a fixture that is a subset of cumulative prior-stage output
plus explicit raw or debug boundaries. Stages do not load one another's saves,
so the suite runs in parallel. No stage may inject undeclared intermediates,
equipment, or finished packs. Wreck machines are bootstrap executors; equipment
used after construction closure must be covered by its production counts.

The resolved prerequisite queries cover the complete equipment and pack target
sets. Their raw boundaries and bootstrap executors are the scenario contracts;
queries fail on unresolved products, inaccessible crafting categories, cyclic
routes, or additional recipe research.
