# Fulgora design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Design only; no playable Fulgora progression is declared |
| Planet mechanics and constraints | This document; extracted from the Space Age brainstorm |
| Shared progression, cargo, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |
| API candidates below | Inherited design notes; require current engine tests before implementation |

## Role

```yaml
planet_role: organic industry
setting: primordial world; no prior civilization or ruins
primary_resource: deep abiogenic hydrocarbon ocean
initial_access: natural hydrocarbon fountains
power: lightning; large peaks, no steady supply
atmosphere: oxygen-free
natural_water: none
metals: dissolved traces; no ore deposits
combustion: unavailable
pre_cargo: independent local bootstrap and petrochemical research
exports: advanced organics, polymers, carbon materials, rare traces
imports: bulk metals, oxygen, water, nuclear devices
```

## Probe and bootstrap

| Step | Proposed player outcome |
|---|---|
| Access | Reactivate the storm-damaged probe near a natural fountain |
| Salvage | Recover capacitor banks, polymer pipes, one distillation column, basic inserters, and scrap; most electronics failed |
| Power | Collect lightning through power poles and buffer it for calm periods |
| Materials | Distill hydrocarbons and filter trace minerals |
| Construction | Use organic substitutes and scarce recovered metals to expand |
| Research | Produce local generic science and petrochemical science before cargo |
| Expansion | Improve fountain processing; later expose the deep ocean |

The bootstrap must work without imports. Surviving equipment, exact recipes,
resource yields, and the local research endpoint are not yet specified.

## Resource model

```text
natural fountains -> raw hydrocarbons -> filtration and distillation
  -> ethylene, propene, methane, benzene and other organic feedstocks
  -> random traces: iron dust, aluminum dust, silicon, sulfur, rare elements
  -> heavy tars and unusable fractions
```

| Constraint | Design consequence |
|---|---|
| Few fountains at fixed locations | Initial extraction has limited throughput |
| Deep ocean inaccessible initially | No unrestricted bulk extraction at arrival |
| Small, probabilistic trace yields | Filter at scale and buffer variable material ratios |
| Large unwanted output volume | Disposal throughput is part of factory capacity |
| No oxygen | Hydrocarbons are chemical feedstock; hydrogen combustion cannot provide backup power |

Disposal candidates: return waste to the ocean through a limited-throughput
outfall, compress and store it, use it in other recipes, or export it after cargo.
Copper dust remains an open choice because Nullius otherwise reserves copper
for asteroid mining.

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
must prove that energy can flow through this sequence without combustion.

## Organic industry

| Conventional material | Proposed local substitute |
|---|---|
| Iron beams and steel structures | Polymer composites and carbon fiber |
| Metal pipes | Polymer tubing |
| Copper or aluminum wire | Conductive polymers; carbon nanotube wire is another candidate |
| Metal gears | Plastic gears and rubber belts |
| Silica glass | Acrylic or polycarbonate |

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
| Trace extraction | Probabilistic recipe products | Set yields and prove a complete local bootstrap |

No engine performance, production-rate, or completion-time claim is established
by these inherited candidates.
