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

## 5. Reproducible Inputs

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

## 6. Campaign Contract

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

## 7. Effective-Prototype Extraction

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

## 8. Reachability and Production Solver

### 8.1 Qualitative reachability

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

### 8.2 Quantitative feasibility

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

### 8.3 Softlock invariants

At minimum, static analysis rejects:

- self-dependent technology or recipe bootstrap cycles;
- required machines whose only recipe requires that machine;
- finite critical assets without protection or a recovery recipe;
- power networks that cannot restart from the declared cold state;
- mandatory byproducts without sufficient storage or a reachable sink;
- required fluids outside accepted temperature ranges;
- planet-local recipes that depend on forbidden imports; and
- required resources absent within the contract's bounded map search.

## 9. Reference Factory and Semantic Executor

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

## 10. Independent Runtime Oracle

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

## 11. Pacing, Effort, and Repetition

Simulation ticks and human effort are separate measurements.

### 11.1 Simulation time

The engine supplies exact time for mining, crafting, machine operation,
transport, spoilage, research, and scripted delays. Headless acceleration does
not change the resulting tick counts.

### 11.2 Semantic effort

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

### 11.3 Repetition metrics

The contract can bound:

- identical manual crafts before automation;
- identical placements before blueprint or bot availability;
- repeated factory-scale multiplications;
- fraction of a stage spent waiting;
- distance between meaningful unlocks;
- mandatory rebuild count; and
- consecutive milestones that exercise no new mechanic.

## 12. Alternative-Path Balance

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

## 13. Adversarial and Property-Based Testing

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

## 14. Save, Migration, and Multiplayer Certification

### 14.1 Save lifecycle

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

### 14.2 Real network multiplayer

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

## 15. Performance Certification

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

## 16. Factorio Version and Dependency Update System

Platform updates are candidate migrations, not routine dependency bumps.

### 16.1 Detection

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

### 16.2 Candidate pipeline

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

### 16.3 Change ownership and adaptation

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

### 16.4 Dependency matrices

Required and optional mod updates use the same process. The matrix is reduced
through pairwise coverage plus explicitly named high-risk combinations, while
the required core combination is always tested exhaustively.

For each dependency, the system records:

- lowest supported, currently accepted, and newest candidate versions;
- which prototypes and remote interfaces the mod consumes or mutates;
- whether the dependency affects campaign reachability or only presentation;
  and
- the saves and contracts that exercise the integration.

## 17. Result Artifacts and Failure Protocol

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

## 18. Execution Tiers

| Tier | Trigger | Required coverage |
|---|---|---|
| Fast | Every source change | Schema validation, strict load, affected graph and focused contracts |
| Integration | Before branch integration | Fresh map, semantic diff, affected milestone routes, save/load |
| Nightly | Scheduled | Seed ensemble, route sensitivity, fuzzing, multiplayer, production performance |
| Platform candidate | Factorio or dependency update | Side-by-side schema, data, world, campaign, migration, multiplayer, performance |
| Release | Mod release candidate | All bounded campaigns, supported matrices and saves, mutation audit, certificate |

Tests are selected by a source-to-contract impact map, but absence of a known
impact does not exempt strict load and semantic prototype comparison.

## 19. Autonomous Development Loop

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

## 20. Initial Nullius* Certification Slice

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

## 21. Implementation Phases and Gates

### Phase A: Hermetic runner and semantic snapshots

Deliver isolated Factorio execution, environment manifests, strict prototype
loading, normalized dumps, semantic diffs, structured artifacts, and clean
failure propagation.

**Gate:** the current Nullius* load is reproducible from a clean directory, and
a deliberate ignored prototype field or recipe change produces a classified
failure.

### Phase B: Progression graph and quantitative solver

Deliver qualitative reachability, bootstrap-cycle diagnostics, material and
energy balance, and a machine-readable plan.

**Gate:** deliberate removal of each Vulcanus prerequisite produces the correct
minimum blocking witness; the unmodified slice produces a feasible plan.

### Phase C: Engine oracle and focused production cells

Deliver the companion test mod, semantic player actions, factory cells, event
stream, ledger, watchdog, save/load, and minimized failures.

**Gate:** each Vulcanus machine family and scripted composite entity operates and
cleans up under real engine ticks; injected lifecycle mutations are detected.

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

## 22. Decisions Required Before Pacing Becomes a Release Gate

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

## 23. Reference Material

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
