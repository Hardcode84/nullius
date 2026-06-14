# Nullius SA: Vulcanus -- Planet Design Document

> **Status**: Partially implemented (updated 2026-06-14)
> **Role**: Heavy industry. Abundant metals from lava. No water, no organics.
> **Unlock**: Volcanic Probe Signal Recovery (Tier 3, after signal acquisition + metallurgy-2)
> **Theme**: Time-gated production (spoilage-as-cooldown), silicon-only insulation, late-game synthetic demolishers.

---

## 1. Core Constraints

| Constraint | Details |
|---|---|
| **CO2 atmosphere** | Dense carbon dioxide atmosphere. Separation yields CO2 + trace N2 + SO2. Oxygen obtained via SO2 catalytic decomposition (rutile catalyst). |
| **Almost no water** | No oceans, no rain. Tiny amounts from Deacon process (HCl + O2 --> Cl2 + H2O). |
| **No organic chemistry** | Too hot for organics. No plastic, rubber, methanol, ethylene. |
| **No biology** | No organisms can survive. Purely inorganic world. |
| **Silicon insulation only** | Abundant silica from volcanic rock replaces organic insulation. |
| **Abundant metals** | Iron, aluminum, calcite from lava. Cheap but need time to cool. |
| **Abundant geothermal** | Constant heat from fumaroles. No intermittency problem. |
| **No wind/solar** | Wind: dense corrosive atmosphere (CO2 + SO2 + HCl traces) destroys exposed mechanical parts. Solar: surface temperature exceeds panel operating range -- semiconductor junctions degrade rapidly above 150C, Vulcanus ambient is 200C. |

---

## 2. Resources

### 2.1 Lava (Primary Resource)

Lava is Vulcanus's equivalent of Nauvis's ores. Extracted by free lava intakes from lava pools (infinite, like water on Nauvis).

**Lava composition** (fractional distillation/separation):

| Recipe | Input | Output | Time | Category |
|---|---|---|---|---|
| Lava iron separation | 100 lava | 4 molten-iron-bloom + 30 compressed-volcanic-gas + 10 stone | 5s | water-treatment (hydro-plant) |
| Lava aluminum separation | 100 lava | 3 molten-aluminum-bloom + 25 compressed-volcanic-gas + 8 stone | 5s | water-treatment (hydro-plant) |
| Lava calcite separation | 80 lava | 6 crushed-limestone + 20 compressed-volcanic-gas | 4s | water-treatment (hydro-plant) |
| Lava silica extraction | 60 lava | 8 silica + 5 stone + 15 compressed-volcanic-gas + 10 SO2 | 3s | water-treatment (hydro-plant) |
| **Lava gas extraction** | 50 lava | 60 compressed-volcanic-gas + 3 stone | 2s | water-treatment (hydro-plant) |

Metal separation recipes are **net-negative on gas** (consume more than they produce). The dedicated gas extraction recipe is the primary gas source. Player must balance hydro-plants between metal production and gas production.

### 2.2 Molten Metals (Spoilage Cooldown)

Molten blooms are the key mechanic. They are items with `spoil_ticks` that "cool" into usable ingots:

| Item | spoil_ticks | spoil_result | Approx Time | Notes |
|---|---|---|---|---|
| Molten Iron Bloom | 1800 (30s) | nullius-iron-ingot | 30 seconds | Cools directly into usable ingot. |
| Molten Aluminum Bloom | 2400 (40s) | **nullius-alumina** | 40 seconds | Oxidizes on cooling. Must reduce alumina to ingot via dry-smelting (9 alumina + 5 graphite --> 3 ingot). Extra step makes aluminum harder than iron. |
| Molten Titanium Bloom | 3600 (60s) | nullius-titanium-ingot | 60 seconds | **NOT YET IMPLEMENTED.** Only from deep deposits (demolishers). |

**Water quenching** (requires imported water, late tech):

| Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Quench iron | 1 molten-iron-bloom + 10 water | 1 iron-ingot + 8 steam | 1s | Instant, but water is precious cargo. |
| Quench aluminum | 1 molten-aluminum-bloom + 15 water | 1 aluminum-ingot + 12 steam | 1s | More water needed. |
| Quench titanium | 1 molten-titanium-bloom + 25 water | 1 titanium-ingot + 20 steam | 2s | Expensive water cost. |

**Design**: Early Vulcanus runs entirely on passive cooldown -- belts act as cooling conveyors. Factory layout is determined by belt length needed for items to cool before reaching the next processing step. Water quenching is a late-game luxury that dramatically increases throughput.

### 2.3 Compressed Volcanic Gas

Byproduct of all lava processing. Abundant. Pre-compressed by underground pressure.

Primary use: fuel for all gas-powered machines (see section 4).

### 2.4 HCl Geysers (Fixed Map Feature)

HCl does NOT come from lava processing. It comes from **dedicated volcanic geysers** -- fixed positions on the map (like SA's chemical vents or Nauvis fumaroles).

```
HCl Geyser (fixed map position, infinite, finite throughput)
    |
    v
[Geyser Pump] --> Raw HCl gas
                    |
              [Thermal HCl Cracking] (heat-powered, no electricity!)
                /         \
              H2           Cl2
              |             |
        (precious:     (feeds Kroll,
         water synth,   calcium chloride,
         graphite       general chemistry)
         production)
```

**Two-phase HCl processing:**

**Bootstrap (thermal cracking, low-temp):**
- With no electricity on Vulcanus, HCl electrolysis is not an early option.
- First H2/Cl2 comes from low-temp HCl thermal cracking as soon as the factory
  generates enough waste heat to drive a radiator (see 2.4).
- Slow but functional -- enough to get first graphite, first drops of water
- (If the player later imports/builds Stirling engines for niche electronics,
  electrolysis becomes available, but it is never the bootstrap path.)

**Bulk production (thermal cracking via overheated radiators):**
- Once the factory is running and generating waste heat, radiators are already at high temperature
- Instead of dumping heat to void, **route HCl through hot radiators** for thermal cracking
- Thermal HCl decomposition at 600-800C (no catalyst needed)

| Recipe | Input | Output | Category | Notes |
|---|---|---|---|---|
| HCl thermal cracking | 60 HCl (through hot radiator) | 30 H2 + 30 Cl2 | high-temp-radiator | Radiator must be above min working temperature (450C). |

**The radiator dual-purpose trick**: Radiators already exist to prevent factory overheating (section 4.5). They absorb waste heat from machines via heat pipes. Now they have a SECOND function: if you pipe HCl through a hot radiator, it thermally cracks the HCl while simultaneously cooling the radiator. The waste heat does useful chemistry.

```
[Factory machines] --heat pipe--> [Hot Radiator] <--HCl pipe-- [Geyser]
                                       |
                                   H2 + Cl2 out
                                   (and radiator is cooled!)
```

**This creates a beautiful feedback loop:**
- More factory activity = more waste heat = hotter radiators
- Hotter radiators = faster HCl cracking = more H2 + Cl2
- More H2 = more graphite + water production
- More Cl2 = more titanium production
- More production = more factory activity = more waste heat...

The "overheating problem" from section 4.5 becomes a **resource**. A factory that runs hot isn't just a management challenge -- it's a chemistry accelerator. Players who push their factories to the thermal limit get rewarded with faster HCl processing.

**Two-tier radiator system** (assembling-machines with HeatEnergySource and fluid boxes):

Radiators are the heat-powered chemistry buildings. They consume waste heat from the heat pipe network to drive fluid-input thermal reactions. Two tiers with different temperature thresholds:

| Tier | min_working_temp | Heat Pipe Required | Crafting Categories |
|---|---|---|---|
| **Low-temp radiator** | 200C | Tier 1 (max 250C) | `nullius-low-temp-radiator` |
| **High-temp radiator** | 450C | Tier 2 (max 500C) | `nullius-low-temp-radiator` + `nullius-high-temp-radiator` |

High-temp radiator can craft all low-temp recipes too (it's hotter).

**Low-temp recipes** (200C + 200C ambient = 400C effective, easy):

| Recipe | Input | Output | Notes |
|---|---|---|---|
| Deacon process | 60 HCl + 15 O2 | 30 Cl2 + 30 H2O | Water source (precious) |
| SO2 catalytic decomposition | 40 SO2 + 1 rutile (catalyst) | 40 O2 + 1 rutile | Only O2 source on Vulcanus |

**High-temp recipes** (200C + 450C ambient = 650C effective, serious heat investment):

| Recipe | Input | Output | Notes |
|---|---|---|---|
| HCl thermal cracking | 60 HCl | 30 H2 + 30 Cl2 | Bulk H2 production |
| Carbochlorination | 2 alumina + 30 Cl2 + 3 graphite | 4 AlCl3 + 30 CO | Chlorine sink |
| H2S thermal cracking (FUTURE) | H2S | H2 + S | From FeS shuttle |

**Design distinction**: Thermal furnaces (HeatEnergySource) handle solid-to-solid smelting. Radiators handle fluid-input thermal chemistry. Clean separation -- furnaces eat heat to smelt metal, radiators eat heat to crack molecules.

Player picks the recipe in the radiator like any assembling machine. No Ctrl+R toggle needed.

**Radiator crafting recipes:**

| Building | Input | Notes |
|---|---|---|
| Low-temp radiator | 8 iron-plate + 4 silica + 4 pipe | Early game. Place adjacent to machines. |
| High-temp radiator | 1 low-temp-radiator + 8 aluminum-sheet + 8 silica + 1 heat-pipe-1 + 4 pipe-2 | Standard tiered upgrade pattern. |

**Progression:**
- Early factory: Low-temp radiators for Deacon (water) and SO2 decomposition (oxygen). Place anywhere near machines.
- Growing factory: Upgrade to high-temp radiators for HCl cracking (hydrogen) and carbochlorination. Must place adjacent to busy machines (heat interfaces cap at 500C, threshold is 450C -- tight without tier 2 heat pipes).
- Large factory with tier 2 heat pipes: High-temp radiators can be placed remotely, heat piped from distant machine clusters. Layout freedom.

**Implementation**: Two entity prototypes with `fast_replaceable_group` for upgrade path. Both are assembling-machines with HeatEnergySource and 2-3 fluid connections. No toggle script needed -- standard recipe selection UI.

**Why this matters**: The entire Vulcanus chemistry chain now runs on waste heat from production. Electricity is only needed for the initial bootstrap (probe's Stirling engine) and niche electronics. Once the thermal factory is established, chemistry is powered by the factory's own thermal exhaust.

**Why geysers, not lava byproduct:**
- Separates metal production (lava) from chemistry (HCl). Two independent supply chains, both must be invested in.
- Map layout creates spatial tension: lava pools and HCl geysers may not be near each other. Base design must span both.
- Scaling metals doesn't auto-scale chemistry. Must deliberately build geyser infrastructure.
- Finite geyser count per map creates natural chemistry throughput cap. More geysers = further from base.
- Parallels other planet fixed resources: Fulgora fountains, Aquilo ocean dredging sites.

**Geyser properties:**
- Fixed positions, generated at map creation
- Infinite fluid, limited throughput per geyser (~100-200 HCl/s?)
- Higher density further from starting area (incentivizes expansion)
- Each geyser needs a gas-powered pump + gas pipe connection to base

### 2.5 Volcanic Rocks (IMPLEMENTED)

Mining volcanic rocks provides early-game materials without lava processing:

| Rock | Stone | Graphite | Rutile |
|---|---|---|---|
| **Huge volcanic rock** | 10-25 | 3-8 | 1-3 |
| **Big volcanic rock** | 5-15 | 2-5 | 0-2 (50% chance) |

Graphite from rocks gives early carbon before atmospheric processing is set up. Rutile from rocks is the only pre-demolisher titanium source -- scarce, finite, used as catalyst in SO2 decomposition.

### 2.6 Deep Deposits (Demolisher-Gated, Late Game -- NOT YET IMPLEMENTED)

Surface lava provides iron, aluminum, calcite, silica. **Titanium ore (rutile)** bulk deposits are only found deep beneath the volcanic crust, inaccessible to normal mining.

Requires synthetic demolishers (Phase 1.7 in implementation plan) to expose.

---

## 3. Production Chains

### 3.1 Iron (Vulcanus route)

```
Lava --> [Lava Iron Separation] --> Molten Iron Bloom
                                        |
                    [Passive cooldown: 30s on belt/in chest]
                                        |
                                    Iron Ingot
                                        |
                        +--- Iron Plate (existing recipe)
                        +--- Iron Rod (existing recipe)
                        +--- Iron Gear (existing recipe)
```

**Comparison with Nauvis**:
- Nauvis: Mine iron ore --> crush --> smelt (8-20s active processing)
- Vulcanus: Pump lava --> separate (5s) --> wait 30s cooldown --> ingot
- Vulcanus iron is "cheaper" in active processing but **time-gated** by cooldown. Throughput is belt-length-limited, not machine-limited.

### 3.2 Aluminum (Vulcanus route)

```
Lava --> [Lava Aluminum Separation] --> Molten Aluminum Bloom
                                            |
                        [Passive cooldown: 40s on belt/in chest]
                                            |
                                        Alumina (oxidizes on cooling)
                                            |
                        [Dry Smelting: 9 alumina + 5 graphite --> 3 ingot]
                                            |
                                      Aluminum Ingot
                                            |
                            +--- Aluminum Wire
                            +--- Aluminum Sheet
                            +--- Silicon-Insulated Wire (Vulcanus variant)
```

### 3.3 Alternative Recipes (IMPLEMENTED)

Vulcanus has no organics (plastic, rubber, methanol) and almost no water. These alt recipes replace organic/wet ingredients with locally available materials. All are Vulcanus-only (`surface_conditions: nullius-ambient-temperature >= 100`).

**Base materials:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Silicon insulation | 3 silica + 1 aluminum-sheet | 2 silicon-insulation | 4s | dry-smelting | New intermediate (replaces rubber/plastic role) |
| Heat pipe (dry) | 1 pipe-2 + 2 aluminum-sheet + 2 silica | 1 heat-pipe-1 | 4s | small-crafting | Normal recipe needs water |

**Wire and circuits:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Insulated wire (silicon) | 3 aluminum-wire + 2 silicon-insulation | 4 insulated-wire | 6s | small-crafting | Rubber in normal recipe |
| Logic circuit (silicon) | 3 silicon-insulation + 4 aluminum-wire + 2 polycrystalline-silicon + 1 graphite | 3 logic-circuit | 5s | tiny-assembly | Plastic in normal recipe |
| Capacitor (silica) | 2 aluminum-sheet + 4 silica + 1 alumina + 1 graphite | 2 capacitor | 6s | machine-casting | Plastic in normal recipe |

**Mechanical:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Motor (ceramic) | 2 iron-wire + 1 iron-plate + 2 silica + 1 iron-rod | 1 motor-1 | 8s | medium-crafting | Plastic in normal recipe |
| Motor 2 (silica) | 2 insulated-wire + 1 steel-plate + 1 steel-gear + 1 steel-rod + 3 silica | 1 motor-2 | 10s | medium-crafting | Lubricant in normal recipe |
| Filter (silica) | 2 silica + 1 graphite + 1 iron-sheet + 10 CO2 | 1 filter-1 | 8s | basic-chemistry | Plastic in normal recipe |
| Pump 2 (silicon) | 1 pump-1 + 1 motor-2 + 2 pipe-2 + 2 silicon-insulation | 1 pump-2 | 8s | medium-crafting | Rubber in normal recipe |

**Logistics:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Splitter (silicon) | 2 underground-belt + 2 silicon-insulation | 1 splitter | 4s | small-crafting | Plastic in normal recipe |
| Underground pipe (silica) | 5 pipe + 3 silica | 2 pipe-to-ground | 8s | small-crafting | Sand (needs sandstone) in normal recipe |

**Chemistry:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Lubricant (graphite) | 1 silicon-ingot + 3 graphite + 50 HCl | 8 lubricant + 10 HCl-acid | 6s | basic-chemistry | Methanol in normal recipe |
| Carbochlorination | 2 alumina + 30 chlorine + 3 graphite | 4 aluminum-chloride + 30 CO | 6s | high-temp-radiator | Chlorine sink (dump AlCl3 into lava) |

**Explosives:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Thermite explosive (IMPLEMENTED) | 1 chlorine-barrel + 1 SO2-barrel + 4 aluminum-powder + 1 red-wire + 1 green-wire + 1 small-miner | 1 unstable-explosive | 30s | hand-crafting | Methanol in improvised explosive |
| ANFO explosive (NOT YET IMPLEMENTED) | 30 ammonia + 20 nitric-acid + 20 SO2 + 4 aluminum-powder + 2 iron-oxide + 1 red-wire | 1 unstable-explosive + 16 wastewater | ~4s | basic-chemistry | Glycerol/plastic in industrial explosive-1 |

Thermite: field-expedient IED (aluminum-sulfur thermite in a pressurized barrel). ANFO: proper industrial production (ammonium nitrate + aluminum fuel + iron oxide casing, all inorganic).

**Explosive spoilage on Vulcanus (NOT YET IMPLEMENTED).** Ammonium nitrate decomposes at ~230C, Vulcanus ambient is 200C (right on the edge). Vulcanus explosive recipes produce `nullius-unstable-explosive` instead of `cliff-explosives`. Same function, but with `spoil_ticks` (limited shelf life) and `spoil_to_trigger_result` (actual explosion on spoilage -- engine-native trigger, no scripts). Normal `cliff-explosives` from Nauvis recipes stays stable everywhere.

Implementation: purely prototype-level. Vulcanus recipes output the unstable item variant. `spoil_to_trigger_result` fires a `Trigger` (explosion, damage, particles) when spoilage timer expires. `items_per_trigger` controls how many items detonate per trigger tick. No inventory scanning scripts needed -- the item is inherently unstable from the moment it's crafted. Manufacture on demand, not in bulk.

These recipes are generally **worse** than Nauvis equivalents (more steps, more ingredients) but they work without organics. The player builds ugly inorganic production lines and moves on.

### 3.4 Titanium (Full Kroll Process -- Vulcanus Native)

The existing Nullius titanium chain already resembles the Kroll process. On Vulcanus, the chain is:

```
Deep Deposit (demolisher-exposed)
    |
    v
Rutile (TiO2) -- mined from exposed deposit
    |
    v
[Wet Smelting] 4 rutile + 7 graphite + 80 chlorine --> 15 TiCl4 + 2 mineral dust
    |
    v
Titanium Tetrachloride (TiCl4 fluid)
    |
    v
[Ore Flotation] 10 TiCl4 + 6 sodium + 1 argon --> 1 titanium ingot
    |
    v
Titanium Ingot --> Plate, Sheet, etc.
```

**Vulcanus advantage**: Chlorine is abundant from volcanic HCl processing. On Nauvis, chlorine is the bottleneck byproduct. On Vulcanus, the volcanic gas provides HCl directly, and chlorine sinks are plentiful (volcanic calcium compounds). The Kroll process that's painful on Nauvis is natural on Vulcanus.

**Vulcanus disadvantage**: Needs sodium (from where? Probably imported or from trace lava extraction) and argon (from volcanic gas separation).

### 3.5 Calcite and Calcium

```
Lava --> [Lava Calcite Separation] --> Calcite (direct)
                                          |
                                    [Existing recipes]
                                          |
                              +--- Lime (calcite + heat)
                              +--- Calcium (electrolysis)
                              +--- Calcium Chloride
```

Calcite is cheap and abundant on Vulcanus. On Nauvis, limestone must be mined from non-starting-area deposits. This makes Vulcanus a natural calcium/lime exporter.

### 3.6 Atmospheric Chemistry (CO2 Capture)

Vulcanus has a dense CO2 atmosphere. Using the existing Nullius air processing pattern but with Vulcanus-specific ratios (atmosphere is mostly CO2, trace N2):

### Atmospheric Processing (Reusing Existing Nullius Patterns)

**Step 1: Atmospheric intake** (same mechanic as Nauvis air filtration, different fluid)
```
Vulcanus Air Filtration: nothing --> Vulcanus atmosphere fluid
  (Dense CO2 atmosphere with trace nitrogen, sulfur compounds)
```

**Step 2: Atmosphere separation** (same mechanic as Nauvis air separation, different ratios)
```
Vulcanus Atmosphere Separation:
  150 vulcanus-atmosphere --> 120 CO2 + 15 N2 + 10 SO2 + trace
  (Inverted ratio from Nauvis: mostly CO2 instead of mostly N2)
```

**Step 3: CO2 reduction chain** (existing Nullius recipes, unchanged)
```
CO2 --> CO:       40 CO2 + 40 H2 --> 26 CO + 6 water     (1s, basic-chemistry)
CO --> Graphite:  28 CO + 36 H2 --> 1 graphite + 4 water  (2s, basic-chemistry)
```

Both steps consume H2 (from HCl geyser electrolysis) and produce tiny amounts of water as byproduct.

**Step 4: O2 from SO2** (Vulcanus-specific, implemented)
```
SO2 Catalytic Decomposition:  40 SO2 + 1 rutile (catalyst) --> 40 O2 + 1 rutile
  (Rutile is not consumed. Productivity disabled to prevent catalyst duplication.)
  (SO2 comes from lava silica extraction and atmosphere separation.)
  TODO: Add solid sulfur (SA base item) to output. Currently sulfur is "absorbed"
        by the handwave. Needed once FeS shuttle is implemented as sulfur source.
```

Nauvis air separation recipes (which extract O2 from air directly) are **disabled on Vulcanus** via surface conditions. The SO2 catalytic route is the only oxygen source.

### The Complete Chemistry Web

```
[Vulcanus Atmosphere]     [HCl Geysers]     [Lava Pools]
       |                       |                   |
  [Separation]          [Thermal Cracking]    [Lava Processing]
   /    |    \              /       \              |
 CO2   N2   SO2           H2       Cl2      Metals + Comp. Gas
  |     |    |             |         |
  |   (trace,(sulfur)      |    [Kroll Process]
  |    useful)             |    [CaCl2 production]
  |                        |
  +---[CO2 + H2 --> CO + water]---+
  |                               |
  +---[CO + H2 --> graphite + water]---+
  |                                    |
  +---[O2 separation]                 |
       |                              |
       O2 --[H2 + O2 --> water]-------+
                                      |
                                    Water
                                  (precious trickle)
```

**H2 is the universal bottleneck**: CO2 reduction, graphite production, and water synthesis ALL compete for the same geyser-limited H2 supply. Every mole of hydrogen must be allocated.

**Water production is a cascade of byproducts**: Both CO2-->CO and CO-->graphite reactions produce small amounts of water (6 and 4 units respectively). The water synthesis route (H2 + O2) adds more but costs dedicated H2. Total water output from a well-run atmospheric chemistry line is nonzero but tiny -- liters, not cubic meters.

**What this provides locally:**
- Graphite (for smelting, silicon production, electrode fabrication)
- O2 (for steel production via wet smelting, water synthesis)
- N2 (trace -- useful for compressed nitrogen if a recipe needs it)
- SO2 (sulfur source, useful for acid production)
- Water (agonizingly small amounts from H2 allocation + reaction byproducts)

**Water budget**: A large Vulcanus factory might produce enough water for:
- Occasional quenching of high-priority titanium blooms (the 60s cooldown is painful)
- Minimal heat pipe fluid
- NOT for bulk cooling or industrial water chemistry

This shifts water from "completely absent" to "agonizingly scarce local resource." Importing water via cargo is still far more practical for bulk use, but the local trickle means the player isn't completely helpless before cargo rockets.

### 3.7 Volcanic Chemistry (Chlorine Economy -- Inverted)

On Nauvis, chlorine is the unwanted byproduct you can't void. On Vulcanus, the chlorine economy is inverted:

```
HCl Geysers --> [Geyser Pump] --> HCl gas
                                    |
                                    v
                          [Thermal HCl Cracking]
                          (heat-powered, no electricity)
                              /         \
                            H2           Cl2
                            |             |
                    (precious:      (feeds titanium
                     CO2-->CO,       Kroll process,
                     CO-->graphite,  calcium chloride
                     H2+O2-->water)  production)
```

Both products are **valuable** on Vulcanus:
- H2 is precious -- feeds CO2 reduction (graphite production) and water synthesis
- Cl2 is an industrial input -- feeds the Kroll process for titanium

Chlorine is a **useful input** on Vulcanus, not a waste product. And hydrogen is the **rate-limiting reagent** for everything chemical -- graphite, water, and CO reduction all compete for the same H2 supply from the same HCl geysers.

**The H2 allocation puzzle**: Every mole of H2 from HCl electrolysis can go to:
- CO2 --> CO conversion (unlocks carbon/graphite)
- CO --> graphite conversion (solid carbon for smelting)
- Water synthesis (H2 + O2 --> H2O, precious drops)

You never have enough H2 for all three. Must prioritize.

**Making thermal cracking H2-positive (chlorine sink):**

Thermal cracking produces equal H2 and Cl2. If all you want is hydrogen, the chlorine is a byproduct. **Carbochlorination** (IMPLEMENTED) is the chlorine sink:

```
Al2O3 + 3 Cl2 + 3 C --> 2 AlCl3 + 3 CO
```

Alumina and graphite are cheap from lava. AlCl3 is a solid that can be dumped into lava. CO is a useful intermediate (feeds graphite production). Net effect: trade alumina + graphite to extract hydrogen from HCl with no chlorine waste.

**Future**: AlCl3 is the real-world Friedel-Crafts catalyst. Plan to use it as non-consumed catalyst in Vulcanus organic chemistry alt recipes, giving it value beyond a void sink.

**Alternative H2 extraction: Iron sulfide shuttle (NOT YET IMPLEMENTED):**

A second pathway to extract hydrogen from HCl, using sulfur as a recycled catalyst:

```
Step 1: Fe + S --> FeS                (smelting)
Step 2: FeS + 2 HCl --> FeCl2 + H2S  (acid-base chemistry)
Step 3: H2S --> H2 + S               (thermal decomposition at ~1000C)
Net:    Fe + 2 HCl --> FeCl2 + H2    (sulfur fully recycled)
```

Iron is cheap from lava. FeCl2 is a solid dumped into lava. Sulfur loops back to step 1. Different production chain from thermal cracking -- uses smelting + chemistry instead of radiators. Gives the player two independent H2 pathways to invest in.

Note: FeCl2 from this route and FeCl3 from direct chlorination (2Fe + 3Cl2 --> 2FeCl3) can share a single "iron chloride" item in-game (handwave the oxidation state). This unifies two chlorine sinks into one waste product and opens the door for iron chloride as a useful intermediate (PCB etchant, water treatment catalyst, etc).

---

## 4. Power: Abundant Heat, Scarce Electricity

Vulcanus has **infinite geothermal heat** but almost no way to convert it to electricity initially. The Stirling engine recipe (the only heat-to-electricity converter) requires:

```
Stirling Engine 1 recipe (Nauvis mid-game):
  1 compressor-1
  2 turbine-closed-2
  8 heat-pipe-1
  600 compressed nitrogen
  30 lubricant              <-- available via Vulcanus alt recipe (section 3.3)
```

The lubricant alt recipe (section 3.3) makes lubricant locally producible, but compressed nitrogen and other ingredients may still require imports. The probe carries no Stirling engine; electricity is optional later, not part of bootstrap.

### 4.1 Steam(Hydrogen)punk: Compressed Gas Industry

Vulcanus industry runs on **compressed volcanic gas**, not electricity. Machines are toggled between electric and pneumatic mode via Ctrl+R (same transition system as surge/priority electrolyzers and pump/valve toggles).

**Pneumatic Technology**: Researched on Nauvis immediately after probe reactivation. Unlocks the ability to toggle any placed machine to pneumatic mode on Vulcanus (surface_conditions restrict the toggle to Vulcanus).

**Same entities, two modes** (toggle via Ctrl+R on Vulcanus surface):
- Electric mode: standard Nullius behavior, consumes electricity.
- Vulcanus mode: depends on machine type:
  - **Assemblers, labs, chemistry, extractors, air filters**: Pneumatic (compressed volcanic gas via `FluidEnergySource`). Gas pipe connections east/west.
  - **Furnaces**: Thermal (heat via `HeatEnergySource`). Heat pipe connections on all edges. Consumes waste heat from other machines.
  - **Inserters**: Pneumatic (gas). No heat interface spawned (too small).
- Entities in inventory are mode-neutral. Mode is set after placement.
- The toggle swaps between two entity prototypes in the same `fast_replaceable_group`.

**Engine support confirmed**:
- `FluidEnergySource` with `burns_fluid = true` makes machines consume fluid based on `fuel_value`
- `scale_fluid_usage = true` makes consumption proportional to actual work done (idle machines don't waste gas)
- Existing Nullius compressed gases already have `fuel_value` (compressed nitrogen: 14-18 kJ, compressed hydrogen: 4 kJ, pressure steam: 20 kJ)
- Vulcanus-specific compressed volcanic gas can have a custom fuel value
- `fast_replaceable_group` allows hotkey swap between electric/pneumatic variants (identical to existing Nullius turbine toggle)

**The gas economy**:

Compressed gas comes directly from lava processing -- the volcanic pressure underground already does the compression. No electrical compressor step needed.

```
Lava (under pressure) --> [Lava Processing]
                            |           |
                            v           v
                    Molten Blooms   Compressed Volcanic Gas
                    (metal output)  (fuel byproduct, pre-compressed!)
                                        |
                    +-------------------+-------------------+
                    |           |           |               |
                    v           v           v               v
                 Inserters  Assemblers  Furnaces          Labs
                (gas-powered) (gas-powered) (gas+heat)  (gas-powered)
```

Every lava processing recipe produces **both** metal blooms AND compressed gas as outputs. The deeper/hotter the lava source, the more compressed gas per batch. The planet's geology IS your compressor.

| Process | Energy Source | Notes |
|---|---|---|
| Lava pumping | Compressed gas (self-bootstrapping once primed) | First pump primed from probe's gas supply |
| Lava separation | Heat (lava is hot) + compressed gas (mechanical work) | Produces compressed gas as byproduct -- net positive! |
| Molten bloom cooldown | Passive (just wait) | None |
| Smelting / vent-smelting | Geothermal heat + compressed gas | Heat does the work, gas powers the machine |
| Inserters | Compressed volcanic gas | Gas-burner inserters |
| Assemblers | Compressed volcanic gas | Fluid-energy-source variants |
| Labs | Compressed volcanic gas | Gas-powered labs |
| Pumps | Compressed volcanic gas | Gas-powered pumps |

**The key insight**: Lava processing is **net-positive on compressed gas** -- it produces more gas than the machines consume to process it. The factory is self-fueling once the initial lava processing loop is primed. The bottleneck isn't energy production, it's **lava throughput** -- how fast you can pump and process lava determines your total gas supply, which determines how many machines can run.

### 4.2 The Lava Throughput Bottleneck

```
Lava Intake (free/void) --> Lava Processing (gas-powered)
     |                            |            |
     |                      Molten Blooms   Compressed Gas
     |                                         |
     +----<-------- gas feedback loop ---------+
```

The loop is self-sustaining but not infinitely scalable. Each lava processing step produces more gas than the processor consumes, creating a small surplus. The lava intake itself is free/void-powered because its lava-side footprint cannot accept gas pipes. That surplus powers additional machines (inserters, assemblers, labs). More lava processing = more surplus gas = more factory capacity.

**Scaling**: To grow the factory, build more lava intakes and processors. Each new processing line generates its own gas surplus. The growth is linear, not exponential -- you can't "bootstrap" infinite gas from one intake.

**Bootstrap**: No electricity, no Stirling engine. The lava intake is free/void-powered and toggles (Ctrl+R, see 4.3) between **free lava intake** and **free-gas vent**. Lava is therefore available immediately; the vent supplies the first compressed gas needed to run a pneumatic hydro plant. Once lava processing runs, its net-positive gas surplus takes over and the vent becomes a negligible trickle.

### 4.3 Bootstrap Power Budget: The Free-Gas Vent (IMPLEMENTED)

There is no electrical power budget. The factory bootstraps on free gas instead, with **diminishing returns** so it can never replace the real lava economy.

Each free-gas vent on a surface delivers `BASE / sqrt(N)` gas, where N is the number of vents on that surface. Total output across all vents grows as `sqrt(N)` -- the same curve Space Exploration uses for core mining. Doubling vents only multiplies total free gas by ~1.41x.

| N (vents) | per-vent rate | total free gas |
|---|---|---|
| 1 | BASE | BASE |
| 4 | BASE/2 | 2 * BASE |
| 100 | BASE/10 | 10 * BASE |

`BASE` is tuned (currently 12 gas/s) so one vent roughly primes one pneumatic machine. Because free gas scales sub-linearly while lava processing scales linearly and is net-positive, the vent matters only at bootstrap; at any real factory scale it is a rounding error.

**Implementation** (Space Exploration 0.5 core-miner pattern, engine-metered): The free-gas mode is the intake's Ctrl+R alternate state. The player-facing entity is a cosmetic intake-shaped assembling-machine shell that blueprints normally; when built, `vulcanus_gasvent.lua` spawns a hidden void-energy fluid mining drill plus an invisible infinite gas resource underneath it. The resource has `infinite_depletion_amount = 0`, so the engine never changes its amount; the script owns it. Because the engine meters an infinite resource's output at `amount/normal`, throttling is just rewriting `resource.amount = normal/sqrt(N)` on build/remove. The engine does the metering smoothly -- no duty-cycling, no per-tick loop. N is recomputed only when a vent is toggled, built, or mined. See `scripts/vulcanus_gasvent.lua`.

This is enough for: priming the first pneumatic hydro plant, a few starter machines.

NOT enough for: mass production. The player is forced into the lava-processing loop almost immediately -- which is the point.

### 4.4 Power Progression

| Phase | Gas Source | Factory Scale | Unlocked By |
|---|---|---|---|
| **Bootstrap** | Free-gas vent (sqrt-capped) + free lava intake | First lava processor | Starting equipment |
| **Early** | First self-sustaining lava loop | Small surplus -- a few machines | First lava processing recipe |
| **Mid** | Multiple lava processing lines | Medium factory (each line generates surplus) | Vulcanus Metallurgy 2 (improved yields) |
| **Late** | Optimized processing + higher-tier lava recipes | Large factory | Higher-tier lava separation (more gas per batch) |
| **Endgame** | Mass lava processing arrays | Megabase | Full research tree |

**Electricity role on Vulcanus**: none at bootstrap. The probe carries no Stirling; the factory starts and runs entirely on gas. Stirling engines can still be *crafted* later (lubricant alt recipe is local; compressed nitrogen may need import) for the few things that specifically want electricity (circuit fabrication, signal processing, advanced electronics), but they are a fully optional niche tool, never a survival requirement. The "Anhydrous Thermal Conversion" research (lubricant-free Stirling variant) is a nice-to-have for scaling electronics.

### 4.5 Why This Works

The Vulcanus power design creates a unique challenge: **the factory fuels itself through lava processing, but growth is gated by lava throughput.** More lava processing = more gas = more machines. The bottleneck is pump count and processing capacity, not a separate energy infrastructure.

The factory FEELS different from every other planet:
- **Pipes everywhere**: compressed gas lines run to every machine, not power poles
- **No electrical grid**: almost zero power poles. Just gas pipes and heat pipes.
- **Lava processors are the "power plants"**: more lava throughput = more gas = more capacity
- **Self-fueling loops**: each processing line generates its own fuel surplus
- **Belt design for cooldown**: long belts where molten blooms passively cool while traveling to the next station

This is distinct from every other planet:
- Nauvis: electrical grid + wind intermittency + hydrogen storage
- Fulgora: electrical grid + lightning spikes + overload management
- Gleba: biological power that decays
- Aquilo: monopole allocation + polarity oscillation

Vulcanus: **gas-powered steampunk industry where lava processing IS the power source, and dual pipe routing (gas + heat) defines factory layout.**

### 4.6 The Dual Pipe Network

Every Vulcanus machine needs TWO pipe connections:
- **Gas pipe IN**: compressed volcanic gas to power the machine
- **Heat pipe OUT**: waste heat routed to radiators

These are different entity types competing for tile space around machines. Factory layout becomes a routing puzzle:

```
                [Radiator]---heat pipe---+
                                        |
gas pipe---[Assembler]---heat pipe------+
   |
gas pipe---[Furnace]---heat pipe--------+
   |                                    |
gas pipe---[Lab]---heat pipe---[Radiator]
```

On Nauvis, factory layout is about belt throughput and power pole coverage. On Vulcanus, it's about **gas delivery + heat extraction routing**. Every machine is a node in two separate pipe networks that must both reach it.

**Emergent complexity**:
- Compact builds overheat (heat interfaces too close, heat accumulates)
- Spread-out builds need longer pipe runs (more gas lost to radiator distance?)
- Radiator placement matters -- too far from hot machines and heat accumulates before reaching them
- Gas supply trunk lines and heat exhaust trunk lines compete for the same corridors
- Underground gas pipes help but need to be affordable (see below)
- Heat pipes have no underground variant in vanilla (check if TFMG adds them?)

This makes Vulcanus factories look completely unique -- a tangle of two-color pipe networks that no other planet requires. Screenshots are instantly recognizable.

**Cheap short-range underground pipes**:

Players will burn through underground pipes like candy on Vulcanus. Every crossing of gas-over-heat or heat-over-gas needs one. Nauvis underground pipe recipes are expensive (designed for occasional use). Vulcanus needs a cheap local variant:

| Item | Max Underground Distance | Recipe | Notes |
|---|---|---|---|
| **Vulcanus gas duct** | **2 tiles** | 2 iron ingot + 1 silica | Hilariously short. Just enough to hop over one heat pipe. |
| **Vulcanus gas duct (long)** | **4 tiles** | 4 iron ingot + 2 silica + 1 aluminum sheet | Luxury item. Cross a whole heat trunk line. |

The 2-tile range is intentionally terrible. On Nauvis, underground pipes go 7-15+ tiles. On Vulcanus, your "underground" pipe barely clears a single obstruction. This means:
- Every pipe crossing costs a pair of ducts (one in, one out)
- Complex intersections need multiple pairs in sequence
- The factory floor is littered with duct entry/exit points
- Players who plan their routing well need fewer ducts; spaghetti builders burn through hundreds

The cheapness compensates for the quantity -- each duct is trivial to craft (local iron + silica, both from lava) but you need SO MANY of them.

### 4.7 Heat Generation System (IMPLEMENTED)

**Current implementation**: Hidden heat-interface entities spawn alongside pneumatic machines. Working machines increase their heat-interface temperature proportional to energy consumption. Heat flows through heat pipes to thermal furnaces and radiators.

- **Amortized bucket system**: 443 buckets, one per tick (same as Stirling engines). Each machine updated every ~7.4 seconds.
- **Heat scales with machine energy**: `get_max_energy_usage() * (1 + consumption_bonus) / 200`. Speed modules = more heat. Efficiency modules = less heat.
- **Example rates** (degrees per update, every ~7.4 seconds):
  - Small assembler (59kW): ~5 deg/update (~0.7C/sec)
  - Chemical plant (240kW): ~20 deg/update (~2.7C/sec)
  - Multiple machines on same heat network heat up faster.
- **MAX_HEAT**: 500C (matches heat pipe tier 2 max).
- **Furnaces** (thermal mode): consume heat from network, no hidden interface.
- **Inserters**: no heat interface (too small).
- **Cleanup**: heat interface destroyed immediately when machine mined.

**NOT YET IMPLEMENTED**: Overheating penalty (machines stopping/taking damage at high temperature).

### 4.8 Ongoing Tension: Heat Dissipation (FUTURE DESIGN)

The self-fueling lava loop is too comfortable once established. Needs an ongoing management challenge. Candidates:

**Option A: Abuse freeze-as-overheat (engine-native, zero UPS cost)**

The engine has a complete freeze/heat system built for Aquilo:
- `PlanetPrototype.entities_require_heating = true` -- entities freeze without heating
- `ReactorPrototype.heating_radius` -- reactors prevent freezing in a radius
- `EntityPrototype.heating_energy` -- per-entity freeze threshold

**Inversion**: On Vulcanus, define "cooling towers" as the "reactors" that provide "heating" (actually cooling). Machines outside cooler radius "freeze" (reskinned as "overheated/seized" -- engine doesn't care about the flavor, just the mechanic). Coolers consume compressed gas to operate.

Pros:
- **Zero UPS cost** -- entirely engine-native, no scripting
- Spatial mechanic: must spread coolers across factory to prevent overheating
- Coolers consume gas, creating ongoing fuel drain that scales with factory size
- More machines = more coolers needed = more gas consumed = need more lava processing
- Visual: overheated machines get a "seized/glowing" overlay (frozen_patch reskinned)

Cons:
- Thematically inverted (cooling towers that the engine calls "heaters")
- frozen_patch sprites would need reskinning to look like overheating, not ice
- Players who understand the engine might find it confusing
- Same mechanic as Aquilo but reskinned -- could feel repetitive?

**Option B: Scripted gas consumption scaling (simple, low UPS)**

Gas consumption per machine increases based on local machine density. Achieved via periodic script that adjusts machine speed or applies a consumption penalty.

Pros:
- Thematically direct (dense factories trap heat, need more cooling gas)
- Different mechanic from Aquilo

Cons:
- Requires scripting with UPS cost
- Harder to communicate to the player (invisible penalty)

**Option C: Gas leakage from pipes (simplest)**

Compressed gas slowly leaks from pipes and tanks. Longer pipe networks = more leakage. Forces compact design and continuous lava processing to replace losses.

Pros:
- Trivially simple (script reduces fluid in pipes periodically)
- Creates ongoing gas deficit proportional to infrastructure size

Cons:
- Not very interesting -- just a tax
- Doesn't create spatial design challenges

**Option D: TFMG-thermal approach (compound entity + amortized tick processing)**

The TFMG mod has a dedicated thermal library (`TFMG-thermal`) that implements overheating. How it works:

1. **Compound entity**: When a machine is placed, a hidden `reactor`-type entity (heat interface) is spawned at the same position. This gives the machine a `heat_buffer` with temperature, connections to heat pipes, and heat dissipation.

2. **Heat generation**: Each tick (amortized via `flib.for_n_of`), working machines increase their heat interface's temperature proportional to energy consumption:
   ```
   interface.temperature += delta_time * base_heat_per_tick * (1 + consumption_bonus)
   ```

3. **Two thresholds**:
   - `max_working_temperature`: Machine stops crafting (`disabled_by_script = true`, status = "Overheated!")
   - `max_safe_temperature`: Machine takes damage (0.1 * delta_time, can be destroyed)

4. **Heat dissipation**: The heat interface is connected to the heat pipe network. Heat flows through heat pipes to **radiators** (assembling machines with a fixed "radiate heat" recipe that consume heat via `HeatEnergySource`). Radiators are the heat sinks.

5. **Amortized updates**: Uses `flib.for_n_of` to process only `update_budget` machines per tick, spreading the load. Delta time scales inversely -- fewer updates per machine means each update applies more temperature change. Net effect is the same, just smoother.

6. **Per-machine tuning**: Each machine type has its own `heat_ratio` (what fraction of energy becomes heat), `max_working_temperature`, and `max_safe_temperature`. Hot-running machines like furnaces overheat fast; cold machines like labs barely produce heat.

**This is exactly what Vulcanus needs.** Key advantages:
- **Engine heat propagation is free** (C++ side, no Lua cost for heat flow through pipes)
- Only the temperature increase and status check is scripted (amortized, not per-entity-per-tick)
- Heat pipes and radiators create a **spatial design challenge** -- must route heat away from machines
- Each machine type can have different thermal properties
- Radiators consuming compressed gas as coolant fits perfectly
- Player sees heat glow on machines approaching overheating threshold (native heat_buffer rendering)

**For Vulcanus specifically:**
- All gas-powered machines get `TFMG_thermal`-style heat generation
- Compressed volcanic gas radiators as heat sinks (consume gas to radiate heat)
- `heat_ratio` set high (volcanic environment, everything runs hot)
- `max_working_temperature` relatively low (machines designed for temperate planets, struggling on Vulcanus)
- Heat pipes route waste heat to radiators spaced around the factory
- **Dense factories overheat faster** because nearby heat interfaces accumulate temperature
- **The gas budget now has two competing drains**: powering machines AND cooling them

**Decision: Use TFMG-thermal approach (Option D).** Can either depend on TFMG-thermal as a library or reimplement the pattern (it's ~400 lines of core logic). This is proven, performant, and creates the right design tension.

**Note**: TFMG-thermal is described as a reusable library ("This mod can be used by other mods to implement thermal mechanics into the game"). Could depend on it directly.

---

## 5. Metallurgic Science Pack

Produced from Vulcanus-local materials:

| Recipe | Input | Output | Time | Category |
|---|---|---|---|---|
| Metallurgic pack | 3 iron-ingot + 2 aluminum-ingot + 1 calcite + 1 silica + 1 sulfur | 1 metallurgic-pack | 15s | small-crafting |

All ingredients from lava processing. The iron and aluminum ingots must be **cooled** (not molten), so the science pack production inherently includes the cooldown bottleneck.

**Boxed variant** for large assembler:

| Recipe | Input | Output | Time |
|---|---|---|---|
| Boxed metallurgic pack | 3 box-iron-ingot + 2 box-aluminum-ingot + 1 box-calcite + 1 box-silica + 1 box-sulfur | 1 box-metallurgic-pack | 75s |

---

## 6. Vulcanus-Specific Research

### 6.1 Research Available Pre-Cargo (Planet-Specific Packs)

These techs require heavy metallurgic packs + small amount of generic packs, researchable entirely on Vulcanus:

| Tech | Metallurgic Packs | Generic Packs | Unlocks | Globally Useful? |
|---|---|---|---|---|
| **Volcanic Metallurgy 1** | 200 | 10 geology + 5 mechanical | Lava processing recipes, molten bloom items | Yes -- unlocks Vulcanus production |
| **Volcanic Metallurgy 2** | 400 | 15 geology + 10 mechanical | Improved lava separation yields, water quenching | Yes -- better metal yields |
| **Heat-Resistant Alloys** | 300 | 10 mechanical + 5 electrical | Tier 4 furnaces, heat-resistant pipes | Yes -- better furnaces on ALL planets |
| **Advanced Calcite Processing** | 250 | 10 geology | Improved calcium chain, bulk lime production | Yes -- cheaper calcium everywhere |
| **Volcanic Insulation** | 150 | 10 electrical | Silicon insulation recipes | Vulcanus-only (surface_conditions) |
| **Deep Deposit Surveying** | 500 | 20 geology + 10 mechanical | Reveals titanium deposit locations on map | Vulcanus-only |
| **Synthetic Demolisher Design** | 800 | 30 all generic | Demolisher deployment (requires Gleba bio-research prereq) | Vulcanus-only |

### 6.2 Global Benefits (Why Visit Vulcanus Pre-Cargo)

Even without shipping materials, Vulcanus research unlocks:

| Unlock | Benefit on Other Planets |
|---|---|
| Heat-resistant alloys | Higher-tier furnaces and pipes usable on Nauvis, Fulgora, etc. |
| Advanced calcite processing | Cheaper calcium compounds everywhere (useful for chlorine disposal on Nauvis!) |
| Improved metal yields | Better smelting ratios apply to all planets with metal production |
| Volcanic metallurgy knowledge | Prerequisite for some Tier 6+ cross-planet techs |

### 6.3 Weapons Research (Post-Scouts)

| Tech | Prerequisites | Packs | Unlocks |
|---|---|---|---|
| Long-Range Overpressure Vessels 1 | Anomaly Analysis 2, Volcanic Metallurgy 2 | 400 metallurgic + 20 mechanical | Basic artillery, explosive shells |
| Long-Range Overpressure Vessels 2 | LROV-1, Heat-Resistant Alloys | 800 metallurgic + 40 mechanical + 20 chemical | Advanced artillery, incendiary shells |
| Orbital Overpressure Delivery | LROV-2, Rocket Science 1 | 1500 metallurgic + physics | "Offensive Use of Geoengineering Tools" (MIRV platform) |

---

## 7. Starting Conditions and Bootstrap Sequence

### 7.1 Context: What the Player Has Researched

By probe reactivation (Tier 3), the player has all Tier 1-2 techs, electrical engineering, sensors, metallurgy-2, pumping, volcanism-1 (extractors), and basic chemistry. They know how to build everything -- they just have none of it on Vulcanus.

### 7.2 Probe Wreck Contents

| Item | Count | Phase | Notes |
|---|---|---|---|
| Seawater intake | 2 | A | Auto-swaps to free lava intake on Vulcanus. Toggle (Ctrl+R) between lava intake / free-gas vent. Place on lava shore. |
| Hydro plant | 1 | B | Lava separation (water-treatment category). Toggle to pneumatic; runs on free-gas vent output at bootstrap. |
| Small furnace | 2 | B | Smelting (ingot --> plate/rod). Toggle to pneumatic/thermal. |
| Pipe | 20 | B | Lava and gas piping. |
| Small assembler | 1 | C | For crafting components. Toggle to pneumatic. |
| Inserter | 6 | C | Toggle to pneumatic. |
| Iron chest | 2 | C | Storage. |
| Lab | 1 | E | For Vulcanus research. Toggle to pneumatic. |
| Transport belt | 50 | C | Cooling conveyors for molten blooms. |
| Explosives | 30 | A | Clear Vulcanus cliffs near the landing site. |

No electronics in wreck (melted in volcanic heat). Player must rebuild circuits from silicon insulation + local materials. No Stirling, no electrical grid: one intake pumps lava for free, one intake toggles to a free-gas vent to bootstrap the gas loop, then everything runs on pneumatic gas from lava processing.

### 7.3 Bootstrap Sequence

**Phase A: Free-Gas Bootstrap -- Prime the Loop (minutes 0-5)**

No electricity is used on Vulcanus at all.

```
1. Mine probe wreck --> collect starting items.
2. Place seawater intake #1 on lava lake shore --> auto-swaps to free lava intake.
   Pipe lava to where the first hydro plant will go.
3. Place seawater intake #2 on the shore and Ctrl+R to FREE-GAS VENT mode -->
   it vents compressed gas for free (diminishing returns, see 4.3).
4. Pipe that gas to your first pneumatic machines.
5. Lava + bootstrap gas are both available.
```

The free lava intake + free-gas vent do the priming the Stirling used to. Everything from here on is gas-powered.

**Phase B: First Gas Loop -- Self-Sustaining Factory (minutes 5-15)**

The player has already researched "Pneumatic Technology" on Nauvis (unlocked right after probe reactivation). This allows toggling any machine to pneumatic mode on Vulcanus via Ctrl+R.

```
6. Place a hydro plant (from wreck), Ctrl+R to PNEUMATIC mode.
   - Powered by the free-gas vent. Set recipe to lava iron separation.
   - Lava flows in from intake #1. Produces molten iron blooms + compressed gas.
   - This is net-positive on gas: processing makes more than the machines burn.
7. Pipe the compressed gas output back into the machine gas network.
8. Molten iron blooms cool on belt/in chest (30s) --> first iron ingots.
9. Build a second furnace. Toggle it to PNEUMATIC mode (Ctrl+R).
   - Connects to the gas pipe network. Runs on processing surplus.
10. Build more machines, all in pneumatic mode.
    - Assemblers, inserters, labs -- all toggled to pneumatic via Ctrl+R.
    - Each connects to the gas pipe network.
11. GAS-POWERED FACTORY IS LIVE.
    - Lava-processing surplus now dwarfs the vent. The free-gas vent intake can
      be toggled back to lava intake mode if more lava throughput is useful (or
      left venting as a small buffer).
    - Nothing is electrical.
```

**Phase C: Metal Production (minutes 15-30)**

All machines from here are gas-powered, fed by gas from lava processing.

```
12. Build gas-powered lava processors for each metal type:
    - Lava iron separation --> molten iron blooms --> (30s cooldown) --> iron ingots
    - Lava aluminum separation --> molten aluminum blooms --> (40s cooldown) --> alumina
    - Lava silica extraction --> silica + SO2
    - Lava calcite separation --> calcite
13. Set up cooling belts: long belt runs where blooms cool during transit.
    - Belt length determines throughput (blooms must cool before next processing step).
14. Gas-powered furnaces for further smelting (iron ingot --> plate, rod, gear; alumina dry smelting --> aluminum ingot).
15. Gas-powered assemblers for crafting components.
```

**Phase D: Silicon Electronics (minutes 30-60)**

Rebuilding electronics from scratch without organic materials.

```
16. Silica --> silicon insulation (Vulcanus alt recipe, replaces rubber).
17. Aluminum wire + silicon insulation --> insulated wire (Vulcanus alt recipe).
18. Capacitors using Vulcanus alt recipe (glass/silica dielectric).
19. Logic circuits using Vulcanus alt recipe (ceramic substrate PCB).
20. Gas-powered lab built --> begin Vulcanus research.
    - First research: Volcanic Metallurgy 1 (formalizes lava recipes, improves yields).
```

**Phase E: HCl Chemistry (minutes 60-120)**

Once extractors are built (volcanism-1 tech, already researched on Nauvis):

```
21. Place extractor on HCl geyser --> HCl gas flows.
22. HCl thermal cracking via radiators (heat-powered, no electricity).
    - Early: low-temp cracking as soon as the factory makes enough waste heat.
    - Later: high-temp radiators for bulk H2 + carbochlorination.
23. H2 + Cl2 available:
    - H2 --> CO2 reduction --> graphite (essential for smelting recipes).
    - H2 --> water synthesis (tiny amounts, precious).
    - Cl2 --> calcium chloride, future titanium chemistry.
24. Atmosphere processing: CO2 capture --> CO2 + N2 + SO2.
    - Feeds into graphite production chain with H2 from geysers.
```

**Phase F: Dual Pipe Network Emerges (hours 2+)**

The factory now has both gas pipes and heat pipes:

```
25. Heat management becomes necessary as factory grows.
    - Machines produce waste heat (TFMG-thermal approach).
    - Heat pipes route waste heat to radiators.
    - Radiators crack HCl (dual-purpose: cooling + chemistry).
26. Dual pipe routing: gas pipes (fuel) + heat pipes (waste heat) to every machine.
    - 2-tile underground gas ducts for crossing heat pipe runs.
    - Factory layout becomes a routing puzzle.
27. Expand lava processing lines (each line generates gas surplus).
28. Begin Vulcanus-specific research chain (metallurgic science packs).
```

### 7.4 The Two Power Phases

| Phase | Duration | Power Source | What Runs On It |
|---|---|---|---|
| **Free-gas bootstrap** | Minutes 0-10 | Free-gas vent (sqrt-capped) + free lava intake | First pneumatic hydro plant to start lava processing |
| **Pneumatic** | Minutes 10+ forever | Compressed volcanic gas from lava | Everything. Machines toggled to pneumatic mode via Ctrl+R. |

There is no electrical infrastructure at all. The free-gas vent primes the loop; once lava processing runs, its net-positive surplus carries the factory and the vent (diminishing returns) fades to irrelevance.

**The player does NOT build an electrical grid on Vulcanus.** No power poles. Machines are placed in electric mode (default) then immediately toggled to pneumatic. The entire factory runs on gas pipes.

**Pneumatic Technology** is researched on Nauvis (cheap, unlocked right after probe reactivation) before or immediately after first visiting Vulcanus. Without it, machines can't be toggled to pneumatic mode and the intake can't be toggled to free-gas vent mode, so reach it before relying on free gas.

### 7.5 What the Player Cannot Do (Until Later)

| Blocked Activity | Blocker | Unblocked By |
|---|---|---|
| Organic chemistry | No organics on Vulcanus | Cargo imports from Fulgora/Nauvis |
| Bulk water | Almost none locally | HCl chain produces trickle; cargo for bulk |
| Titanium | Deep deposits inaccessible | Demolishers (requires Gleba bio-research) |
| Copper/advanced electronics | No copper | Cargo imports |
| Additional Stirling engines | Recipe needs lubricant + compressed nitrogen | Local lubricant alt recipe exists; may still need import for other ingredients |

### 7.6 Key Design Notes

**Free gas is a bootstrap, not a power system.** The free-gas vent exists to prime the lava loop. Its diminishing returns (sqrt cap) make it useless to scale -- the player who tries to power a factory off a field of vents is doing it wrong. Real power is the net-positive lava-processing loop.

**Gas is abundant but must be piped.** Every machine needs a gas pipe connection. The factory layout is driven by gas pipe routing + heat pipe routing, not by belt throughput or power pole coverage.

**The bootstrap should take 15-30 minutes for an experienced player** from "empty surface" to "functioning gas-powered mini-factory with cooling belts." The first lava separation (Phase B) is the critical moment -- before it, the player has nothing. After it, metals and gas flow.

**Switching back to Nauvis is always available.** Ctrl+U returns to Nauvis. Vulcanus is a challenge, not a prison.

---

## 8. Cross-Planet Interactions

### 8.1 Vulcanus Needs From Other Planets

| Need | Source | When |
|---|---|---|
| Water (for quenching) | Local trickle (CO2+HCl chain) or Nauvis cargo (bulk) | Early: tiny local amounts. Late: bulk import. |
| Organics (plastic, rubber) | Fulgora or Nauvis (cargo) | Mid-late game |
| Bio-feed for demolishers | Gleba (cargo) | Late game |
| Demolisher bio-research prerequisite | Gleba (research) | Late game |

### 8.2 Vulcanus Provides To Other Planets

| Export | Destination | When |
|---|---|---|
| Titanium ingots/plates | All planets | After cargo + demolisher access |
| Bulk iron/aluminum ingots | All planets (cheap metals) | After cargo |
| Calcite / lime / calcium | Nauvis (chlorine disposal!) | After cargo |
| Heat-resistant components | All planets | Via research (pre-cargo) |
| Artillery shells | All planets (post-scouts) | After cargo + weapons research |
| Overpressure vessels for MIRV | Space platform | Late game (Rogue countermeasure) |

### 8.3 Key Cross-Planet Dependency

**Vulcanus calcite --> Nauvis chlorine disposal**: Vulcanus is the cheapest source of calcium compounds in the system. Once cargo rockets connect, Nauvis can import bulk calcite/lime for calcium chloride production, dramatically easing the chlorine bottleneck. This is one of the strongest motivators for Vulcanus investment.

---

## 9. Demolishers (Late Vulcanus Content)

### 9.1 Unlocking

| Step | Requirement | Notes |
|---|---|---|
| 1. Deep Deposit Surveying | 500 metallurgic + generic packs | Reveals titanium on map (but inaccessible) |
| 2. Gleba bio-research (remote) | Gleba Tier 2 bio-research complete | Prerequisite: understanding of synthetic organisms |
| 3. Synthetic Demolisher Design | 800 metallurgic + generic + biological packs | Unlocks demolisher deployment recipe |
| 4. Demolisher Deployment Item | Titanium + bio-organism + control circuit | The actual deployable item |

### 9.2 Deployment

- Player crafts deployment item and places it on Vulcanus surface
- Script creates territory centered on placement
- Script spawns demolisher via `territory.regenerate_segmented_units()`
- Script sets patrol path toward nearest deep deposit via `territory.set_patrol_path()`
- Demolisher burrows toward deposit, exposing rutile ore patches

### 9.3 Maintenance

- Demolishers need periodic feeding (bio-feed imported from Gleba/Nauvis)
- Script checks: if no bio-feed item in nearby chest every N ticks, demolisher takes damage
- Unfed demolisher eventually dies -- territory dissolves, deposit access may be lost
- Well-fed demolisher exposes more deposit area over time

---

## 10. Vulcanus Component Availability Analysis

Every Nauvis recipe depends on a chain of intermediates. Here's what Vulcanus can and cannot produce locally, and what needs alt recipes or imports.

### 10.1 Raw Materials Availability

| Material | Nauvis Source | Vulcanus Source | Status |
|---|---|---|---|
| Iron ingot | Iron ore --> crush --> smelt | Lava --> molten bloom --> cooldown | **LOCAL** (abundant) |
| Aluminum ingot | Bauxite --> alumina --> electrolysis | Lava --> molten bloom --> cooldown | **LOCAL** (abundant) |
| Steel ingot | Iron ingot + O2 --> wet smelting | Iron ingot + volcanic gas? (alt recipe) | **LOCAL** (needs alt recipe, no O2 from water electrolysis) |
| Graphite | Mined on Nauvis | CO2 atmospheric capture --> carbon/graphite | **LOCAL** (from atmosphere) |
| Silica/Sand | Sandstone --> crush | Lava silica extraction | **LOCAL** (abundant) |
| Calcite/Lime | Limestone (non-starting) | Lava calcite separation | **LOCAL** (abundant) |
| Silicon ingot | Silica + graphite --> smelting | Same recipe, local inputs | **LOCAL** |
| Sulfur (as SO2) | Various chemistry | Lava silica extraction byproduct (SO2 fluid, not solid sulfur yet -- see section 11) | **LOCAL** (fluid form) |
| Water | Seawater intake | Synthesized: HCl electrolysis --> H2 + atmospheric O2 --> H2O | **TRACE LOCAL** (agonizingly slow, bulk still import) |
| Graphite/Carbon | Mined on Nauvis | CO2 atmospheric capture --> carbon | **LOCAL** (from atmosphere) |
| Oxygen | Air separation on Nauvis | CO2 splitting --> O2 | **LOCAL** (from atmosphere) |
| Plastic | Ethylene + Cl2 (PVC) or propene (PP) | **NONE** (organic) | **IMPORT** (or alt recipe?) |
| Rubber | Butadiene + styrene | **NONE** (organic) | **IMPORT** |
| Lubricant | Organic chemistry | Graphite-based alt recipe (silicon ingot + graphite + HCl) | **LOCAL** (via alt recipe) |

### 10.2 Key Intermediate Availability

| Intermediate | Nauvis Recipe | Vulcanus Available? | Blocker |
|---|---|---|---|
| Iron plate | 4 iron ingot --> 3 plate | **YES** | None |
| Iron rod | 4 iron ingot --> 5 rod | **YES** | None |
| Iron wire | 3 iron rod --> 4 wire | **YES** | None |
| Iron gear | 2 iron plate + 1 iron rod --> 2 gear | **YES** | None |
| Aluminum sheet | aluminum ingot --> sheet | **YES** | None |
| Aluminum wire | 5 aluminum rod --> 7 wire | **YES** | None |
| Aluminum rod | aluminum ingot --> rod | **YES** | None |
| Alumina | aluminum ore processing | **YES** (from lava aluminum) | May need alt recipe |
| Polycrystalline silicon | 3 silicon ingot + 45 HCl | **YES** | HCl from volcanic gas |
| Glass | silica processing | **MAYBE** | Check recipe - may need specific furnace |
| Motor 1 | 2 iron wire + 1 iron plate + 1 plastic + 1 iron rod | **NO** -- needs plastic | **IMPORT plastic or alt recipe** |
| Insulated wire | 3 aluminum wire + 2 rubber | **NO** -- needs rubber | **IMPORT rubber or silicon insulation alt** |
| Capacitor | 2 aluminum sheet + 3 plastic + 1 alumina + 1 graphite | **NO** -- needs plastic | **IMPORT or alt recipe** |
| Logic circuit | 3 plastic + 4 aluminum wire + 2 poly-silicon + 1 graphite | **NO** -- needs plastic | **IMPORT or alt recipe** |

### 10.3 The Plastic Problem

**Plastic is the universal blocker.** On Nauvis, plastic is made from ethylene + chlorine (PVC) or propene + ethylene (polypropylene). Both require organic chemistry feedstocks that Vulcanus cannot produce.

Almost every electronic/mechanical component needs plastic:
- Motor 1 (1 plastic)
- Capacitor (3 plastic)
- Logic circuit (3 plastic)
- And cascading into: inserters, assemblers, labs...

**Vulcanus alt recipe options:**

| Component | Nauvis Recipe | Vulcanus Alt Recipe (IMPLEMENTED) | Notes |
|---|---|---|---|
| **Motor 1** | iron wire + plate + **plastic** + rod | iron wire + plate + **silica-ceramic** + rod | Ceramic bushing replaces plastic bearing |
| **Capacitor** | aluminum sheet + **plastic** + alumina + graphite | aluminum sheet + **silica glass** + alumina + graphite | Glass dielectric replaces plastic |
| **Logic circuit** | **plastic** + aluminum wire + poly-silicon + graphite | **ceramic substrate** + aluminum wire + poly-silicon + graphite | Ceramic PCB replaces plastic PCB |
| **Insulated wire** | aluminum wire + **rubber** | aluminum wire + **silicon insulation** | Already defined in section 3.3 |

**Additional implemented alt recipes** (not just plastic/rubber replacements):

| Component | Nauvis Blocker | Vulcanus Alt | Notes |
|---|---|---|---|
| **Filter-1** | plastic | silica + graphite + iron sheet + CO2 | For extractors, wells |
| **Motor-2** | lubricant | insulated wire + steel + silica | For pumps, advanced machines |
| **Pump-2** | rubber | pump-1 + motor-2 + pipe + silicon insulation | For fluid infrastructure |
| **Splitter** | plastic | underground belt + silicon insulation | For belt logistics |
| **Underground pipe** | sand (from sandstone) | pipe + silica | Sandstone not on Vulcanus |
| **Heat pipe** | water (100 per pipe!) | pipe-2 + 2 aluminum sheet + 2 silica | Water is precious |

All alt recipes surface-conditioned to Vulcanus (`nullius-ambient-temperature >= 100`). Uses only locally available materials.

### 10.4 Complete Bootstrap Chain (Vulcanus-Local Only)

```
Lava
  |--> Iron bloom --> (cool) --> Iron ingot --> plate, rod, wire, gear
  |--> Aluminum bloom --> (cool) --> Alumina --> [dry smelt + graphite] --> Aluminum ingot --> sheet, wire, rod
  |--> Calcite --> lime, calcium
  |--> Silica --> glass, silicon ingot, ceramic substrate
  |--> Sulfur
  |--> Compressed volcanic gas (fuel)
  +--> Mineral dust, graphite (byproducts)

Silicon ingot + HCl (from volcanic gas) --> Polycrystalline silicon
Silica --> Ceramic substrate (Vulcanus alt for plastic PCB)
Silica + aluminum sheet --> Silicon insulation (Vulcanus alt for rubber insulation)
Silica --> Silica glass (Vulcanus alt for plastic dielectric)

Iron wire + plate + silica-ceramic + rod --> Motor 1 (Vulcanus alt)
Aluminum wire + silicon insulation --> Insulated wire (Vulcanus alt)
Aluminum sheet + silica glass + alumina + graphite --> Capacitor (Vulcanus alt)
Ceramic substrate + aluminum wire + poly-silicon + graphite --> Logic circuit (Vulcanus alt)

Motor 1 + gear --> Inserter (gas-powered Vulcanus variant)
Logic circuit + capacitor + insulated wire --> Electronics for lab
Aluminum sheet + glass + logic circuits + inserters --> Lab (gas-powered)
```

**Everything from lava.** No imports needed for basic bootstrap. The alt recipes are uglier and less efficient than Nauvis versions, but they work.

### 10.5 Generic Science Pack Alt Recipes (Vulcanus-Local)

Each generic pack needs a Vulcanus-specific alt recipe using only local materials. These are intentionally worse than Nauvis versions (slower, more ingredients) -- the player builds a janky minimum-viable-science-line, not a proper setup.

**Geology Pack (Nauvis: 4 bauxite + 4 sandstone + 4 iron ore)**

Problem: Vulcanus has no ore patches -- metals come from lava as ingots, not raw ore. No bauxite/sandstone/iron ore items.

| Vulcanus Alt Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Vulcanus geology pack | 2 mineral dust + 2 silica + 1 calcite + 1 sulfur | 1 geology pack | 40s | All from lava processing byproducts. Slower than Nauvis (40s vs 30s). Mineral analysis of volcanic deposits. |

**Climatology Pack (Nauvis: 5000 air + 4000 seawater OR 200 N2 + 100 wastewater + 5 volcanic gas)**

Problem: No seawater. Recipe 2 needs nitrogen (trace from atmosphere) + wastewater (tiny amounts from chemistry) + volcanic gas (abundant).

| Vulcanus Alt Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Vulcanus climatology pack | 400 CO2 + 30 N2 + 10 SO2 + 5 volcanic gas | 1 climatology pack | 50s | All from Vulcanus atmosphere separation. Heavy on CO2 (abundant), light on N2 (trace). Atmospheric composition analysis. |

**Mechanical Pack (Nauvis: 1 motor-1 + 3 iron gear)**

No alt recipe needed IF the Vulcanus motor alt recipe (ceramic bushing) is available. Motor and gears use only iron, which is local.

| Vulcanus Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| (Same as Nauvis) | 1 motor-1 (Vulcanus alt) + 3 iron gear | 1 mechanical pack | 15s | Uses Vulcanus alt motor. No additional alt needed. |

**Electrical Pack (Nauvis: 1 decider-combinator + 1 lamp + 2 copper-cable + 1 capacitor)**

All ingredients need Vulcanus ceramic/silicon alt recipes (section 10.3). Once those alt components exist, the electrical pack recipe itself can stay the same.

| Vulcanus Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| (Same as Nauvis) | 1 logic-circuit (ceramic alt) + 1 lamp + 2 insulated-wire (silicon alt) + 1 capacitor (glass alt) | 1 electrical pack | 12s | Uses Vulcanus alt components. Pack recipe unchanged. |

**Summary: 2 new alt recipes needed** (geology + climatology packs). Mechanical and electrical packs work with existing component-level alt recipes.

### 10.6 What Still Requires Import (Post-Cargo)

| Item | Why | Import From |
|---|---|---|
| Plastic/rubber | No organic chemistry on Vulcanus | Fulgora or Nauvis |
| Water | No water sources | Nauvis |
| Advanced electronics (processor 2+) | May need copper or complex organics | Nauvis or Fulgora |
| Bio-feed for demolishers | Biological organisms | Gleba |
| Standard Stirling engines | Recipe needs lubricant + compressed nitrogen | Lubricant available locally; may still need import for compressed nitrogen |

---

## 11. Open Questions

- Sodium source on Vulcanus: trace lava extraction? Or import from Nauvis?
- Argon source on Vulcanus: volcanic gas separation? (Realistic -- volcanic gas contains trace noble gases.)
- Should the metallurgic pack recipe require cooled ingots specifically, or accept molten blooms too? (Requiring cooled ingots means the cooldown bottleneck affects science production.)
- How many deep deposits per map? How large? How fast do demolishers expose them?
- Should demolisher bio-feed be a continuous stream or periodic batches?
- Solid sulfur extraction: lava silica extraction currently produces SO2 (fluid), not solid sulfur. Add solid sulfur to output, or require a separate SO2 --> sulfur step?

---

*Per-planet documents for Fulgora, Gleba, and Aquilo will follow.*
