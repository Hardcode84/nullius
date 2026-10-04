# Fulgora design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Planet, terrain, probe access, hydrocarbon vents, slurry extraction, primitive filtration, salt crushing, and sand construction rules implemented |
| Planet mechanics and constraints | This document; extracted from the Space Age brainstorm |
| Shared progression, cargo, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |
| API candidates below | Inherited design notes; require current engine tests before implementation |

## Role

```yaml
planet_role: electromagnetic manufacturing
setting: primordial world; no prior civilization or ruins
surface: dry natural ground; no ruins, scrap, or oil ocean
primary_resource: deep abiogenic hydrocarbon ocean
initial_access: natural hydrocarbon vents on sand
power: lightning; combustion requires manufactured oxygen
atmosphere: nitrogen 80%; carbon dioxide 19%; argon 1%; no oxygen or water
distinctive_surface_property: magnetic-field (99)
surface_water: none
local_water: ice recovered by fountain filtration
metals: dissolved traces; no ore deposits
combustion: permitted with oxygen from water electrolysis
pre_cargo: independent local bootstrap and electromagnetic research
global_machine_reward: overcharged assemblers
exports: advanced organics, polymers, carbon materials, rare traces
imports: bulk metals, oxygen, water, nuclear devices
```

## Probe and bootstrap

| Step | Proposed player outcome |
|---|---|
| Access | Reactivate the storm-damaged probe on an island with a hydrocarbon vent within reach on adjacent sand |
| Salvage | Recover the starter equipment listed below |
| Power | Collect lightning through power poles and buffer it for calm periods |
| Materials | Filter hydrocarbon slurry into filtered hydrocarbons, sludge, ice, and salt |
| Construction | Use organic substitutes and scarce recovered metals to expand |
| Research | Produce local generic science and electromagnetic science before cargo |
| Expansion | Improve fountain processing; later expose the deep ocean |

The bootstrap must reproduce basic buildings and logistics without imports or
large research batches. Research Primitive Filtration on Nauvis before transfer,
as with Vulcanus pneumatic technology. It requires Geology 2 and costs five of
each early science pack. Waste Reclamation improves recovery after this point; its
220-unit research cost must not gate the first local building production.

### Starter inventory

Supplied once per force when the probe is activated.

| Equipment | Count | First use |
|---|---:|---|
| Extractor 1 | 3 | Slurry for materials and science |
| Hydro plant 1 | 4 | Slurry filtration, crude filtration, brine, climatology |
| Distillery 1 | 3 | Ice melting, hydrocarbon cracking, air separation; reuse for other recipes |
| Air filter 1 | 4 | Nitrogen and climatology |
| Chemical plant 1 | 2 | Acids and polymers |
| Electrolyzer 1 | 2 | Water and brine electrolysis |
| Crusher 1 | 2 | Mineral processing and surplus crushing |
| Small furnace 1 | 1 | Early smelting |
| Medium furnace 1 | 1 | Smelting with gas output, including gypsum decomposition |
| Foundry 1 | 1 | Metal parts |
| Small assembler 1 | 2 | Equipment and science |
| Flotation cell 1 | 1 | Silica and dust treatment |
| Combustion chamber 1 | 1 | Consume surplus benzene with oxygen |
| Chimney 1 | 3 | Vent permitted gases; reuse for different gases |
| Lab 1 | 1 | Local research |
| Cliff explosives | 30 | Clear cliffs for the starter factory |
| Small electric pole | 32 | Lightning capture and distribution |
| Pylon 1 | 4 | Wider lightning capture and longer power connections |
| Pipe / underground pipe | 200 / 40 | Connect separate fluid networks |
| Small tank 1 | 8 | Buffer fluids during construction and recipe changes |
| One-way valve | 8 | Direct recovered fluids |
| Transport belt / inserter | 100 / 24 | Solid transport |
| Splitter / underground belt | 8 / 20 | Split belts and cross processing lines |
| Grid battery 1 | 4 | Additional electric storage |
| Grounding coil | 4 | Discharge surplus power; one coil protects eight poles |
| Small chest 1 | 12 | Two placed salvage chests, ten packed; separate filtration outputs and equipment |
| Small chest 2 | 4 | Packed in the wreck; extra storage |

Keep processing machines in the wreck. Put logistics supplies in the two
salvage chests; the wreck has only 20 inventory slots.

No ore, science packs, fuel, or bottled fluids. Keep the equipped probe android.
Poles include lightning energy buffers; the four grid batteries add storage.
Spread the collectors and connect them before processing.
Build filters and other restricted machines on islands; route pipes to sand vents.

This is seed equipment, not a complete science factory. Reproduce ordinary
buildings locally, then research extractor expansion. Support-machine routes
pass `@tests/progression/fulgora-bootstrap-support.args`. Validate these exact
counts with a finite-inventory scenario before treating them as a proven kit.

### Bootstrap audit

The probe supplies the starter kit. Full finite-inventory bootstrap validation
remains separate from the checks below.
Resolved-prototype checks give these results:

| Check | Result |
|---|---|
| Basic buildings and logistics | Nine targets reachable at Primitive Filtration; 29 recipe steps |
| Hydro plant, distillery, chemical plant, electrolyzer, crusher | Reproduction routes reachable at Primitive Filtration |
| Extractor reproduction | Research Volcanism 1 and its prerequisites with local science; starter extractors supply the first factory |
| Geology packs | Primitive Filtration requires Geology 2; the crushed-ore recipe is ready before transfer |
| Climatology packs | Hydro plant: 5000 air + 100 slurry → 1 pack in 60 s; Primitive Filtration |
| Electrical packs | Local nitrogen is available from atmospheric separation |
| Surplus bauxite | Dust conversion unlocks with Waste Management |
| Surplus sand | Crusher: 4 sand → 3 mineral dust in 2 s; Waste Management. Boxed variant: 4 boxes → 3 boxes in 10 s; Mass Production 7 |

The material checks assume powered starter machines and a supply of the six
probabilistic crude-filtration products. They prove recipe reachability, not
starter quantities, production time, or continuous waste balance. Basic-building
and science checks target Factorio 2.1.

Repeat the checks with `tools/analyze_factorio_prereqs.py --compact` and
`@tests/progression/fulgora-bootstrap-basic.args`,
`@tests/progression/fulgora-bootstrap-processing.args`,
`@tests/progression/fulgora-bootstrap-audit.args`, or
`@tests/progression/fulgora-bootstrap-science.args`.
The science check passes. The full-kit check reports the research needed to
reproduce extractors; that research is permitted after arrival.

Test a finite wreck inventory in a headless scenario: extract slurry,
reproduce the starter machines and logistics, and process every surplus without
imports or liquid voiding.

### Initial production time

`tools/plan_factorio_bootstrap.py` uses
`tests/progression/planner/fulgora-bootstrap-timing.json` and fresh prototypes.
The fixed starter machines and one android produce each target from zero stock.
Expansion kit: 1 hydro plant, 1 distillery, 4 air filters, 50 pipes, 50 belts,
10 inserters, and 8 poles. New machines do not operate during these batches.

<!-- bootstrap-timing:start -->
| Target | 100% vent yield | Survey high yield | Survey low yield |
|---|---:|---:|---:|
| 20 iron plates + 20 aluminum plates | 7.3 min | 4.4 min | 7.6 min |
| Expansion kit | 13.4 min | 8.0 min | 14.1 min |
| 10 of each early science pack | 10.3 min | 7.5 min | 10.9 min |
| Expansion kit + first science | 23.7 min | 14.8 min | 25.0 min |
<!-- bootstrap-timing:end -->

These are fractional-work bounds with mean mineral yields and continuous power.
They exclude placement, recipe-change delays, research bonuses, resource depletion,
and startup order. Tanks limit final surplus, not peak fluid volume. The survey
uses the nearest three usable vents from the origin in twelve seeds on 2.1:
94.0–199.2% mean yield. It does not cover every map or probe landing position.

Slurry supply and flotation limit the 100% case. Extra air filters or hydro plants do not
reduce its time. At higher yield, hydro plants, flotation, and hand crafting
limit production. With 50% machine duty, the combined 100% case takes 47.4 min.

Extractor research needs 250 geology, 228 climatology, 255 mechanical, and
247 electrical packs after the minimum arrival research. The starter buffer
allocation cannot support this batch with arrival recipes. Allowing more filtered
hydrocarbon storage makes it feasible; the fixed-fleet work bound is 260.1 min
at 100% yield. This is not a progression schedule with expansion and recipe upgrades.
No zero-liquid-surplus solution exists for these targets at the arrival boundary.
Players can manually delete excess fluid until automated disposal is available.

### Mineral recovery comparison

The recipe now returns 3 items per successful drop, with a 25% chance for each
mineral. The boxed recipe returns 3 boxes. The planner compares absolute drop amounts.
Starter machines, research, and buffer allocation stay fixed.

| Items per drop | First science, 100% vents | Expansion + science, 100% vents | Expansion + science, sampled vents |
|---|---:|---:|---:|
| 1 (previous) | 33.7 min | 82.3 min | 48.6–87.6 min |
| 2 | 16.1 min | 38.1 min | 20.9–40.6 min |
| 3 (current) | 10.3 min | 23.7 min | 14.8–25.0 min |
| 4 | 7.9 min | 17.8 min | 11.8–18.7 min |

At 100% yield, the current recipe meets the proposed 10–15 min science and
20–30 min combined production targets. These remain mean-yield work bounds.

All candidates still fail the extractor-research batch with starter buffers.
The 3-item combined batch retains about 17,749 filtered hydrocarbons, 844 benzene,
and 389 wastewater. Cracking and benzene combustion use local oxygen from water;
steam condensation requires Distillation 2. Wastewater filtration requires
Water Filtration 3. Verify a complete water and oxygen balance before changing
these unlocks. Inspect the routes with
`@tests/progression/planner/fulgora-bootstrap-liquid-inspection.args`.

## Atmospheric capture

| Component | Fraction |
|---|---:|
| Nitrogen | 80% |
| Carbon dioxide | 19% |
| Argon, recovered through residual gas | 1% |
| Oxygen and water | 0% |

| Process | Machine | Recipe | Time |
|---|---|---|---:|
| Capture | Air filter | Electricity → 150 air | 3 s |
| Separation | Distillery | 100 air → 80 nitrogen + 19 CO2 + 1 residual gas | 1 s |
| Argon recovery | Distillery | 50 residual gas → 50 argon | 5 s |

Use the existing air and residual-gas fluids. Fulgora separation requires
`magnetic-field = 99`; generic air separation, oxygen recovery, residual-gas
enrichment, and water-producing residual separation are excluded there.
The destination surface sets the separation recipe, including for imported gas.

Ordinary Fulgora recipes unlock with Primitive Filtration. Compressed variants
unlock with High Pressure Chemistry; they use the same amounts of compressed
fluids and take 2 s and 10 s. Gas recipes have no boxed variants.
Use existing gas vents for surplus products. Hydrocarbons still come from slurry.

Air filters retain their capture recipe and require island ground. Include one
in the planned starter kit. The air filter, distillery, and chimney have local
reproduction routes under `@tests/progression/fulgora-atmosphere-equipment.args`.
Slurry climatology uses the captured air without seawater.

## Sand construction

| Location or object | Rule |
|---|---|
| Hydrocarbon vents | Native oil graphics; generate only on sediment; existing extractors produce hydrocarbon slurry |
| Vent distribution | More, smaller clusters: 28.8 base patches/km²; total base density remains 65.6 |
| Buildings permitted on sand | Extractors, power poles, pipes, underground pipes, pumps, elevated rail supports, and grounding coils only |
| All other buildings | Require island ground, including filters, tanks, power storage, belts, and rail ramps |
| Elevated rails | Bridge sand basins between islands on rail supports |
| Sand | Both android tiers can walk across it; no landfill, paving, or terraforming |
| Vent coverage check | At least three usable vents within 256 tiles of the origin on twelve fixed seeds; `fulgora-vent-coverage` |
| Starter island | Design requirement: provide a reachable vent and space for the starter processing line |

## Implemented terrain and access

| Contract | Value |
|---|---|
| Planet | `nullius-fulgora`; connected to Nauvis |
| Terrain | Native Fulgora islands, elevation, cliffs, and natural ground; dry sediment replaces oil oceans, and dust replaces artificial ground |
| Island size | Native size control: 2; frequency unchanged |
| Sediment | Light rust shallows and darker red depths; one shade per native oil-ocean type |
| Construction | Sediment permits walking and the equipment listed above; no landfill, paving, or drone terraforming |
| Bridges | Elevated rails: basic trains + energy distribution 2; 50 of each early science pack. Steel supports can stand in sediment; ramps need firm ground |
| Rock drops | Stone only; no holmium from either fulgurite size |
| Excluded | Ruins, artificial ground, scrap, oil ocean, surface water, ore deposits, and enemies |
| Probe research | Signal acquisition + insulation 1; 30 of each of the four early science packs; 20 seconds |
| Landing | One equipped idle android, supplied probe wreck, and two salvage chests per force |
| Access | `/nullius-fulgora` completes probe access and Primitive Filtration, then transfers the caller to the idle body |
| Multiplayer | Same-force players share idle bodies; occupied bodies cannot be taken; Vulcanus and Fulgora records are separate |
| Storms | Harmless native lightning all day; daytime frequency is 25% of nighttime frequency |
| Process restrictions | Use `magnetic-field` for processes that need Fulgora's electromagnetic environment; ordinary processing has no planet restriction |
| Tests | `fulgora-mapgen`, `fulgora-terrain`, `fulgora-activation`, `fulgora-shared-body`, `fulgora-probe-alignment`, `fulgora-rail-supports`, `fulgora-extraction`, `fulgora-walking`, `fulgora-vent-coverage`, `fluid-resource-products` on both engines |

To inspect the terrain and capture three screenshots:

```bash
python tools/prepare_fulgora_preview.py --destination release/fulgora-preview
./release/fulgora-preview/launch.sh
```

The preview includes three fixed seeds. Screenshots and terrain maps are in
`release/fulgora-preview/script-output/fulgora-preview/`.

## Resource model

```text
natural fountains -> extractors -> hydrocarbon slurry -> filtration
  -> filtered hydrocarbons -> cracking -> methane + benzene + graphite
  -> sludge -> crude filtration -> low-yield random minerals
            -> waste reclamation -> selective mineral recovery [researched]
  -> ice -> melting -> water -> electrolysis -> hydrogen + oxygen
  -> salt -> brine dissolution
sludge -> crude filtration or gypsum recovery -> gypsum -> lime + sulfur dioxide
salt + recovered water -> brine
brine -> electrolysis -> chlorine + hydrogen + sodium hydroxide
sodium hydroxide + water -> caustic solution
hydrogen + chlorine -> hydrogen chloride
oxygen + fuel -> combustion -> heat or power
surplus salt -> mineral dust
mineral dust + acid -> sludge -> mineral recovery
```

Primitive Filtration requires probe access and Geology 2: 5 of each early science pack,
15 seconds per unit. It unlocks these recipes and their boxed equivalents.

| Recipe | Input | Output | Time | Machine |
|---|---|---|---|---|
| Slurry climatology | 5000 air + 100 hydrocarbon slurry | 1 climatology pack | 60 s | Hydro plant 1 |
| Slurry filtration | 100 hydrocarbon slurry | 50 filtered hydrocarbons + 40 sludge + 2 ice + 1 salt | 4 s | Hydro plant 1 |
| Crude sludge filtration | 50 sludge | Independent chance of 3 each: crushed iron, crushed bauxite, sand, calcium carbonate, stone, gypsum (25% each) | 2 s | Hydro plant 1 |
| Salt crushing | 1 salt | 1 mineral dust | 1 s | Crusher 1 |
| Ice melting | 1 ice | 20 water | 2 s | Distillery 1 |
| Salt dissolution | 6 salt + 45 water | 65 brine | 1 s | Hydro plant 1 |
| Hydrocarbon cracking | 50 filtered hydrocarbons | 60 methane + 12 benzene + 2 graphite | 4 s | Distillery 1 |

Boxed recipes consume five times the input and time; each solid output is a box
of five. Productivity is disabled. These recipes work on every planet.
Design change pending: move boxed recipe unlocks from Primitive Filtration to
much later mass-production research.
Salt and ice come directly from slurry. They supply hydrochloric acid without
mineral recovery. Crude filtration supplies the first gypsum without acid.
Selective gypsum recovery uses oxygen from water electrolysis; it needs no acid.
Cracking supplies organic feedstocks and graphite for metal smelting.

Planner capacity at 60 climatology packs/min, with tier-1 machines:

| Surface | Hydro plants | Air filters | Fluid supply | Electric demand |
|---|---:|---:|---|---:|
| Nauvis | 60 | 100 | 32 seawater intakes | 33.4 MW |
| Fulgora | 60 | 100 | 10 extractors at 100% vent yield | 31 MW |

Use `tools/plan_factorio_factory.py` with the `nauvis-climatology.json` and
`fulgora-climatology.json` configs in `tests/progression/planner/`.
These compare continuous supply at 30, 60, and 120 packs/min. They exclude labs,
power generation, storage, and logistics. Their restricted machine catalogs
cannot produce construction items; use the bootstrap audit for those routes.

| Constraint | Design consequence |
|---|---|
| Few fountains at fixed locations | Initial extraction has limited throughput |
| Deep ocean inaccessible initially | No unrestricted bulk extraction at arrival |
| Fixed output ratios | Use separate sludge recovery lines to adjust mineral supply; process every filtration output |
| Large unwanted output volume | Disposal throughput is part of factory capacity |
| No atmospheric oxygen | Manufacture oxygen by water electrolysis; stored oxygen permits combustion during calm periods |
| No surface water or wells | Recover ice at a fixed yield from filtration; groundwater wells cannot be placed on Fulgora |
| Local chlorine | Recover salt directly from filtration; electrolyze brine made with recovered water |
| Local sulfur | Recover gypsum from sludge; decompose it to supply sulfur dioxide |

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
| Carbon gasification | Graphite + steam → CO + hydrogen, both ventable; basic recipe unlocks at Organic Chemistry 2; boxed recipe remains at bulk processing |

Brine boiling, wastewater boiling, pyrolysis, and benzene reforming require
chemical science. Select earlier local unlocks before these are bootstrap routes.
Local salt dissolution uses pure water. Existing salination produces seawater
from freshwater and salt.

Waste Reclamation unlocks borate leaching in chemical plant 1:

| Input | Output | Time |
|---|---|---|
| 100 sludge + 20 sulfuric acid + 20 water | 1 boric acid + 1 gypsum + 80 wastewater | 10 s |

Deep fluids carry fine borate minerals into the slurry; sludge retains them.
The boxed recipe uses five times the fluids and time and returns one box of each
solid. Both recipes work on all planets and exclude productivity.

Sludge resource recovery is permitted. The metal recovery constraint applies to
recycling shared replacement components, not to processing factory sludge.
Mineral dust acid disposal returns sludge; it is not a final solid sink.

Use electricity or supplied heat to melt ice. Include melting, electrolysis,
compression, combustion, and water recovery in the power balance. A closed
hydrogen/oxygen storage loop must not produce net energy; fountain hydrocarbons
are an external fuel input. Prove the first oxygen batch with probe power.

### Late-game copper

Design only. Fulgora is the sole primary copper source. Remove copper from
asteroid mining; other planets must import it from Fulgora.

Copper is concentrated in deep mineral-rich sediments beneath the hydrocarbon
ocean. Surface vents do not supply recoverable copper at the starter stage.

| Stage | Copper route |
|---|---|
| Arrival | No copper from primitive filtration; use aluminum and polymer conductors |
| Advanced EM industry | Deep extraction supplies a separate copper-bearing concentrate; chemical extraction and electrolysis recover copper |
| Nuclear geoengineering | Expose deeper deposits for bulk copper production and export |

Keep the copper-bearing feed separate from generic sludge. Copper production
must not require copper to build or research its first extraction and processing
line. Preserve copper's late-game role; validate the research and cargo gates
before replacing the asteroid route.

### Mineral ratios and sulfur

Crude filtration and salt crushing unlock at Primitive Filtration. Dust
conversion, dissolution, and acid supply must also be available before research
scales up. Test the complete recycle loop for net loss and test startup across
seeds; average yields alone do not establish equipment reproduction time.

After research, use separate recovery lines to adjust the material mix. Existing recipes consume
200 sludge per batch:

| Recovery | Reagent | Main solid outputs |
|---|---|---|
| Iron | Caustic solution | 8 crushed iron ore + 4 calcium carbonate |
| Bauxite | Sulfuric acid | 8 crushed bauxite + 4 sand |
| Sand | Hydrochloric acid | 8 sand + 4 crushed iron ore |
| Limestone | 5 soda ash + 250 water | 8 calcium carbonate + 4 crushed bauxite |
| Gypsum | 180 oxygen | 8 gypsum + 4 sand; also 150 wastewater |

Prioritize recovered wastewater and sludge before fresh extraction. Send surplus
iron through gravel to mineral dust; bauxite and calcium carbonate can become
mineral dust directly. Acid treatment returns dust to sludge for another recovery
route. This changes the output mix at a reagent and energy cost. Fixed ratios
remain within each recipe; include all surplus outputs in the material balance.
Keep paired recovery outputs. Recycle the unwanted output through dust and
sludge. Dissolution acid must not depend on that mineral pair: salt and ice
supply hydrochloric acid; gypsum recovery with oxygen supplies sulfur.
The acid contract is `tests/progression/fulgora-independent-acids.args`. It assumes
Waste Reclamation and Limestone Processing 2, powered starter machines, and
supplied salt, ice, and sludge. It proves an acid route without mineral inputs;
it does not prove continuous disposal of its co-products.
Waste reclamation now follows Concrete 1, Nitrogen Chemistry 1, and Sulfur
Processing 1. It costs 220 of each early science pack, at 30 seconds per unit.
The five original recovery recipes, gypsum recovery, and barrel recycling unlock
together. Gypsum recovery takes 20 seconds in flotation cell 1. Its boxed recipe
uses 1000 sludge and 225 compressed oxygen, takes 100 seconds, and returns
8 gypsum boxes, 4 sand boxes, and 750 wastewater. Productivity is disabled.
Limestone and stone recovery use water instead of freshwater on every planet.
Stone recovery uses 250 sludge, 4 cement, and 200 water to make 15 stone and
150 wastewater in 30 seconds. Both have boxed recipes at five times the scale.
The research boundary is checked with Nauvis inputs; Fulgora still needs a planner
balance for local supplies, outputs, reagents, and recycle streams.

Crude sludge filtration supplies gypsum without acid. Selective recovery uses
oxygen from water electrolysis. Existing
recipes provide `2 gypsum -> 1 lime + 10 SO2`, then
`8 SO2 + 16 water + 4 oxygen -> 20 sulfuric acid`. Decomposition unlocks at
limestone processing 2, before chemical science; a boxed recipe also exists.
Bauxite recovery returns SO2 but consumes sulfuric acid, so it cannot supply the
first sulfur input. Include
the lime output in the mineral balance; surplus SO2 can use the existing vent.

## Storms and industrial feedback

The inherited fictional explanation is a conductive subsurface ocean of heavy
polyaromatic hydrocarbons and dissolved metal salts. Convection drives a magnetic
dynamo and surface lightning. This is setting material, not a chemistry model.

| Mechanic | Proposed behavior |
|---|---|
| Industrial feedback | Extraction, waste heat, and returned contaminants increase convection and storm intensity |
| Factory response | Scale surge protection, limit extraction, or research storm mitigation |
| Long-term mitigation | Removing dissolved metals can weaken the dynamo |
| Short cycles | Lower intensity, rising intensity, peak, and recovery; storms remain active |
| Cycle candidates | Sine cycle, random superstorms, and longer seasons above the day/night baseline |
| Baseline metric candidates | Extraction rate, machine count, or cumulative hydrocarbons processed |
| Forecast | Expose storm information so the player can prepare |

## Lightning and overload

Power poles collect lightning; there is no separate player-built collector.
Each pole has one native collector. Collection reach is 10 tiles for ordinary
poles, 20 for substations, and 30 for pylons.
Other mods' poles use the ordinary tier-1 profile.

| Pole tier | Strike energy captured | Buffer | Maximum output |
|---|---:|---:|---:|
| 1 | 20% | 200 MJ | 100 MW |
| 2 | 40% | 400 MJ | 200 MW |
| 3 | 60% | 600 MJ | 300 MW |
| 4 (ordinary poles only) | 80% | 800 MJ | 400 MW |

There is no idle drain. Each full buffer supplies maximum output for 2 seconds.
Fast replacement retains stored energy up to the new capacity. Larger outputs
need more storage charge capacity or grounding coils to prevent overload.
`fulgora-collector-tiers` checks native collection reach, energy, discharge,
and charged replacements for all ten pole tiers.
Pole placement, blueprint revival, replacement, cloning, movement, and removal
maintain the collector. Existing poles receive collectors when the mod updates.
Native supply areas determine electricity sharing, including between forces.
Overload protection is active on Fulgora. Overlapping unwired grids form one
shutdown group. Each affected force receives map alerts. A player can reset the
whole group from any pole owned by their force.
A trip plays an alarm for connected players in each affected force. Alert
refreshes do not repeat the sound; simultaneous trips play one alarm per player.
Lightning must interrupt production without destroying the factory.

```text
lightning -> pole collector -> electrical network
  -> sufficient absorption: store energy or consume it
  -> overload: switch the network offline
  -> manual reset from any pole in the affected network
```

| Protection | Role | Cost or constraint |
|---|---|---|
| Grounding coil | Discharge excess electricity into conductive slurry beneath the sand | Tertiary priority; sand placement; spaced like wind turbines |
| Priority sink | Maintain storage headroom through steady consumption | Secondary priority; can cause calm-period shortages |
| Reset grace period | Prevent immediate repeat trips | Allow 120 ticks after manual reset |

Absorption must account for both available capacity and charge rate. Too few
sinks cause overloads; excessive consumption leaves insufficient stored power.

Check each network every 30 ticks. On 2.1, compare offered primary, secondary,
and solar energy against twice the requested energy across all input priorities.
Trip only if offered power also exceeds requested power by more than 1 MW.
Exclude accumulator discharge from the offered sum. This uses the latest tick,
not the whole 30-tick interval. Short pulses between samples can be missed.

### Grounding coils

| Property | Value |
|---|---|
| Function | An electrode conducts excess electricity into buried slurry; the energy becomes underground heat |
| Visual target | Low ceramic base, thick conductive windings, and a central ground electrode; small arcs and a dull orange glow under load |
| Temporary graphics | Reuse the vanilla lightning collector graphics for the grounding coil |
| Placement | Fulgora sand only; use the wind-turbine collision fields, including mutual exclusion with turbines |
| Power | 400 MW / 1.6 GW / 6.4 GW surge demand; no power output |
| Unlock | Primitive Filtration for tier 1; Grounding Coils 2 and 3 for higher tiers; no boxed recipes |
| Inputs and outputs | Electricity only; no fluid supply or waste-disposal chain |
| Recipe | 20 stone bricks, 20 aluminum wire, and 10 aluminum plates; 5 seconds; hand crafting or small assembler |
| Insufficient capacity | The shared grid trips when its overload thresholds are exceeded |
| Upgrades | Default planner: 1 → 2 → 3; custom mappings permit replacement between tiers |

All tiers have the same footprint and wind-turbine spacing. Higher tiers use
blue and violet tints. Each upgrade recipe consumes one previous-tier coil.

| Tier | Other recipe inputs | Research prerequisites | Science cost |
|---|---|---|---|
| 2 | 80 aluminum wire, 40 steel plates, 20 glass | Overcharged Assembly 2; Steelmaking 1 | 200 EM, 40 electrical; 10 × 45 s |
| 3 | 160 aluminum wire, 80 steel plates, 40 insulation | Grounding Coils 2; Overcharged Assembly 3; Insulation 2 | 800 EM, 160 electrical, 320 chemical, 160 physics; 20 × 60 s |

Recipes take 10 seconds in medium crafting and 20 seconds in large assembly.
The `fulgora-coil-upgrades` scenario checks native robot upgrades, custom
planner downgrades, spacing, recipe execution, power demand, and removal.

### Starter power balance

| Property | Value |
|---|---:|
| Tier-1 collector capacity / maximum output, per pole | 200 MJ / 100 MW |
| Full-buffer discharge at maximum output | 2 seconds |
| Grounding coil demand | 400 MW |
| Four coils: protection with full batteries and no factory load | 32 charged tier-1 poles |
| Four starter batteries: capacity / charge / discharge | 60 MJ / 200 MW / 2 MW |
| Battery tiers 1 / 2 / 3: charge rate | 50 / 100 / 200 MW |
| Starter process machines and lab, all active | 7.13 MW |
| Same machines, idle drain | 0.247 MW |

The charge rates apply on all planets. Battery capacity and discharge rates
stay the same. Supercapacitors retain their charge-rate multiplier.
Coils and batteries share tertiary power. Faster charging lets batteries store
a useful part of each pulse before coils discharge the remaining energy.
The overload thresholds stay at twice demand and more than 1 MW excess.

The `fulgora-starter-power` scenario uses seed 1729 and three isolated grids.
Each has 32 poles, four coils with legal spacing, four empty batteries, and a
500 kW test load. One initial strike starts each grid. Native storms then supply
ten minutes at noon and ten minutes at midnight. All three grids remain powered
at every 30-tick sample and do not trip. Native consumption totals confirm
300 MJ delivered to each load per ten-minute period. Removing coils and striking
a grid with full batteries triggers shutdown. This checks starter power at 500 kW; the full
7.13 MW machine fleet needs more supply and battery discharge capacity.

The `fulgora-power-budget` experiment retains the old charging baseline and
compares two-second pulses with different coil and charging rates. Slow charging
with large coils can prevent trips but leave the factory without power.
Run `tools/analyze_fulgora_power.py` with
`tests/progression/planner/fulgora-power.json` and `--output REPORT.json`.
Pass the experiment runner JSON with `--native-results` for measured results.
Run `python tools/test_fulgora_overload.py --case fulgora-grounding-coils`
to check coil construction, removal, and reload.

## Energy storage

Supercapacitors are an alternate mode of all three grid battery tiers.
Research costs 100 EM and 40 electrical science packs. It requires Primitive
Filtration and Battery Storage 2; each mode also requires its ordinary battery recipe.

| Storage | Charge/discharge rate | Capacity | Loss | Role |
|---|---|---|---|---|
| Supercapacitor | 10× normal rate | 20% of normal capacity | 1% of full capacity per second | Handle short power bursts |
| Accumulator | Fast charge; normal discharge | Medium | Low | Supply the gaps between strikes |
| Thermal storage | Slow | High | Low storage loss; conversion loss | Supply extended calm periods through Stirling conversion |

Both modes use native accumulator charge and discharge. Neither supplies surge
consumers nor charges other accumulators. Supercapacitor leakage also applies
when idle or disconnected.

Thermal storage and Stirling conversion remain a separate proposal. Stored oxygen
and fuel provide a combustion option; combustion is not required to start it.

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
| Electromagnetic science | Basic, improved, and improved boxed recipes below |
| Global electromagnetic rewards | Overcharged assemblers; polymers and organic electronics supply their components |
| Post-scout directed-energy devices | Lasers and beam weapons using petrochemistry, organic optics, and polymer waveguides |
| Shared endgame contribution | Exotic polymer focusing lens |

### Electromagnetic science recipes

All three recipes are implemented. Primitive Filtration unlocks basic EM;
Overcharged Assembly 2 unlocks improved EM; tier 3 unlocks boxed EM and packing.

| Recipe | Ingredients | Output | Craft time | Minimum overcharged tier |
|---|---|---|---|---:|
| Basic | 2 iron plates + 4 insulated wire + 2 graphite | 1 EM pack | 20 s | 1 |
| Improved | 1 capacitor + 1 logic circuit + 2 insulated wire | 5 EM packs | 15 s | 2 |
| Improved boxed | 1 capacitor box + 1 logic circuit box + 2 insulated wire boxes | 5 EM boxes | 75 s | 3, medium or large |

The basic recipe uses an iron core, insulated winding, and graphite electrodes.
The improved recipe adds capacitor and circuit production: aluminum sheet,
alumina, plastic, and silicon processing.

- Primitive Filtration uses ordinary science to unlock the basic recipe.
  Tier-1 overcharged modes have no separate research gate.
- Basic EM packs fund Overcharged Assembly 2. Improved EM can then fund tier 3.
  Neither upgrade requires its own recipe output.
- Only overcharged assemblers can make EM science. Higher tiers retain recipes
  from lower tiers. Machine size is a separate requirement for boxed production.
- Restrict all three recipes to Fulgora through its electromagnetic-field property.
- Exclude transformers from this upgrade; their current unlock requires Energy
  Distribution 3 and its power-research prerequisites.
- Each box contains five items. Boxed crafting has the same material and time
  ratios as improved crafting. Packing and unpacking do not gain productivity.

Basic recipe balance (`tests/progression/planner/fulgora-em-capacity.json`):

| Packs/min | Tier-1 small assemblers | Assembly power | Plates/min | Wire/min | Graphite/min |
|---:|---:|---:|---:|---:|---:|
| 30 | 17 | 10 MW | 50 | 100 | 50 |
| 60 | 34 | 20 MW | 100 | 200 | 100 |
| 120 | 67 | 40 MW | 200 | 400 | 200 |

Includes native +20% productivity and drain; excludes upstream production.
The starter-fleet model (`fulgora-em-bootstrap.json` in the same directory)
gives a 4.2-minute work lower bound for 12 packs from slurry, versus 7.5 minutes
for electrical packs. It uses mean mineral yields, eight tanks, both starter
assemblers in overcharged mode, and continuous external power. It excludes
construction, transport, process startup, and lightning outages. Extractors and
assembly limit this batch. A 60-second craft needs 10 minutes; half-price inputs
need 3.3 minutes. Keep the full material cost and use the 20-second craft.
Bulk production uses the improved tier-3 route. At 60 packs/min, final assembly
needs three tier-2 small assemblers and 26.96 MW. Tier-3 medium assembly needs
one machine and 344.06 MW, plus one unpacker for boxed output. These figures
include native productivity and drain; they exclude upstream material production.
The comparison is `tests/progression/planner/fulgora-em-upgrades.json`.

### Overcharged assemblers

Implemented: eight electric assembler variants usable on all planets. Small and
medium assemblers cover tiers 1–3. Large assembler 1 is tier 2; large assembler 2
is tier 3. Overcharged Assembly 2 and 3 unlock the higher modes.
Upgrade planners keep overcharged mode and use ordinary assembler items.
Robot upgrades and downgrades retain compatible recipes.

| Tier | Built-in productivity | Power consumption |
|---|---:|---:|
| 1 | +20% | 10× |
| 2 | +40% | 100× |
| 3 | +60% | 1000× |

Power multipliers apply to the corresponding ordinary assembler's working power
and idle drain. Crafting speed and module slots stay the same. Only overcharged
variants add EM categories for their tier. Small assemblers cannot make boxed EM.
All variants use surge priority and the shared productivity constants. Excluded
recipes have a zero productivity cap, including boxing and unboxing.

| Research | Prerequisites | Total science cost | Units × time |
|---|---|---|---|
| Overcharged Assembly 2 | Primitive Filtration; Automation 2 | 200 EM, 40 mechanical, 40 electrical | 10 × 45 s |
| Overcharged Assembly 3 | Overcharged Assembly 2; Automation 3 | 800 EM, 160 mechanical, 160 electrical, 320 chemical, 160 physics | 20 × 60 s |

Each higher mode also requires its ordinary construction recipe. Large assembler
1 therefore requires Mass Production 3. Tier 3 follows physics through Automation
3. Ordinary Nauvis research has no new Fulgora dependency.

Reference: Vulcanus Thermal Engineering 2 and 3 cost 800 and 3,200 metallurgic
packs. Use the same fourfold increase and research-unit times. EM costs one
quarter as many planetary packs. Tier 2 uses basic EM; tier 3 can use improved EM.
The resolved comparison is `tests/progression/planner/overcharged-research.json`;
it excludes ordinary prerequisite research and includes tier 2 in tier-3 totals.

Chemical plants, refineries, and hydro plants are reserved for other planets.
Keep the existing electrolyzer progression unchanged.

### Mode switching

Ctrl+R switches unlocked assembler modes. On Vulcanus, pneumatic research adds
a mode: ordinary → pneumatic → overcharged → ordinary. Skip overcharged mode
until its research and ordinary recipe are unlocked.
Leaving pneumatic mode releases fuel remaining in the engine; recipe fluids stay.
Leaving overcharged mode cancels exclusive recipes and returns their items on
the ground. Compatible recipes retain their work.
Ctrl+R also switches unlocked grid batteries to supercapacitor mode.

| Building | Modes |
|---|---|
| Grid battery, each tier | Normal accumulator ↔ supercapacitor |
| Assembler, each size and tier | Ordinary ↔ overcharged |

Each pair shares its construction item and footprint. Blueprints retain unlocked
modes. Locked variants become ordinary buildings when placed, revived, or cloned.
Preserve stored energy in joules, capped at the destination's capacity; discard
excess energy. Switching must never create energy.

For assemblers, preserve compatible recipes, contents, modules, and connections.
Crafting and productivity progress retain only work already done. Stored energy
and health must not increase when the mode changes. When EM recipes are added,
clear an incompatible recipe on return to ordinary mode.

## Physics progression analysis

Factorio 2.1.20; fresh resolved prototypes. Repeat with
`tests/progression/planner/fulgora-science-scale.json` and
`tools/plan_factorio_factory.py`. Use `tools/analyze_fulgora_industry.py` for
machine, material, and power details. The factory skill lists the commands.

Subsurface fluid extraction accepts 5000 slurry or volcanic gas, or 1250
compressed volcanic gas. Mixed production counts proportionally across all force
surfaces. Slurry extraction satisfies the local gate before Climatology 2 →
Water Filtration 3 → Distillation 2 → Sulfur Processing 1 → Waste Reclamation.

Players can manually delete excess fluid during startup. Storage pressure is
not a progression blocker. No-void checks assess automated waste handling.

The fixed-arrival batch model also cannot supply Water Filtration 3,
Distillation 2, Limestone Processing 2, or Waste Reclamation within the starter
tank allocation. These cases exclude intermediate research and fleet expansion;
they establish storage pressure, not an additional absolute progression lock.
The extractor-research case with unrestricted hydrocarbon storage retains
165,228 filtered hydrocarbons, 10,000 benzene, and 9,606 wastewater.

Iron-ore and bauxite checkpoints accept crushed ore at their crushing ratios
(6/5 and 7/5 raw units per crushed item). Sandstone and limestone already accept
sand and crushed limestone. Raw-ore and bloom alternatives remain available.

Argon is available through local residual-gas separation. Sand and sulfuric acid
supply rutile. Borate leaching supplies boric acid. All materials for physics
and process construction are locally available in the declared research model.

### Building bootstrap

`tools/audit_factorio_building_bootstrap.py` with
`tests/progression/fulgora-building-bootstrap.json` checks the wreck fleet,
physics-plan machines, logistics, power equipment, and checkpoint materials.
Pass a fresh factory plan with `--plan` and an output path with `--output`.
All 88 targets pass, including 63 placeable items. Research and crafting machines
become available in dependency order; no later machine is supplied as a seed.

Extractor construction needs a well item, but does not need to place the well.
Water canisters come from burning hydrogen canisters in a compatible vehicle.
Construction-only relays use the normal relay item.

This checks material and research order with external electricity and manual
surplus disposal. Crude filtration permits probabilistic drops. It does not
measure finite starter quantities, checkpoint actions, or power supply.

### Factory capacity

The following case uses only local slurry and assumes research checkpoints are
complete. It does not prove the order of research and factory construction.
Targets are equal rates of geology, climatology, mechanical, electrical, chemical, physics, and EM packs.
EM production is included for planet development; the ordinary physics unlock
does not require EM packs. The catalog uses tier-1 extractors, tier-1/2 processing,
large assembler 1, and tier-1 overcharged assembly. No modules or beacons.

| Packs/min each | Stations, including labs | Labs | Average demand | Installed demand | Research supply bound |
|---:|---:|---:|---:|---:|---:|
| 30 | 603 | 20 | 187 MW | 293 MW | 32.57 h |
| 60 | 957 | 40 | 368 MW | 465 MW | 16.29 h |
| 120 | 1,689 | 80 | 731 MW | 821 MW | 8.14 h |
| 240 | 3,167 | 160 | 1,456 MW | 1,542 MW | 4.07 h |

Physics research alone after Primitive Filtration needs 58,126 geology, 56,594
climatology, 55,451 mechanical, 50,977 electrical, and 46,341 chemical packs.
The selected factory routes raise these totals to 58,626 geology, 57,594
climatology, 55,951 mechanical, 51,477 electrical, and 47,342 chemical packs.
Times in the table include the selected routes and assume
all lines operate from the start. They exclude construction, checkpoint work,
transport, and power interruptions. They are not arrival-to-physics timings.

At 60/min: 174 extractors, 96 distilleries, 86 hydro plants, 55 medium furnaces,
50 electrolyzers, 56 chemical plants, 40 air filters, and 40 labs, plus assembly
and support. Gross flows: 104,029 slurry/min, 94,216 water/min, 86,314 oxygen/min.
Boric acid for operation and process construction comes from local sludge.
Climatology alone uses 30 hydro plants, 300,000 air/min, and 6,000 slurry/min.

The six-line case without physics needs 615 stations and 242 MW at 60/min.
Allowing tier-2 overcharged machines across the seven-line factory reduces it to
686 stations, but raises average demand to 1.66 GW and installed demand to
9.92 GW. The solver minimizes active machine time, not electricity or rounded
station count. Use overcharged modes selectively.

Fresh Vulcanus reference: 895 stations at 60/min and 1,518 at 120/min; research
supply bounds are 16.36 h and 8.18 h. That catalog uses pneumatic and thermal
machines and includes metallurgic science instead of EM. Entrance research also
differs. These are factory-scale references, not identical progression starts.

### Power and model boundaries

At 60/min, 312 MW is battery-compatible and 56 MW uses surge priority. Grid
batteries cannot supply the surge load. The ideal full-strike requirement is
110.4 tier-1 captures/min before clipping, grounding losses, and charge limits.
To cover the battery-compatible load, a full tier-1 bank needs 625 batteries
for a 30-second gap or 1,249 for 60 seconds. These gaps are sensitivity inputs,
not measured storm intervals. Logistics and power infrastructure are excluded.

Crude filtration uses mean independent yields. Other uncertain outputs use their
guaranteed yields. All liquid and solid outputs balance through real recipes;
there is no external waste sink. Process construction is feasible with
local materials. The solve does not establish startup order, buffer capacity,
vent availability, or a connected factory layout. Vents remain at 100% yield.

Audit at `60c9b0b` on Factorio 2.1.20: all local flow and process-construction
cases passed at 30, 60, 120, and 240 packs/min. Seven native scenarios passed:
physics executors (2714 assertions), checkpoints (64), filtration (309), borate
leaching (36), gypsum recovery (32), water recovery (70), and well placement (17).
The fresh executor fixture matches the tested fixture. Early science, starter
processing machines, and independent-acid prerequisite checks passed.
The research query is `tests/progression/balance/fulgora-research.json`, used
with `tools/audit_vulcanus_progression.py`. These checks do not execute a connected
arrival-to-physics campaign or prove that local lightning supplies the full load.

Validation: native borate leaching checks both recipe sizes, the research gate,
delayed water connection, exact outputs, and productivity restrictions. The
physics executor fixture checks the selected local production recipes. Executors
use declared inputs and a continuous test grid at Fulgora surface properties. The starter
power test covers 500 kW, not this industrial load. To validate industrial
throughput, place the selected factory and power network, supply finite starter
stock, and measure production, storage, surge duty, and checkpoint completion.

## Nuclear geoengineering

| Step | Proposed behavior |
|---|---|
| Prerequisite | Aquilo fusion research or imported Nauvis nuclear technology; choice unresolved |
| Deployment | Use nuclear charges as geological tools |
| Terrain change | Fracture the crust and expose large areas of hydrocarbon ocean |
| Construction | Use specialized foundations on unstable, fluid-rich terrain |
| Production | Replace limited fountain extraction with bulk surface filtration; expose deeper copper deposits |

The shared endgame also proposes repurposing these charges for orbital defence.

## Cross-planet effects

| Direction | Materials or role |
|---|---|
| Vulcanus to Fulgora | Bulk metals; iron chloride dopant |
| Fulgora to Vulcanus | Organics, polymers, and carbon materials |
| Nauvis or Aquilo to Fulgora | Water; nuclear equipment for geoengineering |
| Fulgora to other planets | Overcharged assemblers, electromagnetic research, advanced organics, copper, and rare traces |

Vulcanus supplies metals with pneumatic and thermal industry. Fulgora supplies
organics and late-game copper with intermittent electricity. Both lack natural
surface water.

## Pole collector experiment

`experiment-lightning-poles`: Factorio 2.0.77, 31 assertions, tick 240.
This experiment established the native mechanism used by gameplay collectors.

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
Gameplay coverage: `fulgora-pole-collectors` tests native power delivery, robot
builds, replacement, cloning, force changes, movement, removal, and surface clear/deletion.
`fulgora-pole-players` tests player builds, blueprints, mining, and multiplayer reload.

```bash
python tools/run_factorio_tests.py experiment-lightning-poles -n auto
```

## Engine candidates and validation questions

### Overload checks

Run `python tools/test_fulgora_overload.py` for the production scenario and a
reload from tick 102. Run `fulgora-grid-threshold` for the eight threshold cases.
Run `fulgora-grid-alerts` for two-client alerts, force changes, reload, and the
pole reset panel. The client test needs a display socket and loopback networking.

| Case | Required result |
|---|---|
| Trip threshold | Offered power > 2× requested power and excess > 1 MW; equality does not trip |
| Storage | Charging demand protects the grid; full storage does not; discharge does not trigger overload |
| Native lightning | An unprotected collector burst triggers a trip |
| Split / merge | Both split parts retain the fault; merging propagates it |
| Remove anchor / sink | Restore one sink per faulted native network |
| Replace pole | Retain the fault after fast replacement |
| Clone sink | Remove the copied consumer |
| Save / reload | Retain faults and complete the same topology and reset checks |
| Reset | Reset the current shared group; allow 120 ticks before another trip |
| Alert | Anchor the map alert to the sink; refresh while offline and remove on reset |
| Alert ownership | Notify every force with a pole in the shared group; follow relocation and force changes |
| Overlapping unwired grids | Shut down together; allow reset from any owned pole in the group |
| Short pulse | An 8-tick pulse between samples is missed |

Each faulted native network gets a hidden 1 TW primary consumer at one of its
poles. Keep that anchor until it is removed or changes networks. Overlapping
coverage joins shutdown groups, including through intermediate grids. Native
supply areas cannot isolate a consumer from other grids that cover its position.
The check reads pole connections and aggregate flow; it does not read collector
buffers or use strike callbacks.

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

Production checks cover sink ownership after save/load, pole removal, network
splits, merges, and pole replacement. Fault state follows poles; native network
IDs identify only the current topology. Offline groups are not sampled. Reset
removes their consumers and starts the grace period.

| Area | Inherited candidate | Required check |
|---|---|---|
| Pole collectors | Implemented native hidden attractor | Lifecycle and native power delivery covered by collector scenarios |
| Storm control | `nullius-storm-intensity`, `LightningProperties.multiplier_surface_property`, `LuaSurface.set_property()` | Verify runtime frequency changes and select an update interval |
| Lightning tuning | Native night rate; 25% day rate; zero damage | Day/night activity and direct strikes tested on both engines |
| Strike effects | Native callbacks are available | Overload detection uses aggregate flow, with no strike callback |
| No destruction | Zero-damage Fulgora bolt | Direct strikes preserve both android tiers, hydro plants, crushers, poles, pipes, and chests |
| Overload detection | 2.1 aggregate offered energy versus requested energy | Test short surges between samples and tune the threshold |
| Network state | Pole fault state and current native parent networks | Split, merge, replacement, and reload checks |
| Offline network | Hidden 1 TW primary consumer per native network | Shared shutdown and reset for overlapping grids |
| Supercapacitors | Native accumulator rates and capacity; scripted stored-energy loss | Verified idle leakage; no surge supply or transfer to other storage |
| Sinks | `ElectricEnergyInterface` with surge or secondary priority | Verify actual excess-power absorption and spacing rules |
| Fountain filtration | Four fixed recipe products: two fluids and two solids | Check filter fluid connections and output slots; set yields and prove a complete local bootstrap |

No engine performance, production-rate, or completion-time claim is established
by these inherited candidates.
