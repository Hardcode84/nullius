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
- `--scenario2map` and `--map2scenario` conversions;
- `--load-game ... --until-tick ...` for a bounded run;
- `--benchmark` for repeatedly running a fixed save quickly;
- the runtime Lua API, events, saves, and `script-output`;
- Instrument Mode for test code that must inspect a mod's private Lua state.

`LuaSimulation.create_test_player` is not a general test-player API. It exists
only in menu and documentation simulations, and those simulations cannot be
saved. Native replays are also a poor maintained test format: they cannot be
recorded headlessly and game or mod changes invalidate them.

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

## Layer 2: chunked campaign

The campaign test plays progression through the real simulation: the player
walks and mines, crafting consumes time and ingredients, buildings are placed
from inventory with reach and collision checks, recipes and research are
selected, and machines and logistics run for their actual game ticks.

The campaign is divided at progression milestones. Each chunk is its own
scenario:

```text
seed scenario
  -> play and verify chunk 1 -> checkpoint 1
  -> play and verify chunk 2 -> checkpoint 2
  -> play and verify chunk 3 -> checkpoint 3
```

After chunk N passes, its save is converted with `--map2scenario` to form the
map state of chunk N+1. The next chunk supplies its own action script and exit
assertions, is converted back with `--scenario2map`, and is run normally. The
first implementation must prove that this round trip preserves mod state and
the player before relying on it for longer progression.

Each chunk declares only:

- its predecessor checkpoint;
- semantic player actions and their preconditions;
- a maximum game tick and wall-clock duration;
- its milestone and resource-ledger assertions; and
- the successor checkpoint it produces.

Actions are goals, not a tick-perfect replay. Examples are `walk_to`,
`mine_until`, `craft`, `place_from_inventory`, `configure_machine`, and
`wait_until`. Every action has a precondition and deadline. Failure reports the
blocked action and relevant state.

Walking and mining are continuous player states: set them once and stop them
when their completion event or condition occurs. Passive production and
research run entirely in the engine and are observed through events or coarse
polling. A temporary per-tick handler is acceptable only while an operation
actually requires tick precision, and is removed as soon as that operation
ends.

A checkpoint is accepted only after the chunk's assertions pass. Its manifest
records the save hash, predecessor hash, Factorio version, complete mod set and
settings, seed, campaign-script revision, tick counts, and resource ledger.
Chunk N+1 refuses any checkpoint whose manifest does not match its declared
input.

Cached checkpoints make local iteration fast. They are not independent proof:
changing a chunk or any input invalidates it and every successor. A release run
rebuilds the entire chain from the seed scenario. Alternative progression paths
fork from a common certified checkpoint and later compare their milestone time
and resource ledgers.

TAS projects demonstrate that Lua can drive a complete Factorio campaign, but
their monolithic exact-tick scripts are too brittle for regression testing. We
reuse their player-action vocabulary while using state-dependent completion and
short restartable chunks.

Campaign chunks that claim player-input behavior run with a real connected
player, not `LuaSimulation` or direct entity creation. Multiplayer cases use the
same chunk format but declare a server and the required real clients; their exit
contract includes join/leave behavior and a clean desync result.

## Factorio updates

The Factorio version, executable hash, API JSON, built-in mods, test framework,
and external mods are inputs to every result and checkpoint.

To evaluate a new Factorio version:

1. diff the runtime API, prototype API, and effective prototype dump;
2. run all feature tests on the candidate;
3. rebuild the campaign chain from the seed scenario; and
4. compare milestone success, resource ledgers, and tick ranges with the
   accepted version.

No checkpoint produced by one Factorio or mod version is reused to certify
another. The version is accepted only when both layers pass and every observed
change is explained.

## First implementation

1. Pin and run FactorioTest with the harness pass/failure/timeout checks.
2. Add the first mod-specific feature cases in the separate test plan.
3. Prove a two-chunk campaign: perform real player placement in chunk 1,
   convert its verified save into chunk 2, continue simulation, and verify that
   the player, mod state, and placed entity survived.
4. Run that same slice with a deliberately changed Factorio input and prove
   stale checkpoints are rejected and the chain is rebuilt.

Only after this vertical slice works should more feature cases or campaign
milestones be added.

## Sources

- [Wube integration tests](https://factorio.com/blog/post/fff-60)
- [Wube GUI/input test fixture](https://factorio.com/blog/post/fff-366)
- [Factorio command-line parameters](https://wiki.factorio.com/Command_line_parameters)
- [Factorio scenario system](https://wiki.factorio.com/Scenario_system)
- [Factorio Instrument Mode](https://lua-api.factorio.com/2.0.76/auxiliary/instrument.html)
- [Factorio LuaSimulation](https://lua-api.factorio.com/2.0.76/classes/LuaSimulation.html)
- [FactorioTest](https://github.com/GlassBricks/FactorioTest)
- [Factorio TAS Generator](https://github.com/MortenTobiasNielsen/Factorio-TAS-Generator)
- [Factorio Any% TAS](https://github.com/gotyoke/Factorio-AnyPct-TAS)
