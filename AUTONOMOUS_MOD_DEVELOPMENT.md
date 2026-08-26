# Autonomous Factorio Mod Development and Certification

> **Status:** Initial architecture
> **Primary implementation target:** Factorio 2.0.76 and Nullius*
> **Applicability:** Reusable across Factorio mods through a generic core and a
> small mod-specific campaign contract

## 1. Purpose

This document defines a system that can develop and validate a Factorio mod
without a person manually playing each revision. The system must determine,
within an explicitly bounded campaign:

- whether progression is reachable and the campaign can be completed;
- whether required resources, machines, energy, surfaces, and technologies can
  be bootstrapped in their intended order;
- whether likely mistakes, destruction, death, save/load, and migration create
  softlocks;
- whether stages fit declared time, effort, and repetition envelopes;
- whether advertised alternative paths have intentional tradeoffs rather than
  accidental dominance;
- whether runtime scripts remain deterministic, multiplayer-safe, and within
  performance budgets; and
- whether a Factorio or dependency update changes any supported contract.

Visual style remains a human responsibility. Structural visual correctness is
still automated: assets must load, icons and locale must exist, collision and
selection boxes must be usable, and generated terrain must contain the intended
objects.

The system certifies a declared contract. It does not claim to prove the absence
of every bug in Factorio's unbounded state space, and it does not invent an
objective definition of fun. Human design judgment establishes experience
envelopes; automation enforces them consistently.

## 2. Certification Claim

Every successful run produces a bounded claim of the following form:

> Commit C is certified on Factorio build F with dependency matrix D, campaign
> contract K, routes R, map seeds S, player counts P, source-save versions M,
> and adversarial suite A. All functional invariants passed and all measured
> experience metrics remained within envelope E.

The claim is invalid if any named input is absent from the result manifest. A
green build without a campaign contract proves loadability, not playability.

## 3. Design Principles

### 3.1 Independent planner, executor, and oracle

The system has four authorities:

1. The **contract** defines intended behavior and accepted bounds.
2. The **planner** finds legal progression and production plans.
3. The **executor** performs those plans in the real Factorio engine.
4. The **oracle** independently observes the world and judges the contract.

The executor cannot mark its own action successful. For example, after asking a
player to build a machine, the oracle checks inventory consumption, the actual
entity, its force and surface, raised runtime effects, connections, and eventual
production.

### 3.2 Production semantics before test convenience

Campaign tests perform ordinary game actions and consume ordinary resources.
Direct entity creation, free research, infinite inventories, and direct storage
mutation are allowed only while constructing an explicitly declared focused-test
fixture. A checkpoint is trusted only if it is reproducibly derived from the
previous certified checkpoint.

### 3.3 Effective prototypes are authoritative

Analysis uses the prototype database after every enabled mod has completed
`data-final-fixes.lua`. Source text alone is insufficient because dependencies
mutate one another's prototypes and load order changes the final game.

### 3.4 Fail loud with a concrete witness

A timeout is not an adequate diagnosis. A failure report must identify the
first violated contract and preserve enough state to reproduce it, such as:

- the minimum unreachable dependency cut;
- the missing machine, fuel, recipe, fluid connection, or surface condition;
- the stalled factory cell and its inventories and status;
- the action sequence and seed that produced a softlock;
- the two route cost vectors that violate a balance envelope; or
- the exact API, prototype, migration, checksum, or timing delta introduced by
  a platform update.

### 3.5 No blind golden regeneration

Baseline changes are classified before acceptance. A tool may generate a new
candidate baseline, but it may not accept unexplained prototype, progression,
world-generation, behavior, or performance changes merely because the new run
is internally consistent.

## 4. System Architecture

```text
Factorio binary + mod matrix + campaign contract
                         |
                         v
              Effective prototype dump
                         |
            +------------+-------------+
            |                          |
            v                          v
   Reachability/production       Semantic diff engine
          solver                       |
            |                          |
            +------------+-------------+
                         v
             Reference campaign plan
                         |
                         v
       Real Factorio semantic-action executor
                         |
                         v
             Independent world oracle
                         |
          +--------------+---------------+
          |              |               |
          v              v               v
     adversarial     multiplayer      performance
        runs           network          corpus
          |              |               |
          +--------------+---------------+
                         v
          Machine-readable result manifest
```

The generic harness owns process isolation, schema parsing, solvers, action
execution, reporting, and comparison. Each mod supplies a campaign contract and
adapters only for mechanics that cannot be inferred from Factorio prototypes.

## 5. Concrete Scenario Test Harness

The first implementation is a conventional deterministic test harness. It does
not require a campaign solver. Each test starts from a declared game fixture,
runs the real engine for a fixed number of ticks while performing scheduled
actions, and asserts observable state at specific ticks and at the deadline.

### 5.1 Test-only mod layout

Tests live in a separate mod so production code does not acquire test branches,
fallbacks, or mutable debug state:

```text
autodev-test/
  info.json
  lib/
    case.lua                 test registration and assertion library
    fixture.lua              surfaces, forces, entities, inventories
    result.lua               stable JSON result writer
  cases/
    gasvent_lifecycle.lua
    pneumatic_heat.lua
    probe_multiplayer.lua
  scenarios/
    focused/
      control.lua            loads selected short cases
      description.json
    gasvent-lifecycle/
      control.lua            one isolated integration case
      description.json
```

`autodev-test` has a required dependency on the mod under test. This makes the
target mod initialize before the test harness. A scenario has its own runtime
Lua state: it can observe and manipulate the game world, but it cannot inspect
or mutate another mod's `storage` table. Assertions therefore prefer public
world behavior. Instrument-only inspection is a separate diagnostic mode and
does not define success.

One scenario may contain several short cases if each case can use an independent
surface and force. Cases that consume a unique planet association, require a
specific save lifecycle, or intentionally terminate the game run in separate
processes.

### 5.2 Exact command flow

For every test invocation, the external runner creates an isolated write-data
directory and configuration, selects an exact mod directory, and executes:

```bash
factorio \
  --config RUN/config.ini \
  --mod-directory RUN/mods \
  --disable-audio \
  --check-unused-prototype-data \
  --scenario2map autodev-test/gasvent-lifecycle

factorio \
  --config RUN/config.ini \
  --mod-directory RUN/mods \
  --disable-audio \
  --load-game RUN/saves/autodev-test/gasvent-lifecycle.zip \
  --until-tick 1200
```

On Factorio 2.0.76, `--scenario2map MOD/SCENARIO` creates
`saves/MOD/SCENARIO.zip` without initializing graphics. `--load-game` combined
with `--until-tick` loads that fixture, advances it to the absolute deadline,
and exits. Correctness tests use this finite execution path; `--benchmark` is
reserved for performance measurement.

This exact flow was verified locally on Factorio 2.0.76 with a minimal test mod:
the compiled scenario started at tick 0, ran headlessly without a connected
player, wrote its required JSON result at tick 10, and exited at tick 20.

The runner requires all of the following:

- both Factorio processes exit successfully;
- strict loader output contains no unapproved project-owned warnings;
- `script-output/autodev/results/CASE.json` exists;
- the result names the expected case, contract version, deadline, and hashes;
- every scheduled action and assertion was executed exactly once; and
- the result status is `pass`.

A missing result is a failure even when Factorio exits zero. This catches a
scenario that never initialized, a disabled test mod, a stalled state machine,
or an early exit before final assertions.

### 5.3 Tick-driven case lifecycle

The scenario registers only ordinary lifecycle and tick handlers:

1. `on_init` creates the fixture and stores serializable case state.
2. `on_tick` executes actions scheduled for the current relative tick.
3. Assertions run immediately after the action phase for that tick.
4. A watchdog records progress counters and diagnoses an early stall.
5. At the deadline, final assertions run and the result JSON is written.
6. If any assertion failed, the scenario raises an error after writing the
   result so Factorio also exits nonzero.

Test definitions and assertion functions remain local code loaded by
`control.lua`. Only data such as the start tick, executed action IDs, entity unit
numbers, samples, and failures is stored in the scenario's `storage` table.
This permits save/load without attempting to serialize functions.

All schedules use ticks relative to the scenario start. The compiled scenario
save begins at a controlled tick, while a resumed checkpoint records its own
phase origin explicitly.

### 5.4 Case definition

The Lua test DSL is deliberately small:

```lua
case.define{
  name = "gasvent-lifecycle",
  deadline = 1200,

  setup = function(ctx)
    ctx.surface = fixture.nullius_vulcanus()
    ctx.force = fixture.force{"nullius-test", researched = {
      "nullius-pneumatic-technology",
    }}
  end,

  actions = {
    case.at(1, "build-shell", function(ctx)
      ctx.shell = fixture.revive_entity{
        surface = ctx.surface,
        force = ctx.force,
        name = "nullius-lava-intake-1-gasvent",
        position = {0, 0},
      }
    end),
    case.at(900, "remove-shell", function(ctx)
      fixture.mine_or_destroy(ctx.shell)
    end),
  },

  assertions = {
    case.at(2, "composite-created", function(ctx, expect)
      expect.entity_count(ctx.surface,
        "nullius-lava-intake-1-gasvent", 1)
      expect.entity_count(ctx.surface, "nullius-gas-vent-drill", 1)
      expect.entity_count(ctx.surface, "nullius-gas-vent-seam", 1)
    end),
    case.at(899, "gas-produced", function(ctx, expect)
      expect.fluid_at_least(ctx.output, "nullius-compressed-volcanic-gas", 1)
    end),
    case.at(901, "composite-removed", function(ctx, expect)
      expect.entity_count(ctx.surface, "nullius-gas-vent-drill", 0)
      expect.entity_count(ctx.surface, "nullius-gas-vent-seam", 0)
    end),
  },
}
```

The example is illustrative; the real fixture must include a valid output
connection and use the exact production event path under test.

Each assertion records expected and actual values, tick, surface, force, and
relevant unit numbers. Approximate quantities require an explicit tolerance.
Unordered collections are normalized before comparison.

### 5.5 Four test levels

Every case declares one coverage level. A higher level does not retroactively
make a lower-level fixture production-shaped.

#### Level 1: Pure logic

Pure Lua helpers with no engine ownership are tested with table inputs and exact
outputs. Logic should be extracted here only when it is genuinely independent
of Factorio objects and events.

#### Level 2: Engine fixture

The scenario creates entities, fluids, inventories, forces, technologies, and
surfaces directly, advances real ticks, and validates engine behavior. This is
appropriate for recipe throughput, fluid and heat networks, cleanup, and
steady-state invariants.

The result must list every injected prerequisite. It proves the tested
mechanism, not that normal progression can obtain the fixture.

#### Level 3: Production event path

The harness performs the production-equivalent action and requires the normal
event path. Separate cases cover player build, robot build, ghost revival,
mining, death, rotation, fast replacement, copy/paste, custom input, and object
destruction when the mod distinguishes them.

Direct `surface.create_entity` is insufficient for a player-build contract.
Where Factorio can raise the exact scripted event, the fixture requests it.
Where the action requires a `LuaPlayer`, the runner connects a client or uses a
connected player through the documented player API. Custom-input behavior is
certified only by an actual input or replay path, not by calling the handler as
a normal Lua function.

#### Level 4: Campaign or network integration

No undeclared assets are injected after the starting fixture. The test crosses
technology, production, surface, save, or client boundaries and validates the
user-visible result. These cases are fewer and slower; focused lower-level
cases provide failure localization.

### 5.6 Assertions and failure behavior

Assertions are observations, not recovery paths. The harness never repairs the
world to keep a test moving.

Core assertions include:

- entity count, identity, validity, ownership, position, direction, and status;
- recipe, input, output, fuel, fluid, temperature, energy, and heat state;
- technology enabled, available, researched, and progress state;
- surface and planet association and generated resource quantities;
- player controller, character, associated bodies, force, and surface;
- event occurrence count and ordering visible to the harness;
- sustained production rate over a specified sampling interval;
- absence of hidden or registered-object debris after removal; and
- deterministic normalized state before and after save/load.

An action that cannot execute is an immediate failure with its preconditions.
An assertion failure is recorded but may allow later independent assertions to
run. At the deadline, any failure produces both structured JSON and a Factorio
script error. The external runner treats process timeout, missing JSON, malformed
JSON, wrong case identity, incomplete schedule, warnings outside policy, and
nonzero exit as distinct failure classes.

### 5.7 Save/load and migration cases

Save/load is a multi-process test, not an in-memory assertion:

1. Phase A starts from a compiled scenario and runs to a named checkpoint.
2. The harness requests a server save after all checkpoint assertions pass.
3. The runner stops the server cleanly and verifies the save artifact.
4. Phase B loads that exact save and runs a second schedule and oracle.
5. The normalized pre-save and post-load states are compared.

Migration tests create the checkpoint with the accepted old Factorio and mod
manifest, then load a copy with the candidate manifest. They verify migration
and `on_configuration_changed` behavior before advancing normal ticks. Source
saves are immutable test inputs; each run works on a copy.

### 5.8 Player and multiplayer cases

A dedicated headless server has no player until a client connects. Therefore a
headless entity fixture cannot certify cursor consumption, controller transfer,
custom inputs, player-specific ownership, or network synchronization.

Player-semantic cases start a server from the compiled fixture, connect one or
more clients with isolated write-data directories, wait for the required join
events, and then schedule actions against those actual `LuaPlayer` objects.
RCON may select the case, poll status, or request a server save; it does not
replace the player action being tested.

Network cases additionally verify server and client logs, disconnect and late
join behavior, final checksums, and absence of desync reports. Instrument Mode
is disabled for these cases.

### 5.9 Initial Nullius* scenario suite

The first useful suite is small and concrete:

1. **strict-load:** current prototypes load with no Nullius-owned ignored data.
2. **gasvent-lifecycle:** ghost revival creates exactly one shell/drill/seam
   composite, gas is produced for fixed ticks, multiple vents obey the declared
   diminishing rule, and every removal path cleans up.
3. **pneumatic-heat-lifecycle:** building creates exactly one correct hidden heat
   interface, active work produces bounded heat, removal cleans up, and a staged
   save/load reconstructs ownership without duplicates.
4. **probe-single-player:** research creates a valid planet surface, wreck,
   inventory, android, association, charting, and transfer path.
5. **probe-two-player:** two real players receive independent bodies; transfer,
   death, late join, disconnect, reconnect, save, and reload preserve ownership.
6. **vulcanus-bootstrap:** the declared wreck assets run a fixed reference
   factory to the first local science output without undeclared grants.

The first implementation milestone is `gasvent-lifecycle`. It exercises a
script-owned composite entity, event registration, engine production, hidden
ownership, tick progression, and cleanup while remaining small enough to
diagnose precisely.

## 6. Reproducible Inputs

Every run resolves an immutable environment manifest containing:

- Factorio semantic version, build number, platform, and binary SHA-256;
- enabled expansion feature flags;
- runtime and prototype API schema versions and SHA-256 values;
- base, quality, elevated-rails, Space Age, and other built-in mod versions;
- every external mod name, version, source artifact SHA-256, and load order;
- startup, runtime-global, runtime-per-user, map-generation, and map settings;
- campaign contract version and SHA-256;
- map seed set and reference-save hashes; and
- repository commit and dirty-tree state.

Tests run with isolated read-data, write-data, mod, save, and script-output
directories. They never rely on a developer's current mod list or overwrite a
personal Factorio configuration.

Distribution compatibility and validation reproducibility are separate:

- `info.json` declares which versions users may load.
- the certification manifest records the exact versions actually tested.
- a supported range requires evidence at its lower and upper boundaries, not
  merely a syntactically permissive dependency string.

## 7. Campaign Contract

The mod-specific contract describes milestones, constraints, and experience
envelopes. It supplements prototypes; it must not repeat facts that can be
derived from them.

Illustrative schema:

```yaml
contract: nullius-star-vulcanus-bootstrap
stop_condition:
  research_completed: nullius-vulcanus-metallurgy-1

initial_state:
  milestone: nullius-probe-vulcanus
  allowed_assets:
    source: vulcanus-probe-wreck
  imports_after_landing: forbidden

goals:
  - surface_exists: nullius-vulcanus
  - independent_remote_body_per_player: true
  - sustained_output:
      item: nullius-metallurgic-science-pack
      rate_per_minute: 10
      duration_minutes: 10

experience_envelopes:
  newcomer:
    elapsed_minutes: [60, 180]
    maximum_manual_crafts: 120
  competent:
    elapsed_minutes: [40, 120]
    maximum_manual_crafts: 80
  optimized:
    elapsed_minutes: [20, 75]
  all:
    maximum_wait_fraction: 0.35
    maximum_identical_expansion_steps: 8

recovery:
  cold_power_restart: required
  renewable_critical_assets: required
  save_load: required
  player_death: required

multiplayer:
  player_counts: [1, 2, 4]
  late_join: required
  disconnect_reconnect: required
```

The numeric values above are examples, not adopted balance targets. Every
envelope requires a named design decision or calibration dataset before it can
gate releases.

## 8. Effective-Prototype Extraction

Factorio 2.0.76 provides the required raw mechanisms:

- `--dump-data` exports effective `data.raw`;
- `--dump-prototype-locale` exports resolved names and descriptions;
- `--dump-icon-sprites` permits structural icon inspection;
- `--check-unused-prototype-data` reports fields silently ignored by the engine;
- map-preview generation and quantity reports sample world generation; and
- the local machine-readable API descriptions are available in
  `factorio-mod-wiki/files/runtime-api.json` and `prototype-api.json`.

The extractor normalizes the final database into a stable intermediate model:

- recipes, ingredients, products, probabilities, catalysts, and temperatures;
- technologies, prerequisites, research units, triggers, and unlock effects;
- item and fluid spoilage, fuel, stack, transport, and quality behavior;
- machines, crafting categories, module rules, fluid boxes, energy sources, and
  placement constraints;
- resources, mining requirements, autoplace controls, and surface conditions;
- planets, space connections, platform requirements, and map-generation rules;
- scripted starting assets and runtime-created resources supplied by adapters;
  and
- resolved locale, icons, collision boxes, selection boxes, and minability.

Normalization removes irrelevant ordering and rendering detail while preserving
all gameplay semantics. The original dump remains an artifact for diagnosis.

## 9. Reachability and Production Solver

### 9.1 Qualitative reachability

Progression is modeled as a directed hypergraph. Starting from the declared
assets and surfaces, the solver repeatedly derives:

- mineable resources;
- hand-craftable recipes;
- buildable and powerable machines;
- runnable recipes;
- researchable technologies;
- reachable surfaces and space locations; and
- newly unlocked actions.

Strongly connected components with no reachable external input are bootstrap
cycles. An unreachable goal produces a minimum dependency cut rather than a
generic failure.

### 9.2 Quantitative feasibility

Reachability does not prove that quantities balance. Linear or mixed-integer
models cover:

- material, fluid, catalyst, and byproduct balance;
- power generation, fuel production, and cold-start reserves;
- machine capital costs and replacement costs;
- probabilistic recipes with declared confidence bounds;
- spoilage and maximum transport time;
- surface-local production and permitted imports;
- science cost and sustained throughput; and
- finite starter assets versus renewable production.

The solver emits a production plan and explains every assumed source, sink,
buffer, and irreversible loss.

### 9.3 Softlock invariants

At minimum, static analysis rejects:

- self-dependent technology or recipe bootstrap cycles;
- required machines whose only recipe requires that machine;
- finite critical assets without protection or a recovery recipe;
- power networks that cannot restart from the declared cold state;
- mandatory byproducts without sufficient storage or a reachable sink;
- required fluids outside accepted temperature ranges;
- planet-local recipes that depend on forbidden imports; and
- required resources absent within the contract's bounded map search.

## 10. Reference Factory and Semantic Executor

The planner compiles production plans into conservative reference factories. A
generic cell library covers common crafting and transport shapes:

- solid-only and fluid-fed crafting machines;
- furnaces, miners, drills, pumps, and offshore-style intakes;
- boilers, generators, solar, accumulators, heat networks, and fuel loops;
- labs and science transport;
- belts, inserters, pipes, bots, trains, and space-platform logistics; and
- waste storage and voiding where the contract allows them.

Cells are generated from collision boxes, fluid connections, energy sources,
and crafting categories. Novel scripted entities use a mod adapter with an
explicit action and observation contract.

Campaign execution uses real player semantics where the API provides them:

- cursor-backed placement through `LuaPlayer.build_from_cursor()`;
- ordinary crafting through `LuaControl.begin_crafting()`;
- ordinary mining through `LuaControl.mine_entity()` and `mine_tile()`;
- actual recipes, power networks, fluids, logistics, research, and elapsed
  ticks; and
- ordinary save, load, death, surface-transfer, and controller transitions.

Focused fixtures may inject prerequisites, but the fixture manifest names every
injected object. Campaign mode permits no undeclared creation, inventory grant,
free research, or direct success-state mutation.

## 11. Independent Runtime Oracle

A test companion mod observes public world state and writes structured records
to `script-output` using Factorio's JSON and file helpers. It does not replace
production handlers or make invalid states recoverable.

The oracle records:

- player, force, surface, controller, and associated-character ownership;
- technology and recipe availability;
- entity validity, status, recipes, connections, and inventories;
- item and fluid production/consumption ledgers;
- electric, heat, and fuel availability;
- research progress and milestone completion;
- build, mine, death, object-destruction, join, leave, and surface events;
- save/load and configuration-change boundaries;
- stalled production diagnostics; and
- final deterministic checksums.

Deep single-player diagnostics may use Instrument Mode. Instrument Mode is not
used for multiplayer certification because Factorio 2.0.76 disables multiplayer
when it is active because injected instrumentation is not desync-safe.

## 12. Pacing, Effort, and Repetition

Simulation ticks and human effort are separate measurements.

### 12.1 Simulation time

The engine supplies exact time for mining, crafting, machine operation,
transport, spoilage, research, and scripted delays. Headless acceleration does
not change the resulting tick counts.

### 12.2 Semantic effort

The executor charges policy-specific effort for meaningful actions:

- walking or remote travel distance;
- resource search and expansion;
- manual mining and crafting;
- entity placement, rotation, configuration, and wiring;
- factory duplication or rebuilding;
- logistics routing and byproduct resolution;
- recovery from expected mistakes; and
- waiting during which no useful parallel action exists.

Three initial player policies are modeled: newcomer, competent automation
player, and optimized expert. Each policy differs in planning horizon, preferred
buffers, parallel construction, willingness to rebuild, and use of optional
routes.

The harness reports rather than hides uncertainty. A stage whose measured
result depends primarily on an uncalibrated effort weight cannot pass a pacing
gate until that weight is adopted by design decision or calibration.

### 12.3 Repetition metrics

The contract can bound:

- identical manual crafts before automation;
- identical placements before blueprint or bot availability;
- repeated factory-scale multiplications;
- fraction of a stage spent waiting;
- distance between meaningful unlocks;
- mandatory rebuild count; and
- consecutive milestones that exercise no new mechanic.

## 13. Alternative-Path Balance

Each advertised route is measured as a cost vector rather than only completion
time:

```text
capital, elapsed ticks, semantic effort, power, space, raw resources,
imports, byproduct burden, operational risk, and recovery cost
```

The route analyzer computes a Pareto frontier. A route is suspicious when
another route is no worse in every declared dimension and better in at least
one. Intentional convenience routes may trade throughput for lower effort;
complex routes must purchase a measurable benefit.

Sensitivity runs vary resource richness, transport distance, demand, machine
tier, and uncertain recipe outputs. A route must remain inside its intended
region across the declared perturbation range rather than only at one tuned
point.

## 14. Adversarial and Property-Based Testing

After a happy path passes, deterministic generators mutate actions and state:

- mine or destroy each starter entity in turn;
- rotate, fast-replace, blueprint, copy/paste, clone, and undo scripted
  composite entities;
- block each output and byproduct independently;
- drain every power source and demand a cold restart;
- fill inventories and reduce available placement area;
- die or disconnect around surface and controller transitions;
- save immediately before and after important events;
- research independent branches in different orders;
- vary map seeds and bounded resource-search radii; and
- perform simultaneous actions by different players.

Every generated case stores its seed and action trace. Failures are minimized to
the shortest reproducing sequence.

Metamorphic properties supplement expected outputs:

- save/load does not change observable state;
- repeating configuration migration is idempotent;
- independent actions commute;
- adding proportional machine capacity does not reduce steady-state output;
- changing player count does not merge player-owned state; and
- changing table iteration or entity construction order does not change final
  deterministic results unless order is part of the contract.

Mutation testing validates the tests themselves. Deliberate mutations such as
removing an unlock, multiplying a cost, breaking a fluid connection, dropping a
cleanup event, or making a starter finite must cause the appropriate gate to
fail.

## 15. Save, Migration, and Multiplayer Certification

### 15.1 Save lifecycle

Every milestone is exercised through fresh creation and save/load. Persistent
state is checked before save and after load. Configuration changes and supported
migrations must reconstruct ownership rather than merely avoid crashing.

For every supported source version, the suite retains a minimal save corpus and
at least one production-shaped save. Upgrade tests verify:

- prototype migration and entity replacement;
- research, recipe, and force state;
- player controllers and associated characters;
- inventories, fluids, energy, trains, platforms, and surfaces;
- registered object ownership and cleanup; and
- idempotence when the migrated save is loaded again.

### 15.2 Real network multiplayer

In-process multiple-player tests validate ownership logic but do not certify
network determinism. Multiplayer certification launches:

- one dedicated Factorio server;
- two or more real clients with isolated write-data directories;
- scripted per-client actions; and
- disconnect, reconnect, late-join, save, reload, death, and simultaneous-action
  schedules.

The run fails on a desync report, checksum disagreement, invalid ownership, or a
client-dependent result. Black-box multiplayer tests use only ordinary,
desync-safe mod APIs.

## 16. Performance Certification

Performance is tested against representative saves, not an empty map alone.
The corpus includes declared entity-count scales, active production, multiple
surfaces, worst supported player count, and stress cases for every scripted hot
path.

Factorio benchmarks run fixed tick counts and repeated trials. Reports preserve:

- average, percentile, and maximum update times;
- script update breakdown where available;
- memory and serialized-save size;
- scaling curves by entity and surface count; and
- deterministic final checksum.

A change fails when it exceeds the contract budget or changes asymptotic scaling
without an approved architecture decision. A faster empty map cannot offset a
regression in the production witness.

## 17. Factorio Version and Dependency Update System

Platform updates are candidate migrations, not routine dependency bumps.

### 17.1 Detection

A scheduled watcher resolves available Factorio releases and dependency mod
versions without modifying the accepted environment. For every candidate it
creates an immutable candidate manifest and isolated installation.

The watcher compares:

1. Factorio version, build, feature flags, binary hash, and command-line surface.
2. Runtime API JSON: classes, methods, attributes, events, concepts, types,
   mutability, optionality, lifecycle restrictions, and descriptions.
3. Prototype API JSON: prototype inheritance, fields, defaults, types,
   optionality, and feature requirements.
4. Built-in and external mod versions and artifact hashes.
5. Effective normalized prototypes under every supported mod matrix.
6. Strict loader diagnostics, locale, icons, and map-generation summaries.
7. Fresh-game, old-save, behavioral, multiplayer, and performance results.

Each difference is assigned a severity:

- **breaking:** removed or narrowed API, invalid prototype data, failed save,
  changed ownership/determinism, unreachable progression, or violated contract;
- **behavioral:** effective recipe, technology, machine, map, timing, or output
  change requiring campaign revalidation;
- **performance:** statistically significant runtime or memory change;
- **additive:** new API or prototype with no current consumer;
- **documentation-only:** description or metadata change with no semantic delta;
  or
- **unclassified:** any change the classifier cannot prove belongs elsewhere.

Unclassified changes fail the update gate.

### 17.2 Candidate pipeline

The accepted and candidate versions run side by side through these gates:

1. **Acquire:** verify artifact origin and hashes; never replace the accepted
   binary in place.
2. **Schema:** semantically diff command-line, runtime API, and prototype API.
3. **Load:** run strict prototype validation for every supported dependency
   matrix.
4. **Effective data:** compare normalized prototype and locale snapshots.
5. **World generation:** compare map summaries across the seed ensemble and
   prove required resources remain reachable.
6. **Fresh campaign:** execute all affected contracts from new games.
7. **Migration:** load every supported old-version save under the candidate.
8. **Determinism:** replay fixed traces and compare invariant snapshots and
   checksums.
9. **Multiplayer:** run actual server/client join and action schedules.
10. **Performance:** compare the representative benchmark corpus with noise
    bounds and scaling budgets.

If a version jump spans multiple Factorio releases and the candidate fails, the
runner tests intermediate versions to identify the first breaking release.

### 17.3 Change ownership and adaptation

The diff engine maps each affected API or prototype field to source consumers,
campaign contracts, adapters, saves, and tests. It opens concrete tracker issues
containing the old/new values and failing witnesses.

An autonomous repair may adapt code and generate a candidate baseline, but the
baseline is accepted only when:

- every breaking or behavioral delta has an explicit intended resolution;
- all affected contracts pass on the candidate;
- supported old saves migrate correctly;
- no unclassified delta remains; and
- the accepted environment remains available for rollback.

Promotion atomically updates the environment manifest and archives the previous
certificate. Publishing a mod release is a separate action and is not implied
by successful platform certification.

### 17.4 Dependency matrices

Required and optional mod updates use the same process. The matrix is reduced
through pairwise coverage plus explicitly named high-risk combinations, while
the required core combination is always tested exhaustively.

For each dependency, the system records:

- lowest supported, currently accepted, and newest candidate versions;
- which prototypes and remote interfaces the mod consumes or mutates;
- whether the dependency affects campaign reachability or only presentation;
  and
- the saves and contracts that exercise the integration.

## 18. Result Artifacts and Failure Protocol

Each run emits:

```text
manifest.json             immutable inputs and hashes
certificate.json          bounded pass/fail claim
prototype-normalized.json effective semantic model
prototype-diff.json       classified baseline delta
progression-plan.json     solver route and assumptions
events.jsonl              runtime observation stream
ledger.json               material, fluid, energy, and research accounting
metrics.json              pacing, balance, and performance results
failure.json              first violated contract and minimized witness
saves/                    declared checkpoints and failing states
logs/                     Factorio, server, client, and harness logs
```

The top-level process exits nonzero on errors, warnings owned by the mod,
unclassified changes, timeouts, missing artifacts, or incomplete coverage. It
does not convert a missing result into a skipped test.

## 19. Execution Tiers

| Tier | Trigger | Required coverage |
|---|---|---|
| Fast | Every source change | Schema validation, strict load, affected graph and focused contracts |
| Integration | Before branch integration | Fresh map, semantic diff, affected milestone routes, save/load |
| Nightly | Scheduled | Seed ensemble, route sensitivity, fuzzing, multiplayer, production performance |
| Platform candidate | Factorio or dependency update | Side-by-side schema, data, world, campaign, migration, multiplayer, performance |
| Release | Mod release candidate | All bounded campaigns, supported matrices and saves, mutation audit, certificate |

Tests are selected by a source-to-contract impact map, but absence of a known
impact does not exempt strict load and semantic prototype comparison.

## 20. Autonomous Development Loop

For each ready tracker issue, the development agent must:

1. name the production contract being changed;
2. establish the current failing witness or controlled baseline;
3. define a falsifiable success metric and stop condition;
4. implement the smallest design change that restores the contract;
5. run focused static and engine tests;
6. inspect semantic prototype and behavior diffs;
7. run every impacted campaign, migration, multiplayer, and performance gate;
8. preserve the resulting certificate and exact evidence; and
9. close the issue only when all required artifacts exist and the tree is clean.

Speculative balance or architecture work stops at an experiment unless the
measured production witness justifies adoption.

## 21. Initial Nullius* Certification Slice

The first implementation targets the hardest currently implemented ownership
boundary and user-visible output:

1. Start a clean Nauvis game with the accepted dependency matrix.
2. Reach and complete `nullius-probe-vulcanus` through declared prerequisites.
3. Create and validate the `nullius-vulcanus` surface across multiple seeds.
4. Create one independent remote android per player and transfer control.
5. Bootstrap using only probe-wreck assets.
6. Operate one lava intake and one diminishing-return free-gas vent.
7. Cold-start pneumatic processing and validate hidden heat ownership.
8. Produce local iron, aluminum, silicon insulation, and required intermediates.
9. Sustain the declared metallurgic science rate.
10. Complete one Vulcanus technology using that science.
11. Save/load at each ownership boundary and at final steady state.
12. Repeat ownership and progression assertions with two real clients and a
    late joiner.

This slice passes only when both the static solver and real engine execution
agree. It is the prerequisite for expanding horizontally to another planet.

## 22. Implementation Phases and Gates

### Phase A: Hermetic runner and scenario harness

Deliver isolated Factorio execution, environment manifests, strict prototype
loading, normalized dumps, semantic diffs, the test-only scenario mod,
tick-scheduled actions and assertions, required result artifacts, and clean
failure propagation.

**Gate:** the current Nullius* load is reproducible from a clean directory, and
a deliberate ignored prototype field or recipe change produces a classified
failure. The `gasvent-lifecycle` scenario passes unmodified and fails on
deliberately broken creation, production, timing, and cleanup behavior.

### Phase B: Engine oracle and focused production cells

Deliver semantic player actions, reusable fixture builders, conservative
factory cells, event stream, resource and energy ledger, progress watchdog,
save/load staging, and minimized failures.

**Gate:** each Vulcanus machine family and scripted composite entity operates and
cleans up under real engine ticks; injected event-path, lifecycle, and ownership
mutations are detected.

### Phase C: Progression graph and quantitative solver

Deliver qualitative reachability, bootstrap-cycle diagnostics, material and
energy balance, and a machine-readable plan compiled from effective prototypes.

**Gate:** deliberate removal of each Vulcanus prerequisite produces the correct
minimum blocking witness; the unmodified slice produces a feasible plan.

### Phase D: Bounded campaign executor

Deliver the complete initial Nullius* slice, checkpoint derivation, effort
metrics, route accounting, seed ensemble, and adversarial cases.

**Gate:** the bootstrap-to-science contract passes without undeclared grants and
fails when any required production edge is deliberately broken.

### Phase E: Real multiplayer and migration matrix

Deliver isolated server/client orchestration, late join and reconnect schedules,
desync detection, and supported-save upgrades.

**Gate:** two-player and late-join Nullius* contracts pass; injected shared-body,
`on_load`, and orphan-ownership bugs fail deterministically.

### Phase F: Platform update automation

Deliver candidate acquisition, local API schema diffing, dependency matrices,
side-by-side certification, issue generation, intermediate-version isolation,
and atomic promotion/rollback.

**Gate:** a synthetic API removal, effective prototype change, world-generation
change, migration regression, and performance regression are each classified
and block promotion for the correct reason.

## 23. Decisions Required Before Pacing Becomes a Release Gate

Functional development can begin immediately. Pacing and balance become binding
only after these values are adopted:

- the first Nullius* stopping milestone;
- newcomer, competent, and optimized policy definitions;
- time and semantic-effort envelopes per milestone;
- permitted imports and starter-asset recovery policy;
- route tradeoff dimensions and dominance tolerances;
- seed count, resource-search radius, and probability confidence level;
- supported player counts and save-source versions; and
- performance corpus sizes and budgets.

Until adopted, the harness reports these metrics and rejects claims that the mod
is balanced; it may still certify functional reachability, determinism, and
bounded completion.

## 24. Reference Material

- Local Factorio 2.0.76 runtime schema:
  `~/factorio-mod-wiki/files/runtime-api.json`
- Local Factorio 2.0.76 prototype schema:
  `~/factorio-mod-wiki/files/prototype-api.json`
- Local lifecycle documentation:
  `~/factorio-mod-wiki/files/auxiliary/data-lifecycle.html`
- Local Instrument Mode documentation:
  `~/factorio-mod-wiki/files/auxiliary/instrument.html`
- Installed command-line contract: `factorio --help`
- Online command-line reference:
  <https://wiki.factorio.com/Command_line_parameters>
- Online runtime API reference: <https://lua-api.factorio.com/2.0.76/>
