# Automated Testing for Factorio Mods

This document defines the two test layers needed to develop a Factorio mod
without a person playing it. Mod-specific cases and campaign milestones belong
in a separate test plan.

## What Factorio provides

Wube has an internal C++ test framework. Its integration tests create a small
map, place objects, advance the game, and inspect the resulting state. That
framework is not exposed by the production executable or the mod API.

The production game does expose the pieces needed to reproduce that pattern:

- scenarios containing a map and `control.lua`;
- `--scenario2map` for compiling a scenario;
- `--load-game ... --until-tick ...` for a bounded run;
- `--benchmark` for repeatedly running a fixed save quickly;
- the runtime Lua API, events, saves, and `script-output`;
- Instrument Mode for test code that must inspect a mod's private Lua state.

## Layer 1: feature tests

A feature test starts from a small fixture, performs one operation, advances the
real engine only as far as required, and checks observable state. This is the
mod equivalent of Wube's integration tests, even though we call the layer unit
tests because each test owns one feature or contract.

Use [FactorioTest](https://github.com/GlassBricks/FactorioTest) as the runner and
assertion framework. It already runs tests inside Factorio, supports tests that
span ticks, enforces timeouts, and exports structured results. Add only fixture
and assertion helpers specific to the mod.

A test definition contains:

- the initial surface, force, entities, inventories, and researched technology;
- one action through the same public event or API path used in play;
- the event or sparse deadline at which the result is checked; and
- assertions over entities, inventories, fluids, energy, technology, events,
  or mod state.

Direct state injection is allowed while constructing the fixture. It is not a
valid substitute for the operation under test. For example, a placement test
must use the production placement path, not create the final entity graph and
declare success.

Long-running behavior does not require a permanent `on_tick` dispatcher. Tests
should prefer engine events, a one-shot delayed callback, or coarse
`on_nth_tick` readiness checks. The Factorio process also has a hard tick and
wall-clock deadline. A missing result is a failure.

The first vertical slice is one deliberately tiny passing test plus deliberate
assertion, timeout, and missing-result failures. That proves the runner before
feature coverage grows.

## Layer 2: campaign stages

The campaign is split at logical progression boundaries, such as completing a
technology or producing a required quantity of an item. Each stage is a small
scenario on a fixed test map. Resource patches, water, cliffs, and starting
positions are predefined, so failures are about the mod rather than map
generation or player pathing.

A stage does not replay the preceding base. Its setup script constructs the
layout needed for this part of progression. The buildings, materials, and
research supplied by the fixture are its assumed starting state. That assumption
should be achievable at the preceding logical boundary, but the test runner does
not enforce the relationship.

Stages describe consecutive parts of progression but execute independently:

```text
stage 1: reach research A and report available buildings and materials
stage 2: assume that starting state and produce 1,000 of item B
stage 3: assume the next starting state and reach research C
```

Each result records the achieved research, available buildings and materials,
items produced, and ticks spent. No result is an input to another test, so all
stages can run in parallel. If useful, a separate offline check may compare a
stage's result with the next stage's assumptions; it is not part of the main
test system.

Scenario scripts may use editor entities such as infinity chests, infinity
pipes, and electric-energy interfaces to represent supplies, sinks, or utilities
outside the stage being tested. Every such boundary is declared in the result.
Items supplied by an infinity entity are not counted as output achieved by the
stage.

Inside those boundaries, Factorio performs the full simulation: recipes consume
their real inputs and time, inserters and belts move items, pipes carry fluids,
machines consume energy, and laboratories research normally. Buildings may be
created and configured through Lua because player placement is not part of this
test.

A stage passes when its logical goal is observed through the Lua API and written
to the final JSON. Typical goals are:

- a named technology is researched;
- at least a specified amount of an item or fluid was produced;
- a production line sustains a minimum output over a stated interval; or
- the expected buildings and materials exist at the stage boundary.

Checks use engine events or coarse intervals, plus a hard game-tick and
wall-clock deadline. There is no permanent per-tick campaign dispatcher. The
reported completion ticks provide pacing evidence; broad accepted ranges can
flag stages that became unexpectedly short or long.

Alternative progression paths start from the same declared fixture, run as
separate scenarios, and compare completion ticks and remaining materials.
Multiplayer-sensitive behavior is exercised by running the relevant feature or
stage scenario on a server with the required clients; it does not require
simulating an entire multiplayer campaign.

## Factorio updates

Every result records the Factorio version and loaded mod versions.

To evaluate a new Factorio version:

1. diff the runtime API, prototype API, and effective prototype dump;
2. run all feature tests on the candidate;
3. run all campaign stages in parallel; and
4. compare milestone success, resource ledgers, and tick ranges with the
   accepted version.

The version is accepted only when both layers pass and every observed change is
explained.

## First implementation

1. Pin and run FactorioTest with the harness pass/failure/timeout checks.
2. Add the first mod-specific feature cases in the separate test plan.
3. Add two independent campaign stages on fixed maps and run them in parallel.
   Each declares its starting assumptions and verifies its own research or
   production goal through full engine simulation.
4. Run the same slice on the next Factorio version and compare its results.

Only after this vertical slice works should more feature cases or campaign
milestones be added.

## Sources

- [Wube integration tests](https://factorio.com/blog/post/fff-60)
- [Factorio command-line parameters](https://wiki.factorio.com/Command_line_parameters)
- [Factorio scenario system](https://wiki.factorio.com/Scenario_system)
- [Factorio Instrument Mode](https://lua-api.factorio.com/2.0.76/auxiliary/instrument.html)
- [FactorioTest](https://github.com/GlassBricks/FactorioTest)
