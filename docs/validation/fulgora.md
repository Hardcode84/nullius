# Fulgora validation

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

## Helium

Validation: `tests/progression/fulgora-launch-closure-helium.args` checks that the
local rocket path, helium, compressed helium, and research packs are reachable.
`tests/progression/fulgora-launch-manifest.args` quantifies the rocket and silo.
The `fulgora-helium` scenario checks research gates and production on Fulgora, for
ordinary and bulk recipes on every distillery tier. Recipe values live in
`nullius-star/prototypes/planet/fulgora-recipes.lua` and research values in
`fulgora-technology.lua`.

## Terrain and access

The terrain scenarios include `fulgora-mapgen`, `fulgora-terrain`, `fulgora-activation`, `fulgora-shared-body`, `fulgora-probe-alignment`, `fulgora-rail-supports`, `fulgora-extraction`, `fulgora-walking`, `fulgora-vent-coverage`, `fluid-resource-products`, `fulgora-helium` on Factorio 2.1.

To inspect the terrain and capture three screenshots:

```bash
python tools/prepare_fulgora_preview.py --destination release/fulgora-preview
./release/fulgora-preview/launch.sh
```

The preview includes three fixed seeds. Screenshots and terrain maps are in
`release/fulgora-preview/script-output/fulgora-preview/`.

## Slurry climatology

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

#### Copper acceptance checks

| Check | Expected result |
|---|---|
| Copper-free closure | Copper Production closes from the Fulgora boundary without `copper-ore` raw or any copper item, with `--require-no-additional-technologies` |
| Dependents | `tools/check_copper_research.py` compares every technology's closure with the former tree under the moved-closure rule above; `tools/check_asteroid_removal.py` proves no technology keeps the asteroid branch |
| Mode switch | Three-mode cycle on a vent; deep mode skipped before research; no mode on Vulcanus gas vents |
| Lifecycle | Blueprint, robot, revive, clone, and upgrade placements as reinjection |
| Chain | A scenario runs deep slurry to copper ingot through placed machines with declared inputs |
| Vent supply | `tests/progression/planner/fulgora-deep-copper.json` measures ingot supply and net water demand at Electronics 4. Water, power, and machines are supplied; salt and iron oxide leave for mineral disposal. Science at this boundary does not consume copper. Repeat with `python tools/plan_factorio_factory.py --config tests/progression/planner/fulgora-deep-copper.json --output REPORT.json` |
| Boxed parity | Resolved-prototype inspection of every new product and its box |
| Audits | `tests/progression/copper-sources.args` and `tests/progression/copper-consumers.args` list copper producers and consumers |

The reinjection model uses resolved prototypes with
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

## Research supply before reinjection

The historical five-extractor model without magnetic filtration or reinjection
could not supply Volcanism 1,
Water Filtration 3, Distillation 2, Limestone Processing 2, or Waste Reclamation
within the starter tank allocation. These cases exclude intermediate research
and fleet expansion. The extractor-research case with unrestricted hydrocarbon
storage retains 163,228 filtered hydrocarbons, 10,000 benzene, and 9,606
wastewater. With reinjection all five cases are feasible;
see [Reservoir reinjection](../PLANET_FULGORA.md#reservoir-reinjection-and-stream-balancing).

## Overcharged fluid assemblers

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

## Electromagnetic science capacity

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

## Organic substitute checks

Before adding a substitute, test ordinary and boxed routes on Factorio 2.1,
including downstream assembly, recycling, unboxing, and chemical conversion.
Reject any route that turns the substitute into metal or metal-bearing feedstock.
Direct-consumer inspection is not proof of this condition. Use the repeatable
[consumer audit](../../tests/progression/fulgora-intermediate-consumers.args) and
[producer audit](../../tests/progression/fulgora-component-producers.args) as inputs
to the implementation checks.

## Independent acids

The acid contract is `tests/progression/fulgora-independent-acids.args`. It assumes
Waste Reclamation and Limestone Processing 2, powered starter machines, and
supplied salt, ice, and sludge. It proves an acid route without mineral inputs;
it does not prove continuous disposal of its co-products.

## Overcharged research comparison

The resolved comparison is `tests/progression/planner/overcharged-research.json`;
it excludes ordinary prerequisite research and includes tier 2 in tier-3 totals.

Chemical plants, refineries, and hydro plants are reserved for other planets.
Keep the existing electrolyzer progression unchanged.
