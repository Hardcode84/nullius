# Automated Factorio Scenario Tests

> **Status:** Immediate implementation plan
> **Factorio:** 2.0.76
> **Mod under test:** `nullius-star`

## 1. Goal

Build a small test system that can run Nullius* inside Factorio without a person
playing it.

Each test will:

1. start from a known game state;
2. perform scripted actions at specified ticks;
3. let the real Factorio engine run;
4. assert intermediate and final world state; and
5. write a required JSON result before Factorio exits.

The first implementation ends when strict loading, gas-vent lifecycle, and
pneumatic-heat lifecycle tests pass and Factorio version drift is detected.

## 2. Not in this implementation

This document does not design or build:

- a progression or production solver;
- a bot that completes the campaign;
- pacing, repetition, or route-balance models;
- randomized fuzzing;
- automatic Factorio downloads or promotion;
- a general compatibility matrix; or
- real-client multiplayer automation.

Those require working engine-level tests first. We will choose the next slice
after the initial tests produce useful failures on current Nullius* code.

## 3. Files to add

```text
tools/
  run_factorio_tests.py

nullius-star-test/
  info.json
  lib/
    case.lua
    fixture.lua
    result.lua
  cases/
    harness_self_test.lua
    gasvent_lifecycle.lua
    pneumatic_heat_lifecycle.lua
  scenarios/
    harness-self-test/
      control.lua
      description.json
    gasvent-lifecycle/
      control.lua
      description.json
    pneumatic-heat-lifecycle/
      control.lua
      description.json

tests/factorio/
  accepted-environment.json
```

`nullius-star-test` is a test-only mod with a required dependency on
`nullius-star`. It is never included in a release archive.

## 4. How one test runs

The Python runner creates a temporary directory containing an isolated Factorio
configuration, mod directory, saves directory, logs, and `script-output`.
It symlinks or copies only the exact declared mods into that directory.

It then runs:

```bash
factorio \
  --config RUN/config.ini \
  --mod-directory RUN/mods \
  --disable-audio \
  --check-unused-prototype-data \
  --scenario2map nullius-star-test/gasvent-lifecycle

factorio \
  --config RUN/config.ini \
  --mod-directory RUN/mods \
  --disable-audio \
  --load-game RUN/saves/nullius-star-test/gasvent-lifecycle.zip \
  --until-tick 1200
```

Factorio 2.0.76 was locally verified to support this exact pattern. A minimal
scenario compiled to a save, ran headlessly without a connected player, wrote a
JSON result on tick 10, and exited on tick 20.

The runner considers the test passed only when:

- both Factorio invocations exit zero;
- no unapproved Nullius-owned warning appears;
- `RUN/script-output/nullius-test/CASE.json` exists;
- the JSON names the expected case and deadline;
- every scheduled action and assertion ran exactly once; and
- the JSON result is `pass`.

A zero exit without the expected JSON is a failure.

## 5. Scenario lifecycle

Each scenario loads one case. The common harness registers `on_init` and
`on_tick`.

### On initialization

The harness:

- records the start tick;
- creates the required surface and force;
- constructs the declared fixture;
- records every injected entity, item, technology, and fluid; and
- initializes the executed-action and assertion tables in scenario `storage`.

The scenario cannot access `nullius-star` storage. Tests validate observable
entities, fluids, energy, technologies, players, and events.

### On each tick

The harness:

1. executes actions scheduled for the relative tick;
2. executes assertions scheduled for that tick;
3. records expected and actual values for failures; and
4. writes the final JSON at the declared deadline.

If an action cannot run, the case fails immediately with its preconditions. If
an assertion fails, independent later assertions may still run so the result can
show all consequences. After writing a failing result, the scenario raises a Lua
error so Factorio also exits nonzero.

Functions remain in Lua source. Only serializable state is stored in `storage`.

## 6. Case API

The initial API is intentionally small:

```lua
case.define{
  name = "gasvent-lifecycle",
  deadline = 1200,

  setup = function(ctx)
    ctx.surface = fixture.nullius_vulcanus()
    ctx.force = fixture.force{
      name = "nullius-test",
      researched = {"nullius-pneumatic-technology"},
    }
  end,

  actions = {
    case.at(1, "build", build_gasvent),
    case.at(900, "remove", remove_gasvent),
  },

  assertions = {
    case.at(2, "created", assert_composite_created),
    case.at(899, "produced", assert_gas_produced),
    case.at(901, "removed", assert_composite_removed),
  },
}
```

Initial assertion helpers cover:

- entity count by name, surface, force, and area;
- entity validity, direction, status, and temperature;
- item and fluid quantity;
- technology state; and
- equality, numeric ranges, and explicit failure messages.

Approximate values always name their tolerance.

## 7. Fixture actions versus production actions

Directly creating an entity is sufficient to test engine behavior but does not
prove that the production build event works.

Every action is therefore tagged as one of:

- `fixture`: direct setup that the result reports as injected; or
- `production-event`: an action that must raise the normal event used by
  `nullius-star`.

For example, the gas-vent case creates an entity ghost and revives it through
the engine so `script_raised_revive` reaches `scripts/build.lua`. Calling
`vulcanus_gasvent.register()` directly would not be a valid integration test.

Tests requiring an actual `LuaPlayer`, custom input, or network client are not
pretended to pass through fixture creation. The result reports that coverage as
absent until a real-player runner exists.

## 8. Required result

Each scenario writes one result shaped like:

```json
{
  "schema": 1,
  "case": "gasvent-lifecycle",
  "status": "pass",
  "start_tick": 0,
  "deadline_tick": 1200,
  "factorio_version": "2.0.76",
  "actions_expected": 2,
  "actions_executed": 2,
  "assertions_expected": 3,
  "assertions_executed": 3,
  "injected": [],
  "failures": []
}
```

The runner adds process-level data—binary hash, mod hashes, command lines, exit
codes, and log paths—to its outer result. The scenario result contains only
facts observed inside the game.

## 9. Initial tests

### 9.1 Harness self-test

This proves the runner before using Nullius mechanics.

- Create a small empty surface on `on_init`.
- At tick 5 create an iron chest.
- At tick 6 assert that exactly one chest exists.
- At tick 10 write a passing result.
- Also run one deliberately failing assertion and prove the runner returns
  nonzero with the expected actual and expected values.
- Delete or suppress the result in a controlled harness test and prove the
  runner reports `missing-result`.

### 9.2 Strict load

Run `--check-unused-prototype-data` while compiling every scenario.

The first accepted warning policy allows warnings owned by dependencies only
when their exact text is recorded. Every warning naming a Nullius prototype is a
failure. This immediately covers the currently ignored surface and map-generation
fields.

### 9.3 Gas-vent lifecycle

Fixture:

- create or obtain the real `nullius-vulcanus` planet surface;
- create a force with pneumatic technology researched;
- create a valid gas output connection and storage; and
- inject only the items required for the production action.

Actions and assertions:

1. Revive one gas-vent shell through the production event path.
2. Assert exactly one visible shell, hidden drill, and hidden seam.
3. Run until gas reaches the connected output.
4. Add a second vent and assert both remain valid and their seam amounts match
   the declared diminishing-return rule.
5. Remove one shell through each supported removal path in separate runs:
   mining, death, scripted destruction, and hidden-part destruction.
6. Assert no hidden drill, seam, or continuing gas output remains for the
   removed vent, then rebuild at the same position and assert that exactly one
   valid composite exists.

The test never calls gas-vent implementation functions directly.

### 9.4 Pneumatic-heat lifecycle

Fixture:

- create the real Vulcanus surface and researched force;
- build one eligible pneumatic machine through a supported event path;
- connect the machine to valid pneumatic input and a recipe fixture; and
- connect its hidden heat interface to an observable heat sink.

Actions and assertions:

1. Assert exactly one correctly sized hidden heat interface is created.
2. Run the machine and assert temperature increases within a declared range.
3. Stop the machine and assert scripted heat input stops.
4. Remove the machine and assert its hidden interface is destroyed.
5. Repeat build and removal to detect duplicate or stale ownership.

The missing-storage migration case is not part of this first scenario because a
scenario cannot mutate another mod's storage. It will use a staged old-save
fixture after the basic lifecycle test works.

## 10. Factorio version drift gate

The first version system detects silent changes; it does not download or promote
Factorio automatically.

`accepted-environment.json` records:

- Factorio version and build reported by `factorio --version`;
- Factorio binary SHA-256;
- runtime and prototype API JSON SHA-256;
- built-in and external mod names, versions, and artifact hashes; and
- startup settings and effective prototype-dump hashes.

Before ordinary tests, the runner compares the current environment with this
file. Any difference stops the run as `environment-drift` and writes a candidate
manifest.

Candidate mode then:

1. runs strict loading;
2. produces a recursive JSON path diff of the effective prototype dump;
3. runs the harness, gas-vent, and pneumatic-heat tests; and
4. writes a comparison report without changing the accepted manifest.

Updating `accepted-environment.json` is an explicit command allowed only after
candidate tests pass. The previous manifest remains in Git history.

## 11. Runner interface

The first command surface is:

```bash
python3 tools/run_factorio_tests.py list
python3 tools/run_factorio_tests.py run harness-self-test
python3 tools/run_factorio_tests.py run gasvent-lifecycle
python3 tools/run_factorio_tests.py run pneumatic-heat-lifecycle
python3 tools/run_factorio_tests.py run --all
python3 tools/run_factorio_tests.py environment check
python3 tools/run_factorio_tests.py environment candidate /path/to/factorio
python3 tools/run_factorio_tests.py environment accept RESULT/manifest.json
```

Paths may be overridden by command-line arguments. Defaults may point at the
current local installation, but resolved absolute paths and hashes always appear
in the result.

## 12. Implementation order

1. Add the isolated Python runner and `harness-self-test`.
2. Add required-result parsing and prove assertion and missing-result failures.
3. Add strict warning classification.
4. Implement `gasvent-lifecycle` and its removal-path variants.
5. Implement `pneumatic-heat-lifecycle`.
6. Add environment capture, drift refusal, and candidate comparison.

This slice is complete when:

- all three scenarios pass from a clean checkout;
- deliberate assertion, missing-result, gas-vent cleanup, and heat cleanup
  mutations fail for the expected reason;
- no test reads or writes the personal Factorio configuration;
- an altered Factorio binary or API schema is rejected as environment drift;
- candidate mode reports effective prototype changes without accepting them;
  and
- the repository is clean after the test run.

## 13. Local references

- `~/factorio-mod-wiki/files/runtime-api.json`
- `~/factorio-mod-wiki/files/prototype-api.json`
- `~/factorio-mod-wiki/files/auxiliary/data-lifecycle.html`
- installed `factorio --help`
