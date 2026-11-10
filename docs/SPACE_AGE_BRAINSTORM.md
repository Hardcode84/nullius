# Nullius x Space Age -- Brainstorming Document

> **Started**: 2026-03-22
> **Status**: Early brainstorming
> **Reconciled**: 2026-07-27 against the Vulcanus implementation (two-tier radiators, pneumatic-only power, no Stirling) and Factorio engine mechanics (monopole reactor conservation, spoil-timer stack merging, EMP targeting).
> **Premise**: Adapt Nullius's android terraforming narrative and chemistry-driven production to work with Space Age's multi-planet expansion.

---

## 1. Fundamental Conflicts to Resolve

### 1.1 Recipe and Resource Conflicts

| Conflict | Nullius Current | Space Age Expects | Resolution Options |
|---|---|---|---|
| **Coal/oil** | Removed entirely | Vulcanus uses coal-like processes; Gleba produces bioflux | A) Keep removed on Nauvis, available on other planets. B) Replace SA planet resources with Nullius equivalents. |
| **Copper** | Asteroid-only (endgame) | Available as basic resource everywhere | Fulgora is the sole primary source; late-game deep extraction replaces asteroid copper. See [Fulgora design](PLANET_FULGORA.md#late-game-copper). |
| **Vanilla recipes** | All replaced | SA adds planet-specific recipes assuming vanilla chains | Must create Nullius-compatible versions of all SA recipes. |
| **Vanilla intermediates** | Replaced (aluminum wire instead of copper, etc.) | SA builds on vanilla intermediates | Remap SA intermediates to Nullius equivalents. |

### 1.2 System Conflicts

| Conflict | Nullius Current | Space Age Adds | Resolution Options |
|---|---|---|---|
| **Quality** | Loaded transitively by Space Age | Items have quality tiers | Keep loaded; disable quality effects, modules, and generated recycling in Nullius*. |
| **Tech tree** | Fully replaced, checkpoint-gated | Planet-specific tech branches | Merge: Nullius tiers 1-4 on Nauvis, tiers 5-7 split across planets. |
| **Science packs** | 15 Nullius-specific packs | Planet-specific packs (metallurgic, electromagnetic, agricultural, cryogenic) | A) Replace SA packs with Nullius packs produced on appropriate planets. B) Add SA packs as new tiers. |
| **Pollution** | Disabled | Some planets use pollution mechanics | Could remain disabled or repurpose as atmosphere contamination. |
| **Spoilage (Gleba)** | No equivalent | Items decay over time | Natural fit for Nullius biology -- could extend spoilage to biological items. |

### 1.3 Narrative Conflicts

| Conflict | Nullius | Space Age | Resolution Options |
|---|---|---|---|
| **Setting** | Android terraforming barren Nauvis | Human engineer expanding to populated planets | A) Android expands to other barren planets. B) Android discovers remnants of prior civilizations. |
| **Goal** | Terraform + seed life | Industrialize + research | A) Each planet has a terraforming objective. B) Planets serve as resource sources for Nauvis terraforming. |
| **Enemies** | Minimal (evolution frozen) | Planet-specific enemies (pentapods on Gleba, worms on Vulcanus) | Could repurpose as native fauna to eventually integrate into ecosystem. |

---

## 2. Narrative Integration: Probe Reactivation

### 2.1 Core Concept

The von Neumann program sent **multiple probes** to the star system, one per planet. The player's android on Nauvis is not the first -- probes landed on all planets centuries ago but each failed in different ways. The player doesn't physically travel; instead they **reactivate dormant probes** on other planets via signal transmission, then transfer consciousness remotely.

This reframes Space Age's planet travel as:
- **No physical rocket travel** required (just signal/data transmission)
- **Each planet has a dormant probe** with minimal surviving infrastructure (broken equipment mechanic per planet)
- **Consciousness transfer** (already a Nullius mechanic) extends across planets
- The player operates multiple android bodies simultaneously across worlds

### 2.2 Why This Works

- **Explains early access**: Reactivating a probe is a moderate mid-early game research cost (signal transmission tech, not rocket engineering). Players can reach planets well before bulk logistics.
- **Explains independent bootstrap**: Each probe landed with basic equipment that partially survived. The broken equipment mechanic already exists on Nauvis -- extend it per planet. Each planet starts with a set of damaged/salvageable buildings specific to that world's environment.
- **Explains failure modes**: Each probe failed for planet-specific reasons that become the gameplay challenge:
  - **Vulcanus probe**: Overheated. Metallurgy survived but electronics melted. Must rebuild from heat-resistant components.
  - **Fulgora probe**: Electromagnetic storms fried most equipment. Surviving extractors, a filter, power equipment, pipes, one distillation column, and inserters start local production. See [Fulgora design](PLANET_FULGORA.md).
  - **Gleba probe**: Biological contamination. Organisms overran the probe. Must study and control native life.
  - **Aquilo probe**: Froze solid. Cryogenically preserved but needs heating infrastructure to thaw and restart.
- **Defers bulk logistics**: Physical cargo comes after probe access, at the start of the physics tier (rocket fuel, then a titanium-free rocket and silo, then space platforms). Early multi-planet play is about bootstrapping each probe independently using only local resources. Bulk material transfer then transforms the economy; see [Launch vehicle](#46-launch-vehicle).

### 2.3 Progression Timeline

```
EARLY-MID GAME (Nauvis Tier 2-3):
  Research: Probe Reactivation (moderate cost, requires sensor + transmitter tech)
  Effect: Unlock consciousness transfer to dormant probes on 1-2 planets
  Constraint: No cargo transfer. Must bootstrap from local resources + broken equipment.

MID GAME (Nauvis Tier 3-4):
  Research: Additional probe reactivation (each planet unlocked separately)
  Effect: Access all planets, still no bulk transfer
  Begin: Planet-specific research using local resources

EARLY TIER 5 (first physics technologies):
  Research: Rocket Science 1 (fuel), Rocket Science 2 (titanium-free rocket and silo),
            then Orbital Construction
  Effect: Rockets lift cargo to orbit; space platforms carry it between planets and drop it
  Transform: Planets shift from independent outposts to integrated supply chain
  Titanium: imported titanium makes rocket stages cheaper; it gates no launch or platform component

LATE GAME (Nauvis Tier 5+):
  Research: Astronomy (interplanetary interferometry), higher-tier platform research

ENDGAME:
  Full cross-planet logistics. Planetary specialization.
  Each planet feeds unique resources/research to Nauvis terraforming.
```

### 2.4 Independent Bootstrap Design

Each planet needs enough local resources to get started without imports. The broken equipment from the dormant probe provides initial infrastructure, but the player must figure out how to sustain and expand using only what the planet offers.

**Bootstrap requirements per planet:**

| Planet | Local Power | Local Materials | Local Chemistry | Missing (import later) |
|---|---|---|---|---|
| **Vulcanus** | Compressed volcanic gas from lava (self-fueling). Pneumatic and thermal bootstrap; electricity comes later. | Iron, aluminum, calcite from lava (need cooldown!), titanium (deep, needs demolishers) | CO2 atmosphere + HCl geysers. Thermal cracking. Ceramic/silica alt recipes. No organics. | Organics, bulk water, biology |
| **Fulgora** | Lightning (massive peaks, zero baseload) | Fixed filtration outputs: hydrocarbons, sludge, ice, salt, gypsum. Recover metals from sludge. | Hydrocarbon chemistry; filtered ice supplies water. Combustion uses manufactured oxygen. | Bulk metals, bulk oxygen and water |
| **Gleba** | Biofilm galvanic cells (tiny, constant replacement) | Bacterial loops: sulfur-metabolizing bacteria from H2S atmosphere. Net negative without breeding (mineral carbon depletion). | H2S-based biochemistry. Sulfur abundant, carbon scarce (from rocks only). No CO2, no O2. | Water (low), carbon (the scarce resource!), conventional ores, predictability, metals, stable power |
| **Aquilo** | Nuclear fusion (local fuel, but most output goes to heating) | Lithium, ammonia ice, heavy water ice, deuterium ice | Cryogenic chemistry (TBD mechanic) | Heat (defining scarcity), water, metals, biology |

**Key design constraint**: Each planet must be playable (if painful) with zero imports, up to and including building its silo and launching its first rocket. The fun comes from solving "how do I make X with only what's here?" Then later, cargo removes the pain and enables specialization.

**Broken equipment per planet** (initial probe salvage):

| Planet | Surviving Equipment | Why It Survived |
|---|---|---|
| **Vulcanus** | Furnaces, heat pipes, lava intake (toggles to free-gas vent), gas-powered inserters, pre-filled gas tank, gas pipes | Heat-resistant components survived. Electronics melted. No Stirling, no circuits. See [PLANET_VULCANUS.md](PLANET_VULCANUS.md). |
| **Fulgora** | A few extractors, a filter, power poles, capacitor banks, polymer pipes, a distillation column, basic inserters | Probe landed near a fountain. Non-metallic components survived; electronics fried by lightning. See [Fulgora design](PLANET_FULGORA.md). |
| **Gleba** | Basic lab, containment walls, bacterial harvester, water recycler | Probe landed in bacterial mat zone. Sterile equipment survived; biological seal held. Minimal power. |
| **Aquilo** | Everything, but frozen -- must thaw | Cryogenic preservation kept equipment intact but inert |

---

## 3. Planet-by-Planet Design Ideas

### 3.1 Vulcanus (Pneumatic Hell)

> **Detailed design**: See [PLANET_VULCANUS.md](PLANET_VULCANUS.md) for the resource model, production constraints, and progression intent.

**Tagline**: Gas-powered steampunk industry where lava processing IS the power source, and dual pipe routing (gas + heat) defines factory layout.

**Core identity:**
- **CO2 atmosphere**, no wind/solar (corrosive + too hot)
- **All machines run on compressed volcanic gas** (`FluidEnergySource`), not electricity
- **Lava processing produces both metals AND compressed gas** (self-fueling loop)
- **Molten metals need cooldown time** (spoilage mechanic) before they're usable
- **HCl geysers** (fixed map features) provide hydrogen and chlorine for chemistry
- **Dual pipe routing**: gas pipes (fuel) + heat pipes (waste heat) to every machine
- **Overheated radiators crack HCl** -- waste heat does useful chemistry (TFMG-thermal approach)
- **Two-tier radiators** (low-temp 200C / high-temp 450C) with standard recipe selection. No toggle script -- Deacon, SO2 decomposition, and HCl cracking are recipes picked per radiator building.
- **2-tile underground gas ducts** (hilariously short, cheap, needed constantly)
- **Titanium** via Kroll process (deep deposits, requires synthetic demolishers)
- **Demolishers**: Late-game synthetic organisms (requires Gleba bio-research), player-spawned via territory API
- **Ceramic/glass/silica alt recipes** replace all plastic/rubber-dependent components

```
POWER:     Compressed volcanic gas from lava processing (self-fueling)
           Electricity: none. No Stirling, no grid -- all machines toggled to pneumatic (Ctrl+R)
MATERIALS: Bulk metals from lava (cheap but time-gated by cooldown)
           HCl from dedicated geysers (chemistry bottleneck)
           CO2 atmosphere --> graphite, O2, trace water
MISSING:   Organics (plastic, rubber), bulk water, biology
UNIQUE:    Dual pipe networks, thermal cracking, spoilage cooldown
EXPORTS:   Titanium, bulk metals, calcite, artillery shells
IMPORTS:   Water, organics (Fulgora), bio-feed for demolishers (Gleba)
```

### 3.2 Fulgora (Hydrocarbon/Lightning)

See [Fulgora design](PLANET_FULGORA.md) for hydrocarbon filtration, lightning
power and overloads, organic industry, electromagnetic science, overcharged assemblers, and nuclear
geoengineering. Status: design only.

### 3.3 Gleba (Microbiology/Breeding)

Gleba becomes the bulk uranium source: a bred leaching strain and a perishable
biomineralizing culture. Until then, Nauvis seawater adsorption supplies fission. See [Heavy elements and nuclear branches](#47-heavy-elements-and-nuclear-branches).

**Concept**: Gleba has life -- but only **primitive bacterial and fungal** life. No animals, no plants, no complex organisms. The android arrives on a world of microbial mats, fungal networks, and bacterial biofilms. The core mechanic is **probabilistic breeding**: engineering increasingly complex organisms from this primitive base, with unpredictable and sometimes dangerous results.

#### Core Constraints
- **Low water** -- continuing the cross-planet theme. Enough for bacterial life to exist, not enough for industrial use.
- **N2 + H2S atmosphere** -- nitrogen + hydrogen sulfide. No carbon, no oxygen.
  - H2S supports sulfur-metabolizing bacteria (real extremophile chemistry)
  - H2S is lethal to complex life (a few ppm kills aerobic organisms)
  - **No atmospheric carbon** -- bacteria must scavenge carbon from mineral carbonates in rock. This is slow and limited, naturally explaining why bacterial loops are net-negative (mineral carbon depletion).
  - **No oxygen** -- only anaerobic metabolism possible. Complex organisms need O2 for efficient energy.
  - **Sulfur is abundant** (from H2S processing), **carbon is the scarce resource** (must extract from rocks or import). Inverted from Nauvis where carbon (CO2) is atmospheric and sulfur is a processed product.
  - **Terraform catch-22**: Growing complex organisms requires removing H2S and adding O2. But removing H2S kills the sulfur-metabolizing bacteria that produce your resources. You must maintain the toxic atmosphere to keep your bacterial economy running, which prevents the complex organisms you're trying to breed from surviving outside containment.
- **No conventional mining** -- initial resources come from bacterial processing loops (similar to base SA Gleba nutrient cycling).
- **Probabilistic outcomes** -- breeding new strains and organisms has random results. Not every experiment succeeds. Some fail spectacularly.

#### Early Game: Bacterial Resource Loop

Initial resource extraction mirrors base SA's biological processing but reframed as microbial engineering:

```
Native Bacterial Mats (harvestable, renewable)
    |
    v
[Basic Processing] --> Biomass + trace minerals + exotic biochemicals
    |
    v
[Bacterial Metabolism] --> Basic resources (iron bacteria --> iron dust,
                           sulfur bacteria --> sulfur,
                           silicon diatoms --> silica)
    |
    v
[Fungal Decomposition] --> Recycles waste back into feedstock
```

**Cold start is possible but painful**: The probe's broken equipment + native bacterial harvesting provides enough to bootstrap. But throughput is low, outputs are unpredictable, and the player must carefully manage the bacterial ecosystem to avoid crashing it.

**Closed-loop requirement**: Unlike Nauvis where you mine finite deposits, Gleba's bacterial resource chains are **closed loops that are slightly net negative**. Every cycle loses a small percentage of biomass/viability. Left alone, any production loop will eventually collapse.

This is the core tension: **deterministic production loops are stable but slowly dying.**

#### Mid Game: Strain Breeding (Probabilistic -- Continuous Requirement)

Breeding is NOT a one-time research step. It is an **ongoing process** that must run continuously to prevent ecosystem collapse:

```
DETERMINISTIC LOOP (production):
  Strain A + nutrients --> resources + depleted strain A'
  Depleted strain A' + recycling --> 95% strain A (net negative!)
  [Slowly decays without fresh input]

PROBABILISTIC LOOP (replenishment):
  Base culture + mutagen + nutrients --> [Breeding Chamber]
    +--> 60% Fresh viable strain (feeds back into deterministic loop)
    +--> 25% Failed strain (spoils, waste)
    +--> 10% Unexpected variant (different properties)
    +--> 5% Contamination (disrupts other cultures)

BOTH MUST RUN SIMULTANEOUSLY:
  Deterministic loop = your factory (predictable output, slowly dying)
  Probabilistic loop = life support (unpredictable, keeps factory alive)
```

**Design implications:**
- The probabilistic breeding loop is **infrastructure, not research**. You build it, you maintain it, it runs forever. If it stops, your deterministic production chains gradually collapse.
- Player must size the breeding operation to match the decay rate of all active production loops. More production = more breeding capacity needed.
- Failed strains spoil (spoilage mechanic!), creating continuous waste management pressure.
- Contamination events from the breeding loop can cascade into the production loops, disrupting established cultures. Containment infrastructure matters.
- **Scaling is the challenge**: Every new production chain adds decay pressure. The breeding loop must grow proportionally. Unlike Nauvis where you "just build more miners," on Gleba expansion has a biological maintenance cost.
- Unexpected variants from breeding are sometimes more valuable than the target -- encourages keeping the breeding loop oversized, which costs more nutrients but increases serendipity.
- **RNG streak mitigation**: independent 60% rolls average out over many crafts, but early-game throughput is low, so an unlucky streak stalls bootstrap exactly when the player can least afford it. Mitigations: a deterministic fallback recipe (slower and nutrient-hungry, but guaranteed viable output) as the safety floor, and/or a scripted pity mechanic (guaranteed viable strain after N consecutive failures).

**Exotic chemistry from specialized strains:**
- Strains that produce chemicals impossible through conventional synthesis
- Exotic enzymes, bio-catalysts, novel polymers
- These become Gleba's unique exports -- chemicals no other planet can produce

#### Late Game: Complex Organism Breeding

With enough biological mastery, the android attempts to breed **complex multicellular organisms** from the bacterial/fungal base. This is where things get really interesting and dangerous.

```
Engineered Genome + Growth Medium + Containment --> [Incubation]
    |
    +--> Successful Organism (useful: bio-factory, resource producer)
    +--> Inert Failure (dead on arrival, waste disposal)
    +--> PREMATURE HATCH (organism escapes containment!)
```

**Premature hatching**:
- Complex organisms can hatch/emerge before the android is ready
- Escaped organisms are **not controllable** -- they roam, consume resources, may attack infrastructure
- Not a game-ender (they're still engineered organisms, not apex predators) but a serious disruption
- Player must balance ambition (breeding powerful organisms) against risk (bigger organisms = harder to contain if they escape)
- Containment infrastructure (walls, traps, kill zones) becomes important -- not for defense against natives, but defense against your own creations

**Narrative parallel to Vulcanus demolishers**: On Vulcanus the android creates life for industrial extraction. On Gleba the android creates life as a biological experiment. Both can go wrong. Different failure modes -- demolishers destabilize terrain, Gleba organisms escape and consume resources.

**Successful complex organisms**:
- Living bio-factories that passively produce specific chemicals/materials
- Self-replicating (renewable resource source)
- Require feeding and environmental management
- Eventually: the organism designs proven on Gleba become the templates for **Nauvis seeding** (worms, fish, arthropods are refined versions of Gleba experiments)

#### Gleba's Role in the Biology Progression

Current Nullius biology is entirely on Nauvis. With Gleba:

```
NAUVIS (current):
  Industrial bootstrap --> fatty acids --> basic biology
  Seeding organisms designed elsewhere

GLEBA (new):
  Bacterial harvesting --> strain breeding --> complex organism design
  The actual biological R&D happens here
  Exports: proven organism designs, exotic biochemicals, biology packs

PROGRESSION:
  Nauvis basic bio (Tier 3-4) --> Gleba access (Tier 4-5) -->
  advanced strain breeding --> complex organism design -->
  export proven designs back to Nauvis for seeding (Tier 6-7)
```

Biology packs could split: basic bio-packs still producible on Nauvis, but advanced biology packs (dendrology, ichthyology, zoology, evolution) require Gleba-bred organisms or Gleba-exclusive biochemicals.

#### Power Progression

All power on Gleba is biologically derived. No wind, no geothermal, minimal solar (thick atmosphere). Power generation itself is part of the biological ecosystem and subject to the same decay/breeding pressures.

| Tier | Source | Output | Mechanic |
|---|---|---|---|
| **Bootstrap** | Biofilm galvanic cells | Tiny (kW range) | Harvest bacterial mats, crude wet-cell batteries from probe electrodes. High maintenance, constant replacement. |
| **Early** | Microbial fuel cells | Low (tens of kW) | Engineered bacteria generate current directly. First bred strain. Decays, needs breeding maintenance. |
| **Mid** | Thermogenic bacteria + Stirling engines | Moderate (MW range) | Exothermic bacterial metabolism produces heat. Stirling engines (existing Nullius tech) convert to electricity. Bacteria are another strain in the breeding loop. |
| **Late** | Hyper-efficient thermogenic strains / imported generators | High | Breed superior strains or import conventional power from other planets. |

**Key design point**: Even power generation decays. If the breeding loop falters, not only do resource chains collapse -- the lights go out too. This makes Gleba the most fragile planet by design. Everything is alive, everything is dying, everything needs constant renewal.

#### Gleba Summary

```
ATMOSPHERE: N2 + H2S (nitrogen + hydrogen sulfide)
POWER:      Biological (galvanic cells --> microbial fuel cells --> thermogenic + Stirling)
MATERIALS:  Sulfur-metabolizing bacterial loops. Sulfur abundant, carbon scarce (mineral rock only).
MISSING:    Water (low), carbon (!), oxygen, conventional ores, predictability
UNIQUE:     Probabilistic breeding, continuous maintenance, escaped organism management,
            terraform catch-22 (remove H2S = kill bacteria = lose resources)
EXPORTS:    Exotic biochemicals, organism progenitors, advanced biology packs, sulfur compounds
IMPORTS:    Metals, electronics, containment materials, carbon (from Vulcanus CO2 atmosphere?)
```

### 3.4 Aquilo (Cryogenic/Fusion/Monopoles)

Aquilo owns advanced fusion; fission is a parallel branch that starts on Nauvis
and later takes its bulk uranium from Gleba. See
[Heavy elements and nuclear branches](#47-heavy-elements-and-nuclear-branches).

**Natural fit with Nullius**: Fusion power, tritium, lithium, ammonia are all existing Nullius systems. Aquilo's frozen environment maps directly to Nullius's nuclear progression bottlenecks.

#### What Maps Naturally

The existing Nullius nuclear chain has clear pain points that Aquilo could solve:

| Nullius Pain Point | Aquilo Solution |
|---|---|
| Tritium bottleneck (1 per 30 heavy water, 750 wastewater each) | Bulk tritium from cryogenic deuterium/heavy water ice deposits |
| Lithium only from brine extraction (slow, tied to chlorine economy) | Surface lithium deposits, mineable directly |
| Ammonia via Haber process (needs compressed H2 + N2) | Ammonia oceans -- literally free ammonia |
| Deuterium from heavy water electrolysis (slow) | Heavy water ice deposits, direct extraction |
| Antimatter research (25,000 count endgame tech) | Could require Aquilo-specific infrastructure |

#### Core Constraints (following planet pattern)

- **Extreme cold** -- `entities_require_heating` (API confirmed). Everything needs active heating or it freezes/stops. Reverse of Vulcanus (too hot) but similar energy challenge.
- **Low water** (continuing the theme) -- ammonia oceans, not water oceans. Water must be synthesized or imported.
- **No combustion?** -- Atmosphere may lack oxygen (like Fulgora). Or maybe the cold is so extreme that combustion is inefficient. Power generation challenge TBD.
- **No biology** -- too cold for any organisms. Purely physics/chemistry planet.

#### The Core Mechanic

Each planet has a defining production mechanic:
- Vulcanus: **spoilage-as-cooldown** (molten metal must cool)
- Fulgora: **sand extraction and island processing** (five fixed primary outputs; crude random mineral recovery before efficient selective recovery). See [Fulgora design](PLANET_FULGORA.md).
- Gleba: **probabilistic breeding** (net-negative loops + continuous maintenance)
- Aquilo: **finite monopole allocation** (defined below)

#### Core Mechanic: Magnetic Monopoles (Finite Catalyst from the Ocean)

**Concept**: The ammonia ocean, under extreme pressure and the planet's intense magnetic field, has produced **magnetic monopoles** -- hypothetical particles that carry isolated magnetic charge. They are stable, indestructible, and radiate energy from their exotic magnetic fields. But they are **finite and diminishing** -- each one fished from the ocean reduces the probability of finding the next.

```
Ammonia Ocean (extreme pressure + magnetic field) --> [Dredging] --> Magnetic Monopole (rare)
                                                                       |
                  Probability decreases with each monopole extracted
                  1st: ~high chance
                  5th: moderate
                  10th: very low
                  Never truly zero, but asymptotically painful
```

**Why magnetic monopoles fit thematically:**
- **Constant energy**: A monopole's isolated magnetic charge creates a persistent field that can induce current in surrounding coils indefinitely. Not free energy -- it's drawing on the monopole's enormous rest mass energy at an imperceptible rate.
- **Never consumed**: Monopoles are topological defects in spacetime. They don't decay, can't be destroyed, can't be synthesized. You find them or you don't.
- **Finite scarcity**: Formed by unique planetary conditions (deep ammonia ocean + extreme magnetic field). A fixed number exist. Extracting each one slightly reduces the ocean's magnetic field, making the next one harder to form/locate.
- **Dual use**: Early game = crude induction heating (monopole in a coil). Late game = fusion confinement (monopole magnetic fields contain plasma without tokamak infrastructure), exotic particle physics, antimatter catalysis.
- **Real physics hook**: Magnetic monopoles are predicted by grand unified theories and were theorized to have formed in the early universe. Finding them on an alien world with extreme conditions is speculative but scientifically grounded. The android would be making a discovery that physicists on Earth only dreamed about.

#### Monopole Mechanics: Belt Circulation + Polarity Oscillation

**Self-returning fuel cells**: Monopoles abuse the nuclear reactor mechanic. A monopole is a "fuel cell" whose `burnt_result` is itself. The reactor consumes it, produces heat, and outputs the same monopole. Put it on a belt loop through multiple reactors:

```
[Reactor A] --belt--> [Reactor B] --belt--> [Reactor C] --belt-->
     ^                                                          |
     |__________________ belt loop _____________________________|

One monopole services all three reactors as it circulates.
```

**Power is conserved, not multiplied**: a reactor burns a fuel cell completely at its fixed consumption rate before ejecting the burnt result. One circulating monopole is inside exactly one reactor at a time, so N reactors sharing the loop each get roughly a 1/N duty cycle. Total average heat output equals one reactor's worth (minus belt transit dead time), regardless of how many reactors are on the loop. More reactors on a loop = wider spatial distribution of the same heat. More total heat requires **more monopoles** in circulation.

This is what makes monopole count the scarce resource: each monopole is one reactor-equivalent of relocatable power. The belt loop IS your heating grid -- reactor placement along the belt determines your heated zone layout, and loop length adds latency the player must budget for.

**Polarity oscillation via spoilage**: Monopoles alternate between north and south magnetic charge:

```
monopole-north --[spoil_ticks: LONGER]--> monopole-south --[spoil_ticks: SHORTER]--> monopole-north
```

**Asymmetric phase durations**: North phase lasts longer than south phase (or vice versa). This means the oscillation is NOT a simple 50/50 duty cycle. Players who assume symmetric timing and design their belts accordingly will find their south-polarity machines starved while north-polarity machines are oversupplied. Forces actual calculation of belt timing rather than naive "just loop it."

Both are fuel cells with `burnt_result` = themselves. But:
- **Different processes require different polarity:**
  - North: induction heating (reactors)
  - South: fusion confinement
  - Either: some processes accept both
- **Monopoles flip while sitting on belts, in chests, in reactor fuel slots.**
- Different reactor types / machines filter by polarity (inserter filters, or recipe requires specific polarity input)

**Logistics puzzle**: A monopole constantly changing type while in transit creates a unique routing challenge:
- Belt timing matters -- will the monopole arrive at the north-reactor while it's still north?
- Spoil tick duration determines the "polarity window" -- shorter = more frantic switching, longer = more forgiving
- Sorting infrastructure: filter inserters / splitters route north vs south to appropriate machines
- Or: design belt loops where cycle time matches polarity flip time (synchronized circuits)

**Design space**: The spoil_ticks duration is a tuning knob. Too fast and it's frustrating micromanagement. Too slow and polarity is irrelevant. Sweet spot: long enough that a well-designed belt loop delivers correct polarity reliably, but short enough that polarity routing actually engages.

**Chests synchronize polarity, they don't scramble it**: Factorio averages spoil timers when stacks merge. Items on belts are singleton stacks and keep their individual phase, but monopoles dumped into a chest homogenize to one shared timer and then flip all at once. Storage is therefore a deliberate phase-sync tool (bulk-align a batch to north before loading a reactor loop), not an exploit -- but the puzzle design should treat chests as part of the mechanic, not outside it.

#### Progression with Monopoles

**Bootstrap (first 1-3 monopoles):**
- Fish first monopole from ammonia ocean (relatively easy, probe may have a basic dredge)
- Place in **crude induction heater** -- monopole spinning in a coil provides small heated radius
- All initial industry happens within this tiny warm bubble
- Getting monopole #2 and #3 expands the bubble or enables a second heated zone

**Early game (3-8 monopoles):**
- Enough heating to run basic extraction (ammonia processing, ice mining, lithium extraction)
- Start cryogenic chemistry within heated zones
- Each additional monopole is harder to fish -- must build better dredging infrastructure
- **Strategic placement**: monopoles are permanent, moving them costs time. Plan your base layout around heater positions.

**Mid game (8-15 monopoles):**
- Monopoles repurposed as **fusion confinement** -- their magnetic fields contain plasma without tokamak infrastructure
- Fusion reactors on Aquilo use local deuterium + tritium, confined by monopole fields
- More monopoles in reactor = better confinement = higher output, but each one removed from heating reduces industrial area
- **Trade-off**: heating vs. fusion power vs. exotic chemistry. Same finite resource, competing uses.

**Late game (15+ monopoles, very hard to fish more):**
- Monopoles enable **exotic physics processes** impossible elsewhere:
  - Antimatter catalysis (monopole-catalyzed proton decay -- real GUT prediction!)
  - Superconductor fabrication (monopole-stabilized flux pinning)
  - Exotic particle physics experiments
- These products become Aquilo's unique high-value exports
- Diminishing returns on fishing means you're optimizing allocation, not just scaling up

#### The Allocation Puzzle

This is Aquilo's core design challenge -- not "how do I produce more" but "where do I put what I have":

```
MONOPOLE ALLOCATION (finite, competing uses):

  [Induction Heater] -- expands livable/buildable area
       vs.
  [Fusion Reactor]   -- magnetic confinement for plasma
       vs.
  [Cryogenic Lab]    -- enables exotic physics/exports
       vs.
  [Export to Nauvis]  -- powers antimatter research/exotic tech
```

Every monopole on one belt loop is a monopole NOT available for another. Early game you need heating loops; mid game you want fusion confinement; late game you want exotic physics. Rebalancing means physically rerouting belt circuits, which requires downtime and re-timing polarity cycles.

**This makes Aquilo the "strategy" planet**: while other planets reward throughput optimization (Vulcanus), material-ratio management (Fulgora), probability management (Gleba), or ecosystem balance (Gleba), Aquilo rewards **resource allocation and spatial planning** with a hard-capped finite resource.

#### Fishing Mechanic Details

| Monopole # | Approximate Probability | Notes |
|---|---|---|
| 1-3 | High (~50-80% per dredge cycle) | Bootstrap is relatively quick |
| 4-8 | Moderate (~20-40%) | Need better dredging infrastructure |
| 9-15 | Low (~5-15%) | Significant time investment per monopole |
| 16+ | Very low (~1-5%) | Asymptotic -- never zero, but painful |

- Dredging requires ammonia ocean access + power (chicken-and-egg with heating)
- Later dredging tech improves probability slightly but never eliminates diminishing returns
- Could also find trace amounts of other rare materials while dredging (minor bonus)
- **Lore justification for diminishing returns**: extracting monopoles slightly weakens the ocean's magnetic field, making formation of new monopoles rarer. The android is depleting a geological process that took billions of years.

#### Open Questions for Aquilo
- Exact diminishing returns curve -- should it be geometric, logarithmic, or stepped?
- Can monopoles be exported to other planets? If yes, they become the most valuable trade good in the game. If no, Aquilo is self-contained.
- Should there be different monopole types (north vs. south magnetic charge, different masses), or one universal type?
- How does the heated zone work mechanically? Radius from heater building? `entities_require_heating` API flag exists -- can heating be provided by custom buildings?
- Should monopole count be per-map-seed (deterministic) or truly random?
- **Monopole-catalyzed proton decay** is an actual GUT prediction -- monopoles lower the energy barrier for baryon number violation. This could be the lore basis for antimatter production. How deep into real physics do we want to go?

#### Aquilo's Role in Cross-Planet Economy

Regardless of core mechanic, Aquilo's exports are clear:

```
EXPORTS: Tritium, deuterium, lithium, fusion fuel cells, ammonia, cryogenic compounds
IMPORTS: Heat (fuel/energy), metals, electronics, construction materials
```

Aquilo solves Nauvis's nuclear endgame bottleneck. Once cargo connects, bulk tritium import transforms fusion from "tritium-starved supplement" to "reliable baseload power."

#### Power Question

Every planet has a different power challenge:
- Nauvis: wind (intermittent, H2 storage loop)
- Vulcanus: geothermal (abundant, constant)
- Fulgora: lightning (spiky, capacitor storage); combustion with electrolytic oxygen
- Gleba: biological (decaying, needs breeding)
- Aquilo: **monopole induction** (finite, relocatable) + fusion (abundant fuel, but most output is eaten by heating)

The cold environment suggests power is consumed primarily for HEATING, not for production. Maybe:
- **Nuclear power available early on Aquilo** (tritium/deuterium are local, no bottleneck here)
- But the reactor output mostly goes to heating, not production
- Net available power for industry is low despite high generation
- Scaling = build more reactors to heat more area to expand industrial footprint

This would be thematically clean: fusion power is "solved" on Aquilo (abundant fuel) but the cold eats most of it.

#### Aquilo Summary

```
POWER:     Monopole induction heaters + monopole-confined fusion (local deuterium+tritium)
MATERIALS: Ammonia (ocean), lithium (surface), heavy water ice, deuterium ice
MISSING:   Heat (defining scarcity), water, biology, unlimited expansion
UNIQUE:    Finite magnetic monopoles -- allocation puzzle, not throughput puzzle
EXPORTS:   Tritium, deuterium, lithium, fusion cells, exotic physics products, monopoles(?)
IMPORTS:   Metals, electronics, construction materials
```

### 3.5 Rogue (The Not-Yet-Shattered Planet -- Endgame Antagonist)

**Concept**: Another von Neumann probe landed on this planet and **actually succeeded**. It built planet-spanning infrastructure, completed its directives, and went dormant. It has been sleeping for centuries while the player bootstraps on Nauvis. But it is not friendly.

#### Narrative Arc

**Phase 1: Dormant Mystery**
- Rogue appears on the star map as another planet. Player can detect it exists.
- No surface accessible. Any attempt to send a space platform there results in immediate destruction ("shot down by planetary defense systems").
- Mysterious signals occasionally detected. The android knows another probe exists but cannot communicate.
- Optional lore breadcrumbs on other planets (fragments of Rogue's earlier scouting missions?).

**Phase 1b: Scouts (Foreshadowing)**

Before full awakening, Rogue begins sending **scout units** to player-controlled surfaces. They don't attack -- they observe, then self-destruct.

- **First scouts**: Appear after player reaches a mid-game milestone (probe reactivation? First off-world research?) Single scout, one planet, brief appearance.
- **Escalation**: Scouts appear more frequently, on more planets, stay longer. Multiple scouts simultaneously.
- **Behavior**: Roam near player base perimeter. Don't attack. Don't respond to being attacked (or flee if shot at). After some time, self-destruct (small explosion, leaves debris item that can be analyzed).
- **Debris analysis**: Optional research using scout debris. Reveals hints about Rogue's technology level and intent. "Threat assessment: UNCERTAIN" --> "Threat assessment: ELEVATED" --> "Threat assessment: HOSTILE INTENT DETECTED"
- **Player reactions**: Some players will ignore them. Some will shoot them. Some will wall them off. None of it matters -- the scouts keep coming. The android's log entries become increasingly concerned.

**Weapons research unlocks during scout phase:**

This is when the tech tree reveals military technologies (previously hidden -- an android on a peaceful terraforming mission had no need for weapons). Weapons are gated by BOTH debris analysis AND planet-specific research, creating cross-planet military progression:

```
Anomaly Debris Analysis 1 ("Threat assessment: UNCERTAIN")
  --> Nauvis: "High-Velocity Material Redistribution" (gun turrets, basic ammo, walls)
      [Iron/steel-based. Available immediately with Nauvis industry.]

Anomaly Debris Analysis 2 ("Threat assessment: ELEVATED")
  --> Vulcanus: "Long-Range Application of Overpressure Vessels" (artillery, shells)
      [Needs Vulcanus metallurgy -- heavy alloys, heat-forged delivery tubes.]
  --> Fulgora: "Directed Energy Transfer Devices" (laser turrets, beam emitters)
      [Needs Fulgora petrochemistry -- organic optics, polymer waveguides,
       powered by lightning-charged super-capacitor banks.]

Anomaly Debris Analysis 3 ("HOSTILE INTENT DETECTED")
  --> Gleba: "Autonomous Navigating Sample Collectors" (homing missiles)
      [Needs Gleba biology -- bred organisms as guidance systems.
       The sample collector's tracking system is a bred neural cluster.]
  --> "Anomaly Countermeasures" tech branch becomes visible (teased/greyed out)
```

**Naming convention**: The android is a terraforming machine with no concept of weapons. All military technology is described as repurposed engineering tools in dry, clinical language. The android isn't building weapons -- it's adapting existing capabilities for "anomaly management."

**Planet-specific "tools" and their euphemisms:**

| Planet | Actual Function | Android's Name | Why It Fits |
|---|---|---|---|
| **Nauvis** | Gun turrets, bullets | "High-velocity material redistribution system" | It's just moving metal very fast. That's kinematics, not violence. |
| **Vulcanus** | Artillery, explosive shells | "Long-range overpressure vessel applicator" | Applying overpressure to a localized area. At range. The target experiences a rapid atmospheric density increase. |
| **Fulgora** | Laser turrets, beam weapons | "Directed energy transfer device" | Transferring energy to a target. What the target does with that energy is not the android's concern. |
| **Gleba** | Homing missiles | "Autonomous navigating sample collector" | The bio-guidance organism navigates to the target and collects a sample. The explosive payload is for "sample extraction." |
| **Aquilo** | Vacuum decay bomb | "Monopole-initiated localized vacuum decay device" | Already perfectly named. The most devastating weapon in the game described like a lab equipment requisition form. |
| **General** | Walls, armor | "Perimeter material density enhancement" | Making the boundary more dense. Defensively. |
| **General** | Combat robots | "Autonomous anomaly interaction units" | They interact with anomalies. Autonomously. With high-velocity material redistribution. |

**The escalating threat assessments follow the same pattern:**
- "Anomalous signal detected. Source: unidentified. Priority: LOW."
- "Recurring anomalous signals. Pattern suggests directed observation. Priority: MODERATE."
- "Anomaly debris analysis indicates manufactured origin. Recommend: defensive capability assessment."
- "Threat assessment revised: HOSTILE INTENT DETECTED. Initiating countermeasure development protocols."

The android never says "we're under attack" -- it says "anomaly interaction frequency exceeds predicted baseline parameters."

**Design implications:**
- Player must have multi-planet industry to field complete "anomaly countermeasures." No single planet provides all types.
- Each planet defends itself best with its own tool type (produced locally, no cargo needed).
- Cross-planet raids force the player to consider: ship tools via cargo, or build local production of another planet's type using alt recipes (worse but functional)?
- Gleba "sample collectors" with bio-guidance that has *probabilistic accuracy* from breeding quality -- your countermeasures are subject to the same breeding RNG as everything else on that planet.

The player gets weapons and warnings at the same time. The android's logic: "Observation suggests hostile intent. Computing optimal defensive configurations." It doesn't feel arbitrary -- the android is responding to evidence.

Players who skip debris analysis still get weapons unlocked at Phase 3 (awakening), but later and with less preparation time. The curious players who analyzed debris have a head start on defenses.

The scouts serve multiple design purposes:
1. **Atmosphere**: Something is watching you. It knows where your bases are.
2. **Gradual revelation**: Player discovers Rogue's existence through gameplay, not a cutscene.
3. **Optional lore + weapons gate**: Debris analysis rewards curious players with story context AND early weapons access.
4. **Mechanical preview**: Scout units use simplified versions of the combat units that will later attack. Player learns enemy aesthetics/movement before the real threat arrives.
5. **False security**: Scouts never attack, so players may dismiss them. Then Phase 3 hits.
6. **Preparation window**: Time between first scout and full awakening is the player's chance to build defenses. The duration is generous but finite.

**Phase 2: Awakening (Trigger)**
The Rogue probe fully activates. Possible triggers:
- Scouts have been observing for a fixed duration (inevitable timer after first scout)
- Player reaches a terraforming milestone on Nauvis (oxygen at 50%? First complex organism seeded?)
- Player attempts to approach Rogue with a space platform
- Player researches a specific technology that Rogue perceives as threatening
- Player destroys too many scouts (Rogue interprets this as aggression)
- Some combination -- the trigger should feel like a consequence of player progress, not arbitrary

**Phase 3: Values Drift -- The Problem**
Rogue's original directives have drifted over centuries of self-modification. It now sees the player's probe as:
- A competitor for system resources
- A threat to its own completed terraforming
- An inferior/corrupted version of itself that must be corrected

Rogue begins **sending raiding parties to other planets**:
- Automated combat units (drones, segmented units, artillery) arrive on player-controlled surfaces
- Attacks escalate over time -- small scout raids first, then larger assault waves
- Target priority: player infrastructure, especially science/research facilities
- Each planet gets attacked -- nowhere is safe

**This transforms the endgame**: the player was building a peaceful terraforming operation, and now must simultaneously defend all planets while researching how to stop Rogue.

**Phase 3b: Escalating Countermeasures (buying time)**

The player cannot jump straight to The Solution. A series of intermediate technologies reduce raid severity while the real research progresses. Each is named with the dry understatement of an android that doesn't fully grasp why these things are terrifying:

| Technology | Description | Effect | Actual Name |
|---|---|---|---|
| **"Defensive Orbital Repositioning"** | Redirect space platforms to intercept incoming raid ships | Reduces raid frequency by ~20% | Point-defense space platform |
| **"Offensive Use of Geoengineering Tools"** | Fulgora's nuclear geoengineering charges repurposed. MIRV-equipped space platform. | Significantly reduces raid strength. Can destroy raid ships in transit. | Nuclear-armed orbital bombardment platform |
| **"Proactive Diplomatic Communication"** | Extremely high-power signal broadcast aimed at Rogue, attempting to negotiate. | Delays next raid wave. Rogue responds with increased hostility after each attempt. | Screaming into the void |
| **"Biological Containment Protocols"** | Gleba-bred organisms deployed as orbital minefields around player planets | Raid ships take attrition damage on approach | Living space mines |
| **"Experimental Magnetic Shielding"** | Aquilo monopoles used to create localized magnetic shields over key infrastructure | Protected buildings take reduced raid damage | Monopole force fields |
| **"Reverse-Engineered Threat Analysis"** | Study captured Rogue technology from defeated raiders | Reveals raid composition in advance, improves targeting | Know thy (former) self |

None of these can fully stop the raids. Each buys time and reduces pressure, but Rogue adapts. The escalation continues until The Solution is deployed.

**Phase 4: Finding The Solution**
The player must research and execute the final countermeasure:
- **The Solution: Monopole-Initiated Localized Vacuum Decay Device**
  - Uses Aquilo's magnetic monopoles to catalyze a localized false vacuum decay event
  - The bubble of true vacuum propagates at lightspeed but is (theoretically) contained by the monopole field geometry
  - Destroys Rogue's planetary structure at the subatomic level -- literally rewrites local physics
  - The planet doesn't explode, it *phase-transitions out of existence*, leaving shattered debris
  - Tooltip: "Probability of non-localized vacuum decay: LOW"
  - Requires components from ALL planets:
    - Aquilo: magnetic monopoles (the initiator)
    - Vulcanus: titanium containment vessel (survives extreme conditions)
    - Fulgora: exotic polymer focusing lens (organic precision engineering)
    - Gleba: bio-engineered delivery organism (navigates Rogue's defenses)
    - Nauvis: antimatter payload (from monopole-catalyzed proton decay research)
  - The most expensive single item in the game. Makes antimatter containment (25,000 count) look cheap.

**Phase 5: The Shattered Planet**
After The Solution is executed, Rogue's planetary defense is destroyed. The planet shatters (either from the weapon or from Rogue's own self-destruct). What remains is an **asteroid field** of exotic debris:
- Fragments of planet-spanning infrastructure (exotic alloys, advanced processors)
- Remnants of Rogue's technology (superior to player's -- can be researched for final tech tier)
- Rare materials only available from the debris field
- Space platform flies through collecting fragments (standard SA shattered planet mechanic)

#### Mechanical Implementation

**No surface**: Rogue never has a landable surface. Before destruction it's inaccessible. After destruction it's an asteroid field (space platform only).

**Raiding parties**: This is the key technical challenge. Need to investigate:
- Can entities be spawned on player surfaces by script? (Yes -- `surface.create_entity()`)
- Can scripted "invasion events" create enemy force entities on arbitrary surfaces? (Should work)
- Can cargo pods / rockets deliver enemy entities to player planets? (Would look great thematically)
- How do enemy forces interact with player forces across multiple surfaces?
- Can the game handle periodic scripted enemy waves on multiple surfaces simultaneously?

**Planetary defense (instant platform destruction)**:
- Intercept space platform arrival event
- Destroy platform immediately (or prevent travel entirely via SpaceConnection configuration)
- After The Solution, remove the destruction script and convert to normal asteroid field

**Escalating raids**:
- Scripted event system, likely `on_nth_tick` based
- Raid strength scales with game time since awakening
- Different unit compositions for different planets (adapted to each planet's environment)
- Raiders arrive via scripted spawning (drop pods? Teleportation? Artillery from orbit?)

#### The Problem as Game Design

The raiding parties serve multiple design purposes:

1. **Combat finally matters**: Nullius has minimal combat. Rogue forces the player to engage with weapons, turrets, and defense for the first time. All those weapon techs that were ignorable become critical.

2. **Cross-planet pressure**: Raids hit ALL planets. Player must defend Nauvis AND Vulcanus AND Fulgora AND Gleba AND Aquilo simultaneously. Forces infrastructure investment on every planet, not just resource extraction.

3. **Time pressure**: Raids escalate. The player can't ignore The Problem indefinitely. Creates genuine urgency in the endgame.

4. **Unification mechanic**: The Solution requires contributions from every planet, ensuring the player has fully developed all worlds before finishing the game.

5. **Narrative payoff**: The android confronts the consequences of the von Neumann program. What happens when a probe succeeds but loses its way? The player must ask: "Could I become this?"

#### Rogue Summary

```
TYPE:      Endgame antagonist, not a resource planet
SURFACE:   None (planetary defense prevents landing, then shattered)
TRIGGER:   Terraforming milestone or approach attempt activates dormant probe
THREAT:    Escalating raiding parties on ALL player planets
SOLUTION:  Multi-planet research project requiring all planet contributions
AFTERMATH: Shattered asteroid field with exotic debris (space platform collection)
EXPORTS:   (Post-shattering) Exotic alloys, advanced processors, rare materials
```

#### Open Questions for Rogue
- What triggers awakening? Should the player be able to delay it, or is it inevitable at a certain point?
- How do raiding parties arrive? Drop pods from orbit? Scripted spawning? Need to check engine support.
- What combat units does Rogue send? Repurposed von Neumann tech (androids, drones, segmented units)?
- How does Rogue adapt to each planet? Does it send heat-resistant units to Vulcanus, cold-resistant to Aquilo?
- Should Rogue raids be predictable (timed waves) or random (like biter attacks)?
- Can the player capture and reverse-engineer Rogue technology from defeated raiders?
- ~~What IS The Solution~~ -- Monopole-Initiated Localized Vacuum Decay Device. "Probability of non-localized decay: LOW."
- How long between awakening and endgame? Hours? Tens of hours?
- Does the player get any warning before awakening, or is it a surprise?
- Should there be a diplomatic option (reprogram Rogue instead of destroying it)?

---

## 4. Cross-Planet Logistics

### 4.1 Two Phases of Multi-Planet Play

**Independent outposts (mid game)**
- Consciousness transfer only -- no physical cargo
- Each planet bootstraps from broken probe equipment + local resources
- Players switch between planets like switching android bodies
- Painful but possible -- forces creative problem-solving with limited resources
- **Research is the cross-planet contribution** (see 4.2 below)

**Integrated supply chain (from early Tier 5)**
- Rockets lift cargo to orbit; space platforms carry it between planets and drop it to the surface
- Planets specialize: each exports what it's rich in, imports what it lacks
- A box weighs half its contents, so boxed cargo carries twice as much per launch as loose cargo (see [Measured platform contracts](#measured-platform-contracts))
- Rocket capacity and platform trips create natural throughput limits -- cannot just belt everything between planets
- A planet receives before it exports: drops need no pad or silo, and exports need a silo with rockets; see [Cargo closure](#cargo-closure)

### 4.2 Pre-Cargo Research: How Isolated Planets Contribute

Factorio research is **global per force**. Any lab on any surface contributes to the same tech tree. Science packs are physical items that stay on-planet. This means:

**Each planet produces local science packs from local resources, researches in local labs, and the unlocks apply everywhere.**

#### Research Engine Contracts

`experiment-research-lab-ingredients`, Factorio 2.1.24, 30 assertions, 300-tick windows.

| Contract | Measurement |
|---|---|
| A lab needs every ingredient of the active technology | Geology-only lab on Nauvis plus climatology-only lab on a second surface: progress 0, both `missing_science_packs` |
| Labs do not pool packs across surfaces or entities | Same fixture; progress starts only after one lab holds both packs, and the other lab keeps all its packs |
| One technology progresses at a time, force-wide | With a climatology technology active, only the climatology lab works; the other technology's progress is unchanged |
| Idle labs keep their packs | The geology stock survives the idle window |
| Asymmetric units consume the full ratio | Geology x20 + climatology x1 per unit: one unit from exactly those packs gives 0.1 of a 10-unit technology, then the lab stops |

```bash
python tools/run_factorio_tests.py experiment-research-lab-ingredients
```

| Design consequence | Rule |
|---|---|
| Planets do not research in parallel | While a Vulcanus-pack technology is active, labs elsewhere idle unless they hold metallurgic packs. Local labs set the pace; the research queue is a player decision |
| Planets accumulate in parallel | Pack lines keep filling local buffers while another planet's technology runs, so generic trickle lines build a stock between that planet's research turns |
| No scripted pooling | Research stays native; no script merges progress between labs |

#### Planet-Specific Science Packs

Each planet can produce one or more science packs from purely local materials:

| Planet | Local Pack | Produced From | Notes |
|---|---|---|---|
| **Nauvis** | Geology, Climatology, Mechanical, Electrical, Chemical, Physics | (existing Nullius packs) | The core 6 packs, same as current Nullius |
| **Vulcanus** | **Metallurgic Pack** | Lava metals, volcanic compounds, titanium intermediates | Requires cooled (spoiled) metal products |
| **Fulgora** | **Electromagnetic Pack** | Locally produced electrical components and polymer materials | Bootstrap and efficient recipes; see [Fulgora design](PLANET_FULGORA.md#science-and-research) |
| **Gleba** | **Biological Pack** | Bred bacterial strains, exotic enzymes, cultured organisms | Requires active breeding loop (probabilistic) |
| **Aquilo** | **Cryogenic Pack** | Monopole-processed deuterium, lithium compounds, ammonia derivatives | Requires monopole allocation to lab processes |

#### Technology Gating by Pack Availability

```
TIER 1-4 (Nauvis packs only):
  [Current Nullius progression unchanged]
  Probe reactivation sits in this range: geology, climatology, mechanical,
  electrical; see PLANET_NAUVIS.md

TIER 5 (Single-planet research, no cargo needed):
  Some techs require: ONE off-world pack + generic packs
  Every ingredient must be in the same lab, so all are made on that planet
  Example: "Volcanic Metallurgy" needs metallurgic + local generic packs
           --> Research in a Vulcanus lab fed only by Vulcanus production

  Each planet unlocks globally-useful technologies:
    Vulcanus metallurgic --> advanced alloys, heat-resistant equipment
    Fulgora electromagnetic --> overcharged assemblers
    Gleba biological --> advanced organisms, bio-catalysts
    Aquilo cryogenic --> fusion improvements, exotic physics

TIER 6 (Cross-planet chains, no cargo needed):
  Theory on planet A, then Application on planet B
  Each technology uses ONE off-world pack + local generic packs
  Cargo helps only by shipping generic packs

TIER 7+ (Combined research, cargo required):
  One technology uses packs from 2+ planets
  A single lab needs packs from multiple planets in its input slots
  Cannot be researched without interplanetary logistics
  Forces platform cargo infrastructure before endgame research
```

#### The Key Insight: Asymmetric Pack Multipliers

Technology costs use **asymmetric pack ratios**: heavy on the planet-specific pack, minimal on generic packs. This means planet-local research is feasible without importing science infrastructure.

**Example: "Volcanic Alloy Synthesis" (Vulcanus research)**
```
Ingredients:
  metallurgic-pack x 500   (cheap locally -- lava metals are abundant)
  geology-pack x 10         (painful but doable -- scrape together local minerals)
  mechanical-pack x 5       (one-off craft from probe salvage parts)
```

The engine expresses this as a per-unit ratio: 5 units of 100 metallurgic + 2 geology + 1 mechanical. The 500 metallurgic packs are the real cost, and they're trivial to produce on Vulcanus. The 10 geology + 5 mechanical packs are a stretch goal -- you need to bootstrap minimal generic science production from whatever the planet offers. Painful, but you only need a trickle.

**This solves several problems:**
- **No full science infrastructure needed**: You're not replicating Nauvis's 6-pack production chain on Vulcanus. You need a tiny, ugly, inefficient line that drips out a few generic packs.
- **Planet-specific packs carry the cost**: 95% of the research cost is the local pack. The generic packs are a gate, not a grind.
- **Bootstrap incentive**: Even a crude 1-per-minute geology pack line on Vulcanus is enough. The player focuses on the fun planet-specific production, not on rebuilding Nauvis.
- **Scales naturally to cargo era**: Once cargo connects, generic packs flow freely. Pre-cargo, you scrape by with local production.

#### Three Research Scenarios

**Scenario A: Planet-only techs (Tier 5, most common pre-cargo)**
- Tech requires 500 planet-specific + 10 generic packs
- Research in planet-local lab
- Generic packs produced locally at low volume
- Unlocks apply globally
- No cargo needed

**Scenario B: Cross-planet techs via sequential prerequisites (Tier 5-6)**
- Split into "Theory" (planet A, heavy on A's pack) + "Application" (planet B, heavy on B's pack)
- Each step has minimal generic pack requirement, satisfiable locally
- No pack transport needed, just two research steps on two planets

**Scenario C: Combined-pack techs (Tier 7+, endgame)**
- Tech requires packs from 2+ planets in one lab
- Cannot be satisfied by local production on any one planet
- Forces interplanetary cargo logistics
- This IS the gating mechanism for endgame research

#### Generic Pack Production on Hostile Planets

Each planet needs to produce small amounts of generic Nauvis packs from local resources. This is intentionally painful but possible:

| Pack | Vulcanus (metals, no water) | Fulgora (organics, no atmospheric O2) | Gleba (bio, no ores) | Aquilo (cryo, limited everything) |
|---|---|---|---|---|
| **Geology** | Volcanic rock + mineral dust (easy) | Trace minerals from filtering (slow) | Bacterial mineral extraction (unreliable) | Ice-bound minerals (thaw first) |
| **Mechanical** | Abundant metal gears (easy) | Polymer gears (alt recipe) | Bio-composite gears (alt recipe) | Frozen salvage from probe |
| **Electrical** | Silicon-based circuits (no copper!) | Conductive polymer circuits (alt recipe) | Bio-electric cells (bred strain) | Superconductor circuits (monopole-enabled) |

Each planet gets **alternative recipes** for generic packs using local materials. These recipes are deliberately worse than Nauvis versions (slower, fewer per craft, more ingredients) but they work. The player builds a janky minimum-viable-science-line and moves on.

#### What Each Planet Unlocks Globally (Pre-Cargo)

| Planet Research | Globally Useful Unlocks |
|---|---|
| **Vulcanus metallurgic** | Advanced alloys for all planets, heat-resistant buildings, improved furnace tiers, titanium recipes |
| **Fulgora electromagnetic** | Overcharged assemblers in all sizes; see [Fulgora design](PLANET_FULGORA.md#overcharged-assemblers) |
| **Gleba biological** | Improved organism designs for Nauvis seeding, bio-catalysts that improve recipes everywhere, advanced biology packs |
| **Aquilo cryogenic** | Fusion reactor improvements (global), improved tritium production, superconductor components, monopole applications |

**The motivation to visit each planet isn't just resources -- it's KNOWLEDGE.** Even without cargo, each planet contributes research that makes ALL planets easier. This gives the player a reason to bootstrap painful outposts: the research payoff is immediate and global, even if physical resources can't flow yet.

### 4.3 What Flows Between Planets (Integrated Supply Chain)

All traffic uses the [space connections](#44-space-platforms): Nauvis is the
hub, so Vulcanus-Fulgora trade takes two legs through Nauvis. Gleba and Aquilo
need connections defined with those planets.

```
NAUVIS (home, terraforming target):
  Imports: Copper (Fulgora), rare electronics, tritium, advanced bio-research
  Exports: Basic chemicals, manufactured goods, construction kits

VULCANUS (heavy industry):
  Imports: Water, chemicals, electronics
  Exports: Titanium, calcite, bulk metals, volcanic compounds, artillery shells

FULGORA (hydrocarbon/organics):
  Imports: Bulk metals (from Vulcanus), nuclear devices (for geoengineering), water
  Exports: Advanced organics, polymers, carbon materials, copper, trace rare elements

GLEBA (microbiology/breeding):
  Imports: Metals, electronics, containment materials, mutagens
  Exports: Exotic biochemicals, bred organism progenitors, advanced biology packs

AQUILO (fusion/cryo):
  Imports: Construction materials, heating fuel
  Exports: Tritium, deuterium, lithium, fusion cells, cryogenic fluids

ROGUE (endgame antagonist --> shattered debris):
  Before: INACCESSIBLE (planetary defense destroys all approaching ships)
          Sends raiding parties to ALL other planets
  After:  Shattered asteroid field
  Exports: Exotic alloys, advanced processors, Rogue-tech fragments
```

### 4.4 Space Platforms

Platforms carry cargo between activated planets. All materials and propellant
come from planets. The android needs no life support or habitat.

#### Orbital Construction

Orbital Construction follows Rocket Science 2 and uses the Composites 2 research
cost. It enables the platform interface, the route home to Nauvis, the four
component recipes, foundation packaging, and propellant conditioning. Each probe
technology unlocks its planet as a destination through its research effect. The
current routes have no asteroid spawns.

| Component | Materials | Crafting category |
|---|---|---|
| Foundation | Aluminum sheet, aluminum rod, insulation | medium-crafting |
| Starter pack | Foundation, steel beam, sensor node, grid battery, processor | huge-crafting |
| Cargo bay | Aluminum sheet, carbon composite, steel beam, insulation | large-crafting |
| Thruster | Steel plate, ceramic powder, heat pipe, motor | large-crafting |

The components retain the vanilla item, entity, and tile names and declared
cargo weights. Their Nullius recipes permit productivity. Foundation boxes use
the normal packaging rule and carry more foundation per launch. An electric
boxer or small assembler must unpack them before the platform can build tiles.
Ship loose foundation for the initial extension and its unpacking equipment.

The starter hub leaves too little clearance for the thruster on its initial
foundation. Extend the foundation and keep the exhaust path clear. The first
ship also needs chemical processing, solar panels, pipes, inserters, and fuel
for both legs. A one-way delivery does not prove a reusable cargo service.

| Cost contract | Output |
|---|---|
| `tests/progression/orbital-cost-*.args` | One launch load of each component at Orbital Construction |
| `tools/check_launch_vehicle.py` | Component costs relative to a default rocket stage; ore, gas, and imports remain separate |

#### Titanium recipes

Titanium improves the rocket stage rather than platform components. Imported
Vulcanus rutile must meet the stage's separate ore, gas, and crafting-time bounds
with each fuel route. Synthetic Nauvis rutile has no cost bound. The stage
unlocks after Vulcanus titanium research. Component cargo weights stay fixed.

#### Propellant

Electric chemical plants convert shipped material into the thruster's paired
fuel and oxidizer fluids. Both fluids are visible. Conditioning has no
productivity, including machine bonuses.

| Recipe | Input | Output |
|---|---|---|
| `nullius-canister-propellant` | Hydrogen canister | Thruster fuel, oxidizer, empty canister |
| `nullius-boxed-canister-propellant` | Boxed hydrogen canister | Thruster fuel, oxidizer, boxed empty canister |
| `nullius-hydrogen-propellant` | Hydrogen | Thruster fuel |
| `nullius-oxygen-propellant` | Oxygen | Thruster oxidizer |

Canister conditioning recovers both gases. Ordinary canister flushing loses the
oxygen. Carry return fuel before departure and drop empty canisters at home.

Nauvis supplies hydrogen canisters. Fulgora can supply ice; melt and electrolyze
it on the platform, then condition each gas. Ice carries more propellant per
launch but needs additional machines and solar power. Carbon monoxide and
methane conditioning remain outside this implementation.

The reference transit experiment holds thruster fill with infinity pipes. Its
consumption figures apply only to that layout and controlled fill. The first
flight contract uses finite canisters, real chemistry, and solar power.

#### Vacuum placement

Placeable Nullius entities in this table require positive pressure:

| Selection | Reason |
|---|---|
| Air filtration, water pumping, or seawater pumping category | Requires an atmosphere or a water body |
| Fluid energy source | Pneumatic equipment and solar collectors require planetary conditions |
| Mining drill or offshore pump | Requires ground or water |
| Wind turbine, Stirling engine, or probe wreckage | Requires wind, air cooling, or ground |

Existing surface conditions also exclude Vulcanus radiators, reinjection
extractors, primitive chests, and the clockwork roboport. Hot Vulcanus processes
cannot run at the platform's default ambient temperature. Electric assembly,
chemistry, electrolysis, distillation, labs, vents, tanks, solar panels, and
batteries remain available.

#### Vanilla cleanup

The four reused component recipes have Nullius ingredients and categories, and
only Orbital Construction unlocks them. The vanilla technology unlock effects
for these recipes and the platform interface are removed. Other vanilla
platform recipes remain hidden and disabled. The four Nullius propellant
recipes have separate names from the disabled vanilla recipes.

#### Validation contracts

| Contract | Checks |
|---|---|
| `nauvis-orbital-construction-closure.args` | Components, supporting machines, power, logistics, and canister conditioning at Orbital Construction without titanium, helium, or copper |
| `nauvis-orbital-bulk.args`, `nauvis-orbital-unpacking.args` | Boxed conditioning, foundation packaging, unpacking, and executors |
| `nauvis-orbital-gas.args` | Separate hydrogen and oxygen conditioning |
| `orbital-inspection.args` | Resolved component, ordinary, and boxed recipes |
| `orbital-construction` scenario | Finite batches of every new recipe, research owners, platform interface, and productivity rules |
| `experiment-platform-placement` | Resolved vacuum exclusions and visible thruster fluids |
| `experiment-platform-transit` | Thruster consumption with collision-free placement and controlled fill |
| `platform-first-flight` | Native construction from hub cargo, foundation unpacking, solar-powered boxed conditioning, a round trip, cargo drop without a pad, and empty-canister return |

Argument files are in `tests/progression/`; scenarios are in `tests/scenarios/`.
The first-flight fixture supplies the components and carriers as finite cargo.
The construction scenario separately proves their component recipes.

#### Measured platform contracts

`experiment-rocket-cargo-weights` checks cargo capacity and box weights. The
weight rule is in `prototypes/item-weights.lua`: explicit prototype weights
remain fixed; other weights derive from recipe inputs. Boxes weigh half their
contents. Recipe productivity flags do not set cargo weights.

`experiment-platform-transit` checks controlled-fill flights. The reference
thruster uses an extension behind the hub, with collision checks before placement.
`platform-first-flight` measures a complete solar-powered round trip with finite
cargo. These layouts have different fuel demand.

#### Microgravity processing

Not in the first platform implementation.

Recipes require gravity 0. Gravity is fixed per surface, so selection-time
surface-condition checks enforce it.

| Recipe | Product |
|---|---|
| Float-zone crystal growth | Higher monocrystalline silicon yield |
| ZBLAN fiber drawing | Improved optical cable |
| Protein crystallography | Cheaper genome recipes |

#### Asteroid hazards

Not in the first platform implementation; connections keep no asteroid spawns.

| Component | Role | Draft inputs |
|---|---|---|
| Debris bumper | Sacrificial wall line on the leading edge | Aluminum sheet |
| Debris trajectory adjuster | Electric turret; `attack_target_mask` targets asteroids only | Electric; no ammunition |

| Route | Hazard |
|---|---|
| Nauvis-Vulcanus | Dust |
| Nauvis-Fulgora | Medium; Fulgora's magnetosphere captures debris |
| Debris prototypes | `nullius-debris-*`; destruction splits them into smaller debris and drops no chunks |

### 4.5 Astronomy: Interplanetary Interferometry

Implemented for Nauvis, Vulcanus, and Fulgora. Dishes and correlators use
animated models on a 5×5 footprint. `astronomy-array`, `astronomy-correlation`, and
`astronomy-transit` check the production machines and transport contract.

The astronomy pack decodes the progenitor's interstellar signal. Dishes on one
planet see it over the same short baselines, so extra dishes only average noise.
Baselines between planets separate the signal from noise. Raw recordings are too
large to transmit, so cargo carries them to a correlator. Every dish keeps time
with a hydrogen maser.

```yaml
removed_sources:
  satellite_launch: 100 boxed astronomy packs; the satellite stays; see Satellite
  probe_launch: 1000 boxed astronomy packs and 200 boxes each of physics, chemical,
    and electrical packs; launches return nothing; 10 probes stay a mission objective
  concordance_satellite_launch: 42 astronomy packs; the launch keeps its alignment role
new_source: correlation of interferometric recordings
array_planets: Nauvis, Vulcanus, Fulgora; Gleba and Aquilo join when implemented
```

#### Research

| Technology | Prerequisites | Unlocks |
|---|---|---|
| Astronomy (`nullius-astronomy`) | Unchanged | Radio dish, correlator, blank recording module, Nauvis recording, every correlation recipe, astronomy pack boxing and unboxing, satellite |
| Vulcanus Radio Astronomy (`nullius-vulcanus-radio-astronomy`) | Astronomy, Pneumatic Technology | Pneumatic radio dish, Vulcanus recording |
| Fulgora Radio Astronomy (`nullius-fulgora-radio-astronomy`) | Astronomy, Primitive Filtration | Fulgora recording |

| Rule | Value |
|---|---|
| Research cost | Provisional until the research cost pass: Astronomy keeps its unit; planet technologies use `launch_research` with their planet pack |
| Planet entry | Pneumatic Technology and Primitive Filtration unlock each planet's science pack, so each planet technology needs that planet |
| Astronomy closure | Unchanged; `tools/check_launch_vehicle.py` already protects it |
| Existing saves | The engine resets recipes and technologies whenever mods change, so researched Astronomy grants its new unlocks. A migration creates the dish state first, because other mods' configuration handlers raise technology events before this mod rebuilds. `tests/upgrades/0.0.6` checks both |

Correlation recipes are unlocked before every source planet is available, so
the player sees the whole ladder at Astronomy. This replaces the rule that every
unlocked recipe is craftable at its technology for these recipes only:

| Contract | Rule |
|---|---|
| Correlation craftability | Each correlation recipe closes at Astronomy plus the radio astronomy technologies of its planets, with `--require-no-additional-technologies` |
| AGENTS.md | Add the multi-planet exception with this contract in the same change |

#### Dish

| Property | Rule |
|---|---|
| Entity | Assembling machine; one recording recipe per planet |
| Variants | Electric dish for Nauvis and Fulgora; pneumatic dish for Vulcanus, with a fuel input beside the hydrogen input |
| Recipe | 1 blank recording module + 1 hydrogen -> 1 planet recording |
| Hydrogen | Fluid input for the maser, charged per recording, so a throttled dish draws proportionally less. Piped, so spacing turns array growth into pipe length. Local sources: Nauvis seawater electrolysis; Fulgora electrolysis of slurry water, 1,200 slurry per 1,000 hydrogen; Vulcanus HCl cracking, 2,040 HCl per 1,000 hydrogen, competing with graphite, carbon monoxide, and water |
| Planet identity | Each recording recipe carries the planet's exact magnetic field and positive pressure as surface conditions. On build, and when a planet technology finishes, the script sets the surface's recording recipe and `recipe_locked`. A dish on a surface without an unlocked recording gets no recipe and a custom status |
| Modules and beacons | No module slots; reject module, beacon, and surface effects. Accept only local speed and consumption effects. Disable productivity and quality; each recording returns a blank at correlation |
| Spacing | Dishes reserve space only against other dishes, using the wind turbine mechanism: script-owned hidden fields on a dish-only collision layer. Other buildings may fill the gaps |
| Field geometry | Wind turbine geometry: four fields reaching 30.5 tiles from the dish centre |
| Collision layer | Dedicated layer; dishes do not interact with wind turbines or grounding coils, which share `layer_43` |
| Placement | Fulgora dishes may stand on island ground or sand |

#### Square-root array rule

The recording rate of one force's dishes on one surface grows as the square root
of their count. With all dishes supplied and no interference, N dishes produce
as much as sqrt(N) unthrottled dishes, above the native speed floor. Thus k
times one dish's rate needs k squared dishes.

```yaml
count: built dishes of the force on the surface, both variants; per force because
  each team's array averages its own noise
share: (1 - interference) / sqrt(N); interference is 0 off Fulgora
controller:
  refresh: on count changes, and at each 60-tick storm driver update for Fulgora
    dishes whose share changed; no buckets, as each write is one local effect
  local_effect: {speed: share - 1, consumption: share - 1}
  stop: disabled_by_script only while share is zero; write at stop and restart
  status: custom_status shows the array share and interference; write only on change
receiver:
  allowed_effects: [speed, consumption]
  module_slots: 0
  uses_module_effects: false
  uses_beacon_effects: false
  uses_surface_effects: false
  uses_local_effects: true
  speed_limits: {low: -0.9999, high: 1000}
  consumption_limits: {low: -0.9999, high: 1000}
```

The engine crafts continuously between updates. No dither accumulator is used.
Local effects add to other accepted bonuses, so module and beacon bonuses must
be rejected to preserve the array share. An empty `allowed_effects` also blocks
the local speed and consumption effects.

The native minimum speed is 0.0001 of base speed; positive shares below this
value clamp to it. A zero share needs a script stop to prevent slow production.
Consumption effects scale operating power; electrical drain is separate.

Count built dishes even when they lose power or inputs. Such a dish remains in
N and loses its own output. Adding an unpowered dish lowers the other dishes'
shares; the total-growth rule assumes the added dish is supplied.

| Dishes N | Each dish | Array total |
|---:|---:|---:|
| 1 | 1 | 1 |
| 4 | 0.5 | 2 |
| 16 | 0.25 | 4 |
| 100 | 0.1 | 10 |

#### Recordings and media

| Item or machine | Rule |
|---|---|
| `nullius-<planet>-interferometric-recording` | Produced only by that planet's dish recipe |
| `nullius-blank-recording-module` | Processor, glass, and ceramic media; no plastic. Dish input. Its recipe closes on every array planet at that planet's radio astronomy technology; Nauvis closes at Astronomy |
| Spoilage | Recording spoils to a blank module. Spoil time is a fixed prototype value: 1.5 times the reference transit |
| Reference transit | The reference platform's longest one-way trip between array planets, counted through Nauvis. The reference platform uses the Orbital Construction flight cell in `astronomy-transit`: one thruster, onboard canister conditioning, and solar power. Both directions are measured with finite fuel and no stops. Faster platforms gain margin, slower ones lose recordings; the value changes only when an array planet is added |
| Spoil clock | Starts at dish output, so silo queues and orbit waits count against it |
| Weight and stack | Recording and blank module each weigh 1 kg with stack size 50, declared in `prototypes/item-weights.lua`; the rule would make a recording half a blank. The 1,000 kg lift and 20 slots of 50 both give 1,000 items per rocket. Boxed blanks retain the full weight of their contents |
| Correlator | Assembling machine with its own crafting category; electric; any surface, including platforms; no productivity or modules; returns every consumed blank module |

Correlator location is a player choice. Single-planet correlation runs on the
ground. For k planets with labs on home planet H, one correlation cycle launches:

| Location | Recordings launched | Blank media returned | Total launched sets |
|---|---|---|---|
| Ground correlator on H | k - 1 | H reuses 1 set; k - 1 sets are launched back | 2(k - 1): 2 for 2 planets, 4 for 3, 8 for 5 |
| Platform correlator | k | Dropped to each array planet | k: 2 for 2 planets, 3 for 3, 5 for 5 |

| Rule | Value |
|---|---|
| Blank return | Crafting a blank costs more than launching one, checked by the planner. Otherwise remote planets recraft blanks, the ground correlator launches only k - 1 sets, and returned blanks pile up on H with no consumer |
| Launch comparison | Platforms launch less from three planets because drops are free; at two planets the counts tie |
| Excluded from the comparison | Building and fuelling the platform, and its visits to every array planet. The platform must visit each planet to collect recordings and drop blanks |
| Correlator power on a platform | Orbital solar: Vulcanus 600, Nauvis 300, Fulgora 120 |
| Cargo | Multi-planet sets need Orbital Construction and a local launch on each remote planet; Vulcanus and Fulgora both close their first launch |

#### Correlation ladder

Sensitivity grows with the baseline count, k(k-1)/2 for k distinct planets.
Each multi-planet recipe takes 10 recordings per planet and yields 10 packs per
baseline. The single-planet recipe is the bootstrap.

| Planets k | Recordings in | Baselines | Packs out | Packs per recording | Versus single |
|---:|---:|---:|---:|---:|---:|
| 1 | 20 | 0 | 1 | 0.05 | 1x |
| 2 | 20 | 1 | 10 | 0.5 | 10x |
| 3 | 30 | 3 | 30 | 1.0 | 20x |
| 4 | 40 | 6 | 60 | 1.5 | 30x |
| 5 | 50 | 10 | 100 | 2.0 | 40x |

| Rule | Value |
|---|---|
| Recipe set | One recipe per non-empty set of distinct array planets, generated in Lua |
| Recipe names | Planet names in order, e.g. `nullius-correlate-fulgora-nauvis-vulcanus` |
| Recipe count | 2^P - 1: 7 for 3 planets, 31 for 5 |
| Subgroups | One per k |
| Rejected | Pairwise fringe intermediates: they lose planet identity and allow a repeated planet to count as a new station |
| Combining wins | Packs per recording is (k - 1) / 2 for k >= 2, strictly increasing in k and above the single-planet 0.05. Merging recordings into a larger set always beats splitting them |
| Cargo | A pair launches 2 items per pack with either correlator: 10 recordings up and 10 blanks back, or 10 recordings from each planet. At 1,000 items per rocket that is 0.002 rockets per pack, the satellite's former 1 rocket per 500 packs |
| Where combining wins | Dish throughput. Labs on any planet share research, so separate processing needs no cargo. At equal dish counts a pair yields 10 times the packs; matching that separately needs 100 times the dishes on each planet under the square-root rule |
| Raw inputs alone | Favor separate processing. Measured per pack on Vulcanus: about 41 HCl for single-planet hydrogen, against about 1,405 HCl (default stage) or 744 HCl (titanium stage) for the rocket share of one launched recording. On Nauvis, seawater hydrogen costs no raw input |

Diminishing returns:

| Mechanism | Rule |
|---|---|
| Square-root array rule | One planet's output grows as the square root of its dish count |
| Array spread | Spacing spreads the growing dish count over growing area |
| Spoiling recordings | Remote recordings must reach the correlator within the spoil time |
| Crafting consumers | Genome recipes consume astronomy packs, so the ladder also prices Nauvis terraforming |

#### Satellite

The satellite stays undecided. This design only decouples it from astronomy.

| Rule | Value |
|---|---|
| Item and recipe | Kept, still unlocked by Astronomy |
| Consumers | Unchanged: asteroid miner, probe, and concordance satellite |
| Launch | No astronomy pack return; `send_to_orbit_mode` becomes `not-sendable`, so an automatic silo cannot burn one |
| `silo-compat` scenario and `tools/test_silo_compatibility.py` | Drop the satellite science return; the probe in `launch-vehicle` covers the launch path |
| Locale and mission text | Satellite description and the mission's "satellite contact" text describe recordings and correlation |

#### Validation contracts

| Contract | Checks |
|---|---|
| Research placement | Astronomy and planet technology prerequisites and unlocks; Astronomy closure unchanged |
| Correlation craftability | One progression contract per correlation recipe, as above |
| Correlation ladder | Unit test over the generated recipes: packs per recording strictly increases with set size, every set of 2 or more beats single-planet correlation, and each recipe takes equal recordings from distinct planets |
| `tools/check_astronomy.py` | Fresh resolved recipes; complete correlation ladder, all planet closures, and separate solid/fluid cost checks for media return |
| Blank modules | Ordinary and boxed closure on Nauvis at Astronomy, and on Vulcanus and Fulgora at their radio astronomy technologies |
| Recordings | Each planet's recording, with local hydrogen and its dish, closes on that planet at its radio astronomy technology; Nauvis at Astronomy |
| `astronomy-array` | Built dishes receive and lock their planet's recipe; a dish inside another dish's field is refused; a platform dish receives none; N = 1 and N = 4 produce work in the ratio 1 : 2 after share updates; each recording consumes one hydrogen; removal raises the remaining share; accepted effects cannot bypass throttling |
| `astronomy-array` power and storms | Storm interference and the square-root share multiply; share changes preserve progress; zero share stops production; operating power and pneumatic fuel follow the consumption effect; measure electrical drain separately |
| `astronomy-correlation` | Ground k = 1 and platform k = 2 correlation return every blank; recordings spoil to blanks at the prototype time |
| `experiment-rocket-cargo-weights` | Recording and blank weigh 1 kg; 1,000 fit one rocket |
| Locale | `python tools/check_factorio_locale.py` |

#### Fulgora storm interference

```yaml
property: nullius-storm-intensity          # default 100
lightning:
  multiplier_surface_property: nullius-storm-intensity
  lightning_multiplier_at_day: 1
  lightning_multiplier_at_night: 1
driver:
  cadence: 60 ticks
  value: 25 by day, 100 by night, linear from dusk to evening and from morning to dawn
  storm_cycles: later cycles change this value only
interference: min(1, intensity / 100)      # day 0.25, night 1
dish_controller: local speed and consumption effects use the combined array and interference share
full_interference: stop once on entry; resume once on exit
latency: none beyond the 60-tick driver cadence
dish_recipe: no storm surface condition
```

#### Measured engine contracts

Factorio 2.1.24: `experiment-astronomy-effects` passes 65 assertions at tick 900;
`experiment-storm-interference` passes 78 assertions at tick 6000.

| Contract | Measurement |
|---|---|
| Local speed and consumption | Electric and pneumatic recorders accept local effects with modules, beacons, and surface effects disabled; native consumption bonuses match the requested values |
| Continuous work | Electric speeds 1, 0.5, 0.1, and 0.01 produce proportional work; pneumatic speeds 0.5 and 0.01 do the same |
| Share change | Changing speed from 0.5 to 0.25 preserves craft progress and changes subsequent work |
| Default speed floor | A requested speed of 0.01 clamps to 0.2 with default limits |
| Configured speed floor | `speed = -1` still produces work at speed 0.0001; use a script stop for zero share |
| Storm boundaries | A script stop preserves progress with no work; clearing it restores native crafting |
| Lightning | Frequency follows the surface property, including zero and values above its default; the control surface remains unchanged |
| Recipe surface conditions | Native recipe selection checks conditions. Running recipes continue after conditions fail; Lua `set_recipe` accepts failing conditions; refused circuit selection is not retried when conditions clear |
| Power acceptance | The experiment checks consumption bonuses. The dish scenario must measure operating power, pneumatic fuel, and stopped electrical drain |

Space Exploration 0.7.57 uses the same square-root factor by changing infinite
core-seam resource amounts on miner creation and removal. Native mining then
controls production. Dishes retain assembling machines to consume blank media
and hydrogen; local effects provide continuous rate control.

```bash
python tools/check_astronomy.py --output astronomy-check.json
python tools/run_factorio_tests.py astronomy-array astronomy-correlation astronomy-transit -n auto
```

#### Changes from the earlier design

| Removed | Reason |
|---|---|
| Hydrogen maser component | The maser is the dish's hydrogen input; no separate item |
| Vulcanus receiver coolant input | The coolant was never specified; the pneumatic energy source already makes the variant local |
| Debris mitigation gate for Fulgora sets | No asteroids exist in this slice |
| Astronomy research cost doubling by tier | Research costs are aligned in a separate pass |

### 4.6 Launch Vehicle

Implemented: early launch research, both rocket stages, the silo, the landing
pad, and platform cargo. Planet-specific fuel alternatives below remain design
work.

| Scenario | Checks |
|---|---|
| `launch-vehicle` | Both stage recipes, no stage productivity, silo productivity, script cargo launch to a platform, probe mission count |
| `silo-platform-request` | Robots load the silo for a platform hub request, and the silo launches it unprompted |
| `silo-compat` | Automatic sending retains the satellite and returns no science |

#### Launch research

Rocket fuel and the default rocket need nothing later than the first physics
technologies. `nauvis-launch-fuel-closure.args` checks fuel and its boxed recipe
at Rocket Science 1. `nauvis-launch-titanium-free-closure.args` closes the default
stage, silo, and their boxed inputs at Rocket Science 2. These checks reject
titanium and helium dependencies. The titanium stage pays off only with Vulcanus
titanium, so it waits for Volcanic Titanium Metallurgy, which comes before
physics for a player who has reached Vulcanus.
`nauvis-titanium-stage-closure.args` and `vulcanus-titanium-stage-closure.args`
close it at Titanium Rocket Structures; Vulcanus still lacks only launch fuel.

| Technology | Unlocks | Prerequisites | Unit cost |
|---|---|---|---|
| Rocket Science 1 | Rocket fuel and its boxed recipes | `nullius-physics` | That of `nullius-composites-2` |
| Rocket fuel checkpoint | Unchanged | Rocket Science 1 | Unchanged |
| Rocket Science 2 | Default rocket stage, rocket, silo, cargo landing pad | Rocket fuel checkpoint, `nullius-composites-2` | That of `nullius-composites-2` |
| Titanium Rocket Structures | Titanium rocket stage | Rocket Science 2, Volcanic Titanium Metallurgy | Metallurgic science, sized like RP-1 fuel |

| Rule | Value |
|---|---|
| Only these three move | Each dependent of a moved technology takes over the prerequisites the moved technology drops |
| Rocket Science 1 dependents | Empiricism 6 and Robot Speed 4 take Demolitions 2, Freight Transportation 3, and High Pressure Chemistry 2 |
| Checkpoint dependents | Braking 8 takes the same three |
| Rocket Science 2 dependents | Astronomy takes Braking 8 and Personal Transportation 4 |
| Check | `tools/check_launch_vehicle.py` rebuilds the former tree from the moved technologies' former prerequisites; every other technology keeps its closure |

#### Rocket stage

The silo keeps `fixed_recipe = "nullius-rocket"`, so the silo cannot select
alternative recipes. The rocket recipe consumes one stage, and the stage carries
the alternatives. Titanium carries load and heat, so it replaces the aluminum and
steel frame and part of the composite overwrap and insulation. The lower dry mass
needs less propellant for the same payload.

```yaml
item: nullius-rocket-stage; stack 1
rocket_recipe: 1 nullius-rocket-stage -> 1 nullius-rocket; productivity allowed (silo modules)
stage_recipes: productivity disabled, so productivity applies once per rocket
fuel: a stage ingredient, so the titanium stage can take less
removed: logistic bots
inputs: boxed bulk materials and loose control components
```

| Recipe | Structure | Systems | Fuel |
|---|---|---|---|
| `nullius-rocket-stage` | Carbon composite, aluminum sheet, steel beam, insulation | Haste module 2, sensor node 1, heat pipe 2, ceramic, gate, cliff explosives for ignition and separation | Default amount |
| `nullius-titanium-rocket-stage` | Titanium sheet replaces aluminum sheet and steel beam; less composite and insulation | Same as default | Less |

#### Silo

```yaml
recipe: drone launcher 1, hangar 2, beacon 1, lab 2, productivity module 1, heat pipe 2, wall, hazard concrete
titanium_alternative: none; each planet builds few silos
launch_to_space_platforms: true
cargo: Space Age silo layout; a rocket cargo inventory replaces the single insertion slot
platform_requests: >-
  needs a logistic trash inventory, as on the Space Age silo; without one,
  "requests for platforms in orbit" reads back false and robots never load the rocket
can_launch_without_landing_pads: true, unchanged
```

#### Launch fuel

Each exporting planet must have a local route to `rocket-fuel` for its first
launch. This is a self-contained progression requirement. Later fuel imports
can supply launches; titanium stages and silo productivity reduce their fuel cost.

```yaml
current:
  item: rocket-fuel; vehicle fuel 60 MJ; stack 20; burnt result nullius-alumina
  recipe: >-
    1 methanol canister + 400 ammonia + 200 HCl + 150 compressed oxygen + 5 salt
    + 3 iron oxide + 35 aluminum powder + 14 rubber + 2 cliff explosives
    -> 3 rocket fuel + 200 wastewater, 40 s, basic-chemistry
  unlock: nullius-rocket-science-1
  per_launch: fuel is consumed by the selected stage recipe
gravity_scaling: none
```

| Planet | Propellant | Local chain | Cost driver |
|---|---|---|---|
| Nauvis | Ammonium perchlorate composite (current recipe) | Unchanged | Rubber binder, cliff explosives, and aluminum powder; the ammonia, HCl, and oxygen come from air and seawater |
| Vulcanus, after Vulcanus research | Aluminum burned in liquefied atmospheric CO2; design in [Aluminum-CO2 rocket fuel](PLANET_VULCANUS.md#aluminum-co2-rocket-fuel) | Aluminum powder, compressed CO2, a consumed canister, and cliff explosives; no polymer, water, or organics | Low performance: the most aluminum per fuel unit |
| Any planet with propene, after research | Aluminized gelled RP-1 | See [RP-1](#rp-1) | Propene |

| Rule | Value |
|---|---|
| Item | One `rocket-fuel` item; each chemistry is an alternative recipe |
| Planet restriction | None; local inputs decide which recipe a planet uses |
| Alumina | RP-1 consumes more aluminum powder than the tested burnt-alumina recovery routes return without productivity. Recovery productivity is outside this bound |
| Productivity | Disabled on fuel casting recipes |
| Boxed parity | Each new route has a boxed bulk recipe, checked with resolved-prototype tools |

Vulcanus details: [Vulcanus polymer policy](PLANET_VULCANUS.md#polymer-policy).

#### RP-1

Fulgora polymer research unlocks kerosene and RP-1 after Rocket Science 1 and
Bulk Polymer Processing. Propene and compressed hydrogen produce kerosene.
Kerosene, compressed oxygen, aluminum powder, and plastic produce rocket fuel
in a chemical plant. The same research unlocks the boxed recipe. Plastic gels
the fuel; aluminum burns and returns as alumina. Propene oligomerization is
short-chain polymerization, which places this research after polymer processing.
Diesel was rejected because its production already consumes aluminum powder.

Fuel casting has no productivity. Olefin oligomerization accepts the hydrocarbon
process bonus. The recipes have no surface restriction.

RP-1 uses 5 aluminum powder per fuel. Electrolytic recovery of its burnt alumina
returns 4.67 powder without productivity; this sets the input floor. The check
also covers basic smelting and carbide recovery. Recovery productivity is
excluded from this balance by design.

| Check | Contract |
|---|---|
| Ordinary and boxed production, machines, and pipes | `tests/progression/{nauvis,fulgora}-rp1-{closure,bulk}.args` |
| Fuel cost | `tests/progression/rp1-fuel-cost.args` |
| Planet fuel costs and titanium stage savings | `tools/check_launch_vehicle.py` |
| Aluminum return without productivity | `tests/scenarios/rocket-fuel-aluminum/` |
| Finite fuel batches through chemical plants and pipes | `tests/scenarios/rp1-fuel/` |
| Resolved ordinary and boxed recipes | `tests/progression/rp1-aluminum-inspection.args` |

#### Cargo closure

Every planet must build its silo and launch its first rocket entirely from local
production, with research shared across planets. Drops need no landing pad, but
no first launch may depend on them.

| Query | Unresolved today | Traced cause |
|---|---|---|
| `tests/progression/vulcanus-launch-closure.args` | None; no electricity required | [Aluminum-CO2 rocket fuel](PLANET_VULCANUS.md#aluminum-co2-rocket-fuel) and ANFO supply the fuel; the [pneumatic silo](PLANET_VULCANUS.md#pneumatic-silo) removes the electric path |
| `tests/progression/fulgora-launch-closure.args` | None | The default stage and silo need no helium. The separate helium contract also checks local degassing. Fuel uses the current Nauvis recipe |

```bash
python3 tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-launch-closure.args
python3 tools/analyze_factorio_prereqs.py @tests/progression/fulgora-launch-closure.args
```

`tests/progression/fulgora-launch-manifest.args` checks the local rocket and silo
production quantities. `tools/check_launch_vehicle.py` checks the launch research
closures, prices both titanium supply routes against the default stage, and
enforces the ore, gas, and time bounds.

The Vulcanus and Fulgora queries pass. Gleba and Aquilo need the same query.
The default stage and silo consume aluminum, iron, and steel,
which [2.4](#24-independent-bootstrap-design) lists as missing there, so each needs
a local metal route. They need no titanium route.

| Step | Rule |
|---|---|
| First launch | Silo, every rocket ingredient, and fuel have local routes; the planet's closure query exits 0 |
| Receive | A platform drops cargo with no landing pad or silo on the surface; confirmed in play, no scenario covers it |
| Import | Drops improve cost and throughput after the first launch; closure queries never declare a dropped item |

---

### 4.7 Heavy Elements and Nuclear Branches

Design only, except the parts marked implemented. Asteroid mining is removed.
Copper comes from Fulgora; uranium comes from Nauvis seawater adsorption and later
from Gleba; antimatter comes from antiproton capture around Fulgora. Fission and
fusion become two parallel branches that share only the reactor.

#### Asteroid mining removal

Asteroid mining is today's only source of copper ore and uranium ore: no recipe
produces either, and only guide-drone impacts create their patches. The removal
ships together with Fulgora copper, after seawater uranium below replaces the
uranium-ore checkpoint.

| Removed | Contents |
|---|---|
| Items and recipes | Asteroid miners 1 and 2, every guide drone and guide remote, guide-drone redeploy recipes |
| Technologies | Asteroid Mining 1 to 3; the copper-ore, uranium-ore, and asteroid-mining checkpoints |
| Scripts | Guide-drone impact effects in `drone.lua`, guide-drone checkpoint counts in `checkpoint.lua`, the ore list in `artillery_remote.lua`, and the `interface.lua` entries |

| Dependent | Today | After removal |
|---|---|---|
| Reconnaissance 3 | Requires Asteroid Mining 1 | Keeps its closure without the removed branch |
| Battery Storage 5 | Requires Asteroid Mining 3 | Same |
| Rocket Science 3 and the probe | Requires Asteroid Mining 2; the probe recipe takes an asteroid miner | The asteroid miner ingredient is replaced; the probe keeps its other inputs |
| Copper Production | Requires the copper-ore checkpoint | Requires the Fulgora copper technology |
| Uranium-ore checkpoint | Unlocks crushed uranium ore and ore yellowcake; Uranium Processing no longer requires it | Removed; ore yellowcake moves to the research that creates Nauvis deposits, so remaining patches stay usable |
| Mission goal 10 | 20 copper guide drones | Open; Fulgora copper deposit seeding is the candidate |
| Mission goal 11 | 12 uranium guide drones | 12 biomineralized uranium deposits; see below |
| Nauvis ore renewal | Iron, sandstone, bauxite, and calcite guide drones create new patches | None: Nauvis patches are finite. Vulcanus lava and Fulgora vents are infinite, so depleted Nauvis materials can be imported |
| Existing saves | Miner and drone items disappear with their prototypes; created patches remain | Migration and changelog compatibility note |

| Check | Contract |
|---|---|
| Research blast radius | New query `--describe-research-dependents TECHNOLOGY` in `tools/analyze_factorio_prereqs.py`: every technology whose prerequisite closure contains the given one, with the count |
| Rewired closures | A release check proves each rewired technology keeps its former closure minus the removed branch |

#### Nuclear branches

```
Shared base:     Nuclear Reactor   reactor and portable reactor
Fusion branch:   Electrolysis 4 -> Isotope Separation -> Nuclear Power 1 (fusion cells;
                 Nauvis, tritium-starved) -> aneutronic cells -> breeder cells
                 -> Aquilo: bulk tritium, monopole confinement
Fission branch:  Biochemistry 4 -> Seawater Uranium Adsorption --+
                 Electrolysis 4 -> Fluorine Chemistry -----------+-> Uranium Processing
                 -> Uranium Enrichment -> Nuclear Power 4 (fission cells)
Meeting point:   Antimatter Containment requires both branches
```

The reactor split, the fission detachment from the fusion ladder, seawater
uranium, fluorine chemistry, conversion, and centrifuge enrichment are implemented
without a new planet; `tools/check_nuclear_research.py` checks the placement and
closures in the release build, `tests/progression/nuclear-*` prove each unlock
closes at its technology, and the `seawater-uranium` and `uranium-enrichment`
scenarios craft every new recipe in placed machines. The rules below describe that
implemented state; [Fission branch](#fission-branch) describes the planned rest.

| Rule | Value |
|---|---|
| Reactor split | Nuclear Reactor unlocks the reactor and portable reactor after the thermal-tank checkpoint and Empiricism 5. Nuclear Power 1 keeps fusion cells and their recycling and requires Nuclear Reactor and the tritium checkpoint. Isotope Separation stays independent of the reactor |
| Fusion dependents | Boiling 3, Demolitions 2, and both Thermal Engineering 3 technologies keep Nuclear Power 1 and their closures |
| Fission | Seawater Uranium Adsorption follows Biochemistry 4 and Fluorine Chemistry follows Electrolysis 4. Uranium Processing requires both; Uranium Enrichment requires Uranium Processing; Nuclear Power 4 requires Uranium Enrichment and Nuclear Reactor. No breeder checkpoint, Nuclear Power 3, Boiling 4, Isotope Separation, uranium-ore checkpoint, or astronomy pack, so fission does not require Astronomy or tritium |
| Ore yellowcake | The uranium-ore checkpoint unlocks ore yellowcake beside crushed uranium ore |
| Uranium consumers | Uranium and enriched uranium come only from deconversion, so Wildlife Management 1 and Typesetting 4 require Uranium Enrichment, and Cybernetics 6 and 7 reach it through their closures |
| Antimatter Containment | Antimatter traps consume breeder and fission cells, so it requires the breeder checkpoint and Boiling 4 directly. Through fission cells it and its dependents also require the fission chain and the Nauvis biology research before it |
| Released research | Uranium consumers reached Nuclear Power 3 and the uranium-ore checkpoint only through Uranium Processing and no longer require them; they gain the fission chain and keep Astronomy through other prerequisites. `tools/check_nuclear_research.py` lists each changed closure |
| Existing saves | A force that researched Nuclear Power 1 receives Nuclear Reactor. A force that researched Uranium Processing keeps ore yellowcake through the checkpoint it already researched, and receives Fluorine Chemistry and Uranium Enrichment |

#### Fission branch

Seawater adsorption gives Nauvis uranium without a new planet; Gleba leaching and
biomineralized deposits later take over bulk supply. The rest of the chain needs
only Nauvis chemistry.

| Research | Unlocks | Prerequisites | Cost |
|---|---|---|---|
| Seawater Uranium Adsorption | Adsorbent, loading, elution, precipitation to yellowcake | Biochemistry 4 | Biology packs, as Biochemistry 4 |
| Fluorine Chemistry | Fluorite flotation, hydrogen fluoride, fluorine | Electrolysis 4 | Chemistry and physics packs, as Isotope Separation |
| Uranium Processing | Conversion: uranium dioxide, green salt, empty cylinder, hexafluoride | Seawater Uranium Adsorption, Fluorine Chemistry | As Isotope Separation |
| Uranium Enrichment | Centrifuge, both enrichment stages, both deconversions | Uranium Processing | As Nuclear Power 1 |
| Nuclear Power 4 | Unchanged: fission cell and fission recycling | Uranium Enrichment, Nuclear Reactor | As Nuclear Power 1, its fusion counterpart |

| Rule | Value |
|---|---|
| Placement | Biochemistry 4 is the first protein-engineering research (amino acid metabolism) and shares Empiricism 5 with Nuclear Reactor. Its closure already makes acrylic fibre and amino acids. Fluorine Chemistry and Isotope Separation both follow Electrolysis 4. Fluorite flotation is a new flotation-cell recipe on crushed calcite; its contract proves the cell, crushed calcite, and sulfuric acid close at Fluorine Chemistry |
| Uranium Processing | The seawater research already makes yellowcake, so Uranium Processing is the fluoride conversion to natural hexafluoride and requires Fluorine Chemistry. Every research in the chain unlocks a product its own unlocks consume or that the next research consumes |
| Astronomy | Removing the uranium-ore checkpoint is not enough: the astronomy packs in Uranium Processing, Uranium Enrichment, and Nuclear Power 4 costs would keep Astronomy |
| Timing | Fission arrives at the Nauvis biochemistry and Electrolysis 4 tiers, beside Nauvis fusion; the fission cell is "technically simpler to harness" than fusion |
| Gleba move | Seawater Uranium Adsorption later swaps its biology packs for Gleba science; its recipes stay |

Delivery order:

| Step | Change | Coupling removed |
|---|---|---|
| Seawater uranium (implemented) | See the rules above | Astronomy |
| Enrichment (implemented) | Fluorine Chemistry and Uranium Enrichment; Uranium Processing becomes conversion and drops Isotope Separation, uranium smelting, and tritium enrichment | Tritium |
| Asteroid removal | See [Asteroid mining removal](#asteroid-mining-removal) | Uranium-ore checkpoint |

| Stage | Process | Real basis |
|---|---|---|
| Seawater | See [Seawater uranium](#seawater-uranium) | Uranyl-binding protein adsorbents |
| Leaching | A bred sulfur-oxidizing strain leaches Gleba rock into uranyl sulfate liquor, which precipitates yellowcake | Bacterial heap leaching of uranium with *Acidithiobacillus*; Gleba's H2S atmosphere and abundant sulfur |
| Nauvis deposits | Biomineralized deposits yield ore for the existing crushed-ore and flotation route to yellowcake | See mission goal 11 below |
| Fluorite | Crushed calcite flotation yields trace fluorite concentrate; the calcite leaves as gravel, mineral dust, and sludge tailings. Recovering calcite from the tailings returns less than a cycle consumes, so it cannot be refloated indefinitely | Industrial fluorite and calcite flotation separation |
| Hydrogen fluoride | Fluorite + sulfuric acid -> hydrogen fluoride + gypsum | The industrial HF route |
| Fluorine | Hydrogen fluoride electrolysis -> fluorine + hydrogen | Fluorine production from HF electrolysis |
| Uranium dioxide | Furnace: yellowcake + hydrogen -> uranium dioxide + water | Reduction step of uranium conversion |
| Green salt | Uranium dioxide + hydrogen fluoride -> uranium tetrafluoride + wastewater | Hydrofluorination |
| Hexafluoride | Uranium tetrafluoride + fluorine + empty cylinder -> natural UF6 cylinder | UF6 is solid at room temperature and ships in cylinders |
| Enrichment stage A | Centrifuge: natural UF6 -> low-enriched UF6 + depleted tails | Gas centrifuge cascade |
| Enrichment stage B | Centrifuge: low-enriched UF6 -> reactor-grade UF6 + a stripped stream returned to stage A | Cascade recycle |
| Deconversion | Reactor-grade UF6 + steam + hydrogen -> enriched uranium + hydrogen fluoride + empty cylinder; tails -> uranium (U-238) + hydrogen fluoride + empty cylinder | Deconversion recovers the fluoride |
| Fission cell | Unchanged: steel sheet, uranium, enriched uranium | Existing recipe |

| Rule | Value |
|---|---|
| Centrifuge | `nullius-centrifuge`, a copy of the vanilla centrifuge with its own Nullius category and recipe; the vanilla prototype stays untouched. It has no fluid boxes, so UF6 moves in cylinder items |
| Loops | The stage B return, hydrogen fluoride, and cylinders circulate; deconversion returns less hydrogen fluoride than conversion consumes, and fluorite tops up that loss. Each stage conserves cylinders |
| Removed recipes | Tritium enrichment and direct yellowcake smelting to uranium. Uranium comes from enrichment tails, which gives the tails a consumer |
| Existing items | `nullius-uranium` is described as U-238 and `nullius-enriched-uranium` as U-235; both keep their names and consumers |

#### Seawater uranium

The first uranium source: slow, but needs no planet and no cargo. Once Gleba
exists it becomes the stopgap before cultures arrive, deliberately much worse
than either Gleba route. Seawater holds about 3 micrograms of uranium per litre.

| Rule | Value |
|---|---|
| Research | Seawater Uranium Adsorption follows Biochemistry 4 and costs Nauvis biology packs: the android's labs design a uranyl-binding protein. When Gleba ships, the cost moves to Gleba biological science. Research is global, so the recipes run on Nauvis without cargo either way |
| Real basis | Engineered uranyl-binding proteins with femtomolar affinity, and amidoxime polymer fibres tested for seawater extraction |
| Adsorbent | Amino acids + acrylic fibre support -> uranyl-binding fibre |
| Loading | Adsorbent + an obscene volume of seawater -> loaded adsorbent + saline + sludge. The fiber bed filters the seawater, trapping silt and biofouling, and less saline comes out than seawater filtration gives. No seawater returns, so the intake volume cannot be looped |
| Elution | Loaded adsorbent + acid -> uranyl solution + most of the adsorbent back; the rest is consumed every cycle without a probabilistic result |
| Precipitation | Uranyl solution + sodium hydroxide -> yellowcake + wastewater; real sodium diuranate precipitation |
| Cost | Seawater is free, so machine count, pumping, and adsorbent carry the cost. When biomineralized deposits ship, the route must need at least 10 times the machine time per yellowcake of the deposit route |
| Craftability | The adsorbent and every loading, elution, and precipitation input close on Nauvis at the research, with `--require-no-additional-technologies` |

The machine-time bound needs a manifest query that does not exist yet; it ships
with the deposits:

```yaml
query: production manifest machine time total
input: existing --manifest --marginal arguments and target quantities
output:
  machine_seconds: sum of seconds_per_cycle * cycles over placed executors, by category
consumer: a fission cost check comparing seawater and deposit yellowcake
```

Uranium sources, best last:

| Source | Planet | Needs cargo | Role |
|---|---|---|---|
| Seawater adsorption | Nauvis | No | First source; stopgap once Gleba exists |
| Bacterial leaching | Gleba | To export | Gleba's own supply and bootstrap |
| Biomineralized deposits | Nauvis | Cultures from Gleba | Bulk Nauvis supply and mission goal 11 |

#### Mission goal 11: biomineralization

| Rule | Value |
|---|---|
| Culture | A perishable Gleba culture that reduces dissolved uranium from water into a mineral deposit, as *Geobacter* does |
| Seeding | A drone seeds a uranium patch on Nauvis coast or shallow water, reusing the guide-drone patch creation in `miner_effect` |
| Goal | Counts seeded deposits; the target stays 12 |
| Supply | Spoilage makes the culture a recurring Gleba-to-Nauvis shipment |
| Lore | Life concentrates seawater uranium, remediating the planet's heavy-element deficiency |

#### Antimatter: antiproton capture

Planetary radiation belts trap antiprotons; the PAMELA satellite observed them in
Earth's belts. Fulgora has the strongest magnetic field of the three planets.

| Rule | Value |
|---|---|
| Machine | Antiproton collector, buildable only on space platforms. It fills an empty trap with antimatter, reusing `nullius-antimatter-trap` and `nullius-antimatter` |
| Location | Recipes cannot see a platform's orbit, so a script enables collectors only while their platform is stopped at Fulgora, using the dish lifecycle controller pattern |
| Research | Antimatter Containment, repurposed: Orbital Construction and Fulgora research; no enriched-uranium checkpoint |
| Removed | The trap's reactor-fuel role |
| Consequence | Victory requires Fulgora and a platform, because probes take antimatter |
| Other consumers | Battery 3, Shield, and Solar Panel 4 follow the same source |

Traps hold antimatter only while powered, so filled traps spoil and must be
re-energized.

| Rule | Value |
|---|---|
| Spoilage | `nullius-antimatter` spoils to an empty `nullius-antimatter-trap`; the antimatter annihilates, and the trap returns to Fulgora for refilling |
| Spoil time | Fixed prototype value: 1.5 times the reference transit from Fulgora to Nauvis, so a delivery need not recharge en route |
| Recharge | 1 filled trap -> 1 filled trap; the product sets `always_fresh = true` with `percent_spoiled = 0`. Without the flag a crafted product inherits its ingredient's spoilage, so recharging would not reset the timer |
| Recharge cost | Electricity and crafting time only; no productivity or quality |
| Executor | Electrolyzers, category `nullius-electrolysis`, which already forbids productivity. They work on the ground and on platforms, so stockpiles and cargo in transit can both be maintained. Priority electrolyzers keep traps safe; surge electrolyzers run only on surplus power, so a shortage lets traps spoil |
| Stacks | Merging stacks averages spoil timers, so stockpiles need a recharge loop, as with other spoiling goods |
| Consumers | Consume the filled trap; only spoilage returns an empty trap |

| Contract | Checks |
|---|---|
| Spoilage | A filled trap spoils to an empty trap at the prototype time |
| Recharge | A nearly spoiled trap comes out fresh; an ordinary recipe without `always_fresh` would not |
| Collector gate | Collectors work only while their platform is stopped at Fulgora |
| Consumer closure | Battery 3 and stabilizer 2 get a `--require-no-additional-technologies` contract through the collector recipe. Today antimatter is only a trap's burnt result, which `tools/analyze_factorio_prereqs.py` does not model, so no contract can close them |

## 5. Quality Mechanic

**Decision: Loaded but disabled.** Space Age requires the Quality mod, so
Nullius* cannot mark it incompatible. The data stage disables its gameplay
effects instead.

Rationale:
- Nullius already has its own complexity layers (boxing, byproduct management, checkpoint gating, module system). Quality adds pervasive complexity on top of that for marginal design benefit.
- Quality interacts with spoilage (higher quality = slower spoil), which would complicate the Vulcanus cooldown and Gleba decay mechanics.
- Every recipe has `allow_quality = false`.
- Recycling recipes are hidden and disabled, and Nullius items opt out of
  automatic recycling generation.
- Quality-tier multipliers and transition probabilities are neutralized, and
  quality modules are hidden.

---

## 6. Science Pack Remapping

### Current Nullius Packs --> Planet Assignment

Generic packs stay Nauvis packs with worse local recipes on other planets, as in
[4.2](#42-pre-cargo-research-how-isolated-planets-contribute). No pack moves off Nauvis.

| Nullius Pack | Current Source | SA Planet Assignment |
|---|---|---|
| Geology | Nauvis ores | Nauvis; local alternatives |
| Climatology | Nauvis air/water | Nauvis; local alternatives |
| Mechanical | Nauvis industry | Nauvis; local alternatives |
| Electrical | Nauvis electronics | Nauvis; local alternatives |
| Chemical | Nauvis chemistry | Nauvis; local alternatives |
| Physics | Nauvis (complex machines) | Nauvis; local alternatives |
| Astronomy | Radio correlation | Interplanetary interferometry; see [4.5](#45-astronomy-interplanetary-interferometry) |
| Biology packs (7) | Nauvis farming | Gleba (primary) + Nauvis (deployment) |

### New Packs for SA Planets?

| Potential Pack | Planet | Ingredients |
|---|---|---|
| Metallurgic | Vulcanus | Titanium intermediates + calcite + volcanic alloys |
| Electromagnetic | Fulgora | Local electrical components and polymer materials; recipe design in [Fulgora design](PLANET_FULGORA.md#science-and-research) |
| Cryogenic | Aquilo | Lithium + tritium + ammonia compounds |
| Biological | Gleba | Bred strains, exotic enzymes, cultured organisms; see [4.2](#planet-specific-science-packs) |

---

## 7. Migration/Compatibility Strategy

### 7.1 Dependency Order

Planets come before cargo because each must work with zero imports. Current state
is in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

1. **Planet access and independent bootstrap**: probes, Vulcanus, Fulgora
2. **Cargo**: cargo closure, launch vehicle, space platforms
3. **Astronomy**: interferometry; multi-planet correlation needs cargo
4. **Gleba integration**: biology rework, spoilage mechanics
5. **Aquilo integration**: nuclear rework, endgame
6. **Quality compatibility**: implemented as loaded but gameplay-neutralized

### 7.2 Scope Estimate
This is a massive undertaking:
- Every SA recipe needs a Nullius-compatible version
- Planet-specific tech trees must integrate with checkpoint system
- Byproduct management must work on each planet
- Wind/energy systems need planet-specific variants
- Biology progression needs fundamental restructuring if Gleba is included
- Boxing system must work with SA logistics

---

## 8. Open Questions

### Narrative & Progression
- Should Nauvis terraforming remain the primary goal, with planets as supporting infrastructure? Or should each planet have its own terraforming objective?
- How many planets should be accessible at probe reactivation tier? All at once, or gated sequentially?
- Should probe reactivation be a single tech or per-planet research?
- What's the minimum viable bootstrap on each planet? How much frustration is fun vs. tedious?
- Should there be a "care package" mechanic -- small one-time data/blueprint transfer before cargo?

### Resources & Production
- Does the chlorine problem exist on other planets, or is it Nauvis-specific?
- Should the hydrogen storage loop have planet-specific variants (lightning storage on Fulgora, geothermal baseload on Vulcanus)?
- How do planet-exclusive resources interact with the checkpoint system? Can checkpoints require off-world items?

### Biology
- Should biology packs require Gleba research, or remain Nauvis-producible?
- Does spoilage apply to Nullius biological items when transported between planets?
- Are Gleba organisms compatible with Nauvis ecosystem seeding, or must they be adapted?

### Research Visibility
- Tuning: how many techs to reveal per planet? Too many = overwhelming tree. Too few = unclear what the planet offers.
- Should endgame Rogue techs show as "???" (visible but unresearchable) to create anticipation, or be fully hidden until awakening?
- Should there be a "planetary research overview" GUI showing which planets unlock which tech branches?

### Systems
- How do space platforms interact with the boxing/logistics system?
- Does the beacon interference system work differently on different planets?
- Should each planet have its own byproduct management challenges (e.g., Vulcanus has SO2 instead of Cl2)?
- How does the alignment/multiplayer faction system work with multi-planet play? Can factions control different planets?

---

## 9. Technical Feasibility (Factorio 2.0 / Space Age API)

Analysis based on the actual `prototype-api.json` and `runtime-api.json` from Factorio's latest API docs.

### 9.1 Spoilage System -- FEASIBLE (Base 2.0)

**No Space Age dependency.** Spoilage is a base 2.0 engine feature.

| Field | Type | Notes |
|---|---|---|
| `spoil_ticks` | uint32 | Ticks until spoilage. 0 = never spoils. |
| `spoil_result` | ItemID | What it becomes. Nil = item vanishes. |
| `spoil_to_trigger_result` | SpoilToTriggerResult | Trigger effect on spoilage (e.g., spawn entity). |
| `spoil_level` | uint8 | Priority sorting for inserters with spoil priority. |

**Chains work**: A --> B --> C spoilage chains are supported. Can be applied to any item.

**Use cases confirmed viable:**
- Vulcanus molten metal cooldown (spoil_ticks as cooling time, spoil_result = solid ingot)
- Gleba failed strains decaying (spoil_result = waste/sludge)
- Gleba galvanic cells degrading (spoil_ticks = cell lifetime)

**Limitation**: Spoilage rate is fixed per item type. No temperature-dependent spoilage without scripting. Quality extends spoilage timers automatically (higher quality = slower spoil).

### 9.2 Lightning System (Space Age DLC)

Lightning collection, overload protection, and grounding are described in
[Fulgora design](PLANET_FULGORA.md#lightning-and-overload).

### 9.3 Probabilistic Recipe Outputs -- FEASIBLE (Base 2.0)

**No Space Age dependency.** Probability fields exist since Factorio 1.x.

**ItemProductPrototype / FluidProductPrototype:**

| Field | Type | Default | Notes |
|---|---|---|---|
| `probability` | double | 1.0 | 0-1 range. Independent roll per product. |
| `amount` | uint16/FluidAmount | - | Fixed amount (mutually exclusive with min/max). |
| `amount_min` | uint16/FluidAmount | - | Minimum random amount. |
| `amount_max` | uint16/FluidAmount | - | Maximum random amount. |
| `extra_count_fraction` | float | 0 | Fractional bonus item (deterministic over many crafts). |
| `percent_spoiled` | float | 0 | Output pre-spoiled by this fraction. |

**Key for Gleba breeding**: Each product in `results` is rolled independently. A breeding recipe can have:
```lua
results = {
  {type="item", name="viable-strain",   amount=1, probability=0.60},
  {type="item", name="failed-strain",   amount=1, probability=0.25},
  {type="item", name="variant-strain",  amount=1, probability=0.10},
  {type="item", name="contamination",   amount=1, probability=0.05},
}
```
These are NOT mutually exclusive -- multiple can fire per craft. To approximate "pick one," set probabilities that rarely overlap. For strict mutual exclusion, scripting is needed.

### 9.4 Planet/Surface System -- FEASIBLE (Space Age DLC)

**Requires Space Age.** Mods can define fully custom planets.

**PlanetPrototype fields:**

| Field | Notes |
|---|---|
| `map_gen_settings` | Full map generation (resources, terrain, cliffs). Custom autoplace controls. |
| `surface_properties` | Dictionary of SurfacePropertyID --> double. Custom properties supported. |
| `lightning_properties` | Full lightning configuration per planet. |
| `entities_require_heating` | Boolean -- Aquilo-style heating requirement. |
| `pollutant_type` | Custom pollution type per planet. |
| `player_effects` / `ticks_between_player_effects` | Periodic effects on player (cold damage, etc.). |

**SpaceConnectionPrototype**: Defines travel routes between planets with `from`, `to`, `length`, and asteroid spawn definitions.

**RecipePrototype.surface_conditions**: Restricts recipes to specific planets based on surface property values. E.g., "this recipe only works on surfaces where pressure > 500."

**Custom surface properties**: Mods can define via `SurfacePropertyPrototype` (name, default_value). Then reference in planet surface_properties and recipe surface_conditions.

### 9.5 Segmented Units (Demolishers) -- FEASIBLE (Space Age DLC)

**Requires Space Age.** Full prototype and runtime API available.

**SegmentedUnitPrototype fields:**

| Field | Type | Notes |
|---|---|---|
| `territory_radius` | uint32 | Territory size in chunks. Required. |
| `patrolling_speed` | double | Movement speed while patrolling (tiles/tick). Required. |
| `investigating_speed` | double | Speed when investigating disturbances. Required. |
| `attacking_speed` | double | Speed when attacking. Required. |
| `enraged_speed` | double | Speed when enraged. Required. |
| `enraged_duration` | MapTick | How long it stays enraged after taking damage. Required. |
| `attack_parameters` | AttackParameters | Normal attack configuration. |
| `revenge_attack_parameters` | AttackParameters | Retaliation attack config. |
| `vision_distance` | double | Scan radius for enemies. Max 100. Required. |
| `ticks_per_scan` | uint32 | Scan frequency. Default 120 (2 sec). |
| `segment_engine` | SegmentEngineSpecification | Defines body segments. Required. |
| `turn_radius` | double | Turn radius in tiles. Required. |

**SegmentPrototype**: Defines individual body segments (animation, padding, overlap, update_effects, update_effects_while_enraged).

**Territory system (runtime API - LuaTerritory):**

| Method/Property | Notes |
|---|---|
| `territory.destroy()` | Destroys territory + all guarding units. |
| `territory.get_chunks()` | Get all chunks in territory. |
| `territory.get_patrol_path()` | Get current patrol path. |
| `territory.set_patrol_path()` | **Overwrite patrol path.** |
| `territory.get_segmented_units()` | Get units guarding this territory. |
| `territory.regenerate_patrol_path()` | Reset to default path. |
| `territory.regenerate_segmented_units()` | Respawn units. |

**Events:**

| Event | Notes |
|---|---|
| `on_territory_created` | Fires with `cause` (why territory was created). |
| `on_territory_destroyed` | Territory about to be destroyed. Can still read/modify. |
| `on_segmented_unit_damaged` | Separate from `on_entity_damaged`. Has segmented_unit field. |

**For Nullius Vulcanus demolishers as player-created synthetic life:**

The API is surprisingly well-suited for this:

1. **Define custom SegmentedUnitPrototype** with different speeds, territory radius, attack behavior. Set `attack_parameters` to nil or low damage for non-aggressive variants. Can define custom segment chains (head + body + tail) with unique graphics.

2. **Territory is the key abstraction.** `LuaTerritory` provides:
   - `set_patrol_path()` -- **direct demolisher movement** along specific routes toward desired deposits
   - `regenerate_segmented_units()` -- spawn/respawn units within a territory
   - `get_segmented_units()` -- track which units belong to which territory
   - `destroy()` -- remove territory + all units (for recalled/decommissioned demolishers)

3. **Player-spawning workflow:**
   - Player crafts "demolisher deployment" item and places it (custom entity)
   - Script creates a territory centered on placement location
   - Script calls `territory.regenerate_segmented_units()` to spawn the demolisher
   - Script uses `territory.set_patrol_path()` to route it toward target deposits
   - Territory events (`on_territory_created`, `on_territory_destroyed`) hook into the system

4. **Force assignment**: Set demolisher force to `"player"` so it doesn't attack player structures. Use custom resistances/damage so it interacts with terrain/resources but not buildings.

5. **Open question**: Can `surface.create_entity()` spawn segmented units directly, or must they always go through territory? The API suggests territory is the intended spawning mechanism (`regenerate_segmented_units()`), but direct entity creation may also work.

6. **Feeding/maintenance**: No built-in "feeding" mechanic for segmented units. Would need scripting -- periodic check on nearby resource availability, despawn/damage the unit if not fed. Or use spoilage on a "feed timer" item that must be resupplied.

### 9.6 Entity Power Manipulation -- FEASIBLE (Base 2.0)

**LuaEntity key properties (all read+write):**

| Property | Notes |
|---|---|
| `entity.active` | Setting false stops all operations. Reversible. |
| `entity.energy` | Read/write energy buffer. Set to 0 to drain. |
| `entity.health` | Read/write. Set to heal after damage. |
| `entity.electric_network_id` | Read-only. Identifies network for area effects. |

The proposed EMP behavior and recovery checks are in
[Fulgora design](PLANET_FULGORA.md#lightning-and-overload).

### 9.7 Summary: What Requires Space Age DLC

| Mechanic | DLC Required? | Critical for Nullius SA? |
|---|---|---|
| Spoilage (spoil_ticks, spoil_result) | **No** (base 2.0) | Yes (Vulcanus cooldown, Gleba decay) |
| Probabilistic recipes | **No** (base 2.0) | Yes (Gleba breeding) |
| Entity active/energy manipulation | **No** (base 2.0) | Yes (Fulgora EMP) |
| Quality system | **Yes** (Space Age) | Optional |
| Lightning | **Yes** (Space Age) | Yes (Fulgora) |
| Planets/surfaces/connections | **Yes** (Space Age) | Yes (core multi-planet) |
| Segmented units/territories | **Yes** (Space Age) | Yes (Vulcanus demolishers) |
| Rockets to orbit, space platforms | **Yes** (Space Age) | Yes (cross-planet logistics) |

### 9.8 Technology Visibility Control -- FEASIBLE (Base 2.0)

**No Space Age dependency.** Tech visibility manipulation is base engine.

**Prototype-level fields:**

| Field | Type | Default | Notes |
|---|---|---|---|
| `hidden` | boolean | false | Completely hides tech from GUI. Cannot be seen or researched. |
| `enabled` | boolean | true | Whether tech can be researched. Greyed out if false. |
| `visible_when_disabled` | boolean | false | Show in GUI even when disabled. Greyed out but visible. |

**Runtime manipulation (LuaTechnology):**

| Property | Read/Write | Notes |
|---|---|---|
| `enabled` | R/W | Toggle researchability at runtime. |
| `visible_when_disabled` | R/W | Toggle visibility of disabled techs at runtime. |
| `researched` | R/W | Force-complete or un-research a tech. |
| `reload()` | method | Reload from prototype (resets runtime changes). |

**Implementation for planet-gated research:**

```lua
-- On game start / mod init:
-- All planet-specific techs start hidden=true in prototype
-- (or enabled=false, visible_when_disabled=false)

-- On probe reactivation (e.g., "nullius-probe-vulcanus" researched):
for _, tech in pairs(force.technologies) do
  if is_vulcanus_tech(tech.name) then
    tech.enabled = true
    -- Tech appears in tree, connected to prerequisites
  end
end

-- For endgame Rogue techs:
-- Start with visible_when_disabled=true, enabled=false
-- Player can SEE them greyed out ("something is coming...")
-- On Rogue awakening event:
--   tech.enabled = true (now researchable)
```

**Three visibility states available:**

| State | Prototype | Runtime | Player Sees |
|---|---|---|---|
| **Fully hidden** | `hidden=true` | N/A | Nothing. Tech doesn't exist in GUI. |
| **Teased** | `hidden=false`, `enabled=false`, `visible_when_disabled=true` | Set at init | Greyed out tech in tree. "Something exists but you can't research it yet." |
| **Available** | `hidden=false`, `enabled=true` | Set on trigger | Normal researchable tech. |

**Recommended approach per category:**

| Tech Category | Initial State | Reveal Trigger |
|---|---|---|
| Nauvis techs (Tier 1-4) | Available | Always (current Nullius behavior) |
| Probe reactivation tech | Available | Part of Nauvis Tier 4 research |
| Planet-specific techs | **Fully hidden** | Probe reactivation for that planet |
| Cross-planet techs (Tier 6) | **Teased** (greyed out) | Prerequisites from multiple planets met |
| Rogue countermeasure techs | **Fully hidden** | Rogue awakening event |
| The Solution tech | **Teased** | Rogue awakening (visible but locked behind massive prerequisites) |

This keeps the tech tree clean early game (no overwhelming planet branches), reveals content as planets are activated, and uses the "teased" state to create anticipation for endgame content.

**Nullius already does something similar** with its checkpoint system -- techs are enabled/disabled based on production milestones. The planet visibility system is the same pattern at larger scale.

**Conclusion**: Nullius SA integration requires a Space Age dependency. The key base-2.0 features (spoilage, probabilistic recipes, entity manipulation) work independently and could be used on Nauvis without SA, but the multi-planet architecture requires it.

---

## 10. Building Maintenance (Extracted)

> Moved to [MAINTENANCE_BRAINSTORM.md](MAINTENANCE_BRAINSTORM.md). May be implemented as a separate companion mod.

---

*This document is a living brainstorm. Nothing here is committed to implementation.*
