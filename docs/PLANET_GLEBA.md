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
planet_role: geomicrobiology
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
pre_cargo_global_reward: bioreactor chemical and hydro plants
exports: genomes and progenitors, uranium, uranium-reducing culture, sulfur compounds, iron
imports: carbon-rich materials, copper, aluminum
```

## Decisions

| Question | Decision |
|---|---|
| Probe timing | Tier 3, at Organic Chemistry 1, as in [Nauvis design](PLANET_NAUVIS.md#23-per-planet-reactivation) |
| Biology before nanotechnology | Native wild strains exist on Gleba; culturing them needs no genome, nanofabricator, or Biochemistry 1 |
| Electricity | None on Gleba. Machines burn nutrient goop, as Vulcanus machines burn volcanic gas |
| Global machine reward | Bioreactor chemical plants and hydro plants, the families [Fulgora](PLANET_FULGORA.md#overcharged-assemblers) reserves for other planets |
| Metals | Bioleaching of local rock; no ore deposits |
| Production decline | Comes from carbon and rock mass balance, not a loss factor; see [Carbon](#carbon) |
| Random breeding | Probabilistic recipes never carry a closure; see [Randomness rule](#randomness-rule) |
| Aerobic organisms | Cannot grow on Gleba; see [Biology pack split](#biology-pack-split) |
| Escaped organisms | Not part of the planet slice |

## Environmental constraints

| Constraint | Consequence |
|---|---|
| Hydrogen sulfide atmosphere | New surface property `nullius-hydrogen-sulfide`, default 0, positive on Gleba only. Wild-strain and sulfide recipes require it above 0 |
| No electricity | Generators, solar panels, wind turbines, and accumulators cannot be placed on Gleba; electric-only machines have no power source |
| No oxygen | Nothing combusts; oxygen is a chemistry input only. Aerobic growth recipes require `nullius-hydrogen-sulfide` at 0 |
| Oxidants poison the mats | Gleba cannot vent oxygen or sulfur dioxide; void recipes for both require `nullius-hydrogen-sulfide` at 0 |
| No carbon dioxide | Carbon comes from carbonate rock through acid neutralization |
| No usable surface water | No offshore pumps or water wells; water comes from rock sulfidation and biomass dewatering |
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
| Role | Inoculum source for wild strains, not bulk feedstock |
| Form | Open question: a slow infinite resource on mat tiles or a harvested decorative entity |
| Output | Wild mat culture item; spoils into sludge |

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
| Engineered | Genome route | Later research; see [Global research](#global-research) |

### Carbon

| Rule | Value |
|---|---|
| Source | Carbonate rock neutralizing acid liquor releases CO2; chemosynthesis and phototrophs fix it |
| Circulation | Goop burned in machines leaves digestate; chemosynthesis takes digestate back with a fixed carbon loss |
| Sinks | The digestate loss, methane, exported organics, plastics, spoilage to sludge |
| Decline | Every loop exports carbon, so it needs fresh rock. No loop returns more carbon than it receives |
| Pressure | Energy and materials share one carbon pool. Acid neutralization is mandatory waste handling and the carbon supply |

### Water and oxygen

| Fluid | Source | Constraint |
|---|---|---|
| Water | Sulfiding ferric oxide; biomass dewatering | Low and tied to rock throughput |
| Hydrogen | Thermal splitting of H2S in goop-fired furnaces | Abundant; sulfur coproduct |
| Oxygen | Gypsum decomposition | Chemistry input only; cannot be vented |

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
| Nauvis route | Single-cell protein from ordinary organic chemistry, as the ICI Pruteen process made from methanol and ammonia. It closes on Nauvis at the research that unlocks it |
| Fulgora route | Hydrocarbons and ammonia |
| Vulcanus | No route; Vulcanus has thermal machines |
| Energy bound | On Nauvis and Fulgora, goop fuel value per craft is below the fuel value of its organic inputs, so goop never generates net energy |

The spent-goop carbon loss is a design value fixed with the Gleba power balance.

## Machine modes

| Family | Mode | Surface | Bonus | Fuel |
|---|---|---|---|---|
| The Vulcanus pneumatic list: assemblers, boxers, barrel pumps, filters, hydro plants, distilleries, chemical plants, compressors, flotation cells, labs, extractors, pumps, inserters, miners | Nutrient | Gleba | None | Goop |
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
| Wild and domesticated cultures | Dead culture, then sludge | Vulcanus bloom cooling |
| Re-cultured strain | Fresh | `always_fresh` with `percent_spoiled = 0`, as antimatter recharge |
| Exported progenitors and uranium-reducing culture | Dead culture | Recurring shipments |
| Stockpiles | Averaged timers | Stack merging, as recordings and antimatter |

A spoiled item that stays in a one-slot fuel inventory blocks the burner, as the
antimatter-trap migration found. Before goop is designed around it, an
engine-witness scenario records whether inserters remove spoiled items from fuel
inventories and whether digestate in the burnt-result slot is removed.

## Probe and bootstrap

| Step | Player outcome |
|---|---|
| Access | Biological Probe Signal Recovery activates the overrun probe on weathered rock beside mats |
| Pre-transfer research | Wild Strain Cultivation, researched on Nauvis with early packs, unlocks mat culture, acid leaching, chemosynthetic goop, nutrient mode, and bioreactor tier 1 |
| Energy | Burn the starter goop, then culture mats and grow chemosynthetic goop from crushed rock |
| Materials | Mine and crush rock, leach it, neutralize the liquor, reduce iron with hydrogen from H2S |
| Construction | Build basic machines and logistics from reduced iron and recovered silica |
| Research | Local generic packs and geomicrobiology packs in nutrient-mode labs |

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
| Geomicrobiology | Planet pack: selected strains, leach products, and biomass |

### Global research

Research is global but cultures are physical, so pre-cargo rewards are recipes
and modes that other planets can use with their own inputs.

| Reward | Effect |
|---|---|
| Wild Strain Cultivation | Bioreactor tier 1 and goop routes on Nauvis and Fulgora |
| Bioreactor Engineering 2 and 3 | Bioreactor tiers 2 and 3; geomicrobiology packs priced as Overcharged Assembly 2 and 3; each tier also requires its ordinary construction recipe |
| Wild genome sequencing | A cheaper bacteria-genome recipe on Nauvis without physics packs; still requires Biochemistry 1 inputs |
| Tailings bioleaching | After Biology 1, Nauvis bacteria recover metals from gravel, mineral dust, and sludge |
| Seawater Uranium Adsorption | Cost moves from Nauvis biology packs to geomicrobiology packs, as [Seawater uranium](SPACE_AGE_BRAINSTORM.md#seawater-uranium) |

Bioreactor research is optional and never gates the ordinary Nauvis path.

### Biology pack split

| Pack | Home |
|---|---|
| Biochemistry, microbiology | Nauvis recipes stay; Gleba gains anaerobic routes once it reaches chemical science |
| Botany, dendrology, nematology, ichthyology, zoology | Nauvis grows the organisms; aerobic growth cannot run on Gleba |
| Genome and progenitor stage | Gleba genome recipes use geomicrobiology packs instead of Nauvis packs; progenitors are a perishable post-cargo export |

## Cross-planet effects

| Flow | Content | Driver |
|---|---|---|
| Gleba to Nauvis | Genomes and progenitors | Cheaper biology tiers; spoilage makes them recurring |
| Gleba to Nauvis | Uranium-reducing culture | Mission goal 11, as [biomineralization](SPACE_AGE_BRAINSTORM.md#mission-goal-11-biomineralization) |
| Gleba to Nauvis | Yellowcake | Bulk fission supply, as bacterial leaching |
| Gleba to Vulcanus | Demolisher feed | [Post-cargo demolisher concept](PLANET_VULCANUS.md#post-cargo-demolisher-concept) |
| Fulgora to Gleba | Organics | Carbon: Fulgora is carbon-rich and metal-poor, Gleba the reverse |
| Fulgora to Gleba | Copper | Sole primary source |
| Nauvis or Vulcanus to Gleba | Aluminum | Replaces carbon-expensive local reduction |
| Nauvis and Fulgora, local | Goop | Fuel for bioreactor chemical and hydro plants |

## Changes to existing designs

| Document | Change |
|---|---|
| Space Age brainstorm 3.3 | Gleba access at tier 3 replaces "Gleba access (Tier 4-5)"; carbon-balance decline replaces the 95% recycling loss; nutrient goop replaces the biological power ladder; the bacterial-harvester salvage maps to the starter inventory above |
| Space Age brainstorm 2.4 | Gleba local power is goop, not galvanic cells; carbon cannot be a pre-cargo import |
| Space Age brainstorm 6 | The Gleba planet pack is geomicrobiology, not "Biological" |
| Nauvis design 2.3 | Biological Probe Signal Recovery keeps Organic Chemistry 1 and adds Wild Strain Cultivation as the pre-transfer research |

## Unresolved design decisions

| Decision | Options |
|---|---|
| Mat form | Infinite resource on mat tiles or harvested entities with regrowth |
| Astronomy array | Whether Gleba joins the array. Joining needs a nutrient radio dish and changes the square-root rule, the correlation ladder, and possibly the reference transit in `shared/reference-transit.lua`, which bounds recording and antimatter spoil times |
| Geomicrobiology pack spoilage | Whether the pack spoils |
| Flotation cell bioreactors | Whether flotation cells join the bioreactor family |
| Vanilla overlap | Spoiling machine fuel is a vanilla Gleba mechanic; goop keeps its own chemistry, carbon loop, names, and values |
| Hostile organisms | Escapes need a hostile force on a mod with frozen evolution; outside the planet slice |

## Acceptance contracts

| Contract | Check |
|---|---|
| Surface | `surface-mapgen-contract` covers Gleba terrain, rock, mats, and no natural enemies |
| Surface conditions | Aerobic growth, oxygen void, sulfur dioxide void, and electricity generators fail on Gleba; wild-strain recipes fail elsewhere |
| Electricity | Every Gleba closure rejects electricity-required paths, as `vulcanus-launch-closure.args` |
| Randomness | Every Gleba closure passes with probabilistic results uncredited |
| Spoiled fuel | Engine witness: spoiled goop and digestate leave fuel and burnt-result slots of placed nutrient machines |
| Goop energy | A release check fails if a Nauvis or Fulgora goop recipe yields more fuel value than its organic inputs |
| Carbon | No Gleba recipe cycle, including the goop-digestate loop, returns more carbon than it consumes |
| Machine modes | Transitions between ordinary, nutrient, and bioreactor modes keep recipes and contents and never create energy or health |
| Bootstrap | A finite starter inventory reproduces basic machines and logistics without imports |
| Science | Local generic and geomicrobiology packs close at their research with `--require-no-additional-technologies` |
| Bioreactor closure | Goop on Nauvis and Fulgora closes on each boundary at the research that unlocks bioreactor tier 1 |
| Launch | Gleba builds a nutrient silo and launches a rocket with zero imports |
| Global rewards | Each Nauvis recipe that Gleba research unlocks closes on the Nauvis boundary at that research |
