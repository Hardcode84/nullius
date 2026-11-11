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
local_progression: independent through physics science
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
| Composition | Ferric oxide, sulfate, carbonate, silicate, and trace uranium; no copper |
| Residue | Silica sand and mineral dust from leached rock |

### Microbial mats

| Rule | Value |
|---|---|
| Role | The only source of wild culture, and so of all life in the game |
| Form | Open question: a slow infinite resource on mat tiles or a harvested decorative entity |
| Output | Wild culture item; spoils into sludge |

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
| Hydrogen | Thermal splitting of H2S in goop-fired furnaces | Abundant; sulfur coproduct |
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
| Logistics | Clockwork robots from [Vulcanus primitive logistics](PLANET_VULCANUS.md#primitive-logistics); normal logistic robots forbidden on Gleba |
| Flotation cells | Bioreactor mode deferred until tiers 1-3 have been played |
| Exclusive pairs | No machine belongs to two improved families: assemblers stay Fulgora, crushers, furnaces, and foundries stay Vulcanus |

## Biology branch

All biology research becomes one branch rooted at Gleba access. It runs in
parallel with the main tree instead of hanging from tiers 5-7.

### Current coupling

From the technology source. The release check below replaces this table as
the authority once the branch exists.

| Direction | Count | Technologies |
|---|---:|---|
| Biology technologies with main-tree prerequisites | 34 | Biochemistry 1-5, 7, 8; Biology 1-2; Botany 1-2; Ecology 1-6; Evolution 1-7; Zoology 1-3; Carbon Sequestration 4; Locomotion 5; Nitrogen Chemistry 3; Personal Transportation 5; Weaving 3; Wildlife Management 2; Woodworking |
| Main-tree technologies requiring biology | 8 | Artificial Intelligence 2, Battery Storage 5, Cybernetics 7, Genetic Archive 1 and 2, Rocket Science 3, Solar Power 4, Uranium Processing |

36 technologies cost biology packs, and every one costs only biology packs.
Biochemistry 1 costs ordinary packs and unlocks the biochemistry pack and the
biology lab.

### Branch rules

| Rule | Value |
|---|---|
| Root | Wild Strain Cultivation and Biological Probe Signal Recovery. Biochemistry 1 follows them and drops Physics and Organic Chemistry 6 |
| Early branch | Prerequisites inside the branch only, plus generic research reachable with Gleba local science |
| Late anchors | Later biology research may keep prerequisites on higher Nauvis organic research. Each kept anchor is listed in the release check with the unlock that needs it |
| Deployment checkpoints | Organism checkpoints count production on any surface, so Gleba contained culture can satisfy them. The oxygen checkpoints stay Nauvis-only and gate late Ecology research: Nauvis seeding progress feeds Gleba research |
| Genetic archives | Genetic Archive 1 and 2 join the branch |
| Outbound edges | A main-tree technology may require biology only at the endgame. Each kept edge is listed in the release check with the unlock that needs it |
| Pack costs | Branch research costs only biology packs, as today. Gleba-only research with generic packs, such as Bioreactor Engineering, costs the biochemistry pack plus local generic packs |
| Route length | Branch closures are parallel routes. The main-tree route to every non-biology technology keeps its current closure minus the removed biology prerequisites |
| Pacing | `tests/progression/research-pacing.args` compares branch closure costs before and after the move |

### Release check

`tools/check_biology_branch.py`, following `tools/check_nuclear_research.py`:

| Check | Fails when |
|---|---|
| Containment | A biology technology's closure contains a main-tree technology outside the declared late anchors |
| Isolation | A main-tree technology's closure contains a biology technology outside the declared outbound edges |
| Moved closures | Restoring the removed prerequisites in a copy of the tree changes any remaining technology's closure other than by the removed technologies |
| Craftability | An unlock of a moved technology no longer closes at it on the Gleba boundary with `--require-no-additional-technologies` |

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
| Carbon | Light on carbon. Late packs that need wood, cellulose, or plastic in bulk use imported Fulgora organics after cargo |
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
| Pre-transfer research | Wild Strain Cultivation, researched on Nauvis with early packs, unlocks mat culture, acid leaching, chemosynthetic goop, nutrient mode, bioreactor tier 1, and the bootstrap biochemistry pack |
| Energy | Burn the starter goop, then culture mats and grow chemosynthetic goop from crushed rock |
| Materials | Mine and crush rock, leach it, neutralize the liquor, reduce iron with hydrogen from H2S |
| Construction | Build basic machines and logistics from reduced iron and recovered silica |
| Research | Local generic packs and bootstrap biochemistry packs in nutrient-mode labs |

### Starter inventory

Supplied once per force on activation, from a shared starter file like
`nullius-star/shared/vulcanus-starter.lua`. Machines arrive as ordinary items and
switch to nutrient mode.

| Equipment | First use |
|---|---|
| Lab 1 | Local research |
| Walls | Containment of the culture area |
| Flotation cell | Mat culture, leaching, neutralization |
| Chemical plant | Chemosynthetic goop |
| Hydro plant | Water recovery and liquor handling |
| Crusher | Rock crushing |
| Small miner | Rock |
| Small furnace | H2S splitting, iron reduction, gypsum treatment |
| Goop and a starter culture | First fuel and inoculum |
| Pipes, pumps, tanks | Liquor and water |
| Belts, inserters, chests | Solid transport and fuel distribution |

No ore, carbon beyond the goop, science packs, or bottled fluids.

## Science and research

### Local packs

| Pack | Gleba route |
|---|---|
| Geology | Crushed rock and leach residue |
| Climatology | Atmospheric hydrogen sulfide and nitrogen |
| Mechanical | Reduced-iron gears |
| Electrical | Reduced iron and dear aluminum; bacterial polyhydroxyalkanoate replaces plastic; the bootstrap audit names every other substitute |
| Chemical, physics | Local routes, as Vulcanus and Fulgora, for genome recipes that take them and for the main tree |

### Biochemistry pack

| Rule | Value |
|---|---|
| Role | Gleba planet pack from probe access, as metallurgic and electromagnetic packs |
| Bootstrap recipe | Wild culture extracts and local generic packs; unlocks with Wild Strain Cultivation |
| Improved recipe | The current recipe with contained inputs; unlocks with Biochemistry 1 |
| Labs | Ordinary labs accept it, so Gleba research can mix it with generic packs; biology labs accept it as today |
| Early availability | Holding packs early does not open biology research early: branch research keeps its own prerequisites |

### Global research

Research is global but cultures are physical, so pre-cargo rewards are recipes
and modes that other planets can use with their own inputs.

| Reward | Effect |
|---|---|
| Wild Strain Cultivation | Bioreactor tier 1 and goop routes on Nauvis and Fulgora |
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
| Membership | Gleba joins the interferometry array with a nutrient-mode radio dish |
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
| Space Age brainstorm 4.7 | Seawater Uranium Adsorption: see the unresolved decision below |
| Nauvis design 2.3 | Biological Probe Signal Recovery keeps Organic Chemistry 1 and adds Wild Strain Cultivation as the pre-transfer research |
| Nauvis design 6 | Advanced biology packs require Gleba: all biology research starts there |

## Unresolved design decisions

| Decision | Options |
|---|---|
| Seawater Uranium Adsorption | Today it costs biology packs and Uranium Processing requires it, so fission would require Gleba. Either keep that outbound edge, or cost it in ordinary packs so Nauvis fission stays independent of Gleba. The adsorbent uses industrial amino acids, not a living culture |
| Late anchors and outbound edges | Which of the 34 main-tree prerequisites and 8 outbound edges survive, decided per unlock by the release check |
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
| Electricity | Every Gleba closure rejects electricity-required paths, as `vulcanus-launch-closure.args` |
| Seeds | On the Nauvis boundary without imports, no living product closes; with declared wild culture, the ordinary biology chain closes at its research |
| Biology branch | `tools/check_biology_branch.py` passes in the release build |
| Contained culture | Every biology pack closes on the Gleba boundary at the research that unlocks it |
| Randomness | Every Gleba closure passes with probabilistic results uncredited |
| Spoiled fuel | Engine witness: spoiled goop and digestate leave fuel and burnt-result slots of placed nutrient machines |
| Goop energy | A release check fails if a Nauvis or Fulgora goop recipe yields more fuel value than its organic inputs |
| Carbon | No Gleba recipe cycle, including the goop-digestate loop, returns more carbon than it consumes |
| Machine modes | Transitions between ordinary, nutrient, and bioreactor modes keep recipes and contents and never create energy or health |
| Bootstrap | A finite starter inventory reproduces basic machines and logistics without imports |
| Science | Local generic and bootstrap biochemistry packs close at their research with `--require-no-additional-technologies` |
| Bioreactor closure | Goop on Nauvis and Fulgora closes on each boundary at the research that unlocks bioreactor tier 1 |
| Transit | `astronomy-transit` measures the Gleba-Nauvis leg and the reference transit stays at its current value |
| Launch | Gleba builds a nutrient silo and launches a rocket with zero imports |
| Spoiling exports | Every spoiling Gleba export outlasts the recording spoil time |
