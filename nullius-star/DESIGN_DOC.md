# Nullius - Comprehensive Design Document

> **Auto-generated** from codebase analysis on 2026-03-22.
> Covers gameplay, progression, energy, science, production chains, and balance.

---

## 1. Overview

**Nullius** is a total-conversion mod for Factorio 2.0 (v2.0.2, MIT0 license). The player is a **von Neumann android** -- a self-replicating AI terraformer that has arrived on a barren, lifeless planet after centuries of relativistic space travel. The primary directive is to:

1. Develop industrial infrastructure from nothing.
2. Terraform the planet and restore a breathable atmosphere.
3. Seed it with life (algae, plants, animals).
4. Build successor androids to continue galactic expansion.

The planet is poor in heavy elements and has no breathable atmosphere. There is **no coal, oil, wood, or biters**. All resources must be synthesized through industrial processes and renewable energy.

---

## 2. Core Design Philosophy

| Principle | Implementation |
|---|---|
| **No free lunches** | Every resource has an energy and processing cost. No coal/oil/wood handouts. |
| **Abundance from processing** | Useful materials are synthesized from abundant inputs (air, seawater, sunlight, geothermal). |
| **Checkpoint-gated progression** | Physical milestones (craft X items, produce Y fluid) gate technology research. Cannot rush research without building infrastructure. |
| **Renewable-only energy** | Wind, solar, geothermal, hydrogen combustion. No fossil fuels. |
| **Chemistry-driven production** | Ore flotation, electrolysis, and organic chemistry replace simple smelting. |
| **Biology as endgame** | The final third of the game focuses on genetic engineering, ecology, and seeding life. |

### Vanilla Systems Replaced

| Vanilla | Nullius |
|---|---|
| Coal/oil/wood resources | Synthesized from air, water, and geothermal |
| Pollution system | **Disabled entirely** |
| Biter threat | Minimal -- evolution essentially frozen |
| Simple smelting | Multi-stage: crushing, flotation, electrolysis, casting |
| Fixed inserter tiers | Tiered inserters with built-in filtering |
| Oil refining | Organic chemistry from atmospheric carbon |
| Power from coal/nuclear | Wind, solar, geothermal, hydrogen combustion, late-game nuclear |
| Free waste disposal | Byproduct management with restricted venting; chlorine cannot be voided |

---

## 3. Byproduct Management

Byproduct management is a **core design constraint** in Nullius. Most production processes generate byproducts that must be consumed, recycled, or disposed of -- and some fluids **cannot be disposed of at all**.

### 3.1 Venting and Voiding

Waste fluids are disposed via **chimneys** (gases) and **outfalls** (liquids), tiered buildings that perform void recipes:

| Building | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| **Chimney** (gas void) | Speed 1x, no power | Speed 5x, no power | Speed 20x, 295 kW |
| **Outfall** (liquid void) | Speed 1x | Speed 5x | Speed 20x |

**Ventable gases**: air, nitrogen, hydrogen, oxygen, argon, helium, steam, CO2, CO, SO2, methane, ammonia, volcanic gas, deuterium, and compressed variants of all above.

**Ventable liquids**: seawater, freshwater, wastewater, brine, water, heavy water, caustic solution, calcium chloride solution, saline, methanol, HCl, amino acids, nucleotides, protocell, bacteria.

**NOT ventable (no void recipe exists):**
- **Chlorine** -- the most significant restriction
- Various other specialty fluids

### 3.2 The Chlorine Problem

Chlorine is produced as a major byproduct of brine/saline electrolysis, the same process that generates essential caustic solution (NaOH) and hydrogen:

```
Brine Electrolysis:    40 brine --> 42 H2 + 42 Cl2 + 3 NaOH
Saline Electrolysis:   52 saline --> 110 H2 + 45 O2 + 14 Cl2 + 1 NaOH
HCl Electrolysis:      240 HCl --> 120 H2 + 120 Cl2
```

Caustic solution is consumed everywhere (chemistry, biology, water treatment), so players **must** run electrolysis. But every batch produces chlorine that **cannot be vented**.

**Chlorine disposal pathways:**

The key insight is that chlorine cannot be voided directly, but can be converted through several chains into products that **can** be voided. Each pathway trades chlorine for other resources:

**Pathway 1: HCl + Mineral Dust --> Sludge (voidable)**

```
Cl2 + H2 --> HCl --> Hydrochloric Acid (+ water)
                         |
Gravel --> Mineral Dust -+--> [Ore Flotation] --> Sludge (VOIDABLE) + CO2
```

- 30 Cl2 + 30 H2 --> 60 HCl --> 40 hydrochloric acid
- 1 mineral dust + 6 acid --> 6 sludge + 5 CO2
- Mineral dust comes from gravel (6 gravel --> 5 dust), which is itself a smelting byproduct but can be made intentionally
- **Net**: consumes chlorine, hydrogen, and gravel; produces voidable sludge
- **Tech**: inorganic-chemistry-2

**Pathway 2: PVC Plastic (productive sink)**

```
25 ethylene + 25 Cl2 --> 1 plastic + 15 HCl
```

- Direct chlorine consumption, but recovers 15 HCl (net -10 Cl2 per plastic)
- Plastic is used extensively downstream (not voidable, but always in demand)
- PEX variant: 325 ethylene + 50 HCl + silicon + aluminum --> 45 plastic + 40 sludge (voidable)
- **Tech**: organic-chemistry-1 (early-mid game)

**Pathway 3: Calcium Chloride Solution (voidable)**

```
Route A: 1 crushed limestone + 25 hydrochloric acid --> 16 CaCl2 solution + 10 CO2
Route B: 3 lime + 50 Cl2 + 60 water --> 60 CaCl2 solution + 20 O2
```

- Calcium chloride solution **can be voided** (nullius-void-calcium-chloride-solution: 200 units, 2 seconds)
- Route B is direct: chlorine in, voidable liquid out. But wastes lime (from limestone, a non-starting-area resource).
- **Tech**: calcium-chloride-production

**Summary of chlorine disposal economics:**

| Pathway | Chlorine In | Voidable Output | Wastes |
|---|---|---|---|
| HCl + mineral dust | Cl2 via HCl | Sludge | Hydrogen, gravel/mineral dust |
| PVC plastic | 25 Cl2 direct | N/A (plastic consumed) | Ethylene |
| CaCl2 solution (route B) | 50 Cl2 direct | CaCl2 solution | Lime, water |

If chlorine backs up, electrolysis stops, caustic production stops, and the entire chemical chain grinds to a halt. Players must design factories with deliberate chlorine consumption pathways from early game onward.

### 3.3 Oxygen Mission Interaction

Venting gases directly affects the **oxygen mission objective** (terraforming goal):

| Gas Vented | Oxygen Equivalent | Effect |
|---|---|---|
| Oxygen | +1 per unit | Adds to atmospheric oxygen |
| Compressed oxygen | +4 per unit | Adds to atmospheric oxygen |
| Hydrogen | -0.5 per unit | **Subtracts** from oxygen |
| Compressed hydrogen | -2 per unit | **Subtracts** from oxygen |
| Methane | -2 per unit | **Subtracts** from oxygen |
| Compressed methane | -8 per unit | **Subtracts** from oxygen |
| Ammonia | -1 per unit | **Subtracts** from oxygen |
| Carbon monoxide | -0.5 per unit | **Subtracts** from oxygen |
| Deuterium | -0.5 per unit | **Subtracts** from oxygen |
| Volcanic gas | -0.2 per unit | **Subtracts** from oxygen |

This creates a tension: venting hydrogen or methane is easy waste disposal, but it **actively harms** terraforming progress. Players must choose between convenient waste disposal and mission advancement.

### 3.4 Cascading Byproduct Constraints

The byproduct system creates interconnected production constraints:

```
Seawater --> [Treatment] --> Freshwater + Saline + Brine
                                |              |
                          (ventable)     [Electrolysis]
                                          /    |    \
                                        H2    Cl2   NaOH (caustic)
                                        |      |        |
                                  (ventable, (NOT     (consumed
                                   but hurts  ventable) everywhere)
                                   O2 mission)
```

- **Need caustic?** Must electrolyze brine. Produces chlorine you must consume.
- **Need hydrogen?** Same electrolysis. Venting excess H2 hurts oxygen mission.
- **Chlorine backed up?** Electrolysis stops. Caustic stops. Chemistry stops.
- **Smelting produces CO2/SO2** -- ventable but affects atmosphere.
- **Wastewater** -- ventable via outfall, but is also feedstock for heavy water (tritium production).

The inability to vent chlorine is the linchpin constraint that forces holistic factory design rather than isolated production chains.

### 3.5 Biology as an Alternative Production Paradigm

Biology is not just endgame terraforming content -- it provides **superior alternative production routes** that bypass the chlorine economy entirely. Several key chemicals are **exclusively** produced through biological processes, and many others have biological alternatives that are simpler, cleaner, or higher-yielding.

#### Industrial Bootstrap (required before biology)

All key chemicals have industrial routes that **must** be established first. Biology cannot bootstrap itself:

| Product | Industrial Route | Tech | Bio Alternative |
|---|---|---|---|
| **Methanol** | 16 methane + 8 O2 --> 2 methanol | organic-chemistry-3 | Fermentation: sugar + water + bacteria --> 80 methanol |
| **Ammonia** | 8 compressed-H2 + 3 compressed-N2 --> 8 ammonia | nitrogen-chemistry-1 | Amino acid metabolism: amino acids + bacteria --> 75 ammonia |
| **Ethylene** | 60 methane + 40 O2 --> 16 ethylene + 6 water | organic-chemistry-1 | Fatty acid pyrolysis: 25 fatty acids --> 50 ethylene + 75 propene |
| **Propene** | 100 CO + 180 H2 --> 16 ethylene + 12 propene + 4 benzene | organic-chemistry-2 | (co-produced with ethylene above) |
| **Fatty acids** | 8 propene + 1 methanol + 4 O2 --> 1 fatty acid | nanotechnology | Organism processing (later) |

The bootstrap dependency is strictly one-way: **industrial --> biological**. You need industrial propene and methanol to synthesize the first fatty acids, which seed the biological production chains.

#### Why Biological Routes are Superior (once unlocked)

| Product | Industrial Route | Biological Route | Bio Advantage |
|---|---|---|---|
| **Methanol** | 16 methane + 8 O2 --> 2 methanol | Sugar fermentation --> 80 methanol | 40x more output per batch; uses renewable sugar |
| **Ethylene/Propene** | 60 methane + 40 O2 --> 16 ethylene | Fatty acid pyrolysis --> 50 ethylene + 75 propene | 3x ethylene yield + free propene + benzene |
| **Glycerol** | ECH + NaOH + HCl --> glycerol (chlor-alkali chain) | Sugar + saline + bacteria --> 60 glycerol | Bypasses entire chlorine economy |
| **Oxygen** | Air separation: 400 air --> 100 O2 + residual gas | Algae/grass/tree cultivation: up to 3500 O2 per batch | 10-35x more O2, no residual gas waste |
| **Plastic** | PVC: ethylene + **chlorine** --> plastic + HCl | Polypropylene: propene + ethylene --> plastic | Zero chlorine involvement |
| **Fertilizer** | Cellulose breakdown: 5 cellulose --> 6 fertilizer | Fish processing: 1 fish --> 16 fertilizer | 2.7x more efficient |
| **Ammonia** | Compressed H2 + N2 (Haber process, needs compression) | Amino acid metabolism --> 75 ammonia + 30 methane | Also produces useful methane |

#### The Industrial-to-Biological Transition

The game presents a deliberate **two-phase production design**:

```
PHASE 1 - INDUSTRIAL BOOTSTRAP (early-mid game):
  Seawater --> Brine --> Electrolysis --> H2 + Cl2 + NaOH
  Methane + O2 --> Ethylene, Methanol (low yields)
  CO + H2 --> Ethylene + Propene (syngas route)
  Compressed H2 + N2 --> Ammonia (Haber process)
  [Chlorine must be managed at every step]
  [Low yields, forced byproducts, circular dependencies]

BRIDGE - FATTY ACID SYNTHESIS (requires nanotechnology):
  Industrial propene + methanol + O2 --> Fatty acids
  [One-way bootstrap: industrial chemicals seed biological production]

PHASE 2 - BIOLOGICAL PRODUCTION (mid-late game):
  Fatty acids --> Ethylene + Propene (3x yield, no chlorine)
  Sugar fermentation --> Methanol (40x yield)
  Amino acid metabolism --> Ammonia + Methane (no compression needed)
  Organism growth --> Oxygen (10-35x yield)
  [Byproducts are CO2, wastewater, methane -- all ventable or useful]
  [Dramatically reduced chlorine pressure]
```

The transition is not instantaneous -- players must maintain industrial production while gradually building biological capacity. But once biological chains reach scale, they produce dramatically higher yields with cleaner byproducts, allowing players to **downsize** chlorine-heavy industrial infrastructure.

#### Wood as Construction Material

Once **woodworking** tech is unlocked (requires botany-2 + weaving-3 + inserter-capacity-5), wood can substitute for metals in key infrastructure, reducing pressure on iron/steel/aluminum production:

| Wood Recipe | Replaces | Key Savings |
|---|---|---|
| **Wooden chest** | 2 wood + iron rod + epoxy --> 2 chests | Less iron |
| **Wooden power pole 1** | 2 aluminum wire + 1 wood --> 2 poles | Less aluminum |
| **Wooden power pole 2** | Pole-1 + copper cable + 3 wood --> pole-2 | Less copper |
| **Wooden rail** | 2 steel beam + 4 wood + steel rod + gravel + epoxy --> 5 rails | Less steel |
| **Wooden wall** | Concrete + steel + insulation + 8 wood + epoxy --> 4 walls | Less concrete |
| **Wooden medium assembler** | 5 small assemblers + 4 wood --> 3 medium assemblers | Less electronics |
| **Wooden medium miner** | 3 small miners + 1 box wood --> 2 medium miners | Less steel |
| **Wood paneling** | Steel wire + gypsum + 4 wood + textile --> 3 insulation | Avoids chemical insulation route |

Wood recipes still require *some* metal (steel beams for rails, iron rods for chests), but significantly reduce overall metal consumption. Since trees are renewable (farming from water + air + fertilizer), this creates a sustainable construction supply chain that complements the biological chemical economy.

Wood processing: 3 trees --> 48 wood + 20 wood chips + 7 tree seeds + 15 sludge. Wood chips can be recycled back to wood via particle board (26 chips + epoxy --> 20 wood).

#### Biological Closed Loops

Biology creates self-sustaining cycles:

- **Sugar <--> Cellulose**: interconvertible, forming a renewable feedstock loop
- **Organism growth cycles**: algae/grass/trees produce oxygen + biomass; biomass processed into chemicals; chemicals feed further growth
- **Fish --> fertilizer --> grass/tree growth --> more organisms**: cascading biological production
- **Tree farming --> wood --> construction + wood chips --> particle board --> more wood**: renewable construction materials

---

## 4. Technology Progression

### 3.1 Technology Tiers

The tech tree contains **400+ technologies** (including checkpoints) across **7 tiers** with exponential cost scaling:

| Tier | Cost Range | Time | Pack Types | Key Unlocks |
|---|---|---|---|---|
| **1** | 1-5 count | 3-10s | 1 (geology) | Iron smelting, water filtration, electrolysis, masonry |
| **2** | 2-20 count | 6-12s | 1-2 (+ climatology, mechanical) | Automation, wind power, logistics, mining |
| **3** | 10-250 count | 15-30s | 2-4 (+ electrical) | Electrical engineering, empiricism, experimental chemistry |
| **4** | 80-250 count | 30-40s | 4-5 (+ chemical) | Nanotechnology, high-pressure chemistry, advanced metallurgy |
| **5** | 1,200-3,200 count | 40-50s | 5-6 (+ physics) | Nuclear power, rocket science, asteroid mining, AI |
| **6** | 12,000-25,000 count | 60s | 6-7 (+ astronomy) | Genetic archives, antimatter containment, rocket science 2 |
| **7** | 15,000-25,000+ count | 60s | 7+ (+ biology packs) | Ecology, evolution, wildlife management |

### 3.2 Critical Path Technologies

These are the **essential gate technologies** that must be researched to progress:

```
nullius-salvage-lab-wreckage     (game start -- mine the landing lab)
    |
nullius-geology-1                (unlocks geology pack)
    |
nullius-climatology-1            (unlocks climatology pack)
    |
nullius-mechanical-engineering-1 (unlocks mechanical pack)
    |
nullius-electrical-engineering   (unlocks electrical pack)
    |
nullius-experimental-chemistry   (unlocks chemical pack -- 250 count COST SPIKE)
    |
nullius-physics                  (unlocks physics pack)
    |
nullius-astronomy                (unlocks astronomy pack -- endgame gate)
    |
nullius-rocket-science-1/2/3     (space program)
    |
nullius-biology-1 ... ecology-6 ... evolution-7  (terraforming endgame)
```

### 3.3 Checkpoint System

**106 checkpoints** gate progression by requiring physical achievements before research can proceed. Examples:

| Checkpoint | Gates | Requirement |
|---|---|---|
| nullius-checkpoint-iron-ingot | iron-working-2 | Produce iron ingots |
| nullius-checkpoint-plastic | electromagnetism-1 | Produce plastic |
| nullius-checkpoint-wind-power | energy-storage-1 | Build wind turbine |
| nullius-checkpoint-lab | geology-2, computation | Build a lab |
| nullius-checkpoint-chemical-engineering | experimental-chemistry | Complete chemical engineering |
| nullius-checkpoint-enriched-uranium | antimatter-containment | Produce enriched uranium |
| nullius-checkpoint-oxygen-partial-1/2/3 | ecology techs | Reach oxygen milestones |

This prevents rushing research without building real infrastructure.

### 3.4 Technology Branches

The tree is essentially linear with required prerequisites but offers flexible ordering within tiers:

1. **Industrial Production**: automation, mass-production-1..7, minerals processing, flotation, metallurgy
2. **Energy Systems**: wind-power-1..3, solar-power-1..4, solar-thermal-1..3, nuclear-1..4, geothermal-1..3, battery-1..6
3. **Logistics & Transport**: logistics-1..4, freight-transportation-1..3, personal-transportation-1..5, inserter-capacity-1..7
4. **Robotics & Automation**: robotics-1..4, logistic/construction robots, robot-speed-1..5
5. **Chemistry & Materials**: electrolysis-1..4, air-separation-1..5, nitrogen/sulfur chemistry, aluminum/silicon/titanium production
6. **Advanced Research**: empiricism-1..6, computation, optimization-1..7, parallel-computing-1..4
7. **Biology & Evolution** (Tier 6-7 only): biology, botany, zoology, ecology-1..6, evolution-1..7

---

## 5. Science Pack System

### 4.1 Science Pack Types

**8 core packs** + **7 biology packs** = 15 total science pack types.

#### Core Science Packs (in unlock order)

| Pack | Unlock Tech | Early Recipe | Bulk Recipe |
|---|---|---|---|
| **Geology** | geology-1 | 4x bauxite + 4x sandstone + 4x iron ore (30s) | Crushed ores + mineral dust (8s) |
| **Climatology** | climatology-1 | 5000 air + 4000 seawater (60s) | 200 nitrogen + 100 wastewater + 5 volcanic gas (10s) |
| **Mechanical** | mechanical-engineering-1 | 1x motor-1 + 3x iron gear (15s) | 1x pump + 3x steel cable = **25 packs** (60s) |
| **Electrical** | electrical-engineering | 1x decider combinator + 1x lamp + 2x copper cable + 1x capacitor (12s) | 1x processor-2 + 1x sensor-2 + 1x battery-2 = **50 packs** (160s) |
| **Chemical** | experimental-chemistry | 3x glass + 5x concrete + 1x ammonia barrel + 2x NaOH + 20 H2SO4 + 4 lubricant (15s) | Barreled chemicals + filters + salts = **5 packs** (200s) |
| **Physics** | physics | Stirling engine + nanofabricator + underground belt-3 + lab-2 + combustion chamber-3 + substation-2 + drone launcher + 3x missiles = **25 packs** (900s!) | N/A |
| **Astronomy** | astronomy | (Late-game, requires rocket/space infrastructure) | N/A |

#### Biology Science Packs (Tier 6-7)

| Pack | Key Ingredients | Craft Time |
|---|---|---|
| **Biochemistry** | 6x chemical pack + 4x electrical pack + sugar + amino acids + fatty acids + nucleotides | 80s |
| **Microbiology** | Algae progenitor + 100x algae + bacteria fluid | 90s |
| **Botany** | Grass progenitor + 120x grass + cellulose | 120s |
| **Dendrology** | Tree progenitor + 80x trees + wood | 160s |
| **Nematology** | Worm progenitor + 150x worms + CO2 | 100s |
| **Ichthyology** | Fish progenitor + 120x fish + wastewater | 120s |
| **Zoology** | Arthropod progenitor + 80x arthropods + plastic | 200s |

### 4.2 Lab Tiers

| Lab | Research Speed | Power | Module Slots |
|---|---|---|---|
| **Lab 1** | 1.0x | 95 kW + 5 kW drain | 2 |
| **Lab 2** | 2.0x | 210 kW + 15 kW drain | 3 |
| **Lab 3** | 4.0x | 460 kW + 40 kW drain | 4 |

All labs accept: geology, climatology, mechanical, electrical, chemical, physics, and astronomy packs. Biology packs are consumed via separate mechanisms.

### 4.3 Production Rate Analysis

**Single-crafter output rates:**

| Pack | Early Recipe | Bulk Recipe |
|---|---|---|
| Geology | 2/min | 7.5/min |
| Climatology | 1/min | 6/min |
| Mechanical | 4/min | 25/min (bulk of 25) |
| Electrical | 5/min | 18.75/min (bulk of 50) |
| Chemical | 4/min | 1.5/min (bulk of 5) |
| Physics | N/A | **1.67/min** (bulk of 25 per 900s) |

**Critical bottleneck**: The Physics Pack at 900 seconds per batch (15 minutes!) requiring complex machinery as ingredients. Multiple huge assemblers needed for any meaningful throughput. The Chemical Pack bulk recipe is also slow at 200s for only 5 packs.

---

## 6. Energy Systems

### 5.1 Wind Power -- The Core Energy Source

Wind turbines are the **primary power source** throughout the game, but they are **highly intermittent**. This intermittency is the central energy design challenge.

#### Wind Turbine Tiers

| Tier | Peak Output | Tech Prerequisite |
|---|---|---|
| **Wind Turbine 1** | 1.5 MW | energy-distribution-1 |
| **Wind Turbine 2** | 4 MW | wind-power-2 |
| **Wind Turbine 3** | 12 MW | wind-power-3 |

Output is scaled by a configurable multiplier (default 1.0x, range 0.01-100x, hidden setting).

**Note**: Pump energy consumption has a separate **10x default multiplier** (`nullius-pump-energy-multiplier`, range 0.1-1000x). Pumps are intentionally expensive to encourage pipe upgrades over pump spam.

#### Wind Intermittency Model

Wind output varies continuously between **0% and 100%** of rated power. The wind speed is generated by combining **4 overlapping sine waves** of different periods, plus random noise and momentum:

| Component | Period | Weight | Purpose |
|---|---|---|---|
| Wave 1 (diurnal) | Day/night cycle | 1.2x | Ties wind to time of day |
| Wave 2 (medium) | ~126 seconds | 1.0x | Medium-frequency gusting |
| Wave 3 (long) | ~485 seconds | 1.0x | Slow wind pattern shifts |
| Wave 4 (very long) | ~1700 seconds | 0.75x | Large-scale weather patterns |
| Random noise | Per-tick | 0-8 range | Turbulence |
| Momentum | Persistent | 0.9985 decay | Smoothing / inertia |

The combined signal is normalized to a 0-1 factor with a **quadratic falloff** at low wind speeds (factor^2 * 0.9), meaning low wind produces disproportionately less power. Wind can and does drop to **zero output** for extended periods.

**Implication**: Wind turbines cannot be relied upon alone. Energy storage is mandatory from early game onward.

### 5.2 Energy Storage: The Hydrogen Loop

The primary energy storage mechanism is a **closed hydrogen cycle**. This is not a secondary system -- it is the core solution to wind intermittency from early game:

```
         EXCESS WIND POWER                    LOW WIND / DEMAND
              |                                      |
    [Electrolyzer]                          [Combustion Chamber]
     Water --> H2 + O2                    Compressed H2 + O2 --> Steam
              |                                      |
        [Compressor]                           [Turbine]
     H2 gas --> Compressed H2              Steam --> Electricity
              |                                      |
        [Tank Storage]  -----(stored)----->   [Tank Storage]
```

#### Step 1: Electrolysis (wind surplus --> hydrogen)

| Recipe | Input | Output |
|---|---|---|
| Water electrolysis | 60 water | 140 hydrogen + 70 oxygen |
| Pressure steam electrolysis | 1600 pressure steam | 160 compressed-H2 + 80 compressed-O2 |
| High-pressure electrolysis | 800 pressure steam | 250 compressed-H2 + 125 compressed-O2 |

#### Step 2: Compression (gas --> liquid for storage)

| Recipe | Input | Output | Ratio |
|---|---|---|---|
| Hydrogen compression | 960 hydrogen gas | 240 compressed hydrogen | 4:1 |

Compressed hydrogen: 4 kJ fuel value, storable indefinitely in tanks.

#### Step 3: Combustion (stored hydrogen --> steam)

| Recipe | Input | Output |
|---|---|---|
| H2 combustion (gas) | 200 H2 + 100 O2 | 440 steam |
| H2 combustion (compressed) | 65 compressed-H2 + 130 O2 | 600 steam |
| H2 combustion (both compressed) | 90 compressed-H2 + 45 compressed-O2 | 850 steam |

#### Step 4: Steam Turbine (steam --> electricity)

| Tier | Output | Effectivity | Max Temp |
|---|---|---|---|
| Turbine 1 | 1 MW | 0.90 | 1000 K |
| Turbine 2 | 2.5 MW | 0.95 | 1800 K |
| Turbine 3 | 6 MW | 1.00 | 2000 K |

**Round-trip efficiency**: The electrolysis-compression-combustion-turbine cycle has inherent conversion losses at each step, making energy storage a real engineering trade-off, not free buffering.

### 5.3 Surge vs Priority Machines

Electrolyzers and compressors come in two variants for **automatic load balancing**:

| Variant | Speed | Power Draw | Grid Priority | Behavior |
|---|---|---|---|---|
| **Surge** | 1.0x (full) | 995 kW (Tier 1) | `tertiary` (lowest) | Runs only when excess power available. Aggressively stores during wind gusts. |
| **Priority** | 0.5x (half) | 495 kW (Tier 1) | `secondary-input` (higher) | Runs continuously at reduced rate. Maintains steady storage accumulation. |

Surge machines have `render_no_power_icon = false` -- they are *expected* to be unpowered frequently. Players toggle between variants via shift-click.

**Design pattern**: Build surge electrolyzers/compressors alongside wind turbines. When wind gusts, surplus power automatically flows to tertiary-priority machines, converting excess into stored compressed hydrogen. When wind drops, combustion chambers burn stored hydrogen through turbines to maintain base power.

### 5.4 Other Power Sources

#### Solar (supplementary, consistent)

| Tier | Output | Notes |
|---|---|---|
| Solar Panel 1 | 100 kW | First power source; bootstraps to wind |
| Solar Panel 2 | 200 kW | Day/night cycle only |
| Solar Panel 3 | 500 kW | Late game |
| Solar Panel 4 | 800 kW | Endgame |

Solar is consistent (day/night only) but low output per tile. Useful as baseline supplement.

#### Solar Thermal (mid-late game)

Solar collectors heat fluids for turbine fuel, combining solar consistency with turbine output. Three tiers available.

#### Geothermal (location-dependent, steady)

| Tier | Notes |
|---|---|
| Geothermal Plant 1-3 | Passive heat from volcanic fumaroles. Steady output but requires map placement near vents. |

#### Nuclear Power (fusion before fission)

Nuclear power uses a single reactor type (50 MW consumption, 1500 K max temp, 0.5 neighbor bonus) that accepts any fuel in the `nullius-nuclear` category. The unique design: **fusion unlocks well before fission**, but is bottlenecked by tritium scarcity.

**Reactor fuel cells:**

| Cell | Fuel Value | Unlock Tech | Key Ingredient |
|---|---|---|---|
| **Fusion** | 3 GJ | nuclear-power-1 | 7 deuterium + 4 tritium |
| **Aneutronic** | 1 GJ | nuclear-power-2 | (helium-3 based) |
| **Breeder** | 500 MJ | nuclear-power-3 | 1 fusion cell + 3 lithium + 2 boron |
| **Fission** | 4 GJ | nuclear-power-4 | 5 uranium + 1 enriched uranium |

**The tritium bottleneck:**

Tritium is produced as a tiny byproduct of heavy water electrolysis:
- 30 heavy water --> 60 deuterium + 60 oxygen + **1 tritium**
- Heavy water itself is slow: 750 wastewater --> 1 heavy water

This makes early fusion power viable but **severely rate-limited**. Players can build the reactor but struggle to fuel it continuously.

**Lithium breeding breaks the bottleneck:**

Once nuclear-power-3 unlocks breeder cells (requires astronomy tech):
- **Craft**: 1 fusion cell + 3 lithium + 2 boron + deuterium + compressed helium --> 1 breeder cell
- **Recycle**: 3 spent breeder cells --> **16 tritium** + 2 lithium + helium + wastewater

This is the breakthrough -- recycling 3 breeder cells yields 16 tritium (enough for 4 fusion cells), and recovers lithium, making the cycle self-sustaining.

**Fission requires asteroid-mined uranium:**

Fission (nuclear-power-4) is gated behind:
1. Asteroid mining infrastructure (guide drones for uranium asteroids)
2. Uranium processing chain: ore --> crushed --> yellowcake (flotation) --> uranium metal --> enriched uranium
3. Enrichment **still requires tritium** (3 tritium per 7 uranium --> 2 enriched), so the tritium economy remains central even for fission

**Nuclear progression timeline:**
```
Isotope Separation
    |
    v
[checkpoint-tritium: produce 40 tritium]
    |
    v
Nuclear Power 1 (FUSION) -- usable but tritium-starved
    |
    v                           Lithium Production (brine processing)
    |                                |
    v                                v
Nuclear Power 2 (aneutronic)    Battery Storage 2
    |
    v
Nuclear Power 3 (BREEDER CELLS) -- lithium breeding solves tritium bottleneck
    |
    v
[checkpoint-uranium-ore: asteroid mining]
    |
    v
Uranium Processing
    |
    v
Nuclear Power 4 (FISSION) -- highest fuel density (4 GJ) but latest unlock
```

### 5.5 Grid Batteries (short-term buffering)

| Storage | Capacity | Input | Output |
|---|---|---|---|
| **Grid Battery 1** | 15 MJ | 200 kW | 500 kW |
| **Grid Battery 2** | 40 MJ | 400 kW | 800 kW |
| **Grid Battery 3** | 100 MJ | 800 kW | 1.5 MW |

Batteries smooth short demand spikes but cannot sustain extended wind lulls. The hydrogen loop is the real long-term storage solution.

### 5.6 Energy Progression Summary

| Phase | Primary Source | Storage Method | Challenge |
|---|---|---|---|
| **Bootstrap** | Solar panels (100 kW each) | None -- manual management | Getting enough panels to do anything |
| **Early** | Wind Turbine 1 (1.5 MW peak) | Electrolysis + compression + combustion | Building first hydrogen loop; intermittency hits hard |
| **Mid** | Wind Turbine 2 (4 MW peak) + geothermal | Scaled hydrogen storage + grid batteries | Balancing surge/priority machines; compressor power draw |
| **Late** | Wind Turbine 3 (12 MW peak) + solar thermal + early fusion | Large hydrogen tank farms + Tier 3 turbines | Scaling storage; fusion usable but tritium-starved |
| **Late-Endgame** | Fusion (breeder cycle) + wind | Breeder cells solve tritium bottleneck | Lithium breeding makes fusion self-sustaining |
| **Endgame** | Fusion + fission + wind + solar | Full nuclear + hydrogen infrastructure | Fission requires asteroid uranium; highest fuel density |

### 5.7 Power Bottlenecks

1. **Wind intermittency is the defining challenge** -- output ranges 0-100% with multi-layered unpredictability. Storage infrastructure is not optional.
2. **Hydrogen loop round-trip losses** -- each conversion step loses energy. Overbuilding wind capacity is cheaper than perfecting storage efficiency.
3. **Compressor power draw** -- surge compressors at ~1 MW are major consumers. Must be balanced against available wind surplus.
4. **Tritium starvation** -- fusion reactors unlock mid-game but heavy water electrolysis produces tritium at a trickle (1 per 30 heavy water, 750 wastewater per heavy water). Fusion is viable but fuel-starved until breeder cells.
5. **Lithium breeding as phase transition** -- breeder cell recycling (16 tritium per 3 spent cells) transforms nuclear from occasional supplement to reliable baseload. This is a hard gate behind astronomy tech.
6. **Geothermal location dependency** -- steady but requires map placement near fumaroles.
7. **Fission gated behind asteroids** -- highest energy fuel (4 GJ) requires uranium from asteroid mining, and enrichment still consumes tritium.

---

## 7. Resource & Production Chains

### 6.1 Raw Resources

| Resource | Type | Source | Availability |
|---|---|---|---|
| **Iron Ore** | Solid | Mined on Nauvis | Start |
| **Bauxite** | Solid | Mined on Nauvis (aluminum source) | Start |
| **Sandstone** | Solid | Mined on Nauvis (silicon source) | Start |
| **Limestone** | Solid | Mined on Nauvis (calcium source) | Not in starting area |
| **Graphite** | Solid | Mined on Nauvis (carbon source) | Start |
| **Copper Ore** | Solid | **Asteroid mining only** | Endgame |
| **Uranium Ore** | Solid | **Asteroid mining only** | Endgame |
| **Seawater** | Fluid | Seawater intake buildings | Start |
| **Air** | Fluid | Air separation | Start |
| **Volcanic Gas** | Fluid | Fumaroles (geothermal, 200 C) | Map-dependent |

### 6.2 Major Production Chains

#### Iron Chain

```
Iron Ore
  |--[Tier 1: Dry Smelting]--> 5 ore --> 2 iron ingot + 1 gravel (8s)
  |--[Tier 2: Crushing + Smelting]--> 6 ore --> 5 crushed --> 8 ingot (18s)
  |--[Tier 3: Vent Smelting]--> 8 iron oxide + limestone + graphite --> 10 ingot + CO2 (20s)
  |
  +--> Iron Plate (4 ingot --> 3 plate)
  +--> Iron Rod (4 ingot --> 5 rod)
  +--> Iron Gear (2 plate + 1 rod --> 2 gear)
  +--> Iron Wire (3 rod --> 4 wire)
```

#### Steel Chain

```
Iron Ingot
  |--[Tier 1: Machine Casting]--> 6 ingot + 60 O2 --> 2 steel ingot + CO2 (12s)
  |--[Tier 2: Wet Smelting]--> 13 ingot + 2 lime + 100 O2 --> 6 steel ingot (25s)
  |--[Tier 3: Advanced]--> 36 ingot + 5 calcium + 1 boron + 300 O2 --> 25 steel ingot (60s)
```

#### Aluminum Chain (early/mid-game wiring and electronics)

Aluminum replaces copper for the entire early and mid game. Copper ore is **removed from Nauvis** (`remove_autoplace("copper-ore")` in resource_override.lua) and only available via asteroid mining in endgame.

```
Bauxite (mined on Nauvis)
  --> Crushed Bauxite
    --> Alumina (aluminum oxide)
      --> Aluminum Ingot (electrolysis)
        +--> Aluminum Wire --> Insulated Wire (+ rubber) --> all early/mid electronics
        +--> Aluminum Sheet --> Capacitors, equipment
        +--> Aluminum Rod
```

**Key substitutions (no copper needed):**
- **Insulated wire** (nullius-insulated-wire-1): 3 aluminum wire + 2 rubber --> 4 copper-cable
- **Logic circuits**: 3 plastic + 4 aluminum wire + 2 polycrystalline silicon + 1 graphite --> 3 decider-combinator
- **Capacitors**: 2 aluminum sheet + 3 plastic + 1 alumina + 1 graphite --> 2 capacitor
- **Electrical science pack**: logic circuit + lamp + insulated wire + capacitor -- all aluminum-based

#### Copper Chain (endgame only -- requires asteroid mining)

Copper ore comes exclusively from asteroids, requiring `nullius-asteroid-mining-1` (which itself requires astronomy + mining-productivity-20). Once available:

```
Copper Ore (asteroid-mined)
  --> Crushed Copper Ore
    --> [Ore Flotation] 5 crushed + 25 H2SO4 + 15 solvent --> 40 copper solution + sludge (15s)
      --> [Electrolysis] 20 copper solution --> 3 copper ingot + wastewater (1s)
        +--> Copper Wire --> Insulated Wire 2 (superior to aluminum variant)
        +--> Copper Sheet
```

Copper unlocks `nullius-insulated-wire-2` (via electronics-4), a direct upgrade over the aluminum-based version. Late-game high-tech equipment benefits from copper's superior conductivity.

#### Water/Fluid Chain

```
Seawater --> [Water Treatment] --> Freshwater + Saline + Brine
Brine --> [Chlor-Alkali] --> Caustic Solution + Chlorine + Hydrogen
Air --> [Air Separation] --> Oxygen + Nitrogen + Argon + Helium + Trace Gas
Freshwater + Heat --> Steam / Pressure Steam
```

#### Chemical Chain

```
Sulfur + O2 + Water --> Sulfuric Acid
Chlorine + Hydrogen --> Hydrochloric Acid
Brine + Electricity --> Caustic Solution + Cl2 + H2
Limestone + HCl --> Calcium Chloride + CO2
Hydrocarbons (methane, ethylene, propene, benzene) --> Plastics, Lubricant, Rubber, Epoxy
```

### 6.3 Smelting Progression

| Method | Inputs | Yield | Building |
|---|---|---|---|
| **Dry Smelting** | Ore only | Low | Small Furnace |
| **Vent Smelting** | Ore + limestone + graphite | Medium-high (+ CO2 byproduct) | Vent |
| **Wet Smelting** | Ingot + lime + O2 | High | Medium/Large Furnace |
| **Machine Casting** | Ingot + precision inputs | Shaped products | Assembler-style |
| **Ore Flotation** | Crushed ore + acid + solvent | Solution (fluid) | Hydro Plant |
| **Electrolysis** | Metal solution | Pure ingot (fast, 1s) | Electrolysis Cell |

### 6.4 Intermediate Product Hierarchy

```
Tier 1 (Raw --> Product):     Crushed ore, iron oxide, iron/copper/steel ingot, lime, gravel
Tier 2 (Product --> Component): Plates, rods, sheets, gears, aluminum wire, glass, ceramics
Tier 3 (Component --> Assembly): Motors, insulated wire (aluminum+rubber), optical cable, bearings
Tier 4 (Assembly --> Machine):  Circuits, processors, heat pipes, valves, complete machines
```

### 6.5 Boxing / Unboxing System

Boxing is a **core production mechanic** -- not just convenience. It compresses multiple items into a single "box" for belt transport, inventory management, and crucially, is **mandatory for large-assembler production**.

#### Box Ratios

| Base Item Stack Size | Items per Box | Box Stack Size |
|---|---|---|
| <= 300 | 5 | `max(1, floor(2 * stack / 5))` |
| > 300 | 10 | `max(1, floor(2 * stack / 10))` |

150+ items have boxing/unboxing recipes, covering raw materials, intermediates, components, science packs, and finished buildings.

#### Boxing Machines

| Machine | Power | Speed | Role |
|---|---|---|---|
| **Boxer** (dedicated) | 395 kW | 4x | Fast, compact boxing/unboxing unit |
| **Small Assembler** | varies | 1x | Can also box via "packaging" category |

Boxing: 20-40 items --> 4 boxes (1 second). Unboxing: 1 box --> 5-10 items (0.2 seconds).

Productivity modules **cannot** affect boxing recipes (`no_productivity = true`). Boxing is hidden from production statistics.

#### Why Boxing Exists: The Assembler Hierarchy

This is the key design insight. Assemblers are **tiered by recipe category**, and large/huge assemblers **only accept boxed recipes**:

```
Small Assembler:   tiny/small/medium-crafting + packaging
                   --> Individual items, can box/unbox

Medium Assembler:  small/medium/large-crafting + fluid recipes
                   --> Direct recipes, NO packaging

Large Assembler:   medium/large/huge-crafting + large/huge-assembly
                   --> ONLY boxed recipes (large-assembly category)

Huge Assembler:    huge-crafting + huge-assembly
                   --> ONLY boxed recipes at maximum scale
```

**Large assemblers cannot craft individual items.** They require boxed inputs and produce boxed outputs. This means scaling production to large assemblers forces the player to build boxing infrastructure -- dedicated boxers feeding boxed intermediates into large assembler lines.

#### Example: Boxed vs Unboxed Production

**Inserter (unboxed, small assembler):**
- 1 motor-1 + 2 iron gear + 3 iron rod --> 4 inserters (8s)

**Inserter (boxed, large assembler):**
- 1 box-motor-1 + 1 box-steel-gear + 2 box-steel-rod --> 5 box-inserter-1 (25s)

The boxed recipe produces more per batch but requires all inputs pre-boxed.

#### Gameplay Impact

1. **Belt throughput**: 5-10x compression ratio. One belt lane of boxes carries 5-10x the material.
2. **UPS optimization**: Fewer entities on belts = fewer engine calculations at mega-factory scale.
3. **Forced progression**: Large assemblers are faster and have more module slots, but require boxing infrastructure investment. This creates a natural mid-to-late game transition.
4. **Science pack scaling**: All science packs have boxed recipes in `large-assembly`. Mega-scale research requires boxing the entire science supply chain.

### 6.6 Throughput Bottlenecks

| Stage | Bottleneck | Reason |
|---|---|---|
| **Mining** | Least constrained | Infinite deposits, multiple miner tiers |
| **Crushing** | Moderate | 5-20s per batch, but parallelizable |
| **Smelting** | Major early bottleneck | 8-60s per batch, limited by furnace count |
| **Ore Flotation** | Fluid throughput | Requires acid + solvent supply chains |
| **Electrolysis** | Power-hungry | Fast (1s) but consumes electricity directly |
| **Chemical processing** | Multi-step chains | 3-15s per step, multiple intermediates needed |
| **Boxing transition** | Infrastructure investment | Switching to large assemblers requires boxing every input chain |
| **Physics Pack production** | Ultimate bottleneck | 900s per batch of 25, requires complex machinery inputs |

---

## 8. Gameplay Mechanics

### 7.1 Mission Objectives (Win Conditions)

All **13 objectives** must reach 100% completion for victory:

| Objective | Target | Method |
|---|---|---|
| **Probe Launch** | 10 probes | Launch in rockets |
| **Oxygen Level** | 100% (125 saturation) | Vent O2, grow plants (reducing gases subtract) |
| **Algae Seeding** | 1,800 algae | Algaculture drones in water |
| **Grass Seeding** | 12,000,000 grass | Horticulture drones on coastal land |
| **Tree Seeding** | 32,000 trees | Arboriculture drones near worms |
| **Worm Release** | 750 worms | Release near grass/trees (needs 30%+ O2) |
| **Fish Release** | 320 fish | Release near algae (needs 60%+ O2) |
| **Arthropod Release** | 60 arthropods | Release on land near trees/fish (needs 80%+ O2) |
| **Terraforming** | 2,500,000 score | Reshape alien terrain via drones |
| **Copper Mining** | 20 guide drones | Asteroid mining |
| **Uranium Mining** | 12 guide drones | Asteroid mining |
| **Coal Sequestration** | 3,000,000 coal | Sequestration drones |
| **Petroleum Sequestration** | 12,000,000 petroleum | Sequestration drones |

**Victory message**: "Nauvis has been successfully terraformed!"
Players can continue playing after victory with infinite research tracks.

### 7.2 Achievements

| Achievement | Condition |
|---|---|
| **Easy Breezy** | Build a wind turbine within 45 minutes |
| **Accelerated Timeline** | Complete all objectives within 6 game days |
| **Lazier Bastard** | Complete without manual crafting |
| **Mission Complete** | Complete all 13 objectives |
| **Atmospheric Modification** | Reach oxygen milestones (4 variations) |

### 7.3 Unique Mechanics

**Consciousness Transfer**: Switch between android bodies using Upload Mind / Previous Body / Next Body controls. Multiple bodies can be active simultaneously with independent equipment grids and portable power. Each body gets a persistent name and map tag for tracking.

**Mecha Suits**: Spider-vehicle chassis with equipment grids. Mountable generators, solar panels, drone launchers (tier 1-2), guns (tier 1-2), and missile launchers. Autonomous power via portable reactors burning nuclear fuel cells.

**Terraforming Drones**: 6 terrain color variants (grey, tan, brown, red, beige, volcanic) that convert alien biomes to standard terrain. Also **9 paving drone colors** (grey, white, red, blue, yellow, green, purple, brown, black, hazard) for creating walkable paths. Drones are fired as artillery ammunition via remote capsule targeting.

**Multiplayer Alignment**: Full faction system, not just optional cooperation. Each player gets their own force. Satellite/pod rocket launch triggers "concordance" -- the launching faction absorbs all others (technologies shared, entities transferred, charts merged). Inactive factions auto-absorbed after 30 days. Requires alignment startup setting AND multiplayer.

**Broken Equipment Start**: In normal (non-alignment) mode, the game spawns **broken versions** of key buildings (3 air filters, 3 hydro plants, 1 electrolyzer, 7 chemical plants, 2 foundries, 3 assemblers, 30 pylons, 18 solar panels, 12 grid batteries, 2 sensor nodes). Players must craft the corresponding broken item to clear the broken status before the normal recipe becomes available. This gates early progression through physical scavenging.

**Valve System**: Five distinct valve types for fluid management, essential for byproduct control:
- **Relief valve**: Spills excess if tank >75% full (prevents backups)
- **Top-up valve**: Fills tank only if <50% (prioritizes byproducts)
- **One-way valve**: Prevents backflow; extends pipelines but reduces throughput
- **Priority/Auxiliary valve**: Supplies secondary destination only if primary >25% full
- **Configurable pump**: Custom thresholds via circuit conditions

**Beacon Interference**: Large beacons suppress small beacon effects within their range (-15% to -45% per field). Large beacons transmit 1-2 module effects up to 12 tiles but are mutually exclusive (cannot place near other large beacons). Small beacons transmit 1-3 effects at 15-50% strength. This creates non-trivial module layout optimization.

**Levitation/Telekinesis Fields**: Equipment grid items. Levitation field allows walking over conveyor belts without being moved. Telekinesis fields (3 tiers) extend reach and improve crafting/mining capabilities.

### 7.4 Module System

| Module Type | Effect | Tiers |
|---|---|---|
| **Efficiency** | -50% to -120% consumption | 1-3 |
| **Haste** (unique to Nullius) | +20-50% speed, +25-80% consumption | 0-3 |
| **Speed** | +20-50% speed, +0-10% consumption | 1-4 |
| **Productivity** | +3-10% output, -5-40% speed, +10-100% consumption | 1-3 |

### 7.5 Equipment/Player Progression

**26 upgrade types** across these categories:

- **Crafting**: Speed, cost, multiplier, productivity bonuses
- **Mining**: Speed and deconstruction
- **Reach**: Hand mining/building distance
- **Cargo**: Inventory slots with multipliers
- **Armor**: Health bonus
- **Speed**: Movement speed
- **Coprocessors**: Speed (+8-20%), Efficiency (-20-40% cost), Productivity (+6-10% output)

**Chassis progression**: 6 tiers from light frame to power armor mk2 equivalent, with 10-50 inventory slots and escalating resistances.

### 7.6 Logistics

- **Belts**: 4 tiers (standard, fast, express, ultimate). Underground max distances: 7, 11, 15, unlimited.
- **Inserters**: Multiple tiers with built-in filtering (except tier 1). Long-reach variants replace vanilla filter inserters.
- **Logistic chests** (small and large variants each):
  - **Demand**: Pull specific items from logistic network
  - **Buffer**: Cache and redistribute items
  - **Dispatch**: Push contents into network storage
- **Trains**: Multi-tier locomotives, cargo/fluid wagons, 150+ rail checkpoint requirement.
- **Robots**: Logistic robots with 800kJ/3MJ/8MJ energy tiers. Construction robots for automated building.
- **Pipes**: 4 tiers with increasing pipeline extent (64, 144, 320, 672 tiles). Upgraded pipes reduce need for pumps.

---

## 9. Mod Compatibility & Architecture

### 8.1 Dependency Summary

- **Required** (6): base 2.0.73+, alien-biomes, angels graphics (3 mods), bob-logistics, configurable-valves
- **Incompatible** (8): space-age, quality, aai-industry, angels bioprocessing/ores/smelting, bobores, stack-size-tooltip
- **Optional** (40+): Factorissimo2, jetpack, miniloader, elevated-rails, cargo-ships, cranes, warehousing, and many more

### 8.2 Loading Architecture

```
data.lua
  +--> legacyAngels.lua       (Angel's mod icon utilities)
  +--> legacyValves.lua        (1.1 --> 2.0 valve migration)
  +--> Core prototypes         (items, entities, recipes, tech)

data-updates.lua
  +--> resource_override.lua   (resource autoplace)
  +--> override.lua            (vanilla system replacements)
  +--> override_mod.lua        (third-party mod integrations)

data-final-fixes.lua
  +--> override_final.lua      (final vanilla tweaks)
  +--> override_mod_final.lua  (final mod tweaks)
  +--> override_final_only.lua (phase-exclusive fixes)
  +--> legacyMirror.lua        (building orientation migration)
  +--> clutterpedia.lua        (factoriopedia recipe renames)
```

### 8.3 Mod Integration Pattern

Each optional mod uses a conditional block in `mods.lua` (4,633 lines):

```lua
if mods["ModName"] then
  -- Rebalance mod's techs for Nullius progression
  -- Add Nullius prerequisites
  -- Adjust recipe costs
  -- Integrate icons and localization
end
```

40+ mods individually integrated with graceful degradation when absent.

---

## 10. Progression Timeline Summary

### Phase 1: Bootstrap (Hours 0-10)

- Mine starting lab wreckage, unlock geology pack.
- Build solar panel farm (100 kW each, need many).
- Establish iron smelting (dry, 5 ore --> 2 ingot).
- Unlock climatology and mechanical packs.
- Build first wind turbine (1.5 MW -- game changer).
- Establish water processing (seawater --> freshwater).

### Phase 2: Industrial Foundation (Hours 10-30)

- Unlock electrical pack through electronics chain (aluminum-based, no copper needed).
- Build Tier 2 wind turbines (4 MW each).
- Establish aluminum production for wiring and electronics (bauxite --> alumina --> aluminum).
- Build chemical processing (acids, caustic solution).
- Research experimental chemistry (250 count -- major cost spike).
- Unlock chemical pack.

### Phase 3: Advanced Industry (Hours 30-80)

- Tier 3 machines across all categories.
- Wind Turbine 3 (12 MW) as primary power.
- Establish advanced metallurgy (aluminum, silicon, titanium).
- Build physics pack production (900s per batch!).
- Unlock fusion reactors (nuclear-power-1) -- powerful but tritium-starved.
- Trickle tritium from heavy water electrolysis (1 per 30 heavy water).
- Begin rocket science program.
- Start asteroid mining operations.

### Phase 4: Nuclear & Biology (Hours 80-200+)

- Unlock breeder cells (nuclear-power-3, requires astronomy) -- lithium breeding solves tritium bottleneck.
- Breeder recycling: 3 spent cells --> 16 tritium. Fusion becomes self-sustaining.
- Asteroid-mine uranium, unlock fission (nuclear-power-4) for 4 GJ fuel cells.
- Unlock all 7 biology packs through genetic research.
- Seed algae, grass, trees across the planet.
- Raise atmospheric oxygen through venting and plant growth.
- Release worms (30%+ O2), fish (60%+ O2), arthropods (80%+ O2).
- Complete terraforming score (2.5M from drone terrain reshaping).
- Launch sequestration programs (coal and petroleum deposits).
- Research ecology and evolution trees (Tier 7, 25,000 count techs).

### Phase 5: Victory & Beyond

- All 13 mission objectives at 100%.
- Nauvis successfully terraformed.
- Infinite research tracks for continued play.
- Successor android construction for galactic expansion.

---

## 11. Key Metrics & Quick Reference

### Cost Scaling Curve

```
Tier 1-2:   1-5 count,     1 pack type    ~3-10 seconds
Tier 2-3:   2-20 count,    1-2 pack types ~6-20 seconds
Tier 3-4:   10-250 count,  2-4 pack types ~20-30 seconds     <-- experimental-chemistry spike
Tier 4-5:   80-3200 count, 4-5 pack types ~30-50 seconds
Tier 5-6:   1200-25000,    5-6 pack types ~50-60 seconds
Tier 6-7:   12000-25000+,  6-7+ pack types ~60 seconds        <-- antimatter: 25,000 count (peak)
```

### Power Budget by Phase

```
Bootstrap:     200-500 kW   (solar panels)
Early:         1-5 MW       (wind turbines + H2 storage loop)
Mid:           5-15 MW      (tier 2-3 wind + geothermal + surge/priority balancing)
Late:          15-50 MW     (tier 3 wind farms + solar thermal + tritium-starved fusion)
Late-Endgame:  50-100 MW    (breeder-cycle fusion as reliable baseload + wind)
Endgame:       100-200+ MW  (fission from asteroid uranium + fusion + wind/solar)
```

### Production Chain Complexity

```
Geology Pack:     1 step   (mine --> craft)
Climatology Pack: 1 step   (process fluids)
Mechanical Pack:  3 steps  (ore --> ingot --> gear/motor --> pack)
Electrical Pack:  5+ steps (bauxite --> alumina --> aluminum --> wire --> insulated wire --> circuit --> pack)
Chemical Pack:    8+ steps (ore + fluid processing --> multiple chemicals --> pack)
Physics Pack:     15+ steps (multiple complete machines as ingredients!)
Biology Packs:    20+ steps (full genetic engineering + organism breeding chains)
```

---

*This document represents a snapshot of Nullius v2.0.2 as implemented in the codebase. Values are extracted from Lua prototype definitions and may be affected by runtime settings, module effects, and mod interactions.*
