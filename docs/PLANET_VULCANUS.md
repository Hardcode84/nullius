# Vulcanus design

## Authorities

| Fact | Authority |
|---|---|
| Theme, mechanics, progression intent, and constraints | This document |
| Progression order | This document |
| Recipe, technology, item, fluid, and entity values | Factorio resolved prototypes |
| Starting inventory | `nullius-star/shared/vulcanus-starter.lua` |
| Runtime behavior | Mod control scripts and scenarios |

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

The foundry needs output space for the cast product and for blooms that cool during a water outage.

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
their boxed production families.
Vulcanus tier 2 geology unlocks with Limestone Processing 1, which supplies lime;
tier 2 climatology unlocks with Pressure Containment, which supplies compressed
gases. Boxed refractory insulation unlocks with Bulk Refractory Materials, after
Mass Production 5 and Vulcanus refractory engineering.

Rocket fuel uses the polymer-free route in
[Aluminum-CO2 rocket fuel](#aluminum-co2-rocket-fuel).

Thermite cliff explosives replace the ordinary organic explosive route. They
tie aluminum powder to barreled chlorine and sulfur chemistry; unstable
explosive spoilage is not part of this design.

### ANFO industrial explosives

Category: `basic-chemistry`. Output: stable cliff explosives.

| Recipe | Inputs | Outputs | Time | Unlock |
|---|---|---|---|---|
| Ordinary | 30 ammonia + 20 nitric acid + 20 SO2 + 4 aluminum powder + 2 iron oxide + 1 red wire | 1 explosive + 16 wastewater | 4 s | Explosives 2 |
| Bulk | 150 ammonia + 100 nitric acid + 100 SO2 + 4 boxes aluminum powder + 2 boxes iron oxide + 1 box red wire | 1 box of 5 explosives + 80 wastewater | 20 s | Mass production 6 |

Iron oxide adds wire, water, oxygen and flotation costs.

### Aluminum-CO2 rocket fuel

Vulcanus launch fuel burns aluminum powder in compressed atmospheric CO2.
A consumed canister holds the charge; ANFO starts the reaction. The fuel needs
no polymer, water, or organic ingredient in its final recipe. Lava supplies
aluminum, and the CO2-rich atmosphere supplies the oxidizer.

Aluminum-CO2 Propellant requires Rocket Science 1 and Pneumatic Technology.
It uses metallurgic science and unlocks ordinary and boxed fuel together.
Its research cost shares one definition with Titanium Rocket Structures and
RP-1, with the corresponding planet science pack.

Both recipes use chemical plants and reject productivity. The output is the
existing rocket fuel. Item weight and launch-stage ingredients stay unchanged.
The recipe has no surface limit; the Vulcanus research gate controls access.
The research and recipe icons use rocket fuel with a small CO2 badge.

Cost checks keep aluminum-CO2 fuel expensive on other planets. It must use at
least twice the default fuel's bauxite and exceed RP-1 in both solid-resource
and gas or slurry costs. Each cost contract pins CO2 compression and local air
separation. This prevents the planner from selecting a polymer or steel
byproduct as the oxidizer source.

The aluminum input exceeds recovery from burnt alumina without productivity.
Rocket fuel burns only in vehicles, trains, and portable generator equipment,
so no factory power route needs an energy bound.

### Pneumatic silo

Vulcanus has no electricity route, so the silo can use compressed volcanic gas
there. Pneumatic Technology unlocks the mode. Select a silo or its ghost and
press Ctrl+R to switch modes.

- Gas use during crafting and powered launch steps matches the total
  electric draw. The night lamp adds the same load in both modes. Pneumatic
  mode has no standby drain.
- Fuel loss pauses crafting and powered launch steps. Refuelling resumes them.
- The silo emits process heat through the large pneumatic heat interface.
- Switch before a rocket is assembled or after the launch sequence ends.
  Partial crafting progress, modules, inventories, logistic requests, circuit
  settings, and automatic orbit sending survive the switch.
- Assembled or launching rockets cannot switch. Pneumatic silos cannot be
  built on space platforms.
- Clockwork robots can load platform requests without an electric grid.

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
- Each vent crafts gas directly. Its local speed effect follows the square-root
  share of all vents on the surface, across all forces and intake tiers, because
  every vent draws on the same subsurface gas. Radio dishes count per force instead.
  Mining-productivity research increases each owner's output as before.
- Placement, removal, and mining-research changes update the shares. Modules
  and beacons cannot change them. The native speed floor applies, as for radio
  dishes.
- The intake owns its output connection, so rotation needs no script handler.
- Dedicated gas extraction scales linearly and funds the factory.
- Pneumatic radio dishes use the same continuous speed control, with a separate
  array for each force. See [radio astronomy](SPACE_AGE_BRAINSTORM.md#45-astronomy-interplanetary-interferometry).
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
- Pneumatic machines cannot be placed off Vulcanus, including from blueprints.
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

Solid miners and the powered chimney support pneumatic mode. Mode changes keep
the same placement item; miner upgrades keep the selected power mode.

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
progression path. Upgrade planners keep thermal mode and use ordinary machine
items, including for nanofabricators. Robot upgrades and downgrades retain
compatible recipes.

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
| Physics science | Local residual-gas separation removes the argon research cycle. Local production supplies the first physics packs. |

| Research family | Role |
|---|---|
| Pneumatic technology | Vulcanus machinery, radiators, sensing, chloride chemistry, and first-tier thermal industry |
| Efficient metallurgy | Improved metallurgic science and fluid barreling |
| Primitive robotics | Low-throughput clockwork logistics and personal logistic requests |
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

### Argon

The argon route uses 150 air to produce 120 CO2, 10 SO2 and 3 residual gas. Air
separation 2 unlocks it on Vulcanus. It replaces nitrogen collection and produces
no oxygen. Existing barrel recipes handle residual gas; there is no boxed fluid.
This supplies the argon for local physics packs.

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
| Vulcanus to rocket builders | Titanium | Volcanic Titanium Metallurgy leads to the titanium rocket stage, which cuts the default stage's Nauvis raw input by the bounds in [Titanium recipes](SPACE_AGE_BRAINSTORM.md#titanium-recipes) |
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
