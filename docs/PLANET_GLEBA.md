# Gleba design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Design only |
| Planet mechanics and constraints | This document; supersedes [Space Age brainstorm 3.3](SPACE_AGE_BRAINSTORM.md#33-gleba-microbiologybreeding) where they differ |
| Shared progression, cargo, nuclear, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |
| Machine-mode precedents | [Vulcanus machine modes](PLANET_VULCANUS.md#machine-modes) and [Fulgora mode switching](PLANET_FULGORA.md#mode-switching) |
| Base biology chain | `nullius-star/prototypes/item/biology.lua` and its technologies |

## Role

```yaml
planet_role: geomicrobiology and the origin of all biology
setting: primordial world with native microbial mats; no plants, animals, or ruins
atmosphere: nitrogen and hydrogen sulfide; no oxygen or carbon dioxide
primary_resource: oxidized crust consumed by native bacteria
initial_access: wild microbial mats on weathered rock
power: none electric; machines burn nutrient goop
energy_source: chemosynthesis of hydrogen sulfide with ferric rock
surface_water: none usable for industry
local_water: released by sulfiding oxide rock
carbon: carbonate rock only; the scarce resource
metals: bioleached from rock; iron cheap, aluminum dear, no copper
local_progression: local science through Orbital Construction and a return cargo flight
planet_pack: biochemistry pack; no new science pack
research_branch: the whole biology tree, parallel to the main tree
pre_cargo_global_reward: bioreactor chemical and hydro plants
exports: wild culture, genomes and progenitors, uranium, sulfur compounds, iron
imports: carbon-rich materials, copper, aluminum
```

## Decisions

| Question | Decision |
|---|---|
| Probe timing | Tier 3, at Organic Chemistry 1, as in [Nauvis design](PLANET_NAUVIS.md#23-per-planet-reactivation) |
| Biology before nanotechnology | Native wild strains exist on Gleba; culturing them needs no genome, nanofabricator, or Biochemistry 1 |
| Science packs | No new pack. The 7 existing biology packs are Gleba's research; the biochemistry pack is its planet pack from probe access |
| Biology tree | A separate branch rooted at Gleba access, parallel to the main tree; see [Biology branch](#biology-branch) |
| Where biology runs | Biology recipes have no surface condition. Life starts only from Gleba wild culture, so other planets run biology once cargo delivers it; see [Seeds](#seeds) |
| Electricity | None on Gleba. Machines burn nutrient goop, as Vulcanus machines burn volcanic gas |
| Global machine reward | Bioreactor chemical plants and hydro plants, the families [Fulgora](PLANET_FULGORA.md#overcharged-assemblers) reserves for other planets |
| Metals | Bioleaching of local rock; no ore deposits |
| Production decline | Comes from carbon and rock mass balance, not a loss factor; see [Carbon](#carbon) |
| Random breeding | Probabilistic recipes never carry a closure; see [Randomness rule](#randomness-rule) |
| Radio array | Gleba joins; see [Radio astronomy](#radio-astronomy) |
| Escaped organisms | Not part of the planet slice |

## Environmental constraints

| Constraint | Consequence |
|---|---|
| Hydrogen sulfide atmosphere | New surface property `nullius-hydrogen-sulfide`, default 0, positive on Gleba only. Mat culture and sulfide recipes require it above 0 |
| No electricity | Generators, solar panels, wind turbines, and accumulators cannot be placed on Gleba; electric-only machines have no power source |
| No oxygen | Nothing combusts; oxygen is a chemistry input only |
| Oxidants poison the mats | Gleba cannot vent oxygen or sulfur dioxide; void recipes for both require `nullius-hydrogen-sulfide` at 0 |
| No carbon dioxide | Carbon comes from carbonate rock through acid neutralization |
| No usable surface water | No offshore pumps or water wells; water comes from rock sulfidation and biomass dewatering |
| No seawater or breathable air | Biology recipes that take seawater, air, or bulk wastewater need contained variants on Gleba; see [Contained culture](#contained-culture) |
| Thick haze | Low `solar-power`; light limits phototrophs |
| No ore deposits | Metals come from leach liquors |
| No copper | Gleba rock carries no copper; Fulgora stays the sole primary copper source |
| No circuit network | Combinators need electricity, as on Vulcanus |

## Core loop

```
reduced atmosphere (H2S)  +  oxidized crust (ferric oxide, sulfate, carbonate, silicate)
          |                              |
          +---- native bacteria ---------+
                     |
                     +-- energy:  chemosynthesis stores sulfide-ferric energy in goop biomass
                     +-- acid:    sulfur oxidation makes sulfuric acid liquor
                     +-- metals:  acid liquor dissolves iron, aluminum, uranium
                     +-- carbon:  acid neutralized on carbonate releases CO2 for fixation
                     +-- water:   ferric oxide + H2S -> iron sulfide + water
                     +-- waste:   gypsum, iron sulfide, silica residue, digestate

goop -> machines -> digestate -> chemosynthesis -> goop
```

Rock is the energy source, ore, carbon source, and water source at once. Goop
carries the energy; its carbon circulates through digestate. Scale is bounded by
rock throughput.

## Resource model

### Rock

| Rule | Value |
|---|---|
| Form | Rock resource patches mined by nutrient-mode miners; infinite, as Vulcanus lava and Fulgora vents |
| Crushing | Crushed Gleba rock feeds leaching; crushing reuses the crusher |
| Composition | Ferric oxide, sulfate, carbonate, silicate, soluble mineral salts and trace uranium. The rock contains no copper |
| Residue | Silica sand and mineral dust from leached rock |

### Microbial mats

| Rule | Value |
|---|---|
| Role | The only source of wild culture, and so of all life in the game |
| Form | Open question: a slow infinite resource on mat tiles or a harvested decorative entity |
| Manual recipe | Harvest renewable mat samples by hand. Biological Probe Signal Recovery unlocks a slow handcraft that takes only mat samples and produces wild culture and nutrient goop. |
| Spoilage | Wild culture spoils into sludge |

### Strains

| Strain | Real basis | Metabolism on Gleba | Uses |
|---|---|---|---|
| Sulfur oxidizer | *Acidithiobacillus* | Oxidizes sulfur and sulfide with ferric iron; fixes CO2 | Chemosynthetic goop, acid liquor, leaching, uranium leaching |
| Iron reducer | *Geobacter* | Reduces ferric iron and dissolved metals | Iron liquor conditioning; the uranium-reducing culture for mission goal 11 |
| Sulfate reducer | *Desulfovibrio* | Reduces sulfate to sulfide | Precipitates metals from liquor as sulfides; regenerates H2S |
| Purple sulfur phototroph | Purple sulfur bacteria | Fixes CO2 with light and H2S; makes sulfur, not oxygen | Light-limited carbon fixation without ferric rock |

| Grade | Source | Rule |
|---|---|---|
| Wild | Mat culture | Deterministic, slow, short spoil time |
| Domesticated | Serial passage of wild culture | Deterministic floor recipe |
| Selected | Screening of domesticated culture | Probabilistic improved strain; failures leave dead culture |
| Engineered | Genomes sequenced from wild culture | The existing biology chain; see [Biology branch](#biology-branch) |

### Carbon

| Rule | Value |
|---|---|
| Source | Carbonate rock neutralizing acid liquor releases CO2; chemosynthesis and phototrophs fix it |
| Circulation | Goop burned in machines leaves digestate; chemosynthesis takes digestate back with a fixed carbon loss |
| Sinks | The digestate loss, methane, exported organics, plastics, spoilage to sludge, biology packs |
| Decline | Every loop exports carbon, so it needs fresh rock. No loop returns more carbon than it receives |
| Pressure | Energy, materials, and biology research share one carbon pool. Acid neutralization is mandatory waste handling and the carbon supply |

### Water and oxygen

| Fluid | Source | Constraint |
|---|---|---|
| Water | Sulfiding ferric oxide; biomass dewatering | Low and tied to rock throughput |
| Hydrogen | H2S splitting in nutrient chemical plants | Abundant; sulfur coproduct |
| Oxygen | Gypsum decomposition | Chemistry and contained-culture input only; cannot be vented |

### Metals

| Metal | Route | Cost driver |
|---|---|---|
| Iron | Iron oxide precipitated from liquor, reduced with hydrogen from H2S | Cheap: hydrogen and liquor are abundant |
| Aluminum | Acid leaching of aluminosilicate residue with organic acids, then the global carbothermic sodium route from [Vulcanus](PLANET_VULCANUS.md#sodium) | Dear: organic acids and graphite both cost fixed carbon; post-cargo import replaces it |
| Silicon | Silica residue | Cheap byproduct |
| Calcium | Gypsum from neutralization | Byproduct |
| Uranium | Uranyl sulfate liquor to yellowcake, as [Fission branch](SPACE_AGE_BRAINSTORM.md#fission-branch) | Trace; bulk needs scale |
| Copper, titanium | None | Import |

No electrowinning or electrolysis: electrolyzers stay electric only.

## Byproducts

| Byproduct | Handling |
|---|---|
| Acid liquor | No void on Gleba; neutralize on carbonate, which yields gypsum and CO2 |
| Oxygen | No void on Gleba |
| Sulfur dioxide | No void on Gleba; reduce back to sulfur with H2S |
| Sulfur | From H2S splitting and phototrophs; feeds acid liquor |
| Gypsum, iron sulfide | Solid waste; decomposition or disposal recipes |
| Digestate | Recycled into goop on Gleba; fertilizer or sludge elsewhere |
| Contaminated culture | Probabilistic product of screening; sterilized at a heat or acid cost |
| Dead culture | Spoil result; becomes sludge |

## Nutrient goop

| Rule | Value |
|---|---|
| Fuel category | Custom `nullius-nutrient`. Only nutrient and bioreactor modes burn it; ordinary burners reject it |
| Burnt result | Digestate |
| Spoilage | Goop spoils into digestate, so stockpiles go stale and supply must be steady |
| Gleba route | Chemosynthesis: sulfur-oxidizer culture, H2S, ferric liquor, CO2 from neutralization, and digestate |
| Nauvis route | Single-cell protein from ordinary organic chemistry, as the ICI Pruteen process made from methanol and ammonia. A protein feedstock, not a living culture, so it needs no wild culture. It closes on Nauvis at the research that unlocks it |
| Fulgora route | Hydrocarbons and ammonia |
| Vulcanus | No route; Vulcanus has thermal machines |
| Energy bound | On Nauvis and Fulgora, goop fuel value per craft is below the fuel value of its organic inputs, so goop never generates net energy |

The spent-goop carbon loss is a design value fixed with the Gleba power balance.

## Machine modes

| Family | Mode | Surface | Bonus | Fuel |
|---|---|---|---|---|
| The Vulcanus pneumatic list: assemblers, boxers, barrel pumps, filters, hydro plants, distilleries, chemical plants, compressors, flotation cells, labs, extractors, pumps, inserters, miners | Nutrient | Gleba | None | Goop |
| Nanofabricators | Nutrient | Gleba | None | Goop; needed by genome and progenitor recipes |
| Crushers, furnaces and foundries | Nutrient | Gleba | None | Goop |
| Radio dishes and correlators | Nutrient | Gleba | None | Goop |
| Biology labs | Nutrient | Gleba | None | Goop |
| Chemical plants and hydro plants, each tier | Bioreactor, tiers 1-3 | Any surface | Built-in productivity from the shared constants | Goop, increasing steeply per tier like overcharged power |
| Rocket silo | Nutrient | Gleba | None | Goop, matching total electric draw as the pneumatic silo |
| Electrolyzers and electrical infrastructure | Electric only | Not usable on Gleba | | |

| Rule | Value |
|---|---|
| Items | Mode-neutral, as Vulcanus and Fulgora |
| Switching | Ctrl+R. On Gleba the cycle is ordinary, nutrient, bioreactor; bioreactor is skipped until its research and the ordinary recipe are unlocked. Elsewhere the cycle is ordinary, bioreactor |
| Transitions | The common transition system: compatible recipes, contents, modules, and connections survive; stored energy and health never increase; leaving a nutrient mode releases remaining fuel |
| Upgrades | Upgrade planners keep the mode and use ordinary machine items |
| Logistics | Unlock the [clockwork logistics](PLANET_VULCANUS.md#primitive-logistics) equipment on Gleba at Robotics 1 and Wild Strain Cultivation. Build and wind it locally. Normal logistic robots are forbidden on Gleba. |
| Flotation cells | Bioreactor mode deferred until tiers 1-3 have been played |
| Exclusive pairs | No machine belongs to two improved families: assemblers stay Fulgora, crushers, furnaces, and foundries stay Vulcanus |

## Biology branch

The player can transfer to Gleba as soon as the force recovers the probe.
From that point, one factory can supply both ordinary research and biology.
The force chooses one active technology. Each working lab must hold all the
packs for one research unit. Pack lines can run while the other branch studies.

### From the probe to a biology lab

The quantities below are proposed first-playtest values. Each listed pack
costs one per unit unless a quantity follows its name.

| Research | Requires | Research units | What the player can do |
|---|---|---|---|
| Biological Probe Signal Recovery | Interplanetary Signal Acquisition and Organic Chemistry 1 | On Nauvis, 40 × 20 s with geology, climatology, mechanical and electrical | Activate the probe and unlock the Gleba destination. Harvest mats and handcraft the first wild culture and goop. Run nutrient machines, produce more goop, and make the first biochemistry packs. |
| Wild Strain Cultivation | Biological Probe Signal Recovery | In the wreck Lab 1, 8 × 20 s with biochemistry | Grow a deterministic domesticated culture. Build the biology lab. Make the first microbiology packs from wild and domesticated cultures in the nutrient flotation cell. |
| Biochemistry 1 | Wild Strain Cultivation | In the new biology lab, 12 × 30 s with biochemistry and microbiology | Recover sugar, amino acids, fatty acids and nucleotides from local culture. Make biochemistry packs by a higher-yield culture recipe. Unlock bioreactor tier 1 and its local fuel routes on Nauvis and Fulgora. |

The probe unlocks a slow recipe in the flotation cell that consumes wild
culture and leach residue for biochemistry packs. Both inputs precede the
first research. The two early pack recipes use physical culture. Their first
batches cost zero chemical packs, physics packs, genomes or nanofabricators.

Replace the current biology lab recipe with one handcraftable lab from
8 iron plates, 4 glass, 2 iron gears and 2 pipes in 10 s. The player keeps
the wreck Lab 1 for ordinary research. The proposed biology lab uses Lab 1's
research speed and active power draw. Its ordinary mode uses electricity and
its Gleba mode uses goop. Both accept all seven biology packs. Ordinary labs
accept the normal packs plus biochemistry for mixed industrial research.
Microbiology is the first pack that needs the dedicated lab. From probe
activation through Biochemistry 1 the two labs consume 20 biochemistry packs
and 12 microbiology packs in total.

After Biochemistry 1 the player can stay with wild strains while industry
works toward Nanotechnology 1. Optional Strain Selection costs 10 units of
one microbiology pack at 30 s each. It opens screening for a strain that
yields more goop per batch of rock. Both ordinary science and the first
genomes keep the deterministic domesticated route.

The current lab costs 3 Lab 2s, a Sensor Node 2, a Nanofabricator 1, 2 Logistic
Bot 2s and 10 boxes of insulation. Current Biochemistry 1 costs 1,000 units
after Physics and Organic Chemistry 6. The early lab and the two culture
recipes replace these construction and research gates together.

### Pack producers and research forks

Each row gives the proposed direct prerequisites and the complete pack bill
per research unit. A newly listed pack becomes available when its research completes.
The proposed unit counts and times are starting prices for the campaign test.

| Research | Direct prerequisites | Units and packs | New production |
|---|---|---|---|
| Biology 1 | Biochemistry 1 and Nanotechnology 1 | 15 × 30 s, biochemistry + microbiology | Make first-generation bacteria, genomes and protocells in a nutrient nanofabricator. The first sequencing recipe uses chemical science and wild culture. Remove physics packs from this grade. |
| Biology 2 | Biology 1 | 20 × 30 s, biochemistry + microbiology | Grow contained algae. Add the current algae-based microbiology pack as an efficient alternative to the culture assay. |
| Botany 1 | Biology 2 | 20 × 30 s, microbiology + biochemistry | Grow grass tissue and cellulose. Make the botany pack. |
| Zoology 1 | Biology 2 | 20 × 30 s, microbiology + biochemistry | Grow a contained worm line on microbial feed. Make the nematology pack. |
| Botany 2 | Botany 1 and Physics | 30 × 40 s, microbiology + botany | Grow tree tissue and wood. Make the dendrology pack. |
| Zoology 2 | Zoology 1 and Physics | 30 × 40 s, microbiology + nematology | Grow a contained fish line with recovered water and oxygen. Make the ichthyology pack. |
| Zoology 3 | Botany 2 and Zoology 2 | 50 × 40 s, botany + dendrology + nematology + ichthyology | Supply plant and animal feed to the contained arthropod line. Make the zoology pack. |

The plant and animal routes can be taken in either order. Each first-generation
genome, progenitor, feed and contained pack gets a deterministic recipe at its
owner above. Move any later ingredient to an improved recipe. For example, the
current first bacterial genome consumes 6 physics and 12 chemical packs, and
the current ichthyology pack consumes 10,000 wastewater. Neither bill fits its
new first-use boundary. Keep the fast archive genome recipes at Astronomy.
Gleba can make all seven packs before cargo if the player stays to do so.

### Shared research gates

| Junction | Prerequisites and reward | Effect on the other route |
|---|---|---|
| Industrial chemistry | Experimental Chemistry opens local chemical science. Nanotechnology 1 supplies the machine for Biology 1. Move the industrial molecule synthesis recipes that need that machine to Nanotechnology 1. Biochemistry 1 supplies the early culture routes. | A Nauvis factory can synthesize nonliving feedstocks. Living lines require a Gleba seed. |
| Bio-composites | Botany 1 and Composites 2 open an alternative carbon-composite recipe from local plant fibre and resin, with a boxed bulk recipe. Use biochemistry and physics packs in one ordinary lab. | The player can use a cultivated crop for rocket-stage and cargo-bay materials. The standard Composites 2 recipe remains available on the ordinary route. |
| Fission | Keep Biochemistry 4 after Biochemistry 3 and Zoology 1. It unlocks protein processing. Keep Seawater Uranium Adsorption after Biochemistry 4, with its biochemistry, microbiology and nematology cost. Uranium Processing also needs Fluorine Chemistry. | Gleba research opens the Nauvis adsorbent route. Nauvis makes the material locally from industrial feedstocks. This is a required biology link for fission and an optional detour on the way to cargo. |
| Genetic archives | Genetic Archive 1 requires Gleba Radio Astronomy and Zoology 3. Genetic Archive 2 follows Archive 1 and Evolution 2. Use normal and astronomy packs in an ordinary lab. | Single-planet astronomy on Gleba enables improved genome recipes. Multiple recordings improve output after ships connect the array. |
| Ecology and evolution | Ecology 1 requires Biology 2 and Orbital Construction. Pay its units with biochemistry and microbiology. Use the first cargo delivery to supply algae for the Nauvis drone. Later deployment needs its contained organism and the preceding Nauvis deployment. Keep 25%, 50% and 75% Nauvis oxygen at Ecology 3, 5 and 6. At 100%, keep Air Separation 5 for industrial oxygen separation. Evolution 1 follows Ecology 3 and Archive 1. | Contained production can advance a culture-production checkpoint. Only deployment and oxygen progress on Nauvis advance its terraforming mission. |

For the other process research, keep the biology prerequisites and the pack
bill its inputs require. Biochemistry 2 processes algae after Biology 2.
Biochemistry 3 adds plant processing after Biochemistry 2 and Botany 1.
Biochemistry 5–9 add processing for the corresponding established lines.
Evolution 2–7 improve established lines after Evolution 1. Deployment,
archive research and oxygen milestones are outside the prerequisites for
the first seven packs. Move operations that need a later machine or a
different surface to their application research, including deployment drones.

Keep the industrial prerequisites that supply a recipe ingredient. For
example, replace Locomotion 5 at Artificial Intelligence 2 with Cybernetics 6
for the Android 2 chassis and legs, and retain Parallel Computing 4. Keep the
Android 2 checkpoint at Rocket Science 3. Remove the Wildlife Management 2
edges to Battery Storage 5 and Rocket Science 3, and the Evolution edges
to Solar Power 4 and Cybernetics 7. Preserve the industrial prerequisites reached through
each removed edge that the remaining products need. Rocket Science 1 and 2,
Composites 2 and Orbital Construction retain their normal prerequisite trees.

### Current coupling

This table records the tree before the proposed moves. The release check compares
the new graph with the resolved tree from the parent release.

| Direction | Count | Technologies |
|---|---:|---|
| Biology technologies with main-tree prerequisites | 34 | Biochemistry 1-5, 7, 8; Biology 1-2; Botany 1-2; Ecology 1-6; Evolution 1-7; Zoology 1-3; Carbon Sequestration 4; Locomotion 5; Nitrogen Chemistry 3; Personal Transportation 5; Weaving 3; Wildlife Management 2; Woodworking |
| Main-tree technologies requiring biology | 8 | Artificial Intelligence 2, Battery Storage 5, Cybernetics 7, Genetic Archive 1 and 2, Rocket Science 3, Solar Power 4, Uranium Processing |

36 technologies cost biology packs, and every one costs only biology packs.
Biochemistry 1 costs ordinary packs and unlocks the biochemistry pack and the
biology lab.

### Release checks

Compare the implemented graph with the parent release using fresh resolved
prototypes. List the direct crossings above and their inherited prerequisites.
For every moved technology, record each retained ingredient or machine gate
and each removed edge. Reject undeclared changes to dependent research.
Check each pack, its usable lab, and each new recipe at its owning research
with `--require-no-additional-technologies`. Check bulk recipes along with
loose recipes. Run deployment and seawater applications on their named surfaces.

Extend the research-pacing comparison to the probe, Wild Strain Cultivation,
Biochemistry 1, both fork tips, Zoology 3 and Orbital Construction. Compare
total packs by type and lab time. In the campaign, measure time from transfer
to the first microbiology research, then time to chemical science and the first
cargo delivery. On the early-biology test route, complete Biochemistry 1 before Experimental
Chemistry with the wreck equipment and ongoing local production.

## Seeds

| Rule | Value |
|---|---|
| Gate | Every recipe that creates a living product from non-living inputs takes Gleba wild culture: genome sequencing and first-generation bacteria |
| Self-replication | Spore, egg, and second-generation culture recipes need no wild culture once a line runs |
| Surface | No biology recipe has a surface condition. Wild culture is the only gate |
| Before cargo | Biology runs only on Gleba |
| After cargo | Imported wild culture or genomes start biology anywhere; spoilage makes the import recurring until lines self-replicate |
| Nauvis | Seeding and industrial biology: organism growth, harvesting, fermentation, drones |

### Contained culture

Gleba has no seawater, breathable air, or bulk wastewater, so it cannot run the
recipes that use them. Contained variants run the same steps in nutrient-mode
machines with Gleba inputs.

| Rule | Value |
|---|---|
| Category | A separate recipe category; ordinary recipes stay unchanged |
| Inputs | Gypsum oxygen, sulfidation water, and Gleba carbon instead of seawater, air, and bulk wastewater |
| Scale | Research scale: cell lines and tissue culture rather than open-air growth |
| Products | The same intermediate and pack items as the ordinary recipes |
| Carbon | Local fixed carbon and contained tissue supply every pack. Imported Fulgora organics increase throughput after cargo |
| Coverage | Every biology pack has a contained route that closes on the Gleba boundary at the research that unlocks the pack |

## Randomness rule

| Rule | Value |
|---|---|
| Floor | Every product a closure needs has a deterministic recipe |
| Probabilistic recipes | Selection only: better strains and waste. Engine rolls each result independently; a craft can give several results or none |
| Tool change | The prerequisite analyzer currently credits every listed result to a closure, including probabilistic ones, and quantity manifests reject them. It must not credit a result with probability below 1 unless the contract declares it `--available`. Gleba contracts consume this rule |
| Streaks | The deterministic floor bounds an unlucky streak; no scripted pity counter |

## Spoilage

| Item | Spoils into | Pattern |
|---|---|---|
| Goop | Digestate | Fuel that must keep moving |
| Wild culture | Sludge | Imports must keep moving |
| Domesticated cultures | Dead culture, then sludge | Vulcanus bloom cooling |
| Re-cultured strain | Fresh | `always_fresh` with `percent_spoiled = 0`, as antimatter recharge |
| Exported genomes, progenitors, and uranium-reducing culture | Dead culture | Recurring shipments |
| Stockpiles | Averaged timers | Stack merging, as recordings and antimatter |

Every spoiling export outlasts the recording spoil time in
`shared/reference-transit.lua`, as antimatter does.

A spoiled item that stays in a one-slot fuel inventory blocks the burner, as the
antimatter-trap migration found. Before goop is designed around it, an
engine-witness scenario records whether inserters remove spoiled items from fuel
inventories and whether digestate in the burnt-result slot is removed.

## Probe and bootstrap

| Step | Player outcome |
|---|---|
| Access | Biological Probe Signal Recovery activates the overrun probe on weathered rock beside mats |
| Probe unlocks | The probe research unlocks the manual craft, nutrient mode, acid leaching, chemosynthetic goop, the four basic local pack recipes and the bootstrap biochemistry pack |
| Energy | Harvest mat samples by hand. Handcraft the first wild culture and nutrient goop from those samples. Use chemosynthesis for sustained goop production. |
| Materials | Mine and crush rock, leach it, neutralize the liquor, reduce iron with hydrogen from H2S |
| Construction | Build basic machines and logistics from reduced iron and recovered silica |
| Research | Local generic packs and bootstrap biochemistry packs in nutrient-mode labs |

### Starter inventory

Each force receives the equipment listed below once, at probe activation. Use a shared
starter file like `nullius-star/shared/vulcanus-starter.lua`. Machines arrive
as ordinary items and switch to nutrient mode.

| Equipment | First use |
|---|---|
| Lab 1 | Local research |
| Walls | Containment of the culture area |
| Flotation cell | Mat culture, leaching, neutralization |
| Chemical plant | Chemosynthetic goop |
| Hydro plant | Water recovery and liquor handling |
| Crusher | Rock crushing |
| Small miner | Rock |
| Small furnace | Dry smelting and glass |
| Pipes, pumps, tanks | Liquor and water |
| Belts, inserters, chests | Solid transport and fuel distribution |

## Science and research

### Ordinary science on Gleba

Each route produces the existing pack item. The probe gives the local routes
for the four packs already used on Nauvis. Later packs open with their normal
research. All six run on Gleba with local rock, mats and atmosphere. Put Gleba pack
assays in the nutrient machine categories. Keep the ordinary recipes and
research costs on the other planets.

| Pack | Research boundary | Proposed local production |
|---|---|---|
| Geology | Probe | Sort crushed rock and leach residue in a nutrient crusher. |
| Climatology | Probe | Sample the atmosphere in a nutrient hydro plant. Use local H₂S and nitrogen in place of air and seawater. |
| Mechanical | Probe | Assemble reduced-iron gears and rods in a nutrient assembler. |
| Electrical | Probe | Assemble a test cell from iron plate, graphite, glass and local acid. The cell is a pack ingredient. The recipe works before local aluminum, plastics or electrical power. |
| Chemical | Experimental Chemistry | A nutrient chemical plant assays sulfuric acid, recovered water, gypsum and glass. The normal four-pack research cost can be paid in the wreck lab. |
| Physics | Physics | Run a machine experiment in a large nutrient assembler. Use locally built Lab 2s, Nanofabricator 1s, Medium Tank 2s, heat pipes and boxed transport equipment. Match the normal batch of 25 boxed physics packs. Unbox them in a nutrient boxer. Set the material bill against the ordinary 900 s machine experiment. |
| Astronomy | Astronomy and Gleba Radio Astronomy | Record on Gleba and run the single-recording recipe in a nutrient correlator. Both use locally made recording media. This supplies astronomy packs even before the first shipment of other planets' recordings. |

Make glass from silica and graphite from fixed carbon at the probe. The
nutrient hydro plant collects atmospheric gas. The nutrient chemical plant
handles gas reactions and iron reduction. The starter furnace takes the dry
solid for final smelting. The probe unlocks a local handcraft for Small Assembler 1
from iron plates, gears, leach residue and an inserter. The first machine can use a wreck
inserter. Make replacement inserters from local materials.

Keep the normal Lab 2 building for its placement checkpoint. At Nanotechnology 1
the local Nanofabricator 1 construction recipe uses a chemical plant, a
flotation cell, sensors and glass. Use a Gleba nutrient assembler for this construction recipe.
Include the precursor machines and their construction recipes in the check
at Nanotechnology 1.

### From local labs to space logistics

Start the campaign with only the probe and its prerequisite research. After
transfer, all new research units and checkpoint actions for this route take
place on Gleba. Use the normal technology graph. Local production may use
biology for fuel and materials while Nauvis keeps its ordinary industrial route.

| Research or action | Player result |
|---|---|
| Experimental Chemistry → Physics | Supply the first four packs, then add chemical science. Meet the ordinary industrial checkpoints. For the Lab 2 checkpoint place ten locally built Lab 2s. Count nutrient variants as the same building. |
| Physics → Rocket Science 1 and Composites 2 | Supply all six ordinary packs in one lab. At Rocket Science 1, unlock a fuel assay in the nutrient chemical plant. One batch consumes five locally made rocket-fuel items and produces chemical packs. Verify the native consumption counter before unlocking the silo. Supply carbon composite from the standard process or from Bio-composites. |
| Fuel checkpoint and Composites 2 → Rocket Science 2 | Make the default stage, nutrient silo, rocket and cargo landing pad on Gleba. Build clockwork logistics for silo loading. |
| Rocket Science 2 → Orbital Construction | Build the starter pack, foundation, cargo bay, thruster and flight equipment on Gleba. Have clockwork robots fill a platform request through the nutrient silo. Load local propellant for both legs. Fly to Nauvis, deliver a Gleba product, then return to Gleba. |

At the launch-fuel boundary use the ordinary fuel recipe with local metals,
recovered mineral salts and fixed-carbon feedstocks. Give the salt and sodium
routes a source in the leach residue. Check the loose and boxed products. On
the platform use the normal solar-powered equipment and the existing canister
conditioning recipe. The zero-electricity requirement applies on the surface.

Audit the full checkpoint closure after subtracting **only** the probe's
ancestors. Preserve each threshold, its action (build, produce or consume),
and the Nauvis route. Where a required action is impossible on Gleba, specify
the local equivalent at the same stage. Count equivalent nutrient machines
for placement, clockwork logistics for robot work and local processed minerals
by their material yield. Show the before/after counts in the game. A force
that already finished the checkpoints elsewhere cannot serve as the witness.

In the current resolved tree, Rocket Science 1, Composites 2, Rocket Science 2
and Orbital Construction each cost 800 units with two physics packs per unit.
Together these four technologies consume **6,400 physics packs**. Size the
Gleba physics line against that demand. As a first balance target, sustain
25 loose physics packs per minute together with the five lower pack lines.
At that rate the physics packs alone take 256 minutes. Measure completed
research units, goop use and elapsed ticks for the full sequence.

### Global research

Research is global but cultures are physical, so pre-cargo rewards are recipes
and modes that other planets can use with their own inputs.

| Reward | Effect |
|---|---|
| Biochemistry 1 | Bioreactor tier 1 and goop routes on Nauvis and Fulgora |
| Bioreactor Engineering 2 and 3 | Bioreactor tiers 2 and 3; biochemistry and local generic packs, priced as Overcharged Assembly 2 and 3; each tier also requires its ordinary construction recipe |
| Tailings bioleaching | Once cargo delivers culture, bacteria recover metals from gravel, mineral dust, and sludge on any planet |

Bioreactor research is optional and never gates the ordinary Nauvis path.

### Late recipes

Later biology recipes may take physics or astronomy packs as ingredients, as
genome 2 recipes take astronomy packs today. Gleba makes physics packs locally
and correlates astronomy packs once it joins the array.

## Radio astronomy

| Rule | Value |
|---|---|
| Membership | Gleba joins the interferometry array with a nutrient-mode radio dish and correlator. Gleba Radio Astronomy follows Astronomy and Biological Probe Signal Recovery. It costs biochemistry and physics packs in one ordinary lab |
| Effect | Adds parallel correlation routes; existing routes keep their cost |
| Reference transit | The longest one-way trip between array planets via Nauvis. It stays unchanged only if the measured Gleba-Nauvis leg is no longer than the shorter of the Vulcanus-Nauvis and Fulgora-Nauvis legs. The Gleba space connection length is chosen to meet this, and `astronomy-transit` measures it |
| Recordings and antimatter | Unchanged spoil times follow from the unchanged reference transit |

## Cross-planet effects

| Flow | Content | Driver |
|---|---|---|
| Gleba to Nauvis | Wild culture, genomes, and progenitors | Starts Nauvis seeding and industrial biology; spoilage makes it recurring |
| Gleba to Nauvis | Uranium-reducing culture | Mission goal 11, as [biomineralization](SPACE_AGE_BRAINSTORM.md#mission-goal-11-biomineralization) |
| Gleba to Nauvis | Yellowcake | Bulk fission supply, as bacterial leaching |
| Gleba to Vulcanus | Demolisher feed | [Post-cargo demolisher concept](PLANET_VULCANUS.md#post-cargo-demolisher-concept) |
| Fulgora to Gleba | Organics | Carbon for late biology packs: Fulgora is carbon-rich and metal-poor, Gleba the reverse |
| Fulgora to Gleba | Copper | Sole primary source |
| Nauvis or Vulcanus to Gleba | Aluminum | Replaces carbon-expensive local reduction |
| Nauvis and Fulgora, local | Goop | Fuel for bioreactor chemical and hydro plants |

## Changes to existing designs

| Document | Change |
|---|---|
| Space Age brainstorm 3.3 | Gleba access at tier 3 replaces "Gleba access (Tier 4-5)"; carbon-balance decline replaces the 95% recycling loss; nutrient goop replaces the biological power ladder; the bacterial-harvester salvage maps to the starter inventory above |
| Space Age brainstorm 2.4 | Gleba local power is goop, not galvanic cells; carbon cannot be a pre-cargo import |
| Space Age brainstorm 4.2 and 6 | No new Gleba pack: the biochemistry pack is Gleba's planet pack, and all 7 biology packs come from Gleba before cargo |
| Space Age brainstorm 4.5 | Gleba joins the array without changing the reference transit |
| Space Age brainstorm 4.7 | Seawater Uranium Adsorption keeps its Biochemistry 4 gate. Gleba supplies the research and Nauvis supplies the industrial ingredients |
| Nauvis design 2.3 | Biological Probe Signal Recovery keeps Organic Chemistry 1. Wild Strain Cultivation is the first research after transfer |
| Nauvis design 6 | Advanced biology packs require Gleba: all biology research starts there |

## Unresolved design decisions

| Decision | Options |
|---|---|
| Mat form | Infinite resource on mat tiles or harvested entities with regrowth |
| Biology pack spoilage | Whether biology packs spoil |
| Flotation cell bioreactors | Whether flotation cells join the bioreactor family |
| Vanilla overlap | Spoiling machine fuel is a vanilla Gleba mechanic; goop keeps its own chemistry, carbon loop, names, and values |
| Hostile organisms | Escapes need a hostile force on a mod with frozen evolution; outside the planet slice |
| Existing saves | Saves inside the biology tier lose Nauvis pack production until wild culture arrives; a breaking change needs a changelog compatibility note |

## Acceptance contracts

| Contract | Check |
|---|---|
| Surface | `surface-mapgen-contract` covers Gleba terrain, rock, mats, and no natural enemies |
| Surface conditions | Oxygen void, sulfur dioxide void, and electricity generators fail on Gleba; mat culture fails elsewhere; no biology recipe has a surface condition |
| Electricity | Every ground production closure on Gleba rejects electricity-required executors, as `vulcanus-launch-closure.args` |
| Seeds | On the Nauvis boundary without imports, no living product closes; with declared wild culture, the ordinary biology chain closes at its research |
| Biology branch | The proposed `tools/check_biology_branch.py` checks the pack owners, shared research gates, and changes to dependent research in the release build. |
| Contained culture | Every biology pack closes on the Gleba boundary at the research that unlocks it |
| Randomness | Every Gleba closure passes with probabilistic results uncredited |
| Spoiled fuel | Engine witness: spoiled goop and digestate leave fuel and burnt-result slots of placed nutrient machines |
| Goop energy | A release check fails if a Nauvis or Fulgora goop recipe yields more fuel value than its organic inputs |
| Carbon | No Gleba recipe cycle, including the goop-digestate loop, returns more carbon than it consumes |
| Machine modes | Transitions between ordinary, nutrient, and bioreactor modes keep recipes and contents and never create energy or health |
| Bootstrap | Check that the starting inventory contains only the listed equipment. Harvest mat samples by hand and use the manual recipe to produce the first wild culture and nutrient goop. Use that batch and the wreck equipment to reproduce basic machines and logistics without imports. |
| Early research | From the equipment-only wreck, complete Wild Strain Cultivation in Lab 1. Build the biology lab from local materials and complete Biochemistry 1 there before chemical science. Record handcrafts and elapsed ticks. |
| Science | Supply all six normal packs, all seven biology packs and single-planet astronomy at their named research boundaries. Check the machines, fuel and ingredients with `--require-no-additional-technologies`. |
| Bioreactor closure | Goop on Nauvis and Fulgora closes on each boundary at the research that unlocks bioreactor tier 1 |
| Transit | `astronomy-transit` measures the Gleba-Nauvis leg and the reference transit stays at its current value |
| Space logistics | From the probe boundary, finish Orbital Construction with locally earned checkpoints and packs. Launch a locally built platform, fill a cargo request, deliver to Nauvis and return using only Gleba supplies. |
| Spoiling exports | Every spoiling Gleba export outlasts the recording spoil time |
