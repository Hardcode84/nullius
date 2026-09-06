# Configuration and queries

Use `tests/progression/planner/vulcanus.json` as the complete configuration
example. The schema version is `1`.

| Field | Meaning |
|---|---|
| `science_rates_per_minute` | Positive production rates to compare. |
| `fuel`, `lab` | Exact fluid fuel and lab prototype names. |
| `entrance_technologies` | Research already completed at the start. |
| `raw` | Explicit external material supplies. |
| `extractors` | Product to resource, machine, and resource yield fraction. |
| `prime_stock` | Finite starting material, separate from continuous supply. |
| `wreck_machines` | Placement items and counts already supplied. |
| `solid_discard` | Solid products that may leave the model as surplus. |
| `uncertain_outputs` | `exact` rejects uncertainty; `guaranteed` uses minimum outputs and excludes probabilistic returns. |
| `heat_controller` | Runtime source file whose heat constants the planner reads. |
| `stages` | Named production boundaries and targets. |
| `argon_comparison` | Recipe names and surface temperatures for the Vulcanus comparison. |
| `assumptions` | Interpretation supplied with the report. |

Each stage names a prerequisite `contract` argument file and a `products` map.
Each product amount multiplies the selected rate. A stage can supply
`technologies`, `research_roots`, `extra_machines`, and `raw` overrides.
`excluded_recipes` removes named recipes from both operating and construction
flows. Unknown names fail. Use this field to compare alternative production paths
under the same boundary. `construction_items` adds positive integer item counts
to the construction demand, for example the pipes and inserters of a test cell.
These counts are fixed; the production rate does not multiply them.
`executor_cycles` overrides the five-cycle executor test default by recipe name.
`executor_transfers` lists solid products that must come from measured outputs
of other fixture machines, with no direct input supply. The first-physics fixture
uses these fields to assemble and unpack one batch into 125 physics packs.

`allow_all_pre_physics` opens the full research set that does not consume physics
science. This is a capacity comparison boundary, not a chronological unlock
schedule. The report includes the research required by selected recipes.

The planner includes native machine productivity, speed, fluid fuel, extraction,
spoilage, and co-products. It does not apply modules, beacons, or technology
productivity bonuses. Temperature-constrained fluid ingredients are excluded
and listed in `excluded.unsupported_fluid_temperature`. Supported process energy
sources are fluid, heat, and void. Extend the model and its tests before making
claims that need other energy sources or excluded recipes.

## Inspect a saved plan

Use the script interface. Do not parse generated JSON with ad hoc commands.

```bash
python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json --overview

python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json \
  --stage pre-physics-industry --rate 60 --field factory.machines

python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json \
  --stage pre-physics-industry --rate 60 --recipe nullius-condensation

python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json \
  --stage first-physics --field blocked_inputs

python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json --field argon_comparison
```

`--field` accepts a dot-separated dictionary path. Select a stage before a rate.
Use `--product NAME` with a stage to filter its blocked-input diagnostics.
Use `--summary-output PATH` to save the compact report and
`--markdown-output PATH` to save its generated table. Keep numeric findings
in generated output; do not replace the solver with hand calculations.

## Validate selected executors

Export the first configured rate for the named stage. The fixture retains the
full declared technology closure, including entrance prerequisites:

```bash
python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-factory-plan.json \
  --stage pre-physics-industry \
  --executor-fixture tests/scenarios/planner-chemical-executors/fixture.lua \
  --overview
```

Run the scenario:

```bash
python tools/run_factorio_tests.py planner-chemical-executors -n auto
```
 The fixture
supplies declared recipe inputs, finite fuel, and controlled heat to separate
machines. Perishable fixture stock is delivered one recipe batch at a time. Its total
quantity remains finite. The fixture does not reset spoilage on inserted items.
It checks five base cycles and the guaranteed native-productivity
outputs. It does not connect the full material or heat network. Use a connected
campaign scenario to measure factory throughput and elapsed progression time.

## Compare production paths

```bash
python tools/plan_factorio_factory.py \
  --config tests/progression/planner/vulcanus-quenching.json \
  --output /tmp/vulcanus-quenching.json \
  --comparison-output docs/VULCANUS_QUENCHING_PLAN.md --overview
```

The optional `comparison` object names a `title` and a `materials` list. Each
stage must have one target product, or `comparison.product` must select a target. `--comparison-output` reports the target rate, process machines,
active machine equivalents, gross material input, fuel, heat, and construction
status. Use this report for non-science products. Gross input includes material
circulation; it is not net extraction. The solver minimizes active machine time,
so a selected route can have more rounded stations than another route.

## Size research supply by science type

```bash
python tools/plan_factorio_factory.py \
  --config tests/progression/planner/vulcanus-science-scale.json \
  --output /tmp/vulcanus-science-scale.json \
  --science-output docs/VULCANUS_SCIENCE_SCALE.md --overview
python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-science-scale.json --field science_analysis.budgets
python tools/plan_factorio_factory.py \
  --read-plan /tmp/vulcanus-science-scale.json --field science_analysis.production_lines
```

`science_analysis` declares `research_roots` by boundary name, `factory_stages`,
`packs`, comparison `rates`, and supply-window `hours`. The query separates direct
research closure from the research needed by selected production and construction
recipes. It reports totals, supply times, required rates, and the ten largest
technology costs per pack. Production rows include boxed producers and unpackers.
The Markdown report uses rates 60 and 120 and supply windows 4 and 8 hours; include
these comparison points in the configuration when using `--science-output`.
Standalone pack factories omit labs when they cannot supply the required research.
Do not add their station counts to estimate a factory that shares co-products.

## Nauvis and Vulcanus comparison

Use `tests/progression/planner/nauvis-science-scale.json` for the Nauvis
boundary. Set `electric_grid: true` to declare externally supplied electricity.
The planner reports active electric demand and drain for rounded installed
stations. It does not count generation, storage, or distribution. This is a
continuous average load model; it does not resolve synchronized machine peaks.
Electric labs and ore miners use resolved energy and speed values. Mining that
requires fluid fails until a fluid-input contract is implemented. A stage can
set `machines` to replace the contract executor catalog.

Both planet configurations subtract the same pneumatic technology prerequisite
closure. The comparison therefore measures the same remaining research. It does
not measure Nauvis progression from a new game.

```bash
python tools/plan_factorio_factory.py \
  --config tests/progression/planner/nauvis-science-scale.json \
  --output /tmp/nauvis-science-scale.json --overview
python tools/plan_factorio_factory.py \
  --config tests/progression/planner/vulcanus-science-scale.json \
  --output /tmp/vulcanus-science-scale.json --overview
python tools/compare_factorio_factory_plans.py \
  --config tests/progression/planner/planet-science-comparison.json \
  --first-plan /tmp/nauvis-science-scale.json \
  --second-plan /tmp/vulcanus-science-scale.json \
  --output /tmp/planet-science-comparison.json \
  --markdown-output docs/PLANET_SCIENCE_COMPARISON.md
python tools/plan_factorio_factory.py \
  --read-plan /tmp/nauvis-science-scale.json --stage first-physics \
  --executor-fixture tests/scenarios/planner-nauvis-physics-executors/fixture.lua \
  --field name
python tools/run_factorio_tests.py planner-nauvis-physics-executors -n auto
```

The Nauvis executor fixture supplies a declared electric generator interface.
The base game's tertiary electric interface cannot supply surge machines.
This test checks recipe execution, not connected factory throughput or electric
peak demand.
