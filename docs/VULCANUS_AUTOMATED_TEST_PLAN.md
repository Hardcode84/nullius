# Vulcanus Automated Test Plan

The generic test architecture is defined in
[`AUTONOMOUS_MOD_DEVELOPMENT.md`](AUTONOMOUS_MOD_DEVELOPMENT.md). This file
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

## Campaign coverage

The implemented campaign slice is defined in
[`VULCANUS_PROGRESSION_PLAN.md`](VULCANUS_PROGRESSION_PLAN.md). It begins with
probe activation, proves local basic and chemical science, and continues through
tier-3 thermal heavy industry on Nauvis.

```bash
python3 tools/run_factorio_tests.py -n auto
```

| Boundary | Scenarios |
|---|---|
| Activation and fuel bootstrap | `vulcanus-activation`, `vulcanus-vent-prime`, `vulcanus-gas-self-power` |
| Lava materials and cooling | `vulcanus-lava-separation-*`, `vulcanus-bloom-cooldown-*`, `vulcanus-aluminum-reduction`, `vulcanus-sulfur-catalysis` |
| Pneumatic machinery and heat | `vulcanus-pneumatic-compressor`, `vulcanus-pneumatic-heat`, `vulcanus-pneumatic-heat-production`, `vulcanus-hcl-thermal-cracking` |
| Bootstrap metallurgy | `vulcanus-metallurgic-pack-recipe`, `vulcanus-construction-closure`, `vulcanus-inorganic-barrel`, `vulcanus-metallurgic-pack-10` |
| Local generic science | `vulcanus-basic-science-10` |
| Local chemical science | `vulcanus-caustic-bootstrap`, `vulcanus-chemical-acid-200`, `vulcanus-chemical-alkali-20`, `vulcanus-chemical-glass-lubricant`, `vulcanus-chemical-concrete-barrels`, `vulcanus-chemical-pack-10` |
| Efficient metallurgy and hot casting | `vulcanus-efficient-metallurgic-research`, `vulcanus-efficient-metallurgic-science`, `vulcanus-hot-casting` |
| Thermal research and cells | `thermal-engineering-*`, `thermal-machines-*`, `thermal-cell-*`, `industrial-optimization-1`, `industrial-productivity-technologies`, `recipe-productivity-family` |

Each stage declares a fixture that is a subset of cumulative prior-stage output
plus explicit raw or debug boundaries. Stages do not load one another's saves,
so the suite runs in parallel. No stage may inject undeclared intermediates,
equipment, or finished packs. Wreck machines are bootstrap executors; equipment
used after construction closure must be covered by its production counts.

The 17 checked-in argument files under `tests/progression/` define the
resolved prerequisite contracts. Queries fail on unresolved products,
inaccessible crafting categories, cyclic routes, undeclared recipe research,
or forbidden electric execution paths.
