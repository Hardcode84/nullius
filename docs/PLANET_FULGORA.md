# Fulgora design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Planet, terrain, probe research, and body access implemented; industry is not included |
| Planet mechanics and constraints | This document; extracted from the Space Age brainstorm |
| Shared progression, cargo, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |
| API candidates below | Inherited design notes; require current engine tests before implementation |

## Role

```yaml
planet_role: organic industry
setting: primordial world; no prior civilization or ruins
surface: dry natural ground; no ruins, scrap, or oil ocean
primary_resource: deep abiogenic hydrocarbon ocean
initial_access: natural hydrocarbon vents on sand
power: lightning; combustion requires manufactured oxygen
atmosphere: oxygen-free
surface_water: none
local_water: ice recovered by fountain filtration
metals: dissolved traces; no ore deposits
combustion: permitted with oxygen from water electrolysis
pre_cargo: independent local bootstrap and petrochemical research
exports: advanced organics, polymers, carbon materials, rare traces
imports: bulk metals, oxygen, water, nuclear devices
```

## Probe and bootstrap

| Step | Proposed player outcome |
|---|---|
| Access | Reactivate the storm-damaged probe on an island with a hydrocarbon vent within reach on adjacent sand |
| Salvage | Recover a few extractors, a working filter, power poles, capacitor banks, polymer pipes, one distillation column, and basic inserters |
| Power | Collect lightning through power poles and buffer it for calm periods |
| Materials | Filter raw hydrocarbon fluid into filtered hydrocarbons, sludge, ice, salt, and gypsum |
| Construction | Use organic substitutes and scarce recovered metals to expand |
| Research | Produce local generic science and petrochemical science before cargo |
| Expansion | Improve fountain processing; later expose the deep ocean |

The bootstrap must reproduce basic buildings and logistics without imports or
additional science. Waste Reclamation improves recovery after this point; its
220-unit research cost must not gate the first local building production.
Exact equipment counts, recipe quantities,
resource yields, and the local research endpoint are not yet specified.

## Planned sand construction

These rules extend the implemented terrain; the building whitelist and vents
are not implemented.

| Location or object | Rule |
|---|---|
| Hydrocarbon vents | Place on sand; pipe raw fluid to island processing |
| Buildings permitted on sand | Extractors, power poles, pipes, underground pipes, pumps, and elevated rail supports only |
| All other buildings | Require island ground, including filters, tanks, power storage, belts, and rail ramps |
| Elevated rails | Bridge sand basins between islands on rail supports |
| Sand | Remains walkable; no landfill, paving, or terraforming |
| Starter island | Provide a reachable vent and space for the starter processing line |

## Implemented terrain and access

| Contract | Value |
|---|---|
| Planet | `nullius-fulgora`; connected to Nauvis |
| Terrain | Native Fulgora islands, elevation, cliffs, and natural ground; dry sediment replaces oil oceans, and dust replaces artificial ground |
| Island size | Native size control: 2; frequency unchanged |
| Sediment | Light rust shallows and darker red depths; one shade per native oil-ocean type |
| Construction | Sediment permits walking but rejects buildings, landfill, and paving; terraforming drones cannot change it |
| Bridges | Elevated rails: basic trains + energy distribution 2; 50 of each early science pack. Steel supports can stand in sediment; ramps need firm ground |
| Rock drops | Stone only; no holmium from either fulgurite size |
| Excluded | Ruins, artificial ground, scrap, oil ocean, surface water, ore deposits, and enemies |
| Probe research | Signal acquisition + insulation 1; 30 of each of the four early science packs; 20 seconds |
| Landing | One equipped idle android and one empty probe wreck per force |
| Access | `/nullius-fulgora` completes access research and transfers the caller to the idle body |
| Multiplayer | Same-force players share idle bodies; occupied bodies cannot be taken; Vulcanus and Fulgora records are separate |
| Storms | Native destructive lightning disabled; this slice adds terrain and access only |
| Tests | `fulgora-mapgen`, `fulgora-terrain`, `fulgora-activation`, `fulgora-shared-body`, `fulgora-probe-alignment`, `fulgora-rail-supports` on both engines |

To inspect the terrain and capture three screenshots:

```bash
python tools/prepare_fulgora_preview.py --destination release/fulgora-preview
./release/fulgora-preview/launch.sh
```

The preview includes three fixed seeds. Screenshots and terrain maps are in
`release/fulgora-preview/script-output/fulgora-preview/`.

## Resource model

```text
natural fountains -> extractors -> raw hydrocarbon fluid -> filtration
  -> filtered hydrocarbons -> distillation -> organic feedstocks + heavy tar
  -> sludge -> crude filtration -> low-yield random minerals
            -> waste reclamation -> selective mineral recovery [researched]
  -> ice -> melting -> water -> electrolysis -> hydrogen + oxygen
  -> salt -> brine dissolution
  -> gypsum -> decomposition -> lime + sulfur dioxide
salt + recovered water -> brine [new local dissolution recipe]
brine -> electrolysis -> chlorine + hydrogen + sodium hydroxide
sodium hydroxide + water -> caustic solution
hydrogen + chlorine -> hydrogen chloride
oxygen + fuel -> combustion -> heat or power
surplus salt -> mineral dust [new recipe]
mineral dust + acid -> sludge -> mineral recovery
```

Filtration has five fixed outputs: two fluids (filtered hydrocarbons and existing
`nullius-sludge`) and three solids (ice, salt, gypsum). Raw hydrocarbon fluid and
filtered hydrocarbons are new fluids; no mineral concentrate is required.
Use the planner to set yields and distillation fractions against extractor
production, processing equipment expansion, and bridge construction.

| Constraint | Design consequence |
|---|---|
| Few fountains at fixed locations | Initial extraction has limited throughput |
| Deep ocean inaccessible initially | No unrestricted bulk extraction at arrival |
| Fixed output ratios | Use separate sludge recovery lines to adjust mineral supply; process every filtration output |
| Large unwanted output volume | Disposal throughput is part of factory capacity |
| No atmospheric oxygen | Manufacture oxygen by water electrolysis; stored oxygen permits combustion during calm periods |
| No surface water | Recover ice at a fixed yield from filtration |
| Local chlorine | Recover salt directly from filtration; electrolyze brine made with recovered water |
| Local sulfur | Recover gypsum directly from filtration; decompose it to supply sulfur dioxide |

Use caustic solution in mineral processing. Water, chlorine, and sulfur supply
must not depend on metal recovery.
Before implementation, check recipe access and the first electrolyzer's
materials at probe-era research.

No liquid voiding on Fulgora. Use existing chimney recipes for gases; no new
venting whitelist is required. Storage does not remove a continuous surplus.

| Existing route | Output or constraint |
|---|---|
| Gas vents | Hydrogen, oxygen, nitrogen, air, argon, helium, CO, CO2, SO2, methane, ammonia, steam, residual gas, trace gas, volcanic gas, and deuterium; compressed vents exist for several gases |
| Chlorine, HCl, ethylene, propene, benzene | No direct chimney recipe |
| HCl + caustic solution | Brine; boil brine to salt + ventable steam |
| Wastewater filtration | Saline + sludge; boiling saline produces steam + brine |
| Wastewater boiling | Steam + sludge; does not remove the sludge problem |
| Sludge dehydration | Mineral dust + steam + CO; requires high-pressure chemistry 2 and physics science |
| Organic combustion | Existing ethylene, propene, benzene, methanol, and biodiesel recipes consume oxygen and produce steam + CO2 |
| Ethylene / propene pyrolysis | Methane plus other organics; not a complete disposal route |
| Benzene reforming | Steam input; hydrogen + CO + CO2 outputs, all ventable |

Brine boiling, wastewater boiling, pyrolysis, and benzene reforming require
chemical science. Select earlier local unlocks before these are bootstrap routes.
Existing salination makes seawater from freshwater and salt, not brine from pure
water. The proposed local dissolution recipe is not implemented.

Sludge resource recovery is permitted. The metal recovery constraint applies to
recycling shared replacement components, not to processing factory sludge.
Mineral dust acid disposal returns sludge; it is not a final solid sink.

Use electricity or supplied heat to melt ice. Include melting, electrolysis,
compression, combustion, and water recovery in the power balance. A closed
hydrogen/oxygen storage loop must not produce net energy; fountain hydrocarbons
are an external fuel input. Prove the first oxygen batch with probe power.

Copper dust remains an open choice because Nullius otherwise reserves copper
for asteroid mining.

### Mineral ratios and sulfur

Design: make crude sludge filtration available at probe access. It gives the
basic mineral set at very low, probabilistic yields. Unlock the required dust
conversion, dissolution, and acid supply with it. Check startup across seeds;
average yields alone do not establish acceptable time to reproduce equipment.

Add salt -> mineral dust, including a boxed equivalent. Keep salt for chemistry
and send excess to dust dissolution. Balance the complete recycle loop for net
loss so unwanted outputs cannot accumulate indefinitely. Product probabilities
and recipe quantities require balance tests.

After research, use separate recovery lines to adjust the material mix. Existing recipes consume
200 sludge per batch:

| Recovery | Reagent | Main solid outputs |
|---|---|---|
| Iron | Caustic solution | 8 crushed iron ore + 4 calcium carbonate |
| Bauxite | Sulfuric acid | 8 crushed bauxite + 4 sand |
| Sand | Hydrochloric acid | 8 sand + 4 crushed iron ore |
| Limestone | Soda ash + freshwater | 8 calcium carbonate + 4 crushed bauxite |

Prioritize recovered wastewater and sludge before fresh extraction. Send surplus
iron through gravel to mineral dust; bauxite and calcium carbonate can become
mineral dust directly. Acid treatment returns dust to sludge for another recovery
route. This changes the output mix at a reagent and energy cost. Fixed ratios
remain within each recipe; include all surplus outputs in the material balance.
Waste reclamation now follows Concrete 1, Nitrogen Chemistry 1, and Sulfur
Processing 1. It costs 220 of each early science pack, at 30 seconds per unit.
All five recovery recipes, including stone, and barrel recycling remain together.
The research boundary is checked with Nauvis inputs; Fulgora still needs a planner
balance for local supplies, outputs, reagents, and recycle streams.

Proposed sulfur source: recover gypsum directly from raw hydrocarbon fluid filtration. Existing
recipes provide `2 gypsum -> 1 lime + 10 SO2`, then
`8 SO2 + 16 water + 4 oxygen -> 20 sulfuric acid`. Decomposition unlocks at
limestone processing 2, before chemical science; a boxed recipe also exists.
Bauxite recovery returns SO2 but consumes sulfuric acid, so it cannot supply the
first sulfur input. Gypsum recovery from fountains is not implemented. Include
its lime output in the mineral balance; surplus SO2 can use the existing vent.

## Storms and industrial feedback

The inherited fictional explanation is a conductive subsurface ocean of heavy
polyaromatic hydrocarbons and dissolved metal salts. Convection drives a magnetic
dynamo and surface lightning. This is setting material, not a chemistry model.

| Mechanic | Proposed behavior |
|---|---|
| Industrial feedback | Extraction, waste heat, and returned contaminants increase convection and storm intensity |
| Factory response | Scale surge protection, limit extraction, or research storm mitigation |
| Long-term mitigation | Removing dissolved metals can weaken the dynamo |
| Short cycles | Calm, rising intensity, peak, and recovery |
| Cycle candidates | Sine cycle, random superstorms, longer seasons, and day/night weighting |
| Baseline metric candidates | Extraction rate, machine count, or cumulative hydrocarbons processed |
| Forecast | Expose storm information so the player can prepare |

## Lightning and overload

Power poles collect lightning; there is no separate player-built collector.
Lightning must interrupt production without destroying the factory.

```text
lightning -> pole collector -> electrical network
  -> sufficient absorption: store energy or consume it
  -> overload: switch the network offline
  -> manual reset from any pole in the affected network
```

| Protection | Role | Cost or constraint |
|---|---|---|
| Surge sink | Consume excess electricity as waste heat | Tertiary priority; spaced like wind turbines |
| Priority sink | Maintain storage headroom through steady consumption | Secondary priority; can cause calm-period shortages |
| Reset grace period | Prevent immediate repeat trips | Clear the measurement window when the player resets the network |

Absorption must account for both available capacity and charge rate. Too few
sinks cause overloads; excessive consumption leaves insufficient stored power.

Check each network every 30 ticks. On 2.1, compare offered primary, secondary,
and solar energy against twice the requested energy across all input priorities.
Exclude accumulator discharge from the offered sum. This uses the latest tick,
not the whole 30-tick interval. On 2.0, production statistics count delivered
energy and cannot implement this check without additional measurements.

## Energy storage

| Storage | Charge rate | Capacity | Loss | Role |
|---|---|---|---|---|
| Super-capacitor | Very high | Low | High continuous drain | Absorb individual strikes |
| Accumulator | Moderate | Medium | Low | Supply the gaps between strikes |
| Thermal storage | Slow | High | Low storage loss; conversion loss | Supply extended calm periods through Stirling conversion |

Proposed flow: lightning -> super-capacitors -> accumulators -> heat storage ->
Stirling generation. Super-capacitors use polymer dielectric and carbon electrodes.
The initial tuning suggestion was 5-10 MJ per capacitor versus 15-100 MJ per
accumulator; these are not validated values. Storage transfer and priority rules
must prove that energy can flow through this sequence. Stored oxygen and fuel
provide a separate combustion option; combustion is not required to start it.

## Organic industry

Design only: change display names, keep item IDs, and add local recipes for the
same output. Preserve separate grades. Apply each change to boxed products too.

| Current intermediate | Naming decision | Fulgora route or restriction |
|---|---|---|
| Iron gear / steel gear | Gear / reinforced gear | Molded polymer / fiber-reinforced polymer |
| Steel beam | Structural beam | Carbon composite; steel plates and rods still limit bridge production |
| Steel cable | Tension cable | High-strength fiber cable |
| Iron, steel, aluminum, titanium, and copper plates, rods, sheets, and bare wires | Keep material names | Use trace metals; substitute at the equipment recipe where practical |
| Insulated wire, red/green wire, optical cable | Keep functional names | Conductive polymer and polymer optics; do not output bare metal wire |
| Glass / hard glass | Keep material names | Use polymer windows in local equipment recipes; hard glass also feeds glass fiber |
| Glass fiber | Keep material name | Its consumers include insulation, composites, and optical cable; use local alternatives at those outputs |
| Fiberglass | Fiber composite | Reinforcing fiber + polymer binder; keep carbon composite as a separate grade |
| Plastic, rubber, acrylic fiber, textile, carbon fiber/composite, graphite, graphene | Keep names | Supply from fountain chemistry; move or add local recipes without removing grade requirements |
| Bearing, filters, insulation | Keep functional names | Polymer/composite alternatives; retain ceramic or metal inputs where required |
| Motors, transformers, circuits, sensors, processors, capacitors, batteries | Keep functional names and tiers | Use local casings, conductors, and dielectrics; retain required metal, silicon, and electrolyte inputs |
| Chassis, robot frames, tools, pipes, valves, tanks, canisters | Keep functional names and tiers | Add local assembly recipes; audit container-to-metal recovery before substituting |
| Ores, ingots, metal powders, oxides, salts, silicon, ceramics, refractory materials | Keep material names | Recover actual minerals; no polymer recipe may output these items |

### Metal recovery constraint

A shared item does not record whether its recipe used metal or polymer.
Renamed components must not recover metals, directly or through other products.

| Existing path | Required decision |
|---|---|
| Iron wire -> iron oxide; boxed equivalent | Keep iron wire metallic |
| Aluminum wire -> aluminum powder; boxed equivalent | Keep aluminum wire metallic |
| Small tank + valves -> barrels -> iron ingot | Remove metal recovery before any metal-free tank, valve, or barrel recipe |
| Component -> equipment -> recycling products | Audit the equipment output as well as the component |

For shared components and equipment with organic alternatives, remove metal
recovery outputs and their unlock paths; retain only disposal or nonmetal
recovery. Apply this on every planet and to boxed, legacy, and generated recipes.
Setting `auto_recycle=false` alone does not remove an existing recipe; hidden
recipes and `enabled=false` alone do not prevent a technology from unlocking it.

Before adding a substitute, test ordinary and boxed routes on both engines,
including downstream assembly, recycling, unboxing, and chemical conversion.
Reject any route that turns the substitute into metal or metal-bearing feedstock.
Direct-consumer inspection is not proof of this condition. Use the repeatable
[consumer audit](../tests/progression/fulgora-intermediate-consumers.args) and
[producer audit](../tests/progression/fulgora-component-producers.args) as inputs
to the implementation checks.

Conductive polymer wire connects the industry to the ocean setting. Imported
Vulcanus iron chloride is a proposed dopant after cargo; local bootstrap wiring
must not depend on that import.

## Science and research

| Research or product | Proposed local route or reward |
|---|---|
| Geology science | Trace minerals from filtration |
| Mechanical science | Polymer gears |
| Electrical science | Conductive polymer circuits |
| Petrochemical pack | Hydrocarbon distillates, polymer compounds, trace metals, and super-capacitor cells; exact recipe unresolved |
| Global petrochemical rewards | Advanced polymers, organic electronics, improved chemical recipes, lightning-resistant equipment |
| Post-scout directed-energy devices | Lasers and beam weapons using petrochemistry, organic optics, and polymer waveguides |
| Shared endgame contribution | Exotic polymer focusing lens |

## Nuclear geoengineering

| Step | Proposed behavior |
|---|---|
| Prerequisite | Aquilo fusion research or imported Nauvis nuclear technology; choice unresolved |
| Deployment | Use nuclear charges as geological tools |
| Terrain change | Fracture the crust and expose large areas of hydrocarbon ocean |
| Construction | Use specialized foundations on unstable, fluid-rich terrain |
| Production | Replace limited fountain extraction with bulk surface filtration |

The shared endgame also proposes repurposing these charges for orbital defence.

## Cross-planet effects

| Direction | Materials or role |
|---|---|
| Vulcanus to Fulgora | Bulk metals; iron chloride dopant |
| Fulgora to Vulcanus | Organics, polymers, and carbon materials |
| Nauvis or Aquilo to Fulgora | Water; nuclear equipment for geoengineering |
| Fulgora to other planets | Advanced organics, rare traces, and petrochemical research |

Vulcanus supplies metals with pneumatic and thermal industry. Fulgora supplies
organics with intermittent electricity. Both lack natural surface water.

## Pole collector experiment

`experiment-lightning-poles`: Factorio 2.0.77, 31 assertions, tick 240.
Test fixtures only; no gameplay implementation.

| Case | Measured result |
|---|---|
| Ordinary pole | Lightning targets the pole; no energy is collected |
| Invisible attractor at the pole position | A 1 MJ strike at 50% efficiency supplies exactly 500 kJ through the native grid |
| Strike callbacks | Ordinary target uses `strike_effect`; collector uses `attractor_hit_effect` |
| Network split and rejoin | Collector retains 500 kJ while disconnected, then supplies it after reconnection |
| Pole removal, death, and replacement | Object-destruction registration removes the helper; replacement collects without duplicates |
| Different forces | Nearby poles auto-connect. Overlapping supply areas still share energy after wire disconnection; separated coverage receives none |
| Visual selection and damage | Helper is not selectable; zero-damage strikes preserve poles |

Use a normal pole with one invisible `lightning-attractor`. The engine handles
capture, efficiency, buffering, and network delivery. Script ownership is needed
for helper creation and removal, not for energy transfer. The fixture uses
`execute_lightning` with ambient storms disabled; it does not measure storm rates.
Before gameplay integration, test player/robot builds, blueprints, upgrades,
cloning, force changes, and surface deletion against the one-helper-per-pole rule.

```bash
python tools/run_factorio_tests.py experiment-lightning-poles -n auto
```

## Engine candidates and validation questions

### Factorio 2.1 API experiment

Isolated Space Age fixtures, not the full Nullius mod: 2.1.19, 81 assertions
across the three electrical scenarios. Use
`pole.electric_network.parent_network.flow_last_tick`.

| Fixture at tick 90 | Offered primary energy | Requested secondary / tertiary energy |
|---|---|---|
| 1 MW generator, 100 kW load | 16.667 kJ | 1.667 / 0 kJ |
| Same with accumulator charging | 16.667 kJ | 1.667 / 10 kJ |
| Charged lightning collector, 100 kW load | 453.333 kJ | 1.667 / 0 kJ |

`get_accumulators_energy{}` returns current energy and capacity: 0.9 MJ and
10 MJ in the charging fixture. `flow_last_tick.accumulator_energy` is the
pre-transfer value, 0.89 MJ. Collector buffers still do not appear in storage
statistics. The 1 TW sink and native lightning capture tests pass on 2.1.

Full-mod loading requires the [2.1 port](FACTORIO_2_1_PORT.md), including dependency
upgrades and prototype/runtime changes. Fixture changes needed for 2.1: lightning damage
uses `{amount=0,type="electric"}`; disable entities with `disabled_by_script`
because `active` is read-only.

```bash
python tools/test_factorio_network_api.py --factorio "$HOME/factorio-2.1.19/bin/x64/factorio"
```

### Factorio 2.0 API experiments

`experiment-network-trip`: Factorio 2.0.77, 22 assertions, tick 450.
Test fixtures only; reset is scripted, not a tested player click.

| Case | Measured result |
|---|---|
| 1 MW source, 100 kW load, 30 ticks | Production and consumption both 50 kJ |
| Same source with 600 kW storage charging | Production and consumption both 350 kJ |
| 1 MJ strike, 50% collection | 48.33 kJ delivered; 451.67 kJ remains in the collector |
| Collector buffer statistics, primary-output and tertiary | Both retain 451.67 kJ; storage totals and latest storage samples both return zero |
| Pole or collector `active=false` | Electricity still flows |
| Replace connected poles with zero-area variants | Wires remain; adjacent loads lose power until reset |
| Load built while offline | Remains unpowered outside the pole centre |
| Source and load overlap the pole centre | Still powered; zero area does not isolate hidden helpers |

`experiment-network-sink`: Factorio 2.0.77, 19 assertions, tick 450.
One hidden 1 TW `primary-input` consumer per network; no repeated energy writes.

| Supply during shutdown | Ordinary 100 kW load | Primary 100 kW load | Sink |
|---|---|---|---|
| 1 MW generator | 0 W | Approximately 0.1 W | Approximately 1 MW |
| Generator plus two 600 kW accumulator discharges | 0 W | Approximately 0.22 W | Approximately 2.2 MW |

Use the hidden consumer for shutdown; remove it on manual reset. Both load
priorities recover, and poles, wires, and network identity remain unchanged.
Existing consumer buffers can run down; accumulators discharge at their output
limit. This causes power starvation, not complete isolation of primary loads.
The 1 TW demand must exceed the network supply. Zero-area pole replacement is
not required for this design.

Read aggregate accumulator charge with `get_flow_count`: `category="storage"`,
`precision_index=defines.flow_precision_index.five_seconds`, `sample_index=1`,
and the accumulator prototype name. The latest sample matches the sum of two
accumulator charges in joules. Sum prototype types, not individual entities.
`get_storage_count` accumulates history; it is not current charge. This read does
not provide total capacity or include the hidden collectors' buffers.

The API provides `on_gui_opened`, `electric_network_gui` relative GUI anchoring,
and `on_gui_click` for a reset button at any pole.

Before gameplay integration, prove one connected sink per offline component
after save/load, pole removal, network splits, and merges. Restore the sink if
its anchor pole is removed. Resolve the current component when a player clicks
reset; network IDs alone are not persistent ownership. Exclude sink consumption
from overload measurements and clear the window on reset. Test overlapping
supply areas because a helper can connect to more than one network.

| Area | Inherited candidate | Required check |
|---|---|---|
| Pole collectors | Native hidden attractor; see experiment above | Validate remaining ownership events before gameplay integration |
| Storm control | `nullius-storm-intensity`, `LightningProperties.multiplier_surface_property`, `LuaSurface.set_property()` | Verify runtime frequency changes and select an update interval |
| Lightning tuning | `lightnings_per_chunk_per_tick`, day/night multipliers, targeting priorities, exemptions, search radius | Confirm current fields and targeting behavior |
| Strike effects | Separate ordinary and attracted callbacks confirmed by the pole experiment | Use the attractor callback for collector-side overload logic |
| No destruction | Zero damage preserves ordinary and collector-backed poles in the experiment | Check other building families when adding storms |
| Overload detection | 2.1 aggregate offered energy versus requested energy | Test short surges between samples and tune the threshold |
| Network state | Cache storage information and identify networks through `electric_network_id` | Keep values correct as energy changes and networks split or merge |
| Offline network | Hidden 1 TW primary consumer with manual reset; see experiment above | Prove sink ownership, topology changes, and the reset interface |
| Super-capacitors | `AccumulatorPrototype` with high `input_flow_limit`, low `buffer_capacity`, and energy-source `drain` | Verify charging, leakage, and transfer to other storage |
| Sinks | `ElectricEnergyInterface` with surge or secondary priority | Verify actual excess-power absorption and spacing rules |
| Fountain filtration | Five fixed recipe products: two fluids and three solids | Check filter fluid connections and output slots; set yields and prove a complete local bootstrap |

No engine performance, production-rate, or completion-time claim is established
by these inherited candidates.
