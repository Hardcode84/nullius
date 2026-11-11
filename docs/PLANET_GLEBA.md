# Gleba design

## Status and authorities

| Fact | Authority |
|---|---|
| Status | Design only |
| Planet mechanics and constraints | This document; supersedes [Space Age brainstorm 3.3](SPACE_AGE_BRAINSTORM.md#33-gleba-microbiologybreeding) where they differ |
| Shared progression, cargo, nuclear, and endgame | [Space Age brainstorm](SPACE_AGE_BRAINSTORM.md) |
| Probe access research | [Nauvis design](PLANET_NAUVIS.md) |
| Base biology chain | `nullius-star/prototypes/item/biology.lua` and its technologies |

## Role

```yaml
planet_role: geomicrobiology
setting: primordial world with native microbial mats; no plants, animals, or ruins
atmosphere: nitrogen and hydrogen sulfide; no oxygen or carbon dioxide
primary_resource: oxidized crust consumed by native bacteria
initial_access: wild microbial mats on weathered rock
power: biological redox cells; weak sunlight
surface_water: none usable for industry
local_water: released by sulfiding oxide rock
carbon: carbonate rock only; the scarce resource
metals: bioleached from rock; iron cheap, aluminum dear, no copper
local_progression: independent through physics science
pre_cargo_global_reward: research knowledge of wild genomes and bioleaching
exports: genomes and progenitors, uranium, uranium-reducing culture, sulfur compounds, iron
imports: carbon-rich materials, copper, aluminum
```

## Decisions

| Question | Decision |
|---|---|
| Probe timing | Tier 3, at Organic Chemistry 1, as in [Nauvis design](PLANET_NAUVIS.md#23-per-planet-reactivation) |
| Biology before nanotechnology | Native wild strains exist on Gleba; culturing them needs no genome, nanofabricator, or Biochemistry 1 |
| Metals | Bioleaching of local rock; no ore deposits |
| Production decline | Comes from carbon and rock mass balance, not a loss factor; see [Carbon](#carbon) |
| Random breeding | Probabilistic recipes never carry a closure; see [Randomness rule](#randomness-rule) |
| Aerobic organisms | Cannot grow on Gleba; see [Biology pack split](#biology-pack-split) |
| Escaped organisms | Not part of the planet slice |

## Environmental constraints

| Constraint | Consequence |
|---|---|
| Hydrogen sulfide atmosphere | New surface property `nullius-hydrogen-sulfide`, default 0, positive on Gleba only. Wild-strain and sulfide recipes require it above 0 |
| No oxygen | Combustion needs manufactured oxygen; aerobic growth recipes require `nullius-hydrogen-sulfide` at 0 |
| Oxidants poison the mats | Gleba cannot vent oxygen or sulfur dioxide; void recipes for both require `nullius-hydrogen-sulfide` at 0 |
| No carbon dioxide | Carbon comes from carbonate rock through acid neutralization |
| No usable surface water | No offshore pumps or water wells; water comes from rock sulfidation and biomass dewatering |
| Thick haze | `solar-power` well below Nauvis; panels work but cannot carry a factory |
| No ore deposits | Metals come from leach liquors |
| No copper | Gleba rock carries no copper; Fulgora stays the sole primary copper source |

## Core loop

```
reduced atmosphere (H2S)  +  oxidized crust (ferric oxide, sulfate, carbonate, silicate)
          |                              |
          +---- native bacteria ---------+
                     |
                     +-- energy:  sulfide oxidized by ferric iron in redox cells
                     +-- acid:    sulfur oxidation makes sulfuric acid liquor
                     +-- metals:  acid liquor dissolves iron, aluminum, uranium
                     +-- carbon:  acid neutralized on carbonate releases CO2 for fixation
                     +-- water:   ferric oxide + H2S -> iron sulfide + water
                     +-- waste:   gypsum, iron sulfide, silica residue
```

Rock is fuel, ore, carbon source, and water source at once. Scale is bounded by
rock throughput.

## Resource model

### Rock

| Rule | Value |
|---|---|
| Form | Rock resource patches mined by ordinary miners; infinite, as Vulcanus lava and Fulgora vents |
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
| Sulfur oxidizer | *Acidithiobacillus* | Oxidizes sulfur and sulfide with ferric iron | Acid liquor, leaching, uranium leaching |
| Iron reducer | *Geobacter* | Reduces ferric iron; transfers electrons to electrodes | Microbial fuel cells; the uranium-reducing culture for mission goal 11 |
| Sulfate reducer | *Desulfovibrio* | Reduces sulfate to sulfide | Precipitates metals from liquor as sulfides; regenerates H2S |
| Purple sulfur phototroph | Purple sulfur bacteria | Fixes CO2 with light and H2S; makes sulfur, not oxygen | The only local carbon fixation |

| Grade | Source | Rule |
|---|---|---|
| Wild | Mat culture | Deterministic, slow, short spoil time |
| Domesticated | Serial passage of wild culture | Deterministic floor recipe |
| Selected | Screening of domesticated culture | Probabilistic improved strain; failures leave dead culture |
| Engineered | Genome route | Later research; see [Global research](#global-research) |

### Carbon

| Rule | Value |
|---|---|
| Source | Carbonate rock neutralizing acid liquor releases CO2; phototrophs fix it into biomass |
| Sinks | Methane, exported organics, plastics, biomass spoilage to sludge, fuel-cell consumption |
| Decline | Every loop exports carbon, so it needs fresh rock. No loop returns more carbon than it receives |
| Pressure | Acid neutralization is mandatory waste handling and the carbon supply; more leaching means more carbon |

### Water and oxygen

| Fluid | Source | Constraint |
|---|---|---|
| Water | Sulfiding ferric oxide; biomass dewatering | Low and tied to rock throughput |
| Oxygen | Water electrolysis; gypsum decomposition | Cannot be vented; must be consumed in combustion or chemistry |

### Metals

| Metal | Route | Cost driver |
|---|---|---|
| Iron | Ferrous sulfate liquor, then electrowinning or precipitation and smelting | Cheap: the leach liquor is the power-cycle waste |
| Aluminum | Acid leaching of aluminosilicate residue with organic acids | Dear: organic acids cost fixed carbon |
| Silicon | Silica residue | Cheap byproduct |
| Calcium | Gypsum from neutralization | Byproduct |
| Uranium | Uranyl sulfate liquor to yellowcake, as [Fission branch](SPACE_AGE_BRAINSTORM.md#fission-branch) | Trace; bulk needs scale |
| Copper, titanium | None | Import |

## Byproducts

| Byproduct | Handling |
|---|---|
| Acid liquor | No void on Gleba; neutralize on carbonate, which yields gypsum and CO2 |
| Oxygen | No void on Gleba |
| Sulfur dioxide | No void on Gleba; reduce back to sulfur with H2S |
| Gypsum, iron sulfide | Solid waste; decomposition or disposal recipes |
| Contaminated culture | Probabilistic product of screening; sterilized at a heat or acid cost |
| Dead culture | Spoil result; becomes sludge |

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
| Wild and domesticated cultures | Dead culture, then sludge | Vulcanus bloom cooling |
| Galvanic cell | Spent cell | Burnt result and spoil result together |
| Re-cultured strain | Fresh | `always_fresh` with `percent_spoiled = 0`, as antimatter recharge |
| Exported progenitors and uranium-reducing culture | Dead culture | Recurring shipments |
| Stockpiles | Averaged timers | Stack merging, as recordings and antimatter |

## Power

| Stage | Source | Mechanism | Limit |
|---|---|---|---|
| Bootstrap | Galvanic cells from the probe | Fuel item in a burner generator; biofilm dies by spoilage | Tiny output; cells need recharging in mat culture |
| Early | Microbial fuel cells | Iron-reducer culture consumes organic acid and ferric liquor | Every joule costs fixed carbon |
| Mid | Sulfide-ferric redox cells | Leached ferric liquor oxidizes H2S without biology in the cell | Rock throughput; spent ferrous liquor feeds iron recovery |
| Storage | Ferric liquor tanks | Leaching charges tanks slowly; cells discharge on demand | Tank volume, the Gleba counterpart of the Nauvis hydrogen loop |
| Supplement | Solar panels | Weak sunlight | Low output per tile |

No Stirling engines, matching the Vulcanus decision.

## Probe and bootstrap

| Step | Player outcome |
|---|---|
| Access | Biological Probe Signal Recovery activates the overrun probe on weathered rock beside mats |
| Pre-transfer research | Wild Strain Cultivation, researched on Nauvis with early packs, unlocks mat culture and acid leaching |
| Power | Burn salvaged galvanic cells, then recharge them from mat culture |
| Materials | Mine and crush rock, leach it, neutralize the liquor, recover iron and silica |
| Carbon | Grow phototroph biomass from neutralization CO2 |
| Construction | Build basic machines and logistics from leached iron and recovered silica |
| Research | Local generic packs and geomicrobiology packs |

### Starter inventory

Supplied once per force on activation, from a shared starter file like
`nullius-star/shared/vulcanus-starter.lua`.

| Equipment | First use |
|---|---|
| Lab 1 | Local research |
| Walls | Containment of the culture area |
| Flotation cell | Mat culture, leaching, neutralization |
| Hydro plant | Water recovery and liquor handling |
| Crusher | Rock crushing |
| Small miner | Rock |
| Electrolyzer | Iron electrowinning, water electrolysis |
| Small furnace | Iron sulfide and gypsum treatment |
| Burner generator and galvanic cells | First power |
| Pipes, pumps, tanks | Liquor and water |
| Belts, inserters, chests | Solid transport |

No ore, carbon, fuel beyond the galvanic cells, science packs, or bottled fluids.

## Science and research

### Local packs

| Pack | Gleba route |
|---|---|
| Geology | Crushed rock and leach residue |
| Climatology | Atmospheric hydrogen sulfide and nitrogen |
| Mechanical | Leached-iron gears |
| Electrical | Leached iron and aluminum; bacterial polyhydroxyalkanoate replaces plastic; the bootstrap audit names every other substitute |
| Geomicrobiology | Planet pack: selected strains, leach products, and biomass |

### Global research

Research is global but cultures are physical, so pre-cargo rewards are recipes
that Nauvis can make from its own inputs.

| Reward | Effect |
|---|---|
| Wild genome sequencing | A cheaper bacteria-genome recipe on Nauvis without physics packs; still requires Biochemistry 1 inputs |
| Tailings bioleaching | After Biology 1, Nauvis bacteria recover metals from gravel, mineral dust, and sludge |
| Seawater Uranium Adsorption | Cost moves from Nauvis biology packs to geomicrobiology packs, as [Seawater uranium](SPACE_AGE_BRAINSTORM.md#seawater-uranium) |

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
| Nauvis or Vulcanus to Gleba | Aluminum | Replaces carbon-expensive local leaching |

## Changes to existing designs

| Document | Change |
|---|---|
| Space Age brainstorm 3.3 | Gleba access at tier 3 replaces "Gleba access (Tier 4-5)"; carbon-balance decline replaces the 95% recycling loss; bacterial-harvester salvage maps to the starter inventory above |
| Space Age brainstorm 2.4 | Carbon cannot be a pre-cargo import; local carbon is carbonate rock |
| Space Age brainstorm 6 | The Gleba planet pack is geomicrobiology, not "Biological" |
| Nauvis design 2.3 | Biological Probe Signal Recovery keeps Organic Chemistry 1 and adds Wild Strain Cultivation as the pre-transfer research |

## Unresolved design decisions

| Decision | Options |
|---|---|
| Mat form | Infinite resource on mat tiles or harvested entities with regrowth |
| Astronomy array | Whether Gleba joins the array. Joining changes the square-root rule, the correlation ladder, and possibly the reference transit in `shared/reference-transit.lua`, which bounds recording and antimatter spoil times |
| Geomicrobiology pack spoilage | Whether the pack spoils, like the vanilla agricultural pack |
| Local silo | Default silo from leached iron, or a Gleba variant; decided by the launch closure audit |
| Hostile organisms | Escapes need a hostile force on a mod with frozen evolution; outside the planet slice |

## Acceptance contracts

| Contract | Check |
|---|---|
| Surface | `surface-mapgen-contract` covers Gleba terrain, rock, mats, and no natural enemies |
| Surface conditions | Aerobic growth, oxygen void, and sulfur dioxide void fail on Gleba; wild-strain recipes fail elsewhere |
| Randomness | Every Gleba closure passes with probabilistic results uncredited |
| Bootstrap | A finite starter inventory reproduces basic machines and logistics without imports |
| Carbon | No Gleba recipe cycle returns more carbon than it consumes |
| Power | Galvanic, microbial, and redox cells deliver power in placed generators; redox tanks buffer it |
| Science | Local generic and geomicrobiology packs close at their research with `--require-no-additional-technologies` |
| Launch | Gleba builds a silo and launches a rocket with zero imports |
| Global rewards | Each Nauvis recipe that Gleba research unlocks closes on the Nauvis boundary at that research |
