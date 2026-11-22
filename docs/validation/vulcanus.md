# Vulcanus validation

### Tier 2 capacity

<!-- tier2-capacity:start -->

| Line | Packs/min each | Nauvis stations | Vulcanus stations | Nauvis electric MW | Vulcanus fuel gas/min | Vulcanus heat MW |
|---|---:|---:|---:|---:|---:|---:|
| geology | 120 | 67 | 54 | 9.99 | 15,903 | 2.90 |
| geology | 240 | 102 | 71 | 19.70 | 31,806 | 5.79 |
| climatology | 120 | 41 | 35 | 12.22 | 27,592 | 0.88 |
| climatology | 240 | 80 | 55 | 24.37 | 55,185 | 1.76 |
| combined | 120 | 82 | 78 | 21.49 | 39,684 | 3.93 |
| combined | 240 | 150 | 111 | 42.72 | 79,368 | 7.85 |
<!-- tier2-capacity:end -->

The comparison permits all pre-physics supply recipes and the declared machine
catalog. It measures industrial capacity, not the equipment available at the
instant the Vulcanus tier 2 recipes unlock. Nauvis uses second-tier solid miners
and first-tier gas extractors. Both planets use ordinary and boxed tier 2 science
routes. Each science is supplied at the stated rate in a combined row.

Nauvis receives external electricity. Its generator, accumulator and electric
distribution counts are excluded. Vulcanus includes fuel-gas production. Process
heat demand is internal heat delivery, not a separate fuel addition. Both exclude
belts, pipes, inserters, storage, and a placed layout. Counts include extraction
and separate rounded stations for each recipe. No modules, beacons or research
productivity bonuses are applied; native machine effects are included.

The solver minimizes active machine time, not integer station count. It can
select a shared route with more rounded stations than separate factories.
Nauvis can use 88 stations as independent lines at 120/min, versus 93 in the
combined active-time solution. Vulcanus can share support production in 86
stations at that rate. These are feasible configurations, not integer minima.

Glass can use a simple silica route or a more efficient bulk route that also
needs alumina, lime, soda ash and sodium sulfate. That bulk route adds several
low-duty stations to Vulcanus geology. Climatology avoids large wastewater
production: its independent local chain at 120/min consumes 400 water/min and
2,400 nitrogen/min, compared with 12,000 wastewater/min and 24,000 nitrogen/min
for Nauvis climatology 2. These are gross recipe inputs, including circulation.

### Physics capacity and research time

<!-- physics-capacity:start -->

| Packs/min each | Stations | Labs | Fuel gas/min | Process heat MW | Supply hours | Scheduled hours |
|---:|---:|---:|---:|---:|---:|---:|
| 60 | 954 | 40 | 540,685 | 111.70 | 16.571 | 16.623 |
| 120 | 1631 | 80 | 1,081,370 | 223.41 | 8.285 | 8.311 |
| 240 | 2996 | 160 | 2,162,739 | 446.81 | 4.143 | 4.156 |

Research for the 120/min factory, including selected recipe and construction unlocks:

| Science | Required packs |
|---|---:|
| nullius-chemical-pack | 48,272 |
| nullius-climatology-pack | 58,444 |
| nullius-electrical-pack | 52,348 |
| nullius-geology-pack | 59,654 |
| nullius-mechanical-pack | 56,842 |
| nullius-metallurgic-pack | 1,410 |

Largest geology and climatology research costs:

| Science | Technology | Packs |
|---|---|---:|
| nullius-geology-pack | nullius-land-fill-4 | 3,200 |
| nullius-geology-pack | nullius-geothermal-power-2 | 1,800 |
| nullius-geology-pack | nullius-mining-productivity-14 | 1,200 |
| nullius-climatology-pack | nullius-solar-thermal-power-2 | 1,500 |
| nullius-climatology-pack | nullius-physics | 1,200 |
| nullius-climatology-pack | nullius-empiricism-4 | 1,100 |
<!-- physics-capacity:end -->

The first-physics plan supplies seven science types, including physics and local
metallurgic science. It includes reserved labs. Research starts after the
pneumatic technology prerequisite closure. Shared research on another planet
reduces the remaining budget. Supply bounds assume all configured lines and labs
are available at time zero. Checkpoints and research triggers are assumed complete
when reached. These times do not measure wreck-to-physics player completion.

The missing elapsed-time witness requires a fixed map, measured geyser yields,
finite wreck and seed stocks, crafted expansion machines, connected material and
heat networks, and checkpoints reached through production. Record each unlock
and the first 125 physics packs. Executor completion ticks are not campaign times.

Heat assumes continuous duty and ideal delivery. Extraction assumes the declared
geyser yield and does not prove site availability on a particular map. Startup
reachability is separate from proof that the finite seed stock can commission the
whole factory. Construction flow is a fractional batch bound, not a build schedule.

## Unresolved design decisions

| Decision | Required evidence |
|---|---|
| Deep-deposit density and yield | Post-cargo titanium demand and travel cost |
| Demolisher feeding model | Prototype experiment and automation behavior |
| Sulfur balance | Sustained local science and disposal measurements |
| Heat-pressure mechanic beyond productive heat use | Production witness showing the current heat economy lacks pressure |

## Progression witnesses

| Milestone | Entrance boundary | Completion boundary | Runtime witnesses | Reachability witnesses |
|---|---|---|---|---|
| Activation | Vulcanus probe research completes | Vulcanus surface, shared idle character, and one wreck per force are available | `vulcanus-activation`, `vulcanus-shared-body`, `vulcanus-probe-alignment` | — |
| Pneumatic bootstrap | Wreck inventory is available | Free gas is extracted and usable | `vulcanus-vent-prime`, `vulcanus-gas-vent-smoke` | — |
| Self-powered gas | Primed pneumatic equipment is available | Dedicated gas production sustains its own machinery | `vulcanus-gas-self-power` | — |
| Lava materials | Self-powered gas production is available | Local iron, aluminum, calcite, silica, stone, and sulfur-bearing gas paths operate | `vulcanus-lava-separation-*`, `vulcanus-bloom-cooldown-*` | — |
| Heat chemistry | Lava materials and wreck machinery are available | Aluminum reduction, sulfur catalysis, pneumatic heat, and thermal HCl cracking operate | `vulcanus-aluminum-reduction`, `vulcanus-sulfur-catalysis`, `vulcanus-pneumatic-heat-production*`, `vulcanus-hcl-thermal-cracking*` | — |
| Bootstrap metallurgy | Local metals and chemistry are available | Bootstrap metallurgic science can be crafted | `vulcanus-metallurgic-pack-recipe`, `vulcanus-metallurgic-pack-10*` | `vulcanus-pack.args` |
| Construction closure | Bootstrap production is available | Core pneumatic factory and inorganic fluid handling can be reproduced locally | `vulcanus-construction-closure*`, `vulcanus-inorganic-barrel`, `pneumatic-assemblers`, `pneumatic-barrel-pumps`, `pneumatic-boxer`, `vulcanus-pneumatic-compressor`, `pneumatic-miners-chimney` | `vulcanus-construction.args`, `vulcanus-barrel.args`, `pneumatic-boxer.args` |
| Renewable graphite | Construction closure is available | Atmosphere and HCl chemistry replace rock-mined graphite | `vulcanus-hcl-thermal-cracking*` | `vulcanus-renewable-graphite.args` |
| Basic science | Renewable graphite and construction closure are available | Local geology, climatology, mechanical, and electrical science operate | `vulcanus-basic-science-10*` | `vulcanus-basic-science.args` |
| Chemical science and thermite | Basic science is available | Local alkali, acids, glass, lubricant, barrels, chemical science, and thermite operate | `vulcanus-caustic-bootstrap`, `vulcanus-chemical-*`, `vulcanus-thermite` | `vulcanus-caustic-bootstrap.args`, `vulcanus-chemical-*.args`, `vulcanus-thermite.args` |
| Efficient metallurgy | Bootstrap metallurgic and generic science are available | Efficient metallurgic research and production operate | `vulcanus-efficient-metallurgic-research`, `vulcanus-efficient-metallurgic-science` | `vulcanus-efficient-pack.args` |
| Primitive logistics | Efficient metallurgy is available | Clockwork logistics equipment operates | `primitive-robotics` | `vulcanus-primitive-robotics.args` |
| Hot casting | Efficient metallurgy and metalworking are available | Hot blooms are cast directly into useful products | `vulcanus-hot-casting` | `vulcanus-hot-casting.args` |
| Water quenching | Hot metalworking and experimental chemistry are available | Water increases iron and aluminum plate and rod yields. Pneumatic inserters remove cooled blooms and restart the line after a water outage. | `vulcanus-water-quenching`, `vulcanus-water-quenching-iron-rod`, `vulcanus-water-quenching-aluminum-*` | `vulcanus-water-quenching.args` |
| Tier-1 thermal industry | Base industrial machines and solar heat are available | Thermal crushing, smelting, casting, and heat storage operate | `thermal-machines-1`, `thermal-cell-1`, `variant-upgrades` | `nauvis-thermal-furnace-sizes.args` |
| Industrial optimization | Efficient metallurgy and tier-1 process technology are available | Repeatable process productivity research affects eligible recipes | `industrial-optimization-1`, `industrial-productivity-technologies`, `recipe-productivity-family` | — |
| Refractory and titanium industry | Hot casting, local chemistry, and thermal storage are available | Refractory materials and pilot titanium equipment are produced locally | `vulcanus-boric-acid`, `carbothermic-sodium`, `vulcanus-refractory-production`, `vulcanus-titanium-pilot`, `vulcanus-titanium-construction` | `vulcanus-boric-acid.args`, `carbothermic-sodium.args`, `vulcanus-refractory-production.args`, `vulcanus-titanium-pilot.args`, `vulcanus-titanium-construction.args` |
| Tier-2 thermal industry | Refractory and tier-2 base machines are available | Tier-2 thermal machines and heat storage operate | `thermal-engineering-technologies`, `thermal-machines-higher-tiers`, `thermal-cell-2` | `nauvis-thermal-furnace-sizes.args` |
| Tier-3 thermal industry | Tier-2 thermal industry and nuclear heat are available | Tier-3 thermal machines and heat storage operate | `thermal-engineering-technologies`, `thermal-machines-higher-tiers`, `thermal-cell-3` | — |
| Local launch fuel | Rocket Science 1, Pneumatic Technology, and local aluminum, CO2, and ANFO are available | Aluminum-CO2 rocket fuel is produced locally and the silo, stage, and rocket close on Vulcanus without electricity | `vulcanus-co2-fuel`, `vulcanus-silo-request` | `vulcanus-launch-closure.args`, `vulcanus-co2-fuel-closure.args`, `vulcanus-co2-fuel-bulk.args` |
| Thermal nanofabrication and physics science | High-temperature industry and physics intermediates are available | Thermal nanofabricators operate. Local residual gas and pre-physics executor tests cover the first physics batch; see the physics capacity section | `thermal-nanofabricators`, `vulcanus-residual-gas`, `planner-physics-executors` | `vulcanus-physics-production.args`, `tests/test_vulcanus_physics_contract.py` |

## Cross-cutting contracts

| Contract | Runtime witnesses |
|---|---|
| Surface restrictions | `recipe-surface-conditions`, `renewable-placement`, `water-well-placement`, `vulcanus-polymer-restrictions` |
| Polymer-free substitutes | `vulcanus-high-temperature-resin`, `vulcanus-polymer-free-recipes`, `vulcanus-boxed-polymer-free` |
| Checkpoint aggregation across surfaces | `checkpoint-multisurface` |
| Vulcanus mining productivity | `vulcanus-mining-productivity` |
| Temperature sensing | `temperature-sensor` |
| Pneumatic heat ownership and geometry | `vulcanus-pneumatic-heat` |

## Reproduce the balance checks

The factory-planner skill contains query and fixture-export commands. Keep full
JSON and generated detail tables as build outputs; this document contains the Vulcanus measurements. The historical `docs/data/vulcanus-balance.json` is an earlier
batch audit, not current capacity or elapsed-time evidence.

```bash
python tools/analyze_factorio_prereqs.py @tests/progression/planner/science-tier2-inspection.args
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-science-tier2.json --output /tmp/vulcanus-tier2.json --overview
python tools/plan_factorio_factory.py --config tests/progression/planner/nauvis-science-tier2-miners.json --output /tmp/nauvis-tier2.json --overview
python tools/compare_factorio_factory_plans.py --config tests/progression/planner/science-tier2-miners-comparison.json --first-plan /tmp/nauvis-tier2.json --second-plan /tmp/vulcanus-tier2.json --output /tmp/science-comparison.json --update-vulcanus-doc docs/validation/vulcanus.md
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-science-scale.json --output /tmp/vulcanus-science.json --update-vulcanus-doc docs/validation/vulcanus.md --overview
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-quenching.json --output /tmp/vulcanus-quenching.json --comparison-output /tmp/vulcanus-quenching.md --overview
python tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-water-quenching.args
python tools/run_factorio_tests.py vulcanus-science-tier2 planner-physics-executors planner-chemical-executors vulcanus-probe-alignment -n auto
python tools/check_factorio_locale.py
```

## Water quenching

Four separate runtime scenarios supply water through connected pipes. At tick
2,700, each water outage has let four blooms cool. A pneumatic output inserter
moves all four cooled items to a chest: iron ingots for iron blooms, or alumina
for aluminum blooms. New blooms enter through a second inserter after water
returns. The foundry then makes four plates or seven rods. No script removes or
replaces inventory. Each line needs an output path for its product and cooled items.

The prerequisite manifest checks all eight ordinary and boxed routes with declared
bloom and water supplies. The planner separately checks the complete supply
network and the construction flow for one foundry, one water pipe, one heat pipe,
two inserters, and two chests. The runtime fixture supplies its heat interface
and initial fuel. These checks do not measure a complete connected factory.

## ANFO production

Both prerequisite manifests pass with local inputs and no electricity, including
machine construction and fuel. Contracts: `tests/progression/vulcanus-anfo-*.args`.
Iron oxide adds wire, water, oxygen and flotation costs.
Runtime: `vulcanus-anfo` checks both unlocks and one pipe-fed craft per recipe.

## Rocket fuel contracts

| Check | Contract |
|---|---|
| Local rocket and silo | `tests/progression/vulcanus-launch-closure.args` |
| Ordinary and boxed fuel, chemical plant, pipes, and tank at unlock | `tests/progression/vulcanus-co2-fuel-closure.args`, `tests/progression/vulcanus-co2-fuel-bulk.args` |
| Planet costs, Vulcanus research ownership, and both Vulcanus stage costs | `tools/check_launch_vehicle.py` |
| Aluminum recovery without productivity | `tests/scenarios/rocket-fuel-aluminum/` |
| Finite fuel batches through pneumatic chemical plants and pipes | `tests/scenarios/vulcanus-co2-fuel/` |

## Silo validation

Validation: `experiment-pneumatic-silo`, `pneumatic-silo-transition`, and
`vulcanus-silo-request`. The `vulcanus-launch-closure.args` contract selects the
pneumatic silo and rejects electricity-required paths.

## Local science validation

The dedicated `vulcanus-science-tier2` scenario checks locked recipes, research
unlocks, exact ordinary and boxed inputs, craft times, and real craft outputs.
The declared recipe inputs and finite fuel are test supplies, not a connected
factory. Planner executor scenarios check the selected upstream recipe set.
