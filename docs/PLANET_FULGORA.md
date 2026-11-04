# Fulgora design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Planet, terrain, probe access, hydrocarbon vents, slurry extraction, primitive filtration, salt crushing, and sand construction rules implemented |
| Reservoir processing | Extractor reinjection mode and magnetic sludge filtration implemented; see [Reservoir reinjection](#reservoir-reinjection-and-stream-balancing) |
| Surge power | Lightning collectors, overload protection, and circuit-controlled grounding; see [Metered grounding](#metered-grounding) |
| Tier-2 climatology | Implemented; see [Storm climatology](#storm-climatology) |
| Planet mechanics and constraints | This document; extracted from the Space Age brainstorm |
| Shared progression, cargo, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |

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

Supplied once per force when the probe is activated. Equipment quantities are
defined in the shared starter inventory used by probe reactivation.

| Equipment | First use |
|---|---|
| Extractor 1 | Slurry extraction or surplus liquid reinjection |
| Hydro plant 1 | Slurry filtration, crude filtration, brine, climatology |
| Distillery 1 | Ice melting, hydrocarbon cracking, air separation; reuse for other recipes |
| Air filter 1 | Nitrogen and climatology |
| Chemical plant 1 | Acids and polymers |
| Electrolyzer 1 | Water and brine electrolysis |
| Crusher 1 | Mineral processing and surplus crushing |
| Small furnace 1 | Early smelting |
| Medium furnace 1 | Smelting with gas output, including gypsum decomposition |
| Foundry 1 | Metal parts |
| Small assembler 1 | Equipment and science |
| Flotation cell 1 | Silica and dust treatment |
| Combustion chamber 1 | Consume surplus benzene with oxygen |
| Chimney 1 | Vent permitted gases; reuse for different gases |
| Lab 1 | Local research |
| Cliff explosives | Clear cliffs for the starter factory |
| Small electric pole | Lightning capture and distribution |
| Pylon 1 | Wider lightning capture and longer power connections |
| Pump 1 | Move fluids between processing lines |
| Pipe / underground pipe | Connect separate fluid networks |
| Small tank 1 | Buffer fluids during construction and recipe changes |
| Medium tank 1 | Store surplus fluids |
| One-way valve | Direct recovered fluids |
| Transport belt / inserter | Solid transport |
| Splitter / underground belt | Split belts and cross processing lines |
| Grid battery 1 | Additional electric storage |
| Grounding coil | Discharge surplus power |
| Small chest 1 | Placed salvage chests and packed chests; separate filtration outputs and equipment |
| Small chest 2 | Packed in the wreck; extra storage |

Keep processing machines in the wreck. Put logistics supplies in the
salvage chests so the kit fits in the available inventory.

No ore, science packs, fuel, or bottled fluids. Keep the equipped probe android.
Poles include lightning energy buffers; grid batteries add storage.
Spread the collectors and connect them before processing.
Build filters and other restricted machines on islands; route pipes to sand vents.

This is seed equipment, not a complete science factory. Reproduce ordinary
buildings locally, then research extractor expansion. Support-machine routes
pass `@tests/progression/fulgora-bootstrap-support.args`. Validate the kit with a finite-inventory scenario before treating the complete
bootstrap as proven.

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
imports. Liquids leave only through recipes or extractor reinjection.

### Initial production time

`tools/plan_factorio_bootstrap.py` uses
`tests/progression/planner/fulgora-bootstrap-timing.json` and fresh prototypes.
The results below use the seven-extractor kit and one android, from zero stock,
on Factorio 2.1.23.
Expansion kit: 1 hydro plant, 1 distillery, 4 air filters, 50 pipes, 50 belts,
10 inserters, and 8 poles. New machines do not operate during these batches.

<!-- bootstrap-timing:start -->
| Target | 100% vent yield | Survey high yield | Survey low yield |
|---|---:|---:|---:|
| 20 iron plates + 20 aluminum plates | 2.5 min | 2.3 min | 2.6 min |
| Expansion kit | 4.6 min | 4.3 min | 4.8 min |
| 10 of each early science pack | 4.9 min | 4.9 min | 4.9 min |
| Expansion kit + first science | 9.1 min | 9.1 min | 9.1 min |
<!-- bootstrap-timing:end -->

These are fractional-work bounds with mean mineral yields and continuous power.
They exclude placement, recipe-change delays, research bonuses, resource depletion,
and startup order. Tanks limit final surplus, not peak fluid volume. The survey
uses the nearest three usable vents from the origin in twelve seeds on 2.1:
94.0–199.2% mean yield. It does not cover every map or probe landing position.

At half machine duty, expansion plus first science requires 17.6 min of work.

### Building bootstrap time

The results below use the seven-extractor kit and one android, on Factorio 2.1.23.
The eight small tanks and two medium tanks provide 50,000 filtered-hydrocarbon
storage and 10,000 each for six other liquids. No imported materials.

| Independent target | 100% vents | Sampled yield range | 50% machine duty |
|---|---:|---:|---:|
| First medium assembler | 0.7 min | 0.6–0.7 min | 1.4 min |
| One of each arrival building/logistics type, plus medium assembler | 7.3 min | 6.8–7.6 min | 14.5 min |
| Reproduce the supplied processing fleet, excluding extractors | 12.7 min | 11.8–13.1 min | 24.0 min |

The arrival-type target excludes extractors and grid batteries. Extractors need
motor 2 through pump 2 and well 1; build a medium assembler for the lubricant
input. With that assembler's construction and research included, one additional
extractor needs 99.2 lab-minutes and a 121.4 min production work bound.
Reinjection keeps the surplus within the starter tank allocation.

Reproducing every starter building type also needs grid-battery research,
a compressor, a barrel pump, and medium furnace 2. The deliberately fixed-fleet
case needs 3,707 min of production and 3,946 lab-minutes. This is a counterfactual
capacity warning: expand extraction, processing, and labs before that research.
It is not a normal-play duration. All 63 building types used through physics
have a local material and research path in the separate reachability audit.

The processing-fleet batch saturates the extractor, flotation-cell, medium-furnace,
small-assembler, and android work budgets. See the shared-pool table below.

These are mean-yield work bounds. They omit recipe startup order, fluid fill,
transport, placement, and power interruptions. Research-bound cases permit the
listed research and costed new machines from time zero, then count their science,
lab work, and construction. The ten batteries do not prove continuous power.

Repeat with `tools/plan_factorio_bootstrap.py` and the
`fulgora-building-timing.json`, `fulgora-extractor-building-timing.json`, and
`fulgora-self-reproduction-timing.json` configs in `tests/progression/planner/`.

### Mineral recovery comparison

Historical comparison with the smaller starter fleet and eight small tanks:

The recipe now returns 3 items per successful drop, with a 25% chance for each
mineral. There is no boxed crude filtration recipe. The planner compares absolute drop amounts.
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
| Basic separation | Distillery | 100 air → 80 nitrogen + 19 CO2 | 1 s |
| Advanced separation | Distillery | 100 air → 80 nitrogen + 19 CO2 + 1 residual gas | 1 s |
| Argon recovery | Distillery | 50 residual gas → 50 argon | 5 s |

Use the existing air and residual-gas fluids. Fulgora separation requires
`magnetic-field = 99`; generic air separation, oxygen recovery, residual-gas
enrichment, and water-producing residual separation are excluded there.
The destination surface sets the separation recipe, including for imported gas.

Basic separation unlocks with Primitive Filtration. Air Separation 2 unlocks
advanced separation and argon recovery. Their compressed variants unlock with
High Pressure Chemistry; they use the same amounts of compressed
fluids and take 2 s and 10 s. Gas recipes have no boxed variants.
Use existing gas vents for surplus products. Hydrocarbons still come from slurry.

Air filters retain their capture recipe and require island ground. Include one
in the planned starter kit. The air filter, distillery, and chimney have local
reproduction routes under `@tests/progression/fulgora-atmosphere-equipment.args`.
Slurry climatology uses the captured air without seawater.

## Helium

Helium light enough to escape leaves none in the atmosphere, so it
comes from the primordial hydrocarbon ocean, where it stays dissolved through
filtration. Slow, cold fractionation during cracking recovers it as the lightest
fraction. Rocket closure needs it for heat pipe 3 and
processor 2; see [Cargo closure](SPACE_AGE_BRAINSTORM.md#cargo-closure).

| Property | Rule |
|---|---|
| Recipe | Degassing cracking: the hydrocarbon cracking outputs plus a small amount of helium; slower than ordinary cracking |
| Machine | Distillery, as ordinary cracking. Helium takes its third fluid output |
| Unlock | Hydrocarbon degassing, Fulgora research costed mainly in electromagnetic packs. It requires Overcharged Assembly 2 and Air Separation 3, the normal helium unlock, which also unlocks compression |
| Helium checkpoint | Not a prerequisite: it requires helium production, which degassing supplies on a planet with no other route |
| Surface condition | None. Filtered hydrocarbons come only from Fulgora slurry, and shipped hydrocarbons carry their helium with them |
| Bulk variant | Boxed degassing cracking: the boxed cracking outputs plus compressed helium, slower than boxed cracking; compressed methane, benzene, and compressed helium fit the distillery's three fluid outputs. Bulk hydrocarbon degassing research requires Hydrocarbon degassing and Bulk hydrocarbon cracking. The first launch does not depend on it |
| Surplus | The existing helium vent; a full helium output stalls the recipe, so ordinary cracking stays the bulk route |
| Cost | Helium arrives with methane and benzene. Methane can vent; benzene has no chimney, so surplus goes to combustion or reforming, both paid in water |

| Exploit vector | Closure |
|---|---|
| Reprocessing | Only slurry filtration produces filtered hydrocarbons and the recipe returns none, so each unit degasses once |
| Reinjection | Removes filtered hydrocarbons, has no outputs, and does not change vent yield |
| Stream balance | Same output vector as ordinary cracking, so it opens no new ratio between methane, benzene, and graphite |
| Rejected: returning filtered hydrocarbons | Feeding the output back in converts a whole batch to helium |
| Rejected: helium from slurry filtration | Hydro plants have two fluid outputs, both used by filtration |

Validation: `tests/progression/fulgora-launch-closure-helium.args` checks that the
local rocket path and research packs are reachable with the implemented recipes.
The `fulgora-helium` scenario checks research gates and production on Fulgora, for
ordinary and bulk recipes on every distillery tier. Recipe values live in
`nullius-star/prototypes/planet/fulgora-recipes.lua` and research values in
`fulgora-technology.lua`.

## Sand construction

| Location or object | Rule |
|---|---|
| Hydrocarbon vents | Native oil graphics; generate only on sediment; existing extractors produce hydrocarbon slurry |
| Vent distribution | More, smaller clusters: 28.8 base patches/km²; total base density remains 65.6 |
| Buildings permitted on sand | Extractors, including reinjection mode, power poles, pipes, underground pipes, pumps, elevated rail supports, and grounding coils only |
| Radio dishes | Design: permitted on sand; see [Radio astronomy](#radio-astronomy) |
| All other buildings | Require island ground, including filters, tanks, power storage, belts, and rail ramps |
| Elevated rails | Bridge sand basins between islands on rail supports |
| Sand | Both android tiers can walk across it; no landfill, paving, or terraforming |
| Vent coverage check | At least three usable vents within 256 tiles of the origin on twelve fixed seeds; `fulgora-vent-coverage`. Measured on 2.1.23: 12–33 usable vents per seed; nearest 38–92 tiles |
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
| Tests | `fulgora-mapgen`, `fulgora-terrain`, `fulgora-activation`, `fulgora-shared-body`, `fulgora-probe-alignment`, `fulgora-rail-supports`, `fulgora-extraction`, `fulgora-walking`, `fulgora-vent-coverage`, `fluid-resource-products`, `fulgora-helium` on Factorio 2.1 |

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
                           -> degassing cracking -> same products + helium [researched]
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
sludge -> magnetic sludge filtration -> iron- and bauxite-rich minerals
surplus filtered hydrocarbons, sludge, wastewater, brine
  -> extractor reinjection mode -> returned to the vent
```

Primitive Filtration requires probe access and Geology 2: 5 of each early science pack,
15 seconds per unit. It unlocks the ordinary recipes below.
Mass Production 4 unlocks boxed ice melting, salt crushing, and salt dissolution.
Packaging 3 unlocks ice packaging and unpacking. Crude sludge filtration has no
boxed recipe.

| Specialized research | Prerequisites | Total cost | Unlock |
|---|---|---|---|
| Bulk slurry filtration | Overcharged Assembly 2, Packaging 3 | 200 EM + 40 each climatology, electrical, chemical | Boxed slurry filtration |
| Bulk hydrocarbon cracking | Overcharged Assembly 2, Packaging 3 | 200 EM + 40 each climatology, electrical, chemical | Boxed hydrocarbon cracking |

Each research has 10 units at 45 seconds per unit.
Bulk cracking returns 75 compressed methane instead of 300 methane per batch.

| Recipe | Input | Output | Time | Machine |
|---|---|---|---|---|
| Slurry climatology | 5000 air + 100 hydrocarbon slurry | 1 climatology pack | 60 s | Hydro plant 1 |
| Slurry filtration | 100 hydrocarbon slurry | 50 filtered hydrocarbons + 40 sludge + 2 ice + 1 salt | 4 s | Hydro plant 1 |
| Crude sludge filtration | 50 sludge | Independent chance of 3 each: crushed iron, crushed bauxite, sand, calcium carbonate, stone, gypsum (25% each) | 2 s | Hydro plant 1 |
| Salt crushing | 1 salt | 1 mineral dust | 1 s | Crusher 1 |
| Ice melting | 1 ice | 20 water | 2 s | Distillery 1 |
| Salt dissolution | 6 salt + 45 water | 65 brine | 1 s | Hydro plant 1 |
| Hydrocarbon cracking | 50 filtered hydrocarbons | 60 methane + 12 benzene + 2 graphite | 4 s | Distillery 1 |

Degassing cracking is a slower cracking variant that also yields helium; see
[Helium](#helium).

Boxed recipes consume five times the input and time; each solid output is a box
of five. Productivity is disabled. These recipes work on every planet.
Gypsum crushing uses a crusher: `1 gypsum -> 1 mineral dust` in 1 second.
Waste Management unlocks it; Mass Production 7 unlocks the boxed recipe.
Dissolve surplus dust with hydrochloric acid and return the sludge to filtration.
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

Fulgora has no outfall voiding. The only liquid sink is extractor reinjection of
four reservoir liquids (see
[Reservoir reinjection](#reservoir-reinjection-and-stream-balancing)). Use
existing chimney recipes for gases; no new venting whitelist is required.
Storage does not remove a continuous surplus.

| Existing route | Output or constraint |
|---|---|
| Gas vents | Hydrogen, oxygen, nitrogen, air, argon, helium, CO, CO2, SO2, methane, ammonia, steam, residual gas, trace gas, volcanic gas, and deuterium; compressed vents exist for several gases |
| Chlorine, HCl, ethylene, propene, benzene | No direct chimney recipe |
| HCl + caustic solution | Brine; boil brine to salt + ventable steam |
| Caustic solution + CO₂ | Caustic carbonation in a chemical plant produces wastewater for reinjection; Inorganic Chemistry 1 unlocks this route |
| Wastewater filtration | Saline + sludge; boiling saline produces steam + brine |
| Wastewater boiling | Steam + sludge; does not remove the sludge problem |
| Sludge dehydration | Mineral dust + steam + CO; requires high-pressure chemistry 2 and physics science |
| Organic combustion | Existing ethylene, propene, benzene, methanol, and diesel recipes consume oxygen and produce steam + CO2 |
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
The ordinary mineral recovery recipes, borate leaching, and barrel recycling
unlock together. Bulk Waste Reclamation unlocks boxed variants of all these
recipes. It requires Waste Reclamation, Overcharged Assembly 2, and Packaging 4,
and uses electromagnetic science. The recipes work on all planets. Gypsum recovery
excludes productivity; its boxed recipe uses compressed oxygen. Limestone and stone recovery use water instead
of freshwater.
The Fulgora science planner checks local supplies, reagents, and recycle streams
without imports, solid discard, or liquid outfall disposal.

Crude sludge filtration supplies gypsum without acid. Selective recovery uses
oxygen from water electrolysis. Existing
recipes provide `2 gypsum -> 1 lime + 10 SO2`, then
`8 SO2 + 16 water + 4 oxygen -> 20 sulfuric acid`. Decomposition unlocks at
limestone processing 2, before chemical science; a boxed recipe also exists.
Bauxite recovery returns SO2 but consumes sulfuric acid, so it cannot supply the
first sulfur input. Include
the lime output in the mineral balance; surplus SO2 can use the existing vent.

## Reservoir reinjection and stream balancing

Status: implemented. Planner evidence uses resolved prototypes with
`tests/progression/planner/fulgora-reinjection-timing.json`.

### Coupled streams

Historical five-extractor baseline before magnetic filtration and reinjection,
with unbounded hydrocarbon storage on Factorio 2.1.23:

| Coupling | Mechanism | Evidence |
|---|---|---|
| Fluids | Slurry filtration has one fixed output vector: 50 filtered hydrocarbons, 40 sludge, 2 ice (40 water), 1 salt | Water demand sets extraction: 418,320 slurry, 209,160 hydrocarbons, 45,932 cracked, 163,228 retained against 50,000 tank capacity |
| Minerals | Crude filtration returns six minerals in equal mean amounts; bauxite limits production | Surplus iron, sand, limestone, gypsum, and salt go to dust disposal |
| Sinks | The solid sink is `1 dust + 6 HCl -> 6 sludge + 5 CO2`; benzene combustion needs oxygen from water | Dust disposal uses 63,855 of 184,799 water (34.6%); returned sludge yields 0.54 minerals per disposed dust |

Every arrival sink is paid in water, and water arrives only with more
hydrocarbons and sludge. A stream can be balanced independently only when it has
a sink not paid in another coupled stream, or a source with a different ratio.

### Extractor reinjection mode

| Property | Contract |
|---|---|
| Entity | `nullius-extractor-N-reinjection`: assembling-machine shell with the extractor collision box (3.4 x 3.4, 4 x 4 tiles) and fast-replace group; the extractor output connection becomes an input; placed and mined as the extractor item |
| Switch | Ctrl+R on an extractor whose mining area contains a `nullius-hydrocarbon-vent`, on Fulgora, after Primitive Filtration; extractors on other resources have no reinjection mode |
| Vent use | Exclusive by construction: the vent hosts one extractor in either mode |
| Recipes | Filtered hydrocarbons, sludge, wastewater, brine; 20 units per 2 s; result `nullius-gas-void` with probability 0; `magnetic-field >= 99`; no productivity or boxed variant |
| Rate | 10 units/s on every extractor tier; independent of vent yield |
| Modules, beacons, quality | None |
| Power | 390 kW plus 10 kW drain, as extractor 1 |
| Switch contents | Destroy and recreate without fluid carryover, as the Vulcanus lava-intake gas vent. Discarded fluid is unmined slurry or an accepted reinjection liquid |
| Blueprints, clones, upgrades | On a vent with research: kept. On a vent without research: extractor. Off a vent: ghost removed, or entity removed and its item returned; built, robot, revive, clone, and script-raised paths |
| Sand placement | Extend the extractor exception in `nullius-star/prototypes/planet/fulgora-placement.lua` to reinjection variants |
| Starter kit | Seven extractors; currently five |

Benzene is excluded; the combustion chamber keeps its sink role.

### Magnetic sludge filtration

| Property | Value |
|---|---|
| Recipe | 50 sludge, 2 s, hydro plant 1, Primitive Filtration, `magnetic-field >= 99` |
| Results | 3 crushed iron ore and 3 crushed bauxite at 1/3 each; 3 sand, crushed limestone, stone, and gypsum at 1/6 each |
| Mean yield | 4.0 items per 50 sludge; crude filtration 4.5 |
| Productivity, boxed variant | None, as crude filtration |

Late-game dominance per 200 sludge:

| Route | Wanted items | Surplus per wanted item, single / iron+bauxite | Reagent |
|---|---:|---:|---|
| Crude filtration | 3 per mineral | 5 / 2 | None |
| Magnetic filtration | 4 iron + 4 bauxite | 3 / 1 | None |
| Selective iron recovery | 8 iron | 0.5 | Caustic solution |
| Selective bauxite recovery | 8 bauxite | 0.5 | Sulfuric acid |

Selective recovery stays twice as pure and targets each mineral separately.
Equal iron and bauxite shares of 1/2 with 1/8 for the others would match
selective purity; 1/3 and 1/6 keep a margin.

### Bootstrap effect

Independent fixed-fleet targets, 100% vents, mean yields, continuous power.
In `fulgora-reinjection-timing.json` every starter extractor shares its time
between extraction and reinjection mode (`shared_modes`). Mode switches are free,
as recipe changes are in every planner case. All values are work lower bounds;
they exclude startup, transport, placement, switch delays, and power interruptions.

| Target | Previous kit: five extractors, no reinjection or magnetic filtration | Seven extractors | Five extractors |
|---|---:|---:|---:|
| Expansion kit + first science | 13.3 min | 9.1 min | 10.6 min |
| Processing-fleet reproduction | 20.2 min | 12.7 min | 16.0 min |
| Volcanism 1 (extractor research) | infeasible | 122.9 min | 146.0 min |
| Water Filtration 3 | infeasible | 902.0 min | 1,237.0 min |
| Distillation 2 | infeasible | 992.6 min | 1,366.7 min |
| Waste Reclamation | infeasible | 1,582.0 min | 2,080.2 min |
| Limestone Processing 2 | infeasible | 1,861.1 min | 2,480.1 min |

Extractor pool time is extraction + reinjection. Bottlenecks are machine pools
at 100% utilization; both extractor modes count against one pool.

| Target | Seven: extractor pool | Seven: bottlenecks | Five: extractor pool | Five: bottlenecks |
|---|---:|---|---:|---|
| Expansion kit + first science | 88.9% + 0% | Android, flotation cell, hydro plant, medium furnace, small assembler | 100% + 0% | Android, extractor, medium furnace |
| Processing-fleet reproduction | 100% + 0% | Android, extractor, flotation cell, medium furnace, small assembler | 100% + 0% | Android, extractor, medium furnace |
| Volcanism 1 | 75.0% + 15.2% | Android, medium furnace, small assembler | 83.8% + 16.2% | Android, extractor, medium furnace |
| Water Filtration 3 | 71.9% + 28.1% | Android, air filter, extractor, medium furnace | 71.7% + 28.3% | Android, extractor |
| Distillation 2 | 71.7% + 28.3% | Android, air filter, extractor, medium furnace | 71.5% + 28.5% | Android, extractor |
| Waste Reclamation | 71.9% + 28.1% | Android, air filter, extractor, medium furnace | 71.4% + 28.6% | Android, extractor |
| Limestone Processing 2 | 71.6% + 28.4% | Android, air filter, extractor, medium furnace | 71.1% + 28.9% | Android, extractor |

Early targets use no reinjection. Seven extractors leave 9.8% pool slack at
Volcanism 1: survey-low yield gives the same 122.9 min, and half machine duty
236.8 min. Five extractors saturate the pool from Volcanism 1; seven saturate it
from Water Filtration 3. Fixed-fleet research times are counterfactual capacity
bounds; Volcanism 1 is the expansion point.

The seven-extractor kit also shortens early targets: expansion plus first science
drops from 13.3 to 9.1 min, including the magnetic filtration change.

### Exploit audit

| Vector | Closure |
|---|---|
| Value creation | No outputs; reinjection does not change vent yield |
| Arbitrary voiding | Four reservoir liquids only; chlorine, acids, benzene, alkenes, and copper concentrate excluded |
| Unbounded sink | One vent per reinjecting extractor at a fixed 10 units/s; each costs that vent's extraction. Dumping all hydrocarbons from the 104,029 slurry/min physics factory needs about 87 vents |
| Imported disposal | Recipes require Fulgora's magnetic field; other planets keep their own voids |
| Mineral transmutation | Stone through dust, HCl, and magnetic filtration returns 0.24 iron + bauxite per dust for 6 HCl |
| Energy or H/O loop | Removes water-bearing liquids and consumes power |
| Mode toggling | Discards only unmined slurry or an accepted liquid |

### Later recipes

| Later route | Effect |
|---|---|
| Selective recovery | Higher purity per mineral; see dominance table |
| Wastewater filtration, condensation | More valuable: reinjecting wastewater discards scarce water |
| Extractor tiers 2+ | Extraction rises; reinjection stays 10 units/s per vent |
| Bulk filtration and cracking | Unchanged output streams |
| Deep extraction and copper | Copper concentrate is not accepted |
| Nuclear geoengineering | Exposed ocean has no vent entities; bulk filtration processes its outputs |

Water remains the scarce stream. In the seven-extractor Waste Reclamation case,
1,770,111 filtered hydrocarbons and 94,767 wastewater return to vents.
Condensation and wastewater filtration reduce that extraction.

### Acceptance checks

| Check | Expected result |
|---|---|
| Starter kit | `probe.lua` supplies seven extractors; `fulgora-activation` checks seven; Fulgora planner fleets use seven |
| Mode switch | Hydrocarbon vent on Fulgora after Primitive Filtration only; no mode on Vulcanus gas vents |
| Recipes | Exact 20 units per 2 s for each accepted liquid on every tier; non-accepted liquids rejected |
| Lifecycle | Blueprint, robot, revive, clone, and upgrade placements follow the blueprint contract above |
| Sand | Reinjection variants place on sediment |
| Magnetic filtration | Exact probabilities, no productivity, Fulgora only |
| Planner | Resolved prototypes; Volcanism 1 feasible with starter tanks |

Validation: `fulgora-reinjection` checks mode switches, pipes, research gates,
placement, robot upgrades, and recipe execution on Factorio 2.1.

Repeat the planner evidence with:

```sh
python tools/plan_factorio_bootstrap.py --config tests/progression/planner/fulgora-reinjection-timing.json --output REPORT.json
```

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
| Storm intensity | Design: surface property `nullius-storm-intensity` scales native lightning and radio interference; cycles change only this value. See [Radio astronomy](#radio-astronomy) |

## Lightning and overload

Storms remain active by day and night, with weaker activity by day.
Power poles collect lightning and supply their electrical network. Larger poles
cover more ground; higher tiers capture and deliver more energy. Pole upgrades
retain stored energy up to the new capacity. Lightning does not damage buildings
or androids.

A grid trips when offered generation persistently exceeds its ability to absorb
power. Brief surges and small excesses do not trigger a shutdown. Factory demand,
storage charging, and grounding coils provide absorption. Full storage provides
no charging headroom. Stored energy alone cannot compensate for insufficient
charge or discharge rates.

A trip interrupts production and gives affected players an alarm and map alert.
Reset the grid from an owned power pole. A short grace period allows recovery
before overload detection resumes. Splitting, merging, or replacing poles does
not clear a fault. Overlapping unwired grids share shutdown and reset because
their supply areas can power the same consumers.

### Grounding coils

Grounding coils conduct electricity into the buried slurry as heat. They need
no fluid supply and produce no waste. Place them on Fulgora sand, with the same
spacing restrictions as wind turbines. Higher tiers absorb more power and
support the upgrade planner.

Coils share surge priority with overcharged machines and storage charging.
Permanently connected coils can take power that those machines need. Divide
coils into banks and use power switches to connect more banks as generation
rises, then disconnect them as it falls. Leave absorption headroom for changes
before the controller responds.

Keep switched banks outside the factory grid's supply areas so power cannot
bypass the switches. The poles in each bank also collect lightning; include
their output when sizing protection.

### Metered grounding

Grid batteries and supercapacitors can report offered generation and requested
power through circuit signals on Fulgora. Select the signals in the battery
interface; leave them unset to disable the meter. Players build the control
circuit and choose which coil banks to connect.

The meter reports the connected network, including any coil banks whose
switches are closed. Account for those banks when estimating factory demand;
otherwise the controller can repeatedly connect and disconnect the same load.
Battery charge alone does not show whether surge machines receive enough power.

Meter settings survive mode changes, blueprints, settings paste, and save/load.
An offline grid retains its last readings; use the overload alert to identify
a trip. Meters on the same circuit wire add their signals. A battery covered by
overlapping unwired grids reports its primary network.

## Energy storage

Grid batteries store lightning energy to supply ordinary machines between
strikes. Supercapacitors are a research-gated alternate mode: faster charging
and discharging, lower capacity, and greater leakage. Leakage continues while
idle or disconnected.

Both modes use native accumulator behavior. They cannot supply surge consumers
or charge other accumulators. Overcharged machines therefore need active
generation, while grounding control must leave enough of that power available.

Thermal storage with Stirling conversion remains a separate proposal for calm
periods. Stored oxygen and fuel provide a combustion option.

## Organic industry

Gear, reinforced gear, structural beam, tension cable, and fiber composite use
material-neutral display names. The recipes below preserve their item IDs and
grades. Other equipment alternatives in the table remain proposals.

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

Before adding a substitute, test ordinary and boxed routes on Factorio 2.1,
including downstream assembly, recycling, unboxing, and chemical conversion.
Reject any route that turns the substitute into metal or metal-bearing feedstock.
Direct-consumer inspection is not proof of this condition. Use the repeatable
[consumer audit](../tests/progression/fulgora-intermediate-consumers.args) and
[producer audit](../tests/progression/fulgora-component-producers.args) as inputs
to the implementation checks.

Conductive polymer wire uses local iron plates from arrival. Improved Polymer
Doping permits local iron chloride production. Imports from Vulcanus are optional.

### Organic substitutes

Fulgora recipes use plastic and graphite with iron dopants for gears and
insulated wire. Primitive Filtration unlocks these starter recipes. Improved
Polymer Doping follows Explosives 1 and unlocks mixed-metal gears, iron-chloride
wire, and local iron chlorination. Fulgora does not need Pneumatic Technology
for this route. These recipes can run on any planet after research.

Fiber-reinforced Polymers unlocks reinforced polymer gears and fiber cables. It
requires Primitive Filtration, Weaving 2, and electromagnetic science.
Bulk Polymer Processing follows Mass Production 4, Improved Polymer Doping,
and Fiber-reinforced Polymers. It uses electromagnetic science and unlocks the
bulk gears, cables, wire, and chemical iron chlorination.
Composite Construction follows Composites 2 and Bulk Polymer Processing. It
uses electromagnetic and physics science and unlocks ordinary and boxed composite
beams. Input research still controls
when each bulk recipe can run. Iron chloride
has no box item; bulk recipes use loose iron chloride.

The substitutes retain the existing item IDs and separate grades. Recipe values
are in `shared/fulgora-organics.lua`. Use the Fulgora science planner for factory
capacity and the organic recovery audit for downstream metal outputs.

## Science and research

| Research or product | Proposed local route or reward |
|---|---|
| Geology science | Trace minerals from filtration |
| Mechanical science | Doped polymer gears |
| Electrical science | Conductive polymer circuits |
| Electromagnetic science | Basic, improved, and improved boxed recipes below |
| Global electromagnetic rewards | Overcharged assemblers; polymers and organic electronics supply their components |
| Organic process optimization | Infinite productivity research for organic chemistry; see below |
| Post-scout directed-energy devices | Lasers and beam weapons using petrochemistry, organic optics, and polymer waveguides |
| Shared endgame contribution | Exotic polymer focusing lens |
| Radio astronomy | Interferometric recordings for astronomy correlation; see below |
| Rocket fuel | Plasma-fixed ammonium nitrate composite; see below |

### Radio astronomy

Design only. The shared design is
[interplanetary interferometry](SPACE_AGE_BRAINSTORM.md#45-astronomy-interplanetary-interferometry).

| Fulgora rule | Value |
|---|---|
| Dish placement | Island ground or sand; mutual spacing against other dishes only |
| Power | Electric |
| Interference | `min(1, nullius-storm-intensity / 100)`: 0.25 by day, 1 by night |
| Controller | Amortized error-diffusion duty cycle through `disabled_by_script`; 443 buckets |
| Lightning | Native frequency multiplied by `nullius-storm-intensity / 100`; day and night multipliers become 1 |

### Rocket fuel

Design only. Shared rules: [Launch fuel](SPACE_AGE_BRAINSTORM.md#46-launch-fuel).
Storm surplus fixes atmospheric nitrogen as the oxidizer.

| Step | Machine | Draft recipe |
|---|---|---|
| Plasma nitrogen fixation | Overcharged medium or large assembler, `nullius-electromagnetism-1` | 10 nitrogen + 20 water -> 1 ammonium nitrate, 4 s; N2 + 2 H2O -> NH4NO3, no byproduct |
| Composite casting | Ordinary assembler; productivity disabled | Ammonium nitrate + rubber + aluminum powder -> rocket fuel |

| Rule | Value |
|---|---|
| Inputs | Nitrogen from air separation, water from ice melting, rubber from fountain chemistry, aluminum from sludge bauxite |
| Fixation productivity | Built-in overcharged productivity is permitted; fuel aluminum comes only from casting |
| Casting aluminum | At least the no-mint minimum per fuel; see the shared alumina rule |
| Small assemblers | Excluded: no fluid boxes |
| Bulk fixation | Boxed recipe in medium or large overcharged assemblers |

Energy per recipe-second, before built-in productivity:

| Overcharged machine | Crafting speed | Power | MJ per recipe-second |
|---|---:|---:|---:|
| Medium 1 | 1 | 1.44 MW | 1.44 |
| Medium 2 | 2 | 28.5 MW | 14.25 |
| Large 1 | 4 | 65 MW | 16.25 |
| Medium 3 | 4 | 670 MW | 167.5 |
| Large 2 | 8 | 1.5 GW | 187.5 |

Measured contract: `experiment-overcharged-fluids`, Factorio 2.1.24, 125 assertions.

| Contract | Measurement |
|---|---|
| Two fluid inputs | Every medium and large overcharged tier finishes one craft of 10 nitrogen + 20 water and of 600 nitrogen + 1200 water, consuming both fluids |
| Shipped recipe | Medium overcharged tier 1 finishes ordinary and boxed diesel canisters |
| Fluid box capacity | Each input box holds 4 times its recipe amount, above the 500 prototype volume: 2400 nitrogen and 4800 water for the bulk case |
| Power priority | Surge (`tertiary`) |
| Built-in productivity | 0.2, 0.4, 0.6 by tier |
| Small overcharged assemblers | No fluid boxes; `set_recipe` selects nothing and raises no error |

```bash
python tools/run_factorio_tests.py experiment-overcharged-fluids
```

### Organic process optimization

Independent repeatable research improves hydrocarbon processing, polymerization,
and fibers on every planet. Each branch requires Overcharged Assembly 2 and its
process technology: Primitive Filtration, Organic Chemistry 1, or Weaving 2.

Recipe outputs select the branch. Boxed products and compressed fluids receive
the same coverage. Packaging, unboxing, fluid transfer, voiding, reinjection,
recycling, and recipes that forbid productivity are excluded. Substitute
assembly receives neither organic nor Vulcanus industrial research bonuses.

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
| Extractor, each tier | Extraction ↔ reinjection, on Fulgora hydrocarbon vents only |

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

Manual fluid deletion is not a design sink. No-void checks assess automated
waste handling.

The historical five-extractor model without magnetic filtration or reinjection
could not supply Volcanism 1,
Water Filtration 3, Distillation 2, Limestone Processing 2, or Waste Reclamation
within the starter tank allocation. These cases exclude intermediate research
and fleet expansion. The extractor-research case with unrestricted hydrocarbon
storage retains 163,228 filtered hydrocarbons, 10,000 benzene, and 9,606
wastewater. With reinjection all five cases are feasible;
see [Reservoir reinjection](#reservoir-reinjection-and-stream-balancing).

Iron-ore and bauxite checkpoints accept crushed ore at their crushing ratios
(6/5 and 7/5 raw units per crushed item). Sandstone and limestone already accept
sand and crushed limestone. Raw-ore and bloom alternatives remain available.

Argon is available through local residual-gas separation. Sand and sulfuric acid
supply rutile. Borate leaching supplies boric acid. All materials for physics
and process construction are locally available in the declared research model.

### Building bootstrap

`tools/audit_factorio_building_bootstrap.py` with
`tests/progression/fulgora-building-bootstrap.json` checks the wreck fleet,
physics-plan machines, logistics, power equipment, checkpoint materials, and all
science packs through physics.
Pass a fresh factory plan with `--plan` and an output path with `--output`.
The targets pass from the landing research boundary. Research and crafting machines
become available in dependency order; no later machine is supplied as a seed.

Extractor construction needs a well item, but does not need to place the well.
Water canisters come from burning hydrogen canisters in a compatible vehicle.
Construction-only relays use the normal relay item.

This checks material and research order with external electricity and manual
surplus disposal. Crude filtration permits probabilistic drops. It does not
measure finite starter quantities, checkpoint actions, or power supply.

`tools/audit_factorio_checkpoints.py` checks the pre-physics checkpoints against
live definitions from the `checkpoint-contracts` scenario. It checks local
production, consumption, and building surface conditions before each research
unlock. Recipes with hidden statistics cannot satisfy production or consumption
requirements. The audit uses the landing boundary in
`tests/progression/fulgora-building-bootstrap.json`. It reports checkpoints
already researched before landing separately. The
`fulgora-exploration-checkpoint` scenario checks actual scout-drone consumption
and checkpoint completion on Fulgora. These checks do not measure campaign time,
power supply, or finite starter stock.

### Factory capacity

Use the factory planner with `tests/progression/planner/fulgora-science-scale.json`
for science rates, machine counts, power demand, and research supply bounds.
The plan includes local slurry processing and machine construction. It assumes
research checkpoints are complete and the science lines are already operating.
It does not measure arrival-to-physics time.

### Storm climatology

Slurry climatology is the bootstrap recipe. Fulgora-specific Storm Climatology research unlocks storm
climatology, which uses nitrogen, ammonia, and hydrocarbon slurry in a chemical
plant on Fulgora. The process models a lightning discharge through a primordial
atmosphere. Nitrogen Chemistry supplies the ammonia route.

Storm Climatology follows Climatology 2 and uses electromagnetic science.
Bulk Storm Climatology follows it, Overcharged Assembly 2, and Mass Production 7
to unlock boxed storm climatology. Basic slurry climatology
has no boxed recipe.

### Island space

Measured on Factorio 2.1.20: seeds 0, 42, and 1729; 1024×1024 windows at
(0, 0) and (4096, 0). Native terrain and cliffs remain unchanged.

| Measure | Range across samples |
|---|---:|
| Island land | 24.7–35.8% |
| Landing island | 2,366–2,800 tiles |
| Median complete island, at least 256 tiles | 2,800–5,621 tiles |
| Largest observed island portion | 60,348–113,441 tiles |
| Land in complete 32×32 blocks, after cliff removal | 95,232–156,672 tiles/window |
| Same blocks without cliff removal | 58,368–96,256 tiles/window |

The current island size control is 2. Sediment retains the native ocean shapes.
Boundary islands can extend outside the sample. Rocks are assumed cleared.

| Packs/min each | Bare island machines | Full tier-1 batteries | Compact site | Roomy site |
|---:|---:|---:|---:|---:|
| 30 | 6,605 tiles | 318 | 23,254 tiles | 49,039 tiles |
| 60 | 10,473 tiles | 625 | 37,723 tiles | 77,702 tiles |
| 120 | 18,621 tiles | 1,238 | 67,842 tiles | 137,685 tiles |
| 240 | 35,064 tiles | 2,466 | 128,585 tiles | 258,828 tiles |

Both site estimates include batteries for a 30-second ordinary-load gap.
Compact: one tile around each machine and 20% shared space.
Roomy: two tiles around each machine and 35% shared space.
Shared space allows for transport, buffers, and stations; no layout is routed.
No construction mall or inter-island rail route is included.

The landing island cannot hold these factories. At 60/min, distilleries and
hydro plants alone occupy 4,525 bare tiles. Pylons, coils, and extractors can use
sediment; batteries, belts, and processing machines need islands.

A conservative allocation of complete 32×32 blocks needs 1–2 large islands for
compact 60/min, or 2–8 for roomy 60/min. This is not a placement proof or a minimum
for a flexible layout. Roomy 120/min exceeds this block capacity in four of six
windows; roomy 240/min exceeds it in all six. Plan a wider rail network at those
rates. Power delivery remains constrained by the measured surge deficit.

Repeat with:

```sh
python tools/plan_factorio_factory.py --config tests/progression/planner/fulgora-science-scale.json --stage first-physics --output fulgora-area-plan.json --overview
python tools/run_factorio_tests.py fulgora-island-survey -n auto --result-json fulgora-islands.json
python tools/analyze_fulgora_area.py --plan fulgora-area-plan.json --survey fulgora-islands.json --output fulgora-area-report.json --plot fulgora-islands.png
```

### Power and model boundaries

Separate ordinary demand from surge demand when planning the grid. Storage can
bridge gaps for ordinary consumers; surge machines need active generation.
Allow for collector coverage, grounding losses, and storage transfer limits.

Recipe feasibility does not prove startup order, buffer capacity, vent supply,
or a connected factory layout. The source recipes and planner contracts define
quantities; this document defines the mechanics.

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
