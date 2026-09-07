# Vulcanus gameplay evaluation

The local production flow reaches physics science without imported argon or
physics-consuming research. Air separation 2 now unlocks a Vulcanus residual-gas
recipe. The first distillery can execute the recipe with its three fluid outputs.
Ordinary Nauvis air separation remains restricted on Vulcanus.

Use the [generated factory report](VULCANUS_FACTORY_PLAN.md) for rates, research
time, fuel, heat, extraction, and machine counts. The
[planner configuration](../tests/progression/planner/vulcanus.json) declares all
comparison boundaries. The [iron and aluminum quenching assessment](VULCANUS_QUENCHING.md)
records the water recipe, complete supply comparison, and outage recovery test.

## Progression checks

| Boundary | Finding | Evidence |
|---|---|---|
| Basic science expansion | Volcanism 1 permits extractor construction. It uses only the four basic sciences. Include it before sizing an expanded HCl supply. | Basic-science construction flow |
| Chemical science | Early machines can sustain the configured rates, but HCl extraction, thermal cracking, and gas production need large machine groups. | Chemical-industry flow and largest-machine table |
| Pre-physics industry | Broader recipe access and second-tier machines reduce both machine count and fuel demand. Build this capacity before expanding all early routes to the same rate. | Pre-physics-industry flow |
| Local argon | A separate atmosphere recipe supplies residual gas at air separation 2. A delayed pipe connection feeds the ordinary argon recipe. | `vulcanus-residual-gas` |
| First physics | All seven science flows and their machine construction flows are feasible under the pre-physics boundary. | First-physics flow |
| Physics recipe execution | Selected recipes execute under research that consumes no physics packs. The physics assembler produces one batch; its measured boxed output supplies the unpacking machine and produces 125 packs. | `planner-physics-executors` |

See the [geology and climatology scale report](VULCANUS_SCIENCE_SCALE.md) for
pack totals, rate targets, starter and industrial capacity, and the upstream
climatology recipe comparison. The
[Nauvis comparison](PLANET_SCIENCE_COMPARISON.md) uses the same remaining
research boundary and reports electric demand for the Nauvis factory.

The [processed-input tier 2 experiment](SCIENCE_TIER2_MINERS.md) compares
hypothetical local science recipes with Nauvis using second-tier miners.
The [first-tier miner reference](SCIENCE_TIER2_EXPERIMENT.md) retains the
previous Nauvis extraction boundary. Neither experiment changes gameplay.

## Balance assessment

Use the second-tier comparison as the industrial capacity reference. The early
chemical configuration requires more machines and fuel than the first-physics
configuration. A player who expands only the earliest routes will build a much
larger factory. The main cost is the chemical supply network and its energy
system. The final physics assembly recipe is not the main machine-count cost.

The planner minimizes active machine time. It assigns a separate station count
to each selected recipe. Small equipment-production lines increase the rounded
station count. Shared machines with recipe changes need a separate batch schedule
and cannot be assumed to provide the same unattended rate.

The gas recipe uses 150 air and produces 120 CO2, 10 SO2, and 3 residual gas.
It collects residual gas instead of the nitrogen fraction. It produces no oxygen.
The yield is a conservative local route; the report sizes its complete input,
fuel, and co-product flows. This repair does not establish an optimal yield.
There is no boxed residual-gas item. Existing residual-gas barrel recipes remain
the container path. The physics executor selection includes ordinary and boxed
downstream equipment recipes.

## Time and infrastructure boundary

Research times assume that the stated science lines and labs operate from the
start. They include the selected recipe research and machine-construction
research, with shared prerequisites counted once. Do not add stage rows.
Research already completed by the force on another planet reduces this budget.
Checkpoint tokens and research triggers are separate script requirements.

The report does not give a measured wreck-to-physics completion time. The precise
missing witness is a fixed map with measured geyser yields, finite wreck and seed
stock, crafted expansion machines, connected material and heat networks, and
research checkpoints reached by production. Record the first tick at each unlock
and the first 125 physics packs. The focused tests supply declared machinery,
intermediates, or heat and therefore cannot provide that elapsed campaign time.

Extraction counts assume the configured geyser yield. They do not prove that the
map contains enough usable sites. Heat totals assume continuous source activity
and ideal delivery. Pipes, belts, inserters, storage, co-product removal, and heat
connections require a placed production-cell contract. These requirements must
be included before reporting a factory footprint or a player completion time.

## Reproduce

```bash
python tools/plan_factorio_factory.py --overview --summary-output docs/data/vulcanus-factory-plan.json --markdown-output docs/VULCANUS_FACTORY_PLAN.md
python tools/run_factorio_tests.py vulcanus-residual-gas planner-physics-executors planner-chemical-executors -n auto
python tools/check_factorio_locale.py
```

Use the [factory-planner skill](../.agents/skills/factorio-factory-planner/SKILL.md)
for queries and fixture regeneration. The historical
[batch-audit data](data/vulcanus-balance.json) describes the earlier recipe state;
it is not a current capacity or completion-time result.

## Validation

- Factorio 2.0.77: 78 scenarios validated. The two executor cases passed after
  finite perishable stock delivery was changed to one batch at a time. The two
  multiplayer cases also pass
  with desktop display variables removed, using managed Xvfb and software rendering.
- Python: all 84 tests passed.
- Locale audit: no missing prototype names, missing keys, or unused UI keys.
- Connected argon test: 690 assertions; completion at tick 6,330.
- Physics executor test: 2,713 assertions; completion at tick 33,780. This tick
  is the fixture completion time, not the campaign completion time.
