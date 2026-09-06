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

Export the first configured rate for the named stage:

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
machines. It checks five base cycles and the guaranteed native-productivity
outputs. It does not connect the full material or heat network. Use a connected
campaign scenario to measure factory throughput and elapsed progression time.
