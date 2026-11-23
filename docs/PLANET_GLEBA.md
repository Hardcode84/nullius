# Gleba design

## Design references

| Fact | Authority |
|---|---|
| Planet mechanics and constraints | This document |
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
pre_cargo_global_reward: bioreactor chemical plants, hydro plants and flotation cells
exports: wild culture, genomes and progenitors, uranium, sulfur compounds, iron
imports: carbon-rich materials, copper, aluminum
```

## Decisions

| Question | Decision |
|---|---|
| Biology before nanotechnology | Native wild strains exist on Gleba; culturing them needs no genome, nanofabricator, or Biochemistry 1 |
| Science packs | No new pack. The 7 existing biology packs are Gleba's research; the biochemistry pack is its planet pack from probe access |
| Biology tree | A separate branch rooted at Gleba access, parallel to the main tree; see [Biology branch](#biology-branch) |
| Where biology runs | Biology recipes have no surface condition. Life starts only from Gleba wild culture, so other planets run biology once cargo delivers it; see [Seeds](#seeds) |
| Electricity | None on Gleba. Machines burn nutrient goop, as Vulcanus machines burn volcanic gas |
| Global machine reward | Bioreactor chemical plants, hydro plants and flotation cells, families [Fulgora](PLANET_FULGORA.md#overcharged-assemblers) reserves for other planets |
| Metals | Bioleaching of local rock; no ore deposits |
| Production decline | Comes from carbon and rock mass balance, not a loss factor; see [Carbon](#carbon) |
| Random breeding | Probabilistic recipes never carry a closure; see [Randomness rule](#randomness-rule) |
| Radio array | Gleba joins; see [Radio astronomy](#radio-astronomy) |
| First research | Probe research only opens the destination. Nutrient Technology, researched on Nauvis after the probe, Geology 2 and Nitrogen Chemistry 1, unlocks the landing recipes, nutrient mode and bioreactor tier 1, as Pneumatic Technology and Primitive Filtration do |
| Boxed recipes | None at landing. Boxed Gleba recipes arrive with later bulk-production research |
| Escaped organisms | Not part of the planet slice |
| Bioreactors | Tier 1 arrives with Nutrient Technology, as the other planets' first improved tier arrives with their access research. For chemical plants, hydro plants and flotation cells the bioreactor is also the Gleba mode, so every machine has two modes on Gleba. Tier 1 burns no more goop than a nutrient machine, so the bootstrap runs in bioreactors; higher tiers trade steep goop use for productivity |

## Environmental constraints

| Constraint | Consequence |
|---|---|
| Hydrogen sulfide atmosphere | New surface property `nullius-hydrogen-sulfide`, default 0, positive on Gleba only. Mat culture and sulfide recipes require it above 0 |
| No electricity | Generators, solar panels, wind turbines, and accumulators cannot be placed on Gleba; electric-only machines have no power source. [Pneumatic machines](PLANET_VULCANUS.md#machine-modes) are Vulcanus-only |
| No oxygen | Nothing combusts; oxygen is a chemistry input only |
| Oxidants poison the mats | Gleba cannot vent oxygen or sulfur dioxide; void recipes for both require `nullius-hydrogen-sulfide` at 0. Gleba itself is never terraformed: removing the hydrogen sulfide or adding oxygen would kill the mats its economy runs on |
| No carbon dioxide | Carbon comes from carbonate rock through acid neutralization |
| No usable surface water | No offshore pumps or water wells; water comes from rock sulfidation and biomass dewatering |
| No seawater or breathable air | Nutrient air filters draw Gleba air, a separate fluid, instead of ordinary air. Distillery separation of Gleba air yields its components, as each planet separates its own air. Biology recipes that take seawater, air, or bulk wastewater need contained variants on Gleba; see [Contained culture](#contained-culture) |
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

rock + culture -> fixation -> goop -> machines -> digestate -> recycling -> goop
dead culture -> culture sludge -> digestion -> digestate
```

Rock is the energy source, ore, carbon source, and water source at once. Goop
carries the energy; its carbon circulates through digestate. Scale is bounded by
rock throughput.

## Resource model

The wreck lies between a small ferric rock outcrop and a microbial mat. Farther from the landing, both resources occur in scattered clumps with bare ground between them.

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
| Form | Infinite solid resource. One extraction yields one mat sample. Both resource patches keep their initial yield. |
| Manual recipe | Harvest renewable mat samples by hand. Nutrient Technology unlocks a slow handcraft that takes only mat samples and produces wild culture and nutrient goop. |
| Spoilage | Wild culture spoils into culture sludge, which digests into digestate |

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
| Circulation | Goop burned in machines leaves digestate. Recycling returns digestate to goop with a fixed carbon loss; fixation adds new carbon from rock |
| Sinks | The digestate loss, methane, exported organics, plastics, spoilage to sludge, biology packs |
| Decline | Every loop exports carbon, so it needs fresh rock. No loop returns more carbon than it receives |
| Pressure | Energy, materials, and biology research share one carbon pool. Acid neutralization is mandatory waste handling and the carbon supply |

### Water and oxygen

| Fluid | Source | Constraint |
|---|---|---|
| Water | Sulfiding ferric oxide; biomass dewatering | Low and tied to rock throughput |
| Hydrogen | H2S splitting in chemical plant bioreactors | Abundant; sulfur coproduct |
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
| Sulfur | Carried as iron sulfide: sulfidation, acid liquor and sulfur dioxide reduction leave it, and the furnace smelts it back to iron. H2S splitting and phototrophs add elemental sulfur later |
| Gypsum, iron sulfide | Solid waste; decomposition or disposal recipes |
| Digestate | Recycled into goop on Gleba. Each recycling batch consumes more digestate than its goop later leaves, so enough recyclers always clear it. Dissolved into sludge elsewhere |
| Contaminated culture | Probabilistic product of screening; sterilized at a heat or acid cost |
| Dead culture | Spoils into culture sludge; a flotation cell digests the sludge into digestate |

## Nutrient goop

| Rule | Value |
|---|---|
| Fuel category | Custom `nullius-nutrient`. Only nutrient and bioreactor modes burn it; ordinary burners reject it |
| Burnt result | Digestate |
| Spoilage | Goop spoils into digestate, so stockpiles go stale and supply must be steady |
| Gleba routes | Fixation from crushed rock and wild culture. Recycling of digestate with crushed rock and wild culture |
| Energy return | Fixation returns several times the fuel that its mining, crushing, culture and plant burn; recycling returns more. Rock, culture and machine count bound the output |
| Fuel slots | Goop that spoils in a fuel slot moves to free burnt-result space as digestate. With a full burnt-result slot the digestate stays in the fuel slot and blocks it until a player or inserter removes it |
| Nauvis route | Single-cell protein from ordinary organic chemistry, as the ICI Pruteen process made from methanol and ammonia. A protein feedstock, not a living culture, so it needs no wild culture. It closes on Nauvis at the research that unlocks it |
| Fulgora route | Hydrocarbons and ammonia |
| Vulcanus | No route; Vulcanus has thermal machines |
| Energy bound | On Nauvis and Fulgora, goop fuel value per craft is below the fuel value of its organic inputs, so goop never generates net energy |

The recycling carbon loss is a design value in the recipe.

## Machine modes

| Family | Mode | Surface | Bonus | Fuel |
|---|---|---|---|---|
| The Vulcanus pneumatic list except the bioreactor families: assemblers, boxers, barrel pumps, filters, distilleries, compressors, labs, extractors, pumps, inserters, miners | Nutrient | Gleba | None | Goop |
| Nanofabricators | Nutrient | Gleba | None | Goop; needed by genome and progenitor recipes |
| Crushers, furnaces and foundries | Nutrient | Gleba | None | Goop |
| Radio dishes and correlators | Nutrient | Gleba | None | Goop |
| Biology labs | Nutrient | Gleba | None | Goop |
| Chemical plants, hydro plants and flotation cells, each tier | Bioreactor, tiers 1-3; also their Gleba mode | Any surface | Built-in productivity from the shared constants | Goop: tier 1 at ordinary power, then increasing steeply per tier like overcharged power |
| Rocket silo | Nutrient | Gleba | None | Goop, matching total electric draw as the pneumatic silo |
| Electrolyzers and electrical infrastructure | Electric only | Not usable on Gleba | | |

| Rule | Value |
|---|---|
| Items | Mode-neutral, as Vulcanus and Fulgora |
| Switching | Ctrl+R toggles ordinary and the machine's alternate mode: nutrient or bioreactor on Gleba, bioreactor elsewhere, pneumatic and then bioreactor on Vulcanus. Bioreactor mode needs its research and the ordinary recipe |
| Transitions | The common transition system: compatible recipes, contents, modules, and connections survive; stored energy and health never increase; leaving a nutrient mode releases remaining fuel |
| Upgrades | Upgrade planners keep the mode and use ordinary machine items |
| Logistics | Unlock the [clockwork logistics](PLANET_VULCANUS.md#primitive-logistics) equipment on Gleba at Robotics 1 and Wild Strain Cultivation. Build and wind it locally. Normal logistic robots are forbidden on Gleba. |
| Flotation cells | Bioreactor mode, including on Gleba |
| Exclusive pairs | No machine belongs to two improved families: assemblers stay Fulgora, crushers, furnaces, and foundries stay Vulcanus |

## Biology branch

The player can transfer to Gleba as soon as the force recovers the probe.
From that point, one factory can supply both ordinary research and biology.
The force chooses one active technology. Each working lab must hold all the
packs for one research unit. Pack lines can run while the other branch studies.

### From the probe to a biology lab

Each research unit consumes one of each listed pack.

| Research | Requires | Research units | What the player can do |
|---|---|---|---|
| Biological Probe Signal Recovery | [Nauvis probe access](PLANET_NAUVIS.md#23-per-planet-reactivation) | On Nauvis | Activate the probe and unlock the Gleba destination. No recipes. |
| Nutrient Technology | Biological Probe Signal Recovery, Geology 2 and Nitrogen Chemistry 1 | On Nauvis, 20 × 15 s with the four early packs | Harvest mats and handcraft the first wild culture and goop. Run nutrient machines, produce more goop, and make the first biochemistry packs, iron, silica, stone and glass. Rebuild every starter machine locally: silica motors and filters, culture bioplastic, Gleba versions of hydro plant 1, the iron chest and Lab 1, and the other machines by their ordinary recipes. Run chemical plants, hydro plants and flotation cells in bioreactor mode, on any planet. Sulfide ferric concentrate for water, culture acid liquor, neutralize it on carbonate for carbon dioxide and gypsum, decompose gypsum for oxygen and lime, reduce sulfur dioxide and spent iron sulfide, pyrolyse digestate for graphite, and cast steel with local oxygen. |
| Wild Strain Cultivation | Nutrient Technology | In the wreck Lab 1, 8 × 20 s with biochemistry | Grow a deterministic domesticated culture. Build the biology lab. Make the first microbiology packs from wild and domesticated cultures in the flotation cell bioreactor. |
| Biochemistry 1 | Wild Strain Cultivation | In the new biology lab, 12 × 30 s with biochemistry and microbiology | Recover sugar, amino acids, fatty acids and nucleotides from local culture. Make biochemistry packs by a higher-yield culture recipe. |

Nutrient Technology unlocks a slow recipe in the flotation cell that consumes wild
culture, leach residue and ferric concentrate for biochemistry packs. Both
assays cost bootstrap-grade time and materials, as the first metallurgic and
electromagnetic packs do. Every later route for the same pack must use less
machine time per pack than its assay. Both inputs precede the
first research. The two early pack recipes use physical culture. Their first
batches cost zero chemical packs, physics packs, genomes or nanofabricators.

Handcraft the biology lab from
8 iron plates, 4 glass, 2 iron gears and 2 pipes in 10 s. The player keeps
the wreck Lab 1 for ordinary research. The biology lab uses Lab 1's
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

### Pack producers and research forks

Each row gives the direct prerequisites and the complete pack bill
per research unit. A newly listed pack becomes available when its research completes.

| Research | Direct prerequisites | Units and packs | New production |
|---|---|---|---|
| Biology 1 | Biochemistry 1 and Nanotechnology 1 | 15 × 30 s, biochemistry + microbiology | Make first-generation bacteria, genomes and protocells in a nutrient nanofabricator. The first sequencing recipe uses chemical science and wild culture. Remove physics packs from this grade. |
| Biology 2 | Biology 1 | 20 × 30 s, biochemistry + microbiology | Grow contained algae. Use the algae-based microbiology pack as an efficient alternative to the culture assay. |
| Botany 1 | Biology 2 | 20 × 30 s, microbiology + biochemistry | Grow grass tissue and cellulose. Make the botany pack. |
| Zoology 1 | Biology 2 | 20 × 30 s, microbiology + biochemistry | Grow a contained worm line on microbial feed. Make the nematology pack. |
| Botany 2 | Botany 1 and Physics | 30 × 40 s, microbiology + botany | Grow tree tissue and wood. Make the dendrology pack. |
| Zoology 2 | Zoology 1 and Physics | 30 × 40 s, microbiology + nematology | Grow a contained fish line with recovered water and oxygen. Make the ichthyology pack. |
| Zoology 3 | Botany 2 and Zoology 2 | 50 × 40 s, botany + dendrology + nematology + ichthyology | Supply plant and animal feed to the contained arthropod line. Make the zoology pack. |

The plant and animal routes can be taken in either order. Each first-generation
genome, progenitor, feed and contained pack gets a deterministic recipe at its
owner above. Astronomy unlocks the fast archive genome recipes.
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
| Streaks | The deterministic floor bounds an unlucky streak; no scripted pity counter |

## Spoilage

| Item | Spoils into | Pattern |
|---|---|---|
| Goop | Digestate | Fuel that must keep moving |
| Wild culture | Culture sludge | Imports must keep moving |
| Domesticated cultures | Culture sludge | Vulcanus bloom cooling; digests into digestate |
| Re-cultured strain | Fresh | `always_fresh` with `percent_spoiled = 0`, as antimatter recharge |
| Exported genomes, progenitors, and uranium-reducing culture | Dead culture | Recurring shipments |
| Stockpiles | Averaged timers | Stack merging, as recordings and antimatter |

Every spoiling export outlasts the recording spoil time in
`shared/reference-transit.lua`, as antimatter does.

## Probe and bootstrap

The wreck contains [equipment](../nullius-star/shared/gleba-starter.lua). The landing has native terrain and music. Calcite marks some dry banks. Slabs, loose stones and mineral mounds allow movement and construction. The surface has no vegetation, enemies or airborne spores.

| First use | Operation |
|---|---|
| Start or recover | Mine three mat samples. Isolate them by hand for 12 s to get two wild cultures and four goop. |
| Sustain production | Set the wreck machines to nutrient mode with Ctrl+R. Crush ferric rock. Keep one wild culture for propagation. Fix goop from crushed rock and wild culture in the chemical plant. Recycle spent digestate there once a batch has collected, digest culture sludge in a flotation cell, and keep burnt-result slots empty. |
| Supply research | Leach crushed rock in a flotation cell. Use the silica residue for biochemistry packs and glass. Reduce the ferric concentrate in the furnace. Cast plates and rods in the foundry. |

The [starting recipes](../nullius-star/prototypes/planet/gleba-cultivation.lua) specify the yields. The full industrial route adds hydro plants, pumps, tanks and inserters for liquor handling and automatic transport.

## Science and research

### Ordinary science on Gleba

Each route produces the existing pack item. The probe gives the local routes
for the four packs already used on Nauvis. Later packs open with their normal
research. All six run on Gleba with local rock, mats and atmosphere. Put Gleba pack
assays in the nutrient machine categories. Keep the ordinary recipes and
research costs on the other planets.

| Pack | Research boundary | Local production |
|---|---|---|
| Geology | Probe | Sort crushed rock and leach residue in a nutrient crusher. |
| Climatology | Probe | Sample the atmosphere in a hydro plant bioreactor. Use local H₂S and nitrogen in place of air and seawater. |
| Mechanical | Probe | Assemble reduced-iron gears and rods in a nutrient assembler. |
| Electrical | Probe | Assemble a test cell from iron plate, graphite, glass and local acid. The cell is a pack ingredient. The recipe works before local aluminum, plastics or electrical power. |
| Chemical | Experimental Chemistry | A chemical plant bioreactor assays sulfuric acid, recovered water, gypsum and glass. The normal four-pack research cost can be paid in the wreck lab. |
| Physics | Physics | Run a machine experiment in a large nutrient assembler. Use locally built Lab 2s, Nanofabricator 1s, Medium Tank 2s, heat pipes and boxed transport equipment. Match the normal batch of 25 boxed physics packs. Unbox them in a nutrient boxer. Set the material bill against the ordinary 900 s machine experiment. |
| Astronomy | Astronomy and Gleba Radio Astronomy | Record on Gleba and run the single-recording recipe in a nutrient correlator. Both use locally made recording media. This supplies astronomy packs even before the first shipment of other planets' recordings. |

Make glass from silica and graphite from fixed carbon at the probe. The
hydro plant bioreactor collects atmospheric gas. The chemical plant bioreactor
handles gas reactions and iron reduction. The starter furnace takes the dry
solid for final smelting. Small Assembler 1 is hand-crafted by its ordinary recipe from local
iron parts and a wreck inserter and belt. Make replacement inserters from local materials.
Gleba recipes substitute local materials for unavailable ones, as Vulcanus does, and share the
substitutions both planets need: silica for plastic in motors and filters. Culture bioplastic
stands in for rubber in the iron chest and for aluminum and logic circuits in Lab 1, and pumps
replace the seawater intakes in hydro plant 1. The wreck carries no walls.

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
| Physics → Rocket Science 1 and Composites 2 | Supply all six ordinary packs in one lab. At Rocket Science 1, unlock a fuel assay in the chemical plant bioreactor. One batch consumes five locally made rocket-fuel items and produces chemical packs. Verify the native consumption counter before unlocking the silo. Supply carbon composite from the standard process or from Bio-composites. |
| Fuel checkpoint and Composites 2 → Rocket Science 2 | Make the default stage, nutrient silo, rocket and cargo landing pad on Gleba. Build clockwork logistics for silo loading. |
| Rocket Science 2 → Orbital Construction | Build the starter pack, foundation, cargo bay, thruster and flight equipment on Gleba. Have clockwork robots fill a platform request through the nutrient silo. Load local propellant for both legs. Fly to Nauvis, deliver a Gleba product, then return to Gleba. |

At the launch-fuel boundary use the ordinary fuel recipe with local metals,
recovered mineral salts and fixed-carbon feedstocks. Give the salt and sodium
routes a source in the leach residue. Check the loose and boxed products. On
the platform use the normal solar-powered equipment and the existing canister
conditioning recipe. The zero-electricity requirement applies on the surface.

The industrial checkpoints keep their action and threshold on both planets. On Gleba, nutrient machines count for placement, clockwork logistics count for robot work, and processed minerals count by their material yield.

Rocket Science 1, Composites 2, Rocket Science 2
and Orbital Construction each cost 800 units with two physics packs per unit.
Together these four technologies consume **6,400 physics packs**. Size the
Gleba physics line against that demand. As a first balance target, sustain
25 loose physics packs per minute together with the five lower pack lines.
At that rate the physics packs alone take 256 minutes.

### Global research

Research is global but cultures are physical, so pre-cargo rewards are recipes
and modes that other planets can use with their own inputs.

| Reward | Effect |
|---|---|
| Nutrient Technology | Bioreactor tier 1, digestate disposal and the Nauvis goop route |
| Hydrocarbon Protein | The Fulgora goop route, after Primitive Filtration |
| Bioreactor Engineering 2 and 3 | Bioreactor tiers 2 and 3; biochemistry and local generic packs, priced and gated as Overcharged Assembly 2 and 3; each tier also requires its ordinary construction recipe |
| Tailings bioleaching | Once cargo delivers culture, bacteria recover metals from gravel, mineral dust, and sludge on any planet |

Bioreactor research is optional and never gates the ordinary Nauvis path.

### Late recipes

Later biology recipes may take physics or astronomy packs as ingredients, as
genome 2 recipes take astronomy packs today. Gleba makes physics packs locally
and correlates astronomy packs once it joins the array.

## Radio astronomy

| Rule | Value |
|---|---|
| Membership | Gleba joins the interferometry array with a nutrient-mode radio dish and correlator. Gleba Radio Astronomy follows Astronomy and Nutrient Technology. It costs biochemistry and physics packs in one ordinary lab |
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
| Nauvis and Fulgora, local | Goop | Fuel for bioreactors |

## Unresolved design decisions

| Decision | Options |
|---|---|
| Biology pack spoilage | Whether biology packs spoil |
| Higher-tier Gleba goop | Tier 2 and 3 bioreactors burn more goop per fixation cycle than it makes, so Gleba fixation and culture scale with tier 1 machines. Add more efficient goop recipes that only higher-tier machines can run |
| Vanilla overlap | Spoiling machine fuel is a vanilla Gleba mechanic; goop keeps its own chemistry, carbon loop, names, and values |
| Contamination | Whether screening's contaminated culture can spread to neighbouring cultures, which would make containment walls a production layout rule |
| Escaped organisms | Complex contained lines could hatch early through `spoil_to_trigger_result` and roam as an uncontrolled force. Needs a hostile force on a mod with frozen evolution; outside the planet slice |
| Living producers | Whether successful complex organisms become fed buildings that passively produce chemicals, and later the templates for Nauvis seeding |
| Existing saves | Releases up to 0.0.7 make biology packs on Nauvis. Moving them behind Gleba wild culture removes that production from those saves, so the release that moves them needs a changelog compatibility note |
