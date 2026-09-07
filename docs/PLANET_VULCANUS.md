# Vulcanus design

## Authorities

| Fact | Authority |
|---|---|
| Theme, mechanics, progression intent, and constraints | This document |
| Progression order and validation witnesses | This document |
| Recipe, technology, item, fluid, and entity values | Factorio resolved prototypes |
| Starting inventory | Probe activation code and `vulcanus-activation` scenario |
| Runtime behavior | Mod control scripts and scenarios |
| Reachability | Checked-in prerequisite contracts |

## Role

```yaml
planet_role: heavy industry
primary_resource: lava
ambient: extreme heat
early_power: compressed volcanic gas and process heat
natural_water: none
early_organics: none
local_progression: independent through physics science
pre_cargo_global_reward:
  - thermal heavy industry
  - process-specific productivity research
post_cargo_exports:
  - titanium
  - bulk metals
  - calcium products
```

## Environmental constraints

| Constraint | Consequence |
|---|---|
| Carbon-dioxide atmosphere | Atmospheric separation supplies carbon dioxide, trace nitrogen, and sulfur compounds |
| No surface water | Water must be synthesized; water wells and water-only placement entities are forbidden |
| No early commodity organics | Ordinary plastic, rubber, BPA, and ordinary epoxy production are temperature-restricted |
| No biology | Local production is inorganic |
| Abundant lava | Iron, aluminum, calcium, silica, stone, and fuel gas derive from lava processing |
| High ambient temperature | Recipe availability is expressed through ambient-temperature surface conditions |
| No electric bootstrap | Initial production uses pneumatic machines and thermal machinery |

## Surface generation

| Surface | Terrain and autoplace contract |
|---|---|
| Nauvis | Existing Nullius terrain; removed vanilla resources remain absent |
| Nullius Vulcanus | Explicit volcanic tile, decorative, and entity whitelists; unspecified autoplace and natural enemies disabled |
| Hidden Space Age planets | Hidden, non-walkable empty-space terrain, no decoratives, no autoplace entities, and no natural enemies |

Executable contract: `tests/scenarios/surface-mapgen-contract/`.

## Resource model

### Lava

| Separation | Primary product | Coproducts | Role |
|---|---|---|---|
| Iron | Molten iron bloom | Compressed volcanic gas, stone | Iron industry |
| Aluminum | Molten aluminum bloom | Compressed volcanic gas, stone | Aluminum industry |
| Calcite | Crushed limestone | Compressed volcanic gas | Calcium chemistry |
| Silica | Silica | Compressed volcanic gas, stone, sulfur dioxide | Glass, silicon, ceramics, sulfur chemistry |
| Gas extraction | Compressed volcanic gas | Stone | Net-positive pneumatic fuel source |

Mining-productivity research affects the primary mineral or metal product of
the separation recipes. It does not multiply fuel-gas or waste coproducts and
does not affect dedicated gas extraction.

### Bloom cooling and hot casting

```text
lava -> molten iron bloom -> passive cooling -> iron ingot
                         \-> hot casting -> iron plate or rod

lava -> molten aluminum bloom -> passive oxidation -> alumina -> reduction -> aluminum ingot
                             \-> hot casting -> aluminum sheet or rod
```

- Bloom conversion uses spoilage as a cooling deadline.
- Passive cooling remains the failure-safe route.
- Hot casting avoids the cooling delay and, for aluminum, avoids oxidation and
  subsequent reduction.
- Water quenching uses locally synthesized water after hot metalworking and
  experimental chemistry. It is available before cargo.

### Water quenching

Each ordinary recipe consumes four hot blooms and two water. Each bulk recipe
consumes twenty hot blooms and ten water. Each box contains five products.

| Product | Dry yield | Quenched yield | Ordinary time | Bulk output | Bulk time |
|---|---:|---:|---:|---:|---:|
| Iron plate | 3 | 4 | 3 s | 4 boxes | 15 s |
| Iron rod | 5 | 7 | 4 s | 7 boxes | 20 s |
| Aluminum plate | 3 | 4 | 4 s | 4 boxes | 20 s |
| Aluminum rod | 5 | 7 | 4 s | 7 boxes | 20 s |

All recipes use the foundry. Quenching keeps each dry recipe's bloom consumption
rate and productivity eligibility. Water is consumed. There is no steam output
or recovery loop. Water quenching unlocks all four ordinary recipes after hot
metalworking and experimental chemistry. Its ten units each cost ten metallurgic,
one mechanical, and one chemical pack, with a unit time of 30 seconds.
Mass production 4 unlocks all four bulk recipes.

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

### Volcanic rocks and rutile

| Source | Role |
|---|---|
| Scattered volcanic rocks | Early graphite and rutile; renewable through exploration |
| Sand and acid synthesis | Stationary but deliberately punitive rutile fallback with large waste streams |
| Demolisher-exposed deposits | Candidate post-cargo bulk rutile source |

Nauvis uses the same punitive synthetic-rutile route before physical shipments
from Vulcanus. The route preserves progression but is not intended to scale.

### Hydrogen chloride

```text
geyser -> hydrogen chloride
  -> thermal cracking -> hydrogen + chlorine
  -> Deacon process with oxygen -> chlorine + water
```

- High-temperature cracking initially requires direct contact with a working
  heat-producing machine.
- Higher-tier heat distribution later permits remote radiator layouts.
- Hydrogen feeds carbon reduction, graphite, and water synthesis.
- Chlorine feeds titanium and chloride chemistry.
- Renewable direct iron chlorination closes excess chlorine without consuming
  hydrogen or graphite.
- Iron chloride also catalyzes an alternative sludge-dehydration route.

### Atmosphere

```text
atmosphere -> carbon dioxide + nitrogen + sulfur dioxide
carbon dioxide + hydrogen -> carbon monoxide + water
carbon monoxide + hydrogen -> graphite + water
sulfur dioxide --rutile catalyst-> oxygen + sulfur
hydrogen + oxygen -> water
```

Hydrogen allocation is the limiting choice between graphite, carbon monoxide,
and water. Bulk water remains an import incentive.

Compressed volcanic gas can also be decompressed in a pneumatic barrel pump
and separated into boric acid, sulfur dioxide, ordinary air, and carbon
monoxide. This preserves the existing volcanic-gas chemistry without requiring
an electric compressor or electrolyzer.

### Sodium

```text
gravel + hydrogen chloride + synthesized water -> saline
saline -> brine
brine + carbon dioxide + ammonia -> soda ash
soda ash + lime + water -> sodium hydroxide
soda ash + graphite + refractory material + heat -> metallic sodium
```

- The sodium-hydroxide bootstrap is pneumatic and thermal, not electrolytic.
- The carbothermic metallic-sodium route is global, deliberately inefficient,
  and productivity-ineligible.
- Efficient electrolysis remains valuable after electricity is available.

### Refractory production and titanium

```text
alumina + silica + mineral dust -> refractory mix -> refractory brick
rutile + graphite + chlorine -> titanium tetrachloride
titanium tetrachloride + aluminum -> titanium ingot + aluminum chloride
aluminum chloride + water -> alumina + mineral dust + hydrogen chloride
```

- Refractory material closes higher-temperature equipment construction.
- The pre-cargo titanium route uses aluminum reduction and avoids argon,
  metallic sodium, and electricity.
- Local titanium supports pilot higher-tier construction; rutile supply limits
  bulk production.

## Polymer policy

```yaml
ordinary_polymer_production:
  plastic: cool_surfaces_only
  rubber: cool_surfaces_only
  bpa: cool_surfaces_only
  ordinary_epoxy: cool_surfaces_only
imported_polymer_handling:
  packaging: allowed
  unpackaging: allowed
  consumption: allowed
  disposal: allowed
vulcanus_substitution:
  rubber_role: silicon insulation
  plastic_structural_role: ceramics, glass, metal, or refractory material
  plastic_electrical_role: silicon insulation or ceramic substrate
boxed_parity: required for every boxed production family
```

Polymer-free alternatives cover the construction and intermediate families
required by local progression, including barrels, wires, circuits, capacitors,
motors, filters, pumps, belts, logistics, vehicles, electrical components, and
their boxed production families. Resolved prerequisite contracts define the
current closure; this document does not duplicate their ingredient lists.

Rocket fuel remains a post-cargo polymer consumer rather than a local
pre-cargo requirement.

Thermite cliff explosives replace the ordinary organic explosive route. They
tie aluminum powder to barreled chlorine and sulfur chemistry; unstable
explosive spoilage is not part of this design.

### High-temperature resin

```yaml
product: nullius-epoxy
identity: heat-resistant uncured thermoset resin
route: aromatic and nitrile chemistry with alumina catalyst
ordinary_bpa_epichlorohydrin_route: cool_surfaces_only
downstream_epoxy_consumers: unchanged
new_single_use_substances: none
```

The alternative keeps the existing epoxy product and downstream recipes while
replacing the ambient-incompatible BPA branch.

## Industry and energy

### Free-gas bootstrap

```text
free lava intake + diminishing-return gas vent
  -> prime pneumatic hydro plant
  -> dedicated lava-gas extraction
  -> self-powered gas loop
  -> material separation and factory expansion
```

- The vent is a bootstrap source, not a scalable power system.
- Vent output scales sublinearly with the number of vents on a surface.
- Dedicated gas extraction scales linearly and funds the factory.
- Material-separation recipes return gas coproducts but remain net consumers
  after machine fuel.

### Machine modes

| Family | Alternate mode | Surface |
|---|---|---|
| Assemblers, boxers, barrel pumps, filters, hydro plants, distilleries, chemical plants, compressors, flotation cells, labs, extractors, pumps, and inserters | Pneumatic | Vulcanus |
| Crushers, every furnace size, and foundries | Thermal with innate productivity | Any surface |
| Nanofabricators | Higher-consumption thermal | Vulcanus |
| Electrolyzers and electrical infrastructure | Electric only | Any surface where placeable |

- Inventory items are mode-neutral.
- Contextual rotation switches compatible placed variants.
- A transition requires the corresponding base-machine recipe to be enabled.
- Upgrade targets preserve alternate mode and advance to the logical tier.
- Pneumatic pumps and boxers do not create heat interfaces.
- Solar panels, wind turbines, and water wells retain craftable items but cannot
  be placed on Vulcanus.

### Heat

```yaml
sources:
  - working pneumatic machines
  - solar collectors
  - nuclear reactors
distribution: heat pipes and thermal storage
consumers:
  - thermal heavy industry
  - thermal nanofabricators
  - radiators
sensor: circuit-readable temperature sensor
```

Working pneumatic machines own hidden heat interfaces. Updates are amortized;
heat generation follows actual energy use. Ownership cleanup must cover every
build, replacement, mining, and destruction path.

Radiators are heat-powered chemistry machines. Lower-temperature radiators
handle water and sulfur chemistry; higher-temperature radiators handle HCl and
metal-chloride chemistry.

Gas and heat form separate pipe networks. Short underground gas ducts permit
crossings while keeping routing density as a deliberate factory-layout cost.

Thermal crushers, furnaces, and foundries are global alternatives to their
electric equivalents. The first tier unlocks with pneumatic technology; later
tiers depend on corresponding Nauvis machinery and metallurgic thermal
research. Thermal research is optional and never gates the ordinary Nauvis
progression path.

### Industrial optimization

| Branch | Effect |
|---|---|
| Crushing | Productivity for eligible crushing recipes |
| Smelting | Productivity for eligible smelting recipes |
| Casting | Productivity for eligible casting recipes |

- Branches are independent and repeatable.
- Research cost grows superlinearly.
- The metallurgic pack remains a permanent marginal sink.
- Recipe eligibility, not machine mode, determines the effect.
- Recipes that forbid productivity are excluded.

## Primitive logistics

```yaml
system:
  roboport: unpowered, zero construction area, zero recharge
  robot: cheap clockwork logistic robot
  lifetime: initial battery only
  expiry: robot and carried cargo are destroyed
  port_overlap: allowed but increases range risk
  runtime_lifecycle_script: none
chests:
  supply: very_small_passive_provider
  demand: very_small_requester
  storage: small_mixed_overflow
normal_logistic_robots: forbidden_on_vulcanus
```

The system handles low-throughput mixed intermediates. Connected networks are
possible but dangerous because robots may receive routes beyond their battery
range.

## Science and research

| Boundary | Design contract |
|---|---|
| Bootstrap metallurgic science | Slow, resource-heavy recipe from processed local materials |
| Efficient metallurgic science | Hot blooms, crucibles, and barreled chlorine/sulfur chemistry |
| Basic science | Local alternatives only where unavailable raw inputs require them |
| Chemical science | Closed through volcanic sodium, sulfur chemistry, lubricant, concrete, and inorganic barrels |
| Physics science | Local residual-gas separation removes the argon research cycle. Pre-physics executor tests produce 125 physics packs; see the capacity section below. |

| Research family | Role |
|---|---|
| Pneumatic technology | Vulcanus machinery, radiators, sensing, chloride chemistry, and first-tier thermal industry |
| Efficient metallurgy | Improved metallurgic science and fluid barreling |
| Primitive robotics | Low-throughput clockwork logistics |
| Hot metalworking | Direct bloom casting |
| Refractory engineering | Higher-temperature materials and equipment |
| Volcanic titanium metallurgy | Pilot local titanium and higher-tier construction |
| Thermal engineering | Optional global thermal heavy-industry tiers |
| Industrial optimization | Infinite process-specific productivity sink |

Research on Vulcanus must not immediately block the ordinary Nauvis tree.
Vulcanus provides optional production improvements while Nauvis progression can
continue in parallel.

### Local science upgrades

Tier 2 recipes require additional processing of local materials. The ordinary
recipes unlock with `nullius-geology-2` and `nullius-climatology-2`. The boxed
recipes unlock with `nullius-mass-production-7`, as do the ordinary bulk science
recipes. All four local recipes require ambient temperature of at least 100.
They allow productivity and preserve the existing science-pack items.

| Recipe | Inputs per craft | Output | Time |
|---|---|---:|---:|
| Local geology 2 | 1 glass, 1 lime, 2 mineral dust | 2 packs | 10 s |
| Boxed local geology 2 | 1 box glass, 1 box lime, 2 boxes mineral dust | 2 boxes | 50 s |
| Local climatology 2 | 100 compressed CO2, 10 compressed nitrogen, 5 sulfuric acid | 2 packs | 10 s |
| Boxed local climatology 2 | 500 compressed CO2, 50 compressed nitrogen, 25 sulfuric acid | 2 boxes | 50 s |

Each box contains five items. Glass and lime add thermal processing. Gas
compression and sulfuric acid add processing to atmospheric science. Slow local
recipes remain available for bootstrap. Ordinary Nauvis geology 2 remains usable
through sludge recovery; ordinary climatology 2 can consume surplus wastewater.

The dedicated `vulcanus-science-tier2` scenario checks locked recipes, research
unlocks, exact ordinary and boxed inputs, craft times, and real craft outputs.
The declared recipe inputs and finite fuel are test supplies, not a connected
factory. Planner executor scenarios check the selected upstream recipe set.

### Tier 2 capacity

<!-- tier2-capacity:start -->

| Line | Packs/min each | Nauvis stations | Vulcanus stations | Nauvis electric MW | Vulcanus fuel gas/min | Vulcanus heat MW |
|---|---:|---:|---:|---:|---:|---:|
| geology | 120 | 47 | 64 | 8.96 | 15,628 | 3.06 |
| geology | 240 | 85 | 81 | 17.88 | 31,256 | 6.12 |
| climatology | 120 | 41 | 35 | 12.22 | 27,592 | 0.88 |
| climatology | 240 | 80 | 55 | 24.37 | 55,185 | 1.76 |
| combined | 120 | 93 | 86 | 20.81 | 41,988 | 3.91 |
| combined | 240 | 168 | 122 | 41.48 | 83,975 | 7.83 |
<!-- tier2-capacity:end -->

The comparison permits all pre-physics supply recipes and the declared machine
catalog. It measures industrial capacity, not the equipment available at the
instant geology 2 or climatology 2 unlocks. Nauvis uses second-tier solid miners
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
| 60 | 975 | 40 | 564,151 | 115.00 | 16.490 | 16.542 |
| 120 | 1682 | 80 | 1,128,302 | 230.00 | 8.245 | 8.271 |
| 240 | 3096 | 160 | 2,256,604 | 459.99 | 4.122 | 4.136 |

Research for the 120/min factory, including selected recipe and construction unlocks:

| Science | Required packs |
|---|---:|
| nullius-chemical-pack | 48,252 |
| nullius-climatology-pack | 58,154 |
| nullius-electrical-pack | 51,498 |
| nullius-geology-pack | 59,364 |
| nullius-mechanical-pack | 57,112 |
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

The argon route uses 150 air to produce 120 CO2, 10 SO2 and 3 residual gas. Air
separation 2 unlocks it on Vulcanus. It replaces nitrogen collection and produces
no oxygen. Existing barrel recipes handle residual gas; there is no boxed fluid.
This local route removes the physics research cycle without imports. The
`vulcanus-residual-gas` scenario checks delayed fluid connection and production.

## Bootstrap sequence

| Boundary | Player outcome |
|---|---|
| Activation | Recover wreck equipment and unlock the Vulcanus surface |
| Prime | Place lava intake and gas vent |
| Self-power | Run dedicated lava-gas extraction from the vent prime |
| Materials | Separate lava and cool or cast blooms |
| Construction | Reproduce pneumatic and thermal production equipment locally |
| Chemistry | Extract HCl, separate atmosphere, synthesize graphite and water |
| Science | Produce local generic, metallurgic, chemical, and physics science |
| Scale | Add primitive logistics, efficient metallurgy, refractory, titanium, and higher thermal tiers |

Returning to Nauvis remains available throughout the sequence.

## Cross-planet effects

| Direction | Material or knowledge | Purpose |
|---|---|---|
| Vulcanus to Nauvis | Thermal machinery research | Optional heat-powered productivity |
| Vulcanus to all planets | Industrial optimization | Process-specific productivity |
| Vulcanus to Nauvis | Calcite and calcium products | Easier chlorine management |
| Vulcanus to other surfaces | Rutile, titanium, and bulk metals | Remove punitive bootstrap routes |
| Other surfaces to Vulcanus | Bulk water and commodity polymers | Efficient mature industry |
| Gleba to Vulcanus | Biological inputs | Candidate demolisher operation |

## Post-cargo demolisher concept

```yaml
purpose: expose deep rutile deposits
deployment: player-crafted synthetic demolisher
control: territory and patrol APIs
dependency: biological knowledge and feed from Gleba
failure: unfed demolisher ceases operation or dies
```

## Post-scout weapons concept

| Research step | Intended result |
|---|---|
| Long-range overpressure vessels | Artillery and basic explosive shells |
| Improved overpressure vessels | Advanced and incendiary shells |
| Orbital overpressure delivery | Space-platform strategic delivery system |

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
| Heat chemistry | Lava materials and wreck machinery are available | Aluminum reduction, sulfur catalysis, pneumatic heat, and thermal HCl cracking operate | `vulcanus-aluminum-reduction`, `vulcanus-sulfur-catalysis`, `vulcanus-pneumatic-heat-production`, `vulcanus-hcl-thermal-cracking` | — |
| Bootstrap metallurgy | Local metals and chemistry are available | Bootstrap metallurgic science can be crafted | `vulcanus-metallurgic-pack-recipe`, `vulcanus-metallurgic-pack-10` | `vulcanus-pack.args` |
| Construction closure | Bootstrap production is available | Core pneumatic factory and inorganic fluid handling can be reproduced locally | `vulcanus-construction-closure`, `vulcanus-inorganic-barrel`, `pneumatic-assemblers`, `pneumatic-barrel-pumps`, `pneumatic-boxer`, `vulcanus-pneumatic-compressor` | `vulcanus-construction.args`, `vulcanus-barrel.args`, `pneumatic-boxer.args` |
| Renewable graphite | Construction closure is available | Atmosphere and HCl chemistry replace rock-mined graphite | `vulcanus-hcl-thermal-cracking` | `vulcanus-renewable-graphite.args` |
| Basic science | Renewable graphite and construction closure are available | Local geology, climatology, mechanical, and electrical science operate | `vulcanus-basic-science-10` | `vulcanus-basic-science.args` |
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
JSON and generated detail tables as build outputs; this document is the maintained
Vulcanus reference. The historical `docs/data/vulcanus-balance.json` is an earlier
batch audit, not current capacity or elapsed-time evidence.

```bash
python tools/analyze_factorio_prereqs.py @tests/progression/planner/science-tier2-inspection.args
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-science-tier2.json --output /tmp/vulcanus-tier2.json --overview
python tools/plan_factorio_factory.py --config tests/progression/planner/nauvis-science-tier2-miners.json --output /tmp/nauvis-tier2.json --overview
python tools/compare_factorio_factory_plans.py --config tests/progression/planner/science-tier2-miners-comparison.json --first-plan /tmp/nauvis-tier2.json --second-plan /tmp/vulcanus-tier2.json --output /tmp/science-comparison.json --update-vulcanus-doc docs/PLANET_VULCANUS.md
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-science-scale.json --output /tmp/vulcanus-science.json --update-vulcanus-doc docs/PLANET_VULCANUS.md --overview
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-quenching.json --output /tmp/vulcanus-quenching.json --comparison-output /tmp/vulcanus-quenching.md --overview
python tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-water-quenching.args
python tools/run_factorio_tests.py vulcanus-science-tier2 planner-physics-executors planner-chemical-executors vulcanus-probe-alignment -n auto
python tools/check_factorio_locale.py
```
