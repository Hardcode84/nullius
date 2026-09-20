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
  -> overload: drain accumulators and temporarily disable consumers
  -> timed recovery, with protection against repeated EMP shutdowns
```

| Protection | Role | Cost or constraint |
|---|---|---|
| Surge sink | Consume excess electricity as waste heat | Tertiary priority; spaced like wind turbines |
| Priority sink | Maintain storage headroom through steady consumption | Secondary priority; can cause calm-period shortages |
| Recovery interval | Prevent repeated overloads from blocking all progress | Candidate: EMP grace period or temporary storm suppression |

Absorption must account for both available capacity and charge rate. Too few
sinks cause overloads; excessive consumption leaves insufficient stored power.

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

| Area | Inherited candidate | Required check |
|---|---|---|
| Pole collectors | Native hidden attractor; see experiment above | Validate remaining ownership events before gameplay integration |
| Storm control | `nullius-storm-intensity`, `LightningProperties.multiplier_surface_property`, `LuaSurface.set_property()` | Verify runtime frequency changes and select an update interval |
| Lightning tuning | `lightnings_per_chunk_per_tick`, day/night multipliers, targeting priorities, exemptions, search radius | Confirm current fields and targeting behavior |
| Strike effects | Separate ordinary and attracted callbacks confirmed by the pole experiment | Use the attractor callback for collector-side overload logic |
| No destruction | Zero damage preserves ordinary and collector-backed poles in the experiment | Check other building families when adding storms |
| Overload detection | Prefer known strike energy versus network absorption; alternative is `electric_network_statistics` and `LuaFlowStatistics` | Test charge-rate limits, spare capacity, and statistics resolution |
| Network state | Cache storage information and identify networks through `electric_network_id` | Keep values correct as energy changes and networks split or merge |
| EMP | Set consumer `active=false`, drain storage with `energy=0`, restore consumers after a timer | Poles do not gate distribution through `active`; test recovery and repeated strikes |
| Super-capacitors | `AccumulatorPrototype` with high `input_flow_limit`, low `buffer_capacity`, and energy-source `drain` | Verify charging, leakage, and transfer to other storage |
| Sinks | `ElectricEnergyInterface` with surge or secondary priority | Verify actual excess-power absorption and spacing rules |
| Trace extraction | Probabilistic recipe products | Set yields and prove a complete local bootstrap |

No engine performance, production-rate, or completion-time claim is established
by these inherited candidates.
