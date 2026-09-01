# Nullius SA: Vulcanus -- Planet Design Document

> **Status**: Mixed: progression through tier-3 thermal industry is implemented; explicitly proposed sections are design only (updated 2026-08-30)
> **Role**: Heavy industry. Abundant metals from lava. No natural water, no early organics.
> **Unlock**: Volcanic Probe Signal Recovery (Tier 3, after signal acquisition + metallurgy-2)
> **Theme**: Time-gated production (spoilage-as-cooldown), silicon-only insulation, late-game synthetic demolishers.

---

## 1. Core Constraints

| Constraint | Details |
|---|---|
| **CO2 atmosphere** | Dense carbon dioxide atmosphere. Separation yields CO2 + trace N2 + SO2. Oxygen obtained via SO2 catalytic decomposition (rutile catalyst). |
| **Almost no water** | No oceans, no rain. Tiny amounts from Deacon process (HCl + O2 --> Cl2 + H2O). |
| **No early commodity organics** | Ordinary plastic, rubber, and BPA/epichlorohydrin epoxy are not ambient-stable. Later specialized synthesis uses closed equipment and heat-resistant products. |
| **No biology** | No organisms can survive. Purely inorganic world. |
| **Silicon insulation only** | Abundant silica from volcanic rock replaces organic insulation. |
| **Abundant metals** | Iron, aluminum, calcite from lava. Cheap but need time to cool. |
| **Abundant geothermal** | Constant heat from fumaroles. No intermittency problem. |
| **No electric bootstrap** | The wreck contains no generator or electric grid. Initial industry uses free-gas priming, pneumatic machines, and process heat. Electricity may be built later but is not required by the validated local science path. |

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
| Proposed molten titanium bloom | 3600 (60s) | nullius-titanium-ingot | 60 seconds | Design for demolisher-exposed deep deposits. |

**Proposed water quenching** (requires imported water, late tech):

| Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Quench iron | 1 molten-iron-bloom + 10 water | 1 iron-ingot + 8 steam | 1s | Instant, but water is precious cargo. |
| Quench aluminum | 1 molten-aluminum-bloom + 15 water | 1 aluminum-ingot + 12 steam | 1s | More water needed. |
| Quench titanium | 1 molten-titanium-bloom + 25 water | 1 titanium-ingot + 20 steam | 2s | Expensive water cost. |

**Design**: Early Vulcanus runs entirely on passive cooldown -- belts act as cooling conveyors. Factory layout is determined by belt length needed for items to cool before reaching the next processing step. Water quenching is a late-game luxury that dramatically increases throughput.

### 2.3 Compressed Volcanic Gas

Byproduct of all lava processing. Abundant. Pre-compressed by underground pressure.

Primary use: fuel for all gas-powered machines (see section 4).

### 2.4 HCl Geysers

HCl does NOT come from lava processing. The resolved raw source is the
`sulfuric-acid-geyser` resource, extracted as hydrogen chloride by the existing
extractor chain.

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

**Implemented HCl processing:**

- HCl electrolysis is not part of the pneumatic bootstrap.
- `nullius-vulcanus-cracking` runs in Radiator 2 at a minimum of 450C and
  produces the first hydrogen and chlorine.
- Heat-pipe 1 cannot transfer the required temperature. Before higher heat-pipe
  tiers, Radiator 2 must connect directly to the owned heat interface of an
  operating heat-producing pneumatic machine.
- `nullius-vulcanus-deacon` is the separate low-temperature route. It consumes
  HCl and oxygen to produce chlorine and water; it does not produce hydrogen.

| Recipe | Input | Output | Category | Notes |
|---|---|---|---|---|
| HCl thermal cracking | 60 HCl (through hot radiator) | 30 H2 + 30 Cl2 | high-temp-radiator | Radiator must be above min working temperature (450C). |

**The radiator dual-purpose trick**: Radiators turn process heat into useful
chemistry. The first cracking cell uses a direct machine-to-radiator heat
connection; later heat-pipe tiers allow a distributed high-temperature network.

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
| **High-temp radiator** | 450C | Direct machine heat initially; tier-2 heat pipe for distribution | `nullius-low-temp-radiator` + `nullius-high-temp-radiator` |

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
| Proposed H2S thermal cracking | H2S | H2 + S | Design for the FeS shuttle |

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

**Why this matters**: The entire validated Vulcanus chemistry chain runs on
process heat and pneumatic power. The wreck contains no Stirling engine and the
bootstrap requires no electricity.

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

Graphite from rocks gives early carbon before atmospheric processing is set up.
Rutile from rocks is the cheap pre-demolisher source; the infinite map makes it
renewable in practice, but collection cost grows with travel distance. The
synthetic sand route provides a stationary but deliberately terrible fallback.

### 2.6 Proposed Deep Deposits (Demolisher-Gated, Late Game)

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

### 3.3 Direct Hot Casting

```yaml
research:
  prototype: nullius-hot-metalworking
  prerequisites:
    - nullius-efficient-metallurgic-science
    - nullius-aluminum-working-1
  cost: {count: 10, time: 30, metallurgic: 10, mechanical: 1}
recipes:
  surface: Vulcanus
  executor: thermal foundry
  nullius-hot-iron-plate: {input: [4, nullius-molten-iron-bloom], output: [3, nullius-iron-plate], time: 3}
  nullius-hot-iron-rod: {input: [4, nullius-molten-iron-bloom], output: [5, nullius-iron-rod], time: 4}
  nullius-hot-aluminum-sheet: {input: [4, nullius-molten-aluminum-bloom], output: [5, nullius-aluminum-sheet], time: 4}
  nullius-hot-aluminum-rod: {input: [4, nullius-molten-aluminum-bloom], output: [5, nullius-aluminum-rod], time: 4}
  reheating: forbidden
  productivity: ordinary casting family
  failure_path:
    iron_bloom: iron ingot after 30 seconds
    aluminum_bloom: alumina after 40 seconds
invariants:
  item_family: no parallel hot intermediates
  aluminum_advantage: better than cooldown plus graphite reduction
```

| Input | Direct products | Advantage | Missed deadline |
|---|---|---|---|
| Molten iron bloom | Iron plate or rod | Skips passive cooling before metalworking | Bloom cools to iron ingot; ordinary recipes remain available |
| Molten aluminum bloom | Aluminum sheet or rod | Preserves metal before oxidation and skips graphite reduction | Bloom oxidizes to alumina; dry reduction remains available |

### 3.4 Refractory Production

```yaml
research:
  prototype: nullius-vulcanus-refractory-engineering
  prerequisites: [nullius-hot-metalworking, nullius-ceramics, nullius-thermal-storage-2]
  cost: {count: 10, time: 45, metallurgic: 40, geology: 4, chemical: 4}
material_contract:
  raw_boundaries: [lava, atmosphere, hydrogen chloride]
  water: 0
  organics: 0
  electricity: 0
chain:
  mixing:
    recipe: nullius-refractory-mix-vulcanus
    inputs: {nullius-alumina: 5, nullius-silica: 8, nullius-mineral-dust: 12}
    executor: pneumatic assembler
    output: {nullius-refractory-mix: 10}
    time: 12
  firing:
    recipe: nullius-refractory-brick-vulcanus
    input: {nullius-refractory-mix: 10}
    executor: thermal furnace
    output: {nullius-refractory-brick: 30}
    time: 15
uses:
  recipes:
    nullius-heat-pipe-2-vulcanus:
      input: {nullius-heat-pipe-1: 1, nullius-pipe-2: 2, nullius-aluminum-sheet: 4, nullius-refractory-brick: 4, nullius-silicon-insulation: 2, nullius-eutectic-salt: 5}
      output: {nullius-heat-pipe-2: 2}
    nullius-vulcanus-radiator-2-refractory:
      input: {nullius-vulcanus-radiator-1: 1, nullius-aluminum-sheet: 4, nullius-refractory-brick: 4, nullius-heat-pipe-1: 1, nullius-pipe-2: 4}
      output: {nullius-vulcanus-radiator-2: 1}
  roles: [tier-2 pneumatic equipment, high-temperature crucibles, furnace linings]
invariants:
  item_family: one shared refractory intermediate
  fuel: machine heat, not a consumed heat item
  role: construction material, not recurring fuel
```

### 3.5 Alternative Recipes (IMPLEMENTED)

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
| Iron chlorination | 2 iron-ingot + 30 chlorine | 4 iron-chloride | 4s | high-temp-radiator | Renewable chlorine sink; dump solid into lava |
| Iron-assisted sludge dehydration | 30 sludge + 1 iron-chloride | 3 mineral-dust + 90 steam + 6 CO | 0.5s | boiling | Global faster tier-1 alternative to pressure dehydration |

**Explosives:**

| Recipe | Input | Output | Time | Category | Replaces |
|---|---|---|---|---|---|
| Thermite explosive (IMPLEMENTED) | 1 chlorine-barrel + 1 SO2-barrel + 4 aluminum-powder + 1 red-wire + 1 green-wire + 1 small-miner | 1 cliff-explosives | 30s | hand-crafting | Methanol in improvised explosive |
| Proposed ANFO explosive | 30 ammonia + 20 nitric-acid + 20 SO2 + 4 aluminum-powder + 2 iron-oxide + 1 red-wire | 1 cliff-explosives + 16 wastewater | ~4s | basic-chemistry | Glycerol/plastic in industrial explosive-1 |

Thermite: field-expedient IED (aluminum-sulfur thermite in a pressurized barrel). ANFO: proper industrial production (ammonium nitrate + aluminum fuel + iron oxide casing, all inorganic).

**Deferred unstable variant.** Current Vulcanus recipes produce stable
`cliff-explosives`; no unstable explosive item or spoilage behavior is part of
the implemented progression.

These recipes are generally **worse** than Nauvis equivalents (more steps, more ingredients) but they work without organics. The player builds ugly inorganic production lines and moves on.

### 3.6 Titanium: Nauvis Bootstrap, Vulcanus Scale

| Phase | Titanium source | Contract |
|---|---|---|
| Nauvis, before shipments | Synthetic rutile from sand | Complete titanium chain remains possible; bulk production is deliberately uneconomic |
| Vulcanus, pre-cargo | Rutile from volcanic rocks or synthetic rutile from local sand | Rocks are cheaper but require exploration; synthesis is stationary and extremely wasteful |
| Vulcanus, pre-cargo | Aluminothermic TiCl4 reduction | Limited local titanium for advanced equipment without sodium metal, argon, or electricity |
| Vulcanus, later | Demolisher-exposed deep deposits | Planned bulk titanium source |
| Nauvis, after shipments | Imported rutile or titanium ingots | Imports bypass the punitive sand, acid, and waste burden |

#### Nauvis synthetic rutile

| Change | Inputs | Outputs | Time | Status |
|---|---|---|---|---|
| Delete `nullius-silica-2` | - | - | - | Implemented; normal and boxed recipes and unlocks removed |
| Retune `nullius-rutile` | 50 sand + 150 sulfuric acid | 1 rutile + 80 sludge + 5 mineral dust + 25 carbon dioxide | 12s | Implemented; boxed recipe is exactly 5x |
| Reduce titanium-ingot checkpoint | - | 10 titanium ingots | - | Implemented |

| Invariant | Requirement |
|---|---|
| Availability | Nauvis progression cannot hard-require a shipment to make its first titanium products |
| Scaling | Sustained Nauvis titanium production must require massive quarry, acid, and waste-processing capacity |
| Checkpoint | Proves the complete titanium chain once; does not require scaling the temporary synthetic-rutile factory |
| Downstream chemistry | TiCl4, sodium/argon reduction, casting, and working recipes remain unchanged |
| Vulcanus payoff | Physical material shipments, not a remote research bonus, remove the synthetic-rutile burden |

#### Vulcanus rutile sources

| Source | Baseline input | Output | Constraint |
|---|---|---|---|
| Volcanic rocks | Big and huge volcanic rocks | Rutile plus other rock products | Sparse; collection distance increases |
| Synthetic rutile | 50 sand + 150 sulfuric acid | 1 rutile + 80 sludge + 5 mineral dust + 25 carbon dioxide | Existing global recipe; intentionally terrible |

The stationary route closes locally through existing slag reprocessing:

```text
136 gravel
  -> 51 sand + 102 mineral dust

50 sand + 150 sulfuric acid
  -> 1 rutile + 80 sludge + 5 mineral dust + 25 carbon dioxide

baseline net for one rutile:
  136 gravel + 150 sulfuric acid
  -> 1 rutile + 1 sand + 107 mineral dust + 80 sludge + 25 carbon dioxide
```

This is the same punitive recipe used for Nauvis bootstrap titanium. Vulcanus
can sustain it because gravel and sulfuric acid are local, but the material and
waste volumes prevent it from replacing later deep deposits.

#### Vulcanus reduction chain

```yaml
research:
  prototype: nullius-volcanic-titanium-metallurgy
  prerequisites: [nullius-vulcanus-refractory-engineering, nullius-titanium-production-2, nullius-water-filtration-3, nullius-metalworking-2]
  cost: {count: 10, time: 60, metallurgic: 80, geology: 8, chemical: 8}
recipes:
  upstream:
    recipe: nullius-titanium-tetrachloride
    input: {nullius-rutile: 4, nullius-graphite: 7, nullius-chlorine: 80}
    output: {nullius-titanium-tetrachloride: 15, nullius-mineral-dust: 2}
  reduction:
    recipe: nullius-titanium-ingot-vulcanus
    category: nullius-high-temp-radiator
    input: {nullius-titanium-tetrachloride: 15, nullius-aluminum-ingot: 4}
    output: {nullius-titanium-ingot: 2, nullius-aluminum-chloride: 4}
    time: 8
  recovery:
    recipe: nullius-aluminum-chloride-recovery
    category: nullius-high-temp-radiator
    input: {nullius-aluminum-chloride: 4, nullius-water: 30}
    output: {nullius-alumina: 1, nullius-mineral-dust: 3, nullius-hydrogen-chloride: 60}
    time: 6
  equipment:
    nullius-hydro-plant-2-vulcanus: {input: {nullius-hydro-plant-1: 1, nullius-chemical-plant-1: 1, nullius-medium-tank-2: 1, nullius-refractory-brick: 20, nullius-titanium-plate: 2, nullius-red-wire: 5}, output: {nullius-hydro-plant-2: 1}}
    nullius-foundry-2-vulcanus: {input: {nullius-foundry-1: 1, nullius-small-furnace-2: 1, nullius-refractory-brick: 12, nullius-titanium-plate: 1, bob-turbo-inserter: 2}, output: {nullius-foundry-2: 1}}
scale_limit_before_cargo: rutile supply
invariants:
  forbidden_inputs: [nullius-argon, nullius-sodium]
  electricity: 0
  aluminum_chloride_recovery: "4 aluminum ingots -> 4 aluminum chloride -> 1 alumina"
  pilot_output: "4 titanium ingots -> 3 titanium plates -> hydro plant 2 + foundry 2"
  bulk_output: unattractive before deep deposits
```

### 3.7 Volcanic Sodium

#### Source

Sodium in volcanic rock is bound in aluminosilicate minerals and glass. It is not present as free metal or separable sodium oxide. Vulcanus recovers it by acid-leaching the gravel byproduct of lava-based metal production.

| Recipe | Input | Output | Time | Category | Conditions |
|---|---|---|---|---|---|
| Volcanic saline (IMPLEMENTED) | 10 gravel + 50 hydrogen chloride + 100 water | 70 saline + 4 silica + 5 mineral dust | 8s | basic-chemistry | Global; productivity disabled |
| Volcanic causticization (IMPLEMENTED) | 1 soda ash + 1 lime + 100 water | 2 sodium hydroxide + 1 crushed limestone | 30s | water-treatment | Global; productivity disabled |

`nullius-water` is synthesized locally. Hydrogen chloride comes from volcanic geysers. The pneumatic chemical plant performs the leach without electricity.

#### Progression

| Property | Contract |
|---|---|
| Research | `nullius-volcanic-alkali-processing` |
| Prerequisite | `nullius-nitrogen-chemistry-1` |
| Position | After local basic science; before local chemical science |
| Preliminary cost | 50 geology + 50 climatology + 50 mechanical + 50 electrical packs |
| Recipe availability | Global; poor yield rather than a surface restriction |
| Bootstrap invariant | Must not depend on Sodium Processing or chemical packs |

The early unlock is required to break the existing cycle:

```text
chemical pack
  requires sodium hydroxide
    produced by saline electrolysis
      requires saline
        produced by hydrochloric neutralization
          requires caustic solution
            requires sodium hydroxide
```

Volcanic saline supplies the missing external sodium boundary. The first sodium hydroxide does not use electrolysis:

```text
125 saline
  -> 30 brine + 90 recovered water
  -> 1 soda ash + 15 recovered hydrogen chloride
  + lime + synthesized water
  -> 2 sodium hydroxide + crushed limestone
```

The soda-ash step is the existing Solvay-style recipe: 30 brine + 80 carbon dioxide + 8 ammonia. Local ammonia uses pneumatically compressed hydrogen and nitrogen. The intentionally slow, water-hungry causticization step abstracts slaking lime and reacting calcium hydroxide with sodium carbonate.

#### Downstream chemistry

```text
lava metal industry -> stone/gravel
                         |
                         + HCl + synthesized water
                         v
                       saline
                         |
        +----------------+-----------------------------+
        |                                              |
        v                                              v
  sand + saline                              desalination -> brine
        |                                              |
        v                                              v
silica + wastewater                    CO2 + ammonia -> soda ash
                                                       |
                                                       + lime + water
                                                       v
                                              sodium hydroxide
                                                       |
                                                       v
                                               chemical science

brine -> salt -> electric electrolysis -> elemental sodium + chlorine
                                                    |
                                                    v
                                             titanium reduction
```

Every step through chemical-science sodium hydroxide runs in pneumatic chemical, distillation, or water-treatment machines. Elemental sodium retains the existing electric electrolysis route later. Pneumatic electrolyzers are not part of the Vulcanus design.

### 3.8 Calcite and Calcium

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

### 3.9 Atmospheric Chemistry (CO2 Capture)

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
SO2 Catalytic Decomposition:  40 SO2 + 1 rutile (catalyst) --> 40 O2 + 1 sulfur + 1 rutile
  (Rutile is not consumed. Productivity disabled to prevent catalyst duplication.)
  (SO2 comes from lava silica extraction and atmosphere separation.)
  (Excess sulfur can be dumped directly into lava using Space Age lava disposal.)
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
- SO2 and solid sulfur (sulfur source, useful for acid production and science)
- Water (agonizingly small amounts from H2 allocation + reaction byproducts)

**Water budget**: A large Vulcanus factory might produce enough water for:
- Occasional quenching of high-priority titanium blooms (the 60s cooldown is painful)
- Minimal heat pipe fluid
- NOT for bulk cooling or industrial water chemistry

This shifts water from "completely absent" to "agonizingly scarce local resource." Importing water via cargo is still far more practical for bulk use, but the local trickle means the player isn't completely helpless before cargo rockets.

### 3.10 Volcanic Chemistry (Chlorine Economy -- Inverted)

```yaml
boric_acid:
  unlock: nullius-sulfur-processing-2
  decompression:
    recipe: nullius-decompress-volcanic-gas
    executor: nullius-barrel-pump-1-pneumatic
    input: {nullius-compressed-volcanic-gas: 25}
    output: {nullius-volcanic-gas: 100}
    time: 1
    productivity: false
  separation:
    recipe: nullius-volcanic-separation-2
    executor: nullius-distillery-1-pneumatic
    input: {nullius-volcanic-gas: 80}
    output: {nullius-acid-boric: 1, nullius-sulfur-dioxide: 16, nullius-air: 24, nullius-carbon-monoxide: 32}
    time: 3
metallic_sodium:
  unlock: nullius-sodium-processing
  scope: global
  recipe: nullius-carbothermic-sodium
  executor: nullius-vulcanus-radiator-2
  input: {nullius-soda-ash: 3, nullius-graphite: 6, nullius-refractory-brick: 1}
  output: {nullius-sodium: 2, nullius-carbon-monoxide: 90}
  time: 20
  heat: {minimum_temperature: 450, energy: 20MJ}
  productivity: false
```

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

**Renewable chlorine disposal:**

Direct iron chlorination consumes no hydrogen or graphite:

```
2 Fe + 3 Cl2 --> 2 FeCl3
```

Iron is produced from lava. The solid iron chloride is dumped into lava by
inserter, making this the renewable closure for excess chlorine from thermal
HCl cracking.

**Carbochlorination:**

Thermal cracking produces equal H2 and Cl2. If all you want is hydrogen, the chlorine is a byproduct. **Carbochlorination** (IMPLEMENTED) is the chlorine sink:

```
Al2O3 + 3 Cl2 + 3 C --> 2 AlCl3 + 3 CO
```

AlCl3 is a solid that can be dumped into lava, and CO is a useful intermediate
for graphite production. Because atmospheric graphite itself consumes hydrogen
from HCl cracking, carbochlorination is a secondary chlorine consumer rather
than the renewable chlorine closure.

**Future**: AlCl3 is the real-world Friedel-Crafts catalyst. Plan to use it as non-consumed catalyst in Vulcanus organic chemistry alt recipes, giving it value beyond a void sink.

**Proposed alternative H2 extraction: iron sulfide shuttle:**

A second pathway to extract hydrogen from HCl, using sulfur as a recycled catalyst:

```
Step 1: Fe + S --> FeS                (smelting)
Step 2: FeS + 2 HCl --> FeCl2 + H2S  (acid-base chemistry)
Step 3: H2S --> H2 + S               (thermal decomposition at ~1000C)
Net:    Fe + 2 HCl --> FeCl2 + H2    (sulfur fully recycled)
```

Iron is cheap from lava. FeCl2 is a solid dumped into lava. Sulfur loops back to step 1. Different production chain from thermal cracking -- uses smelting + chemistry instead of radiators. Gives the player two independent H2 pathways to invest in.

FeCl2 from this route can use the implemented iron-chloride item from direct
chlorination (handwaving the oxidation state). This unifies both sinks into one
waste product and leaves iron chloride available as a later PCB etchant or
water-treatment catalyst.

---

## 4. Power: Abundant Heat, Scarce Electricity

Vulcanus has **infinite geothermal heat** but almost no way to convert it to electricity initially. The Stirling engine recipe (the only heat-to-electricity converter) requires:

```
Stirling Engine 1 recipe (Nauvis mid-game):
  1 compressor-1
  2 turbine-closed-2
  8 heat-pipe-1
  600 compressed nitrogen
  30 lubricant              <-- available via Vulcanus alt recipe (section 3.5)
```

The lubricant alt recipe (section 3.5) and pneumatic compressor make every Stirling engine ingredient locally producible. The probe carries no Stirling engine; electricity is optional later, not part of bootstrap.

### 4.1 Steam(Hydrogen)punk: Compressed Gas Industry

Vulcanus industry uses **compressed volcanic gas and process heat**, not electricity. Machines are toggled between electric and pneumatic or thermal mode via Ctrl+R. Compressors use one combined priority/surge/electric/pneumatic cycle.

**Pneumatic Technology**: Researched on Nauvis immediately after probe
reactivation. Unlocks Vulcanus-only pneumatic machinery, both radiator tiers,
carbochlorination, iron chlorination, and tier-1 thermal heavy industry on
every surface. Boiling 1 unlocks iron-assisted sludge dehydration.

**Same entities, two modes** (toggle via Ctrl+R on Vulcanus surface):
- Electric mode: standard Nullius behavior, consumes electricity.
- Vulcanus mode: depends on machine type:
  - **Gas-powered**: ordinary assemblers, boxer, barrel pumps, air filters,
    hydro plants, distilleries, chemical plants,
    compressors, flotation cell 1, lab 1, extractors, pumps, and inserter tiers
    1-2.
  - **Heat-powered**: crushers, all furnace sizes, and foundries use global
    thermal variants with tier-specific innate productivity. Nanofabricators
    use separate higher-temperature thermal variants at twice the electric
    energy demand.
- Entities in inventory are mode-neutral. Mode is set after placement.
- The toggle swaps between two entity prototypes in the same `fast_replaceable_group`.

**Resolved building-family audit**:

| Treatment | Families |
|---|---|
| Add gas mode | solid miners (all 8 size/tier variants); inserter tiers 3-4; chimney 3; flotation cells 2-3; labs 2-3 |
| Add global heat mode | crushers, every furnace size, and foundries; tier 1 with Pneumatic Technology, tiers 2-3 with Thermal Engineering |
| Add heat mode on Vulcanus | nanofabricators 1-2 with the same recipes, speed, modules, and effects but 2x energy demand |
| Keep electric | electrolyzers; biology lab; electric boilers; beacons; radar/sensors; lamps; laser turret; accumulators and grid infrastructure; rocket silo |
| Undecided pneumatic candidate | roboports; engine-native robot behavior backed by a script-fed electric buffer |
| No alternate mode | passive belts, pipes, tanks, chests, valves, rails and wagons; existing void-, burner-, heat-, and generation-powered entities |
| Planet source special case | seawater intakes and wells do not get generic pneumatic clones; Vulcanus intake placement already selects lava-intake and gas-vent modes |

The audit is generated from resolved placeable prototypes with:

```bash
python3 tools/analyze_factorio_prereqs.py --describe-placeable-prefix nullius-
```

Pneumatic variants are for mechanically driven work. Heavy industry and
nanofabricators use direct process heat. Electrolyzers remain an electricity
boundary.

**Pneumatic roboport candidate -- undecided**:

| Field | Contract |
|---|---|
| Engine boundary | Roboports accept electric or void energy sources, not fluid energy sources |
| Candidate entity | Electric-buffer roboport with `input_flow_limit = 0W` plus an owned compressed-gas reservoir |
| Conversion | Script removes compressed volcanic gas and writes the equivalent joules to the roboport buffer |
| Scheduling | Same 443-bucket amortization as pneumatic heat interfaces; process one `unit_number % 443` bucket per tick |
| Buffer invariant | `capacity >= (idle demand + charging slots * per-slot demand) * 443 / 60` |
| Tier-1 witness | 20 MJ capacity; 14.77 MJ maximum demand per bucket interval |
| Experimentally validated | Live-grid isolation; gas consumption; native robot charging; buffer drain on gas starvation; recovery after gas restoration |
| Not yet validated | Player-facing gas connection geometry; compound-entity ownership across build, mine, death, clone, and migration events |
| Design decisions | Whether pneumatic roboports fit the planet identity; tiers, recipes, research gates, and gas efficiency |

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
                (gas-powered) (gas-powered) (heat)      (gas-powered)
```

Lava separation recipes return some compressed gas as a coproduct but are
net-negative after machine fuel. `nullius-lava-gas-extraction` is the dedicated
net-positive recipe: 50 lava produces 60 compressed gas and 3 stone in two
seconds.

| Process | Energy Source | Notes |
|---|---|---|
| Lava pumping | Void/free | Intake placement converts to a lava intake on Vulcanus |
| Lava gas extraction | Compressed gas | Dedicated self-powered gas source after a 24-gas vent prime |
| Lava separation | Compressed gas | Produces a gas coproduct but remains net-negative |
| Molten bloom cooldown | Passive (just wait) | None |
| Smelting / vent-smelting | Pneumatic process heat + compressed gas | Operating pneumatic machines provide the initial usable heat |
| Inserters | Compressed volcanic gas | Gas-burner inserters |
| Assemblers | Compressed volcanic gas | Fluid-energy-source variants |
| Labs | Compressed volcanic gas | Gas-powered labs |
| Pumps | Compressed volcanic gas | Gas-powered pumps |

**The key insight**: Dedicated lava-gas extraction is net-positive and funds
the rest of the pneumatic factory. Metal and mineral separation consume part of
that surplus. Gas capacity therefore competes directly with material-processing
capacity for lava and hydro plants.

### 4.2 The Lava Throughput Bottleneck

```
Lava Intake (free/void) --> Lava Processing (gas-powered)
     |                            |            |
     |                      Molten Blooms   Compressed Gas
     |                                         |
     +----<-------- gas feedback loop ---------+
```

The gas-extraction loop is self-sustaining after its vent prime. The lava intake
is free/void-powered. Scaling the rest of the factory requires explicit
gas-extraction capacity; ordinary separation lines do not fund themselves.

**Scaling**: To grow the factory, allocate more intakes and pneumatic hydro
plants to gas extraction alongside the hydro plants assigned to metals and
minerals. Growth is linear in lava and machine throughput.

**Bootstrap**: No electricity, no Stirling engine. The lava intake is
free/void-powered and toggles between **free lava intake** and **free-gas vent**.
The vent supplies the first 24 gas; the first lava-gas extraction cycle then
makes the loop self-sustaining.

### 4.3 Bootstrap Power Budget: The Free-Gas Vent (IMPLEMENTED)

There is no electrical power budget. The factory bootstraps on free gas instead, with **diminishing returns** so it can never replace the real lava economy.

Each free-gas vent on a surface delivers `BASE / sqrt(N)` gas, where N is the number of vents on that surface. Total output across all vents grows as `sqrt(N)` -- the same curve Space Exploration uses for core mining. Doubling vents only multiplies total free gas by ~1.41x.

| N (vents) | per-vent rate | total free gas |
|---|---|---|
| 1 | BASE | BASE |
| 4 | BASE/2 | 2 * BASE |
| 100 | BASE/10 | 10 * BASE |

`BASE` is tuned (currently 12 gas/s) so one vent primes the first gas-extraction
cycle. Because free gas scales sub-linearly while dedicated gas extraction
scales linearly, the vent matters only at bootstrap.

**Implementation** (Space Exploration 0.5 core-miner pattern, engine-metered): The free-gas mode is the intake's Ctrl+R alternate state. The player-facing entity is a cosmetic intake-shaped assembling-machine shell that blueprints normally; when built, `vulcanus_gasvent.lua` spawns a hidden void-energy fluid mining drill plus an invisible infinite gas resource underneath it. The resource has `infinite_depletion_amount = 0`, so the engine never changes its amount; the script owns it. Because the engine meters an infinite resource's output at `amount/normal`, throttling is just rewriting `resource.amount = normal/sqrt(N)` on build/remove. The engine does the metering smoothly -- no duty-cycling, no per-tick loop. N is recomputed only when a vent is toggled, built, or mined. See `scripts/vulcanus_gasvent.lua`.

This is enough for: priming the first pneumatic hydro plant, a few starter machines.

NOT enough for: mass production. The player is forced into the lava-processing loop almost immediately -- which is the point.

### 4.4 Power Progression

| Phase | Gas Source | Factory Scale | Unlocked By |
|---|---|---|---|
| **Bootstrap** | Free-gas vent (sqrt-capped) + free lava intake | First lava processor | Starting equipment |
| **Early** | First self-sustaining lava-gas extraction loop | Small surplus -- a few machines | Pneumatic Technology |
| **Mid** | Parallel gas extraction and material separation | Medium factory | Locally reproduced pneumatic machines |
| **Late** | Scaled gas extraction plus optimized processes | Large factory | Thermal engineering and industrial optimization |
| **Endgame** | Mass lava processing arrays | Megabase | Full research tree |

**Electricity role on Vulcanus**: none at bootstrap. The probe carries no
Stirling; the factory starts and the validated local-science route runs entirely
on gas and heat. Stirling engines become locally buildable after chemical
production supplies their lubricant and pneumatic compressors supply compressed
nitrogen. They are optional for the current Vulcanus progression slice.

### 4.5 Why This Works

The Vulcanus power design creates a unique challenge: **dedicated lava-gas
extraction fuels the factory, while every material line competes for the same
lava and hydro-plant capacity.**

The factory FEELS different from every other planet:
- **Pipes everywhere**: compressed gas lines run to every machine, not power poles
- **No electrical grid**: almost zero power poles. Just gas pipes and heat pipes.
- **Gas-extraction hydros are the power plants**: more dedicated gas throughput means more factory capacity
- **Explicit fuel allocation**: metal lines consume the surplus rather than generating their own
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

**Current implementation**: Hidden heat-interface entities spawn alongside pneumatic machines. Working machines increase their heat-interface temperature proportional to energy consumption. Heat flows through heat pipes to thermal heavy industry and radiators.

- **Amortized bucket system**: 443 buckets, one per tick (same as Stirling engines). Each machine updated every ~7.4 seconds.
- **Heat scales with machine energy**: `get_max_energy_usage() * (1 + consumption_bonus) / 200`. Speed modules = more heat. Efficiency modules = less heat.
- **Example rates** (degrees per update, every ~7.4 seconds):
  - Small assembler (59kW): ~5 deg/update (~0.7C/sec)
  - Chemical plant (240kW): ~20 deg/update (~2.7C/sec)
  - Multiple machines on same heat network heat up faster.
- **MAX_HEAT**: 500C (matches heat pipe tier 2 max).
- **Crushers, furnaces, and foundries** (thermal mode): consume heat from the network and have no hidden interface.
- **Inserters**: no heat interface (too small).
- **Cleanup**: heat interface destroyed immediately when machine mined.

**Proposed**: overheating penalty in which machines stop or take damage at high temperature.

### 4.8 Proposed Heat-Dissipation Pressure

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
| Bootstrap metallurgic pack | 12 iron-ingot + 8 aluminum-ingot + 4 crushed-limestone + 4 silica + 4 sulfur | 1 metallurgic-pack | 60s | small-crafting |
| Efficient metallurgic pack | 2 molten-iron-bloom + 2 molten-aluminum-bloom + 1 crucible + 1 chlorine-barrel + 1 sulfur-dioxide-barrel | 5 metallurgic-pack + 2 barrels with expected return 1.9 | 15s | medium-crafting |

The bootstrap recipe is intentionally slow and wasteful. Efficient Metallurgic
Science replaces it with a hot-bloom process tied to crucibles and chlorine and
sulfur chemistry. Barrel return is productivity-ineligible and averages 1.9;
the pack output remains productivity-eligible.

---

## 6. Vulcanus-Specific Research

### 6.1 Research Available Pre-Cargo (Planet-Specific Packs)

These techs require heavy metallurgic packs + small amount of generic packs, researchable entirely on Vulcanus:

| Tech | Metallurgic Packs | Generic Packs | Unlocks | Globally Useful? |
|---|---|---|---|---|
| **Volcanic Alkali Processing** | 0 metallurgic | 50 each geology, climatology, mechanical, electrical | Volcanic saline and non-electric causticization | Enables chemical science |
| **Efficient Metallurgic Science** | 10 | 10 geology + 5 mechanical + 5 electrical | Efficient pack recipe and chlorine/SO2 barreling | Vulcanus production |
| **Hot Metalworking** | 100 | 10 mechanical | Direct iron and aluminum bloom casting | Vulcanus throughput |
| **Vulcanus Refractory Engineering** | 400 | 40 geology + 40 chemical | Refractory mix, industrial brick firing, dry heat pipe 2, improved high-temp radiator | Vulcanus high-temperature infrastructure |
| **Volcanic Titanium Metallurgy** | 800 | 80 geology + 80 chemical | Aluminothermic titanium, aluminum-chloride recovery, refractory hydro plant 2 and foundry 2 | Limited tier-2 construction closure |
| **Thermal Engineering 2** | 800 | 80 geology + 40 mechanical + 40 electrical + 40 chemical | Tier-2 thermal heavy industry | Optional Nauvis industry |
| **Thermal Engineering 3** | 3200 | 320 geology + 160 climatology + 160 mechanical + 160 electrical + 320 chemical | Tier-3 thermal heavy industry | Optional Nauvis industry |
| **Industrial Optimization** | `100*L^2` per branch | none | +1% crushing, smelting, or casting productivity per level | Global process bonus |

Proposed finite additions:

| Tech | Prerequisite shape | Cost shape | Unlocks | Role |
|---|---|---|---|---|

### 6.2 Global Thermal Heavy Industry

The main pre-cargo benefit of Vulcanus research is **heat-powered heavy industry
on every surface**. Vulcanus exports process knowledge before it can export materials.
The existing electric production chain remains complete; thermal machinery is
an optional alternative for players who build a heat network.

```text
Pneumatic Technology
  -> global thermal machine tier 1

metallurgic Thermal Engineering 2
  -> global thermal machine tier 2

metallurgic Thermal Engineering 3
  -> global thermal machine tier 3
```

The initial machine families are:

- crushers;
- furnaces and other smelting machines;
- foundries and other casting machines.

The thermal research branches are optional leaves. They do not become
prerequisites of ordinary Nauvis crushing, metallurgy, casting, generic science
packs, or other main progression. Thermal mode requires its tier research and
an enabled recipe for the corresponding base machine.

Placed machines remain mode-neutral items and use contextual `Ctrl+R`
transitions:

| Surface | Modes |
|---|---|
| Any surface | electric <-> thermal for crushers, furnaces, and foundries |
| Vulcanus | electric <-> pneumatic for eligible non-heavy-industry machines; electric <-> thermal for nanofabricators |

Thermal variants consume heat instead of electricity. Heavy-industry variants
have an innate productivity bonus; nanofabricator variants preserve the
electric machine's effects and instead consume twice as much energy. Their cost
is the required heat-generation, distribution, storage, and warm-up
infrastructure. Early tiers are operable from solar heat; higher tiers require
increasing temperature and throughput, with nuclear heat eventually providing
continuous heavy-industry baseload.

The intended Nauvis progression is:

```text
solar heat
  -> intermittent thermal crushing, smelting, and casting
  -> larger solar collection and thermal storage
  -> higher-temperature thermal machinery
  -> continuous nuclear-heated heavy industry
```

Productivity bonuses, crafting speed, operating temperatures, heat consumption,
module compatibility, research costs, and tier boundaries are **preliminary**.
They will be balanced in a separate pass. The stable design contract is:

```yaml
thermal_heavy_industry:
  power: heat
  productivity: greater_than_electric_equivalent
  tier_1_unlock: pneumatic_technology
  higher_tier_unlock: metallurgic_thermal_research
  transition_requires: base_machine_recipe_enabled
  unlock_location: vulcanus_research
  nauvis_critical_path: false
  early_heat: solar
  late_heat: nuclear
```

### 6.3 Repeatable Industrial Optimization

```yaml
repeatable_industrial_optimization:
  currency: metallurgic_pack
  branches:
    crushing:
      effect: productivity
      scope: crushing_recipes
    smelting:
      effect: productivity
      scope: smelting_recipes
    casting:
      effect: productivity
      scope: casting_recipes
  effect_per_level: approximately_1_percent_preliminary
  cost_growth: superlinear_preliminary
  maximum_level: none
  prerequisite_for_other_research: false
  machine_modes: [electric, thermal]
```

Each branch improves only its named process family. Bonuses apply through the
recipe family, independent of the machine or power mode executing it. Branches
are independent, repeatable leaves and never gate finite research or main
progression.

The exact bonus, cost function, process membership, and productivity caps are
balance parameters. Costs use metallurgic packs as the primary sink and grow
superlinearly, providing useful marginal investment without a completion point.

### 6.4 Other Global Benefits (Why Visit Vulcanus Pre-Cargo)

Even without shipping materials, Vulcanus research unlocks:

| Unlock | Benefit on Other Planets |
|---|---|
| Thermal heavy industry | Heat-powered crushers, furnaces, and foundries with innate productivity |
| Industrial optimization | Repeatable, process-specific productivity improvements |
| Efficient metallurgic science | Replaces the deliberately poor bootstrap recipe with hot-bloom chemistry |
| Volcanic alkali processing | Non-electric sodium hydroxide route for local chemical science |

### 6.5 Proposed Weapons Research (Post-Scouts)

| Tech | Prerequisites | Packs | Unlocks |
|---|---|---|---|
| Long-Range Overpressure Vessels 1 | Anomaly Analysis 2, thermal research | 400 metallurgic + 20 mechanical | Basic artillery, explosive shells |
| Long-Range Overpressure Vessels 2 | LROV-1, higher-tier thermal research | 800 metallurgic + 40 mechanical + 20 chemical | Advanced artillery, incendiary shells |
| Orbital Overpressure Delivery | LROV-2, Rocket Science 1 | 1500 metallurgic + physics | "Offensive Use of Geoengineering Tools" (MIRV platform) |

---

## 7. Starting Conditions and Bootstrap Sequence

### 7.1 Context: What the Player Has Researched

By probe reactivation (Tier 3), the player has all Tier 1-2 techs, electrical engineering, sensors, metallurgy-2, pumping, volcanism-1 (extractors), and basic chemistry. They know how to build everything -- they just have none of it on Vulcanus.

### 7.2 Probe Wreck Contents

| Item | Count | Phase | Notes |
|---|---|---|---|
| Seawater intake | 2 | A | Auto-swaps to free lava intake on Vulcanus. Toggle (Ctrl+R) between lava intake / free-gas vent. Place on lava shore. |
| Hydro plant | 4 | B | Lava separation. Toggle to pneumatic. |
| Small furnace | 4 | B | Smelting. Toggle to thermal mode. |
| Pipe | 50 | B | Lava, gas, and chemistry piping. |
| Heat pipe 1 | 30 | B | Low-temperature heat distribution. |
| Pipe to ground | 10 | B | Fluid crossings. |
| Extractor 1 | 2 | C | HCl geyser extraction. Toggle to pneumatic. |
| Air filter 1 | 2 | C | Atmospheric intake. Toggle to pneumatic. |
| Distillery 1 | 2 | C | Atmospheric and fluid separation. Toggle to pneumatic. |
| Chemical plant 1 | 2 | C | Local inorganic chemistry. Toggle to pneumatic. |
| Foundry 1 | 4 | C | Casting. Toggle to thermal mode. |
| Small assembler | 4 | C | Component production. Toggle to pneumatic. |
| Inserter | 12 | C | Material handling. |
| Iron chest | 4 | C | Storage. |
| Lab | 1 | E | For Vulcanus research. Toggle to pneumatic. |
| Transport belt | 50 | C | Cooling conveyors for molten blooms. |
| Splitter | 4 | C | Belt logistics. |
| Explosives | 30 | A | Clear Vulcanus cliffs near the landing site. |

No electronics in wreck (melted in volcanic heat). Player must rebuild circuits from silicon insulation + local materials. No Stirling, no electrical grid: one intake pumps lava for free, one intake toggles to a free-gas vent to bootstrap the gas loop, then everything runs on pneumatic gas from lava processing.

### 7.3 Bootstrap Sequence

**Phase A: Free-Gas Bootstrap -- Prime the Loop (minutes 0-5)**

No electricity is used during bootstrap.

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
   - Powered by the free-gas vent. Set recipe to lava gas extraction.
   - Each cycle consumes 50 lava and produces 60 compressed volcanic gas plus 3 stone.
   - Its output powers its next cycle and leaves a net gas surplus.
7. Pipe the compressed gas output back into the machine gas network.
8. Molten iron blooms cool on belt/in chest (30s) --> first iron ingots.
9. Build a second furnace. Toggle it to THERMAL mode (Ctrl+R).
   - Connects to the gas pipe network. Runs on processing surplus.
10. Build more machines in their applicable alternate modes.
    - Crushers, furnaces, and foundries use thermal mode.
    - Assemblers, inserters, and labs use pneumatic mode on Vulcanus.
    - Each connects to the gas pipe network.
11. GAS-POWERED FACTORY IS LIVE.
    - Dedicated gas-extraction capacity supplies the other, net-negative lava
      separation recipes. The free-gas vent intake can
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
    - Early targets: Efficient Metallurgic Science and Volcanic Alkali Processing.
```

**Phase E: HCl Chemistry (minutes 60-120)**

Once extractors are built (volcanism-1 tech, already researched on Nauvis):

```
21. Place extractor on HCl geyser --> HCl gas flows.
22. HCl thermal cracking via radiators (heat-powered, no electricity).
    - Radiator 2 must be heated to at least 450C by a direct heat-producing
      machine connection until a higher-temperature heat-pipe tier is available.
23. H2 + Cl2 available:
    - H2 + atmospheric CO2 --> carbon monoxide/graphite + water byproducts.
    - HCl + atmospheric O2 --> chlorine + water through the Deacon route.
    - Cl2 --> calcium chloride and pilot titanium chemistry.
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
28. Produce metallurgic and local generic science, then establish sulfur,
    alkali, lubricant, and chemical-science production.
```

### 7.4 The Two Power Phases

| Phase | Duration | Power Source | What Runs On It |
|---|---|---|---|
| **Free-gas bootstrap** | Minutes 0-10 | Free-gas vent (sqrt-capped) + free lava intake | First pneumatic hydro plant to start lava processing |
| **Pneumatic** | Minutes 10+ through the current slice | Compressed volcanic gas from lava | Validated local production. Machines toggled to pneumatic mode via Ctrl+R. |

There is no required electrical infrastructure. The free-gas vent primes the
dedicated lava-gas extraction loop; its surplus powers material processing and
the vent fades to irrelevance.

**The validated progression does not require an electrical grid on Vulcanus.**
Machines are placed in electric mode (default) and immediately toggled to
pneumatic. Optional later electric production is outside this bootstrap
contract.

**Pneumatic Technology** is researched on Nauvis (cheap, unlocked right after probe reactivation) before or immediately after first visiting Vulcanus. Without it, machines can't be toggled to pneumatic mode and the intake can't be toggled to free-gas vent mode, so reach it before relying on free gas.

### 7.5 What the Player Cannot Do (Until Later)

| Blocked Activity | Blocker | Unblocked By |
|---|---|---|
| Organic chemistry | No organics on Vulcanus | Cargo imports from Fulgora/Nauvis |
| Bulk water | Almost none locally | HCl chain produces trickle; cargo for bulk |
| Bulk stationary rutile mining | Current rutile comes from scattered volcanic rocks | Planned demolisher-exposed deposits |
| Copper/advanced electronics | No copper | Cargo imports |

### 7.6 Key Design Notes

**Free gas is a bootstrap, not a power system.** The free-gas vent exists to
prime lava-gas extraction. Its diminishing returns make it useless to scale.
Real power comes from hydro plants running the dedicated gas recipe.

**Gas is abundant but must be piped.** Every machine needs a gas pipe connection. The factory layout is driven by gas pipe routing + heat pipe routing, not by belt throughput or power pole coverage.

**The bootstrap should take 15-30 minutes for an experienced player** from
"empty surface" to "functioning gas-powered mini-factory with cooling belts."
The first self-powered lava-gas extraction cycle is the critical moment. Metal
separation scales only after dedicated gas production is established.

**Switching back to Nauvis is always available.** Ctrl+U returns to Nauvis. Vulcanus is a challenge, not a prison.

---

## 8. Proposed Cross-Planet Interactions

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

## 9. Proposed Demolishers (Late Vulcanus Content)

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
| Steel ingot | Iron ingot + O2 --> smelting | Same chemistry; oxygen comes from SO2 catalytic decomposition | **LOCAL** |
| Graphite | Mined on Nauvis | Atmospheric CO2 + hydrogen from thermal HCl cracking --> CO --> graphite | **LOCAL** |
| Silica/Sand | Sandstone --> crush | Lava silica extraction | **LOCAL** (abundant) |
| Calcite/Lime | Limestone (non-starting) | Lava calcite separation | **LOCAL** (abundant) |
| Silicon ingot | Silica + graphite --> smelting | Same recipe, local inputs | **LOCAL** |
| Sulfur | Various chemistry | SO2 from lava/atmosphere --> catalytic decomposition --> solid sulfur | **LOCAL** |
| Water | Seawater intake | Deacon synthesis, CO/graphite byproducts, and saline recovery | **LOCAL** (expensive; bulk import remains optional) |
| Oxygen | Air separation on Nauvis | CO2 splitting --> O2 | **LOCAL** (from atmosphere) |
| Plastic | Ethylene + Cl2 (PVC) or propene (PP) | Same recipes currently work from local CO/H2 synthesis | **CURRENTLY LOCAL; INTENDED IMPORT** |
| Rubber | Butadiene + styrene | Same recipe currently works from local CO/H2 synthesis | **CURRENTLY LOCAL; INTENDED IMPORT** |
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
| Polycrystalline silicon | 3 silicon ingot + 45 HCl | **YES** | HCl geyser extraction |
| Glass | silica processing | **YES** | Pneumatic foundry; validated by chemical-science scenario |
| Motor 1 | Normal recipe needs plastic | **YES** | Vulcanus ceramic motor recipe |
| Insulated wire | Normal recipe needs rubber | **YES** | Vulcanus silicon-insulation recipe |
| Capacitor | Normal recipe needs plastic | **YES** | Vulcanus silica capacitor recipe |
| Logic circuit | Normal recipe needs plastic | **YES** | Vulcanus silicon circuit recipe |
| Titanium ingot | Normal tier-2 route needs sodium metal and argon | **YES** | Synthetic rutile, TiCl4, aluminothermic reduction, and high-temperature refractory equipment |

### 10.3 The Plastic Problem

All 22 recipes that create plastic or rubber require an ambient temperature
of 50C or lower, including chemical synthesis, biological harvesting, barrel
recycling, and direct boxed production. Packaging, unboxing, consumption, and
disposal of imported polymers remain available on Vulcanus.

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
| **Insulated wire** | aluminum wire + **rubber** | aluminum wire + **silicon insulation** | Already defined in section 3.5 |

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

#### Current polymer-free replacement recipes

| Product | Polymer-consuming recipes superseded | Current replacement recipe | Inputs | Output |
|---|---|---|---|---|
| Barrel | `nullius-barrel-1`, `nullius-legacy-barrel-2` | `nullius-vulcanus-barrel` | 2 steel sheet + 2 aluminum sheet + 1 glass + 1 one-way valve | 3 barrel |
| Explosive | `cliff-explosives`, `nullius-explosive-2` | `nullius-thermite-explosive` | 1 chlorine barrel + 1 sulfur dioxide barrel + 4 aluminum powder + red wire + green wire + small miner 1 | 1 cliff explosive |
| Logic circuit | `nullius-logic-circuit` | `nullius-logic-circuit-vulcanus` | 3 silicon insulation + 4 aluminum wire + 2 polycrystalline silicon + 1 graphite | 3 decider combinator |
| Capacitor | `nullius-capacitor` | `nullius-capacitor-vulcanus` | 2 aluminum sheet + 4 silica + 1 alumina + 1 graphite | 2 capacitor |
| Filter 1 | `nullius-filter-1`, `nullius-pressure-filter-1` | `nullius-filter-1-vulcanus` | 2 silica + 1 graphite + 1 iron sheet + 10 carbon dioxide | 1 filter 1 |
| Motor 1 | `nullius-motor-1` | `nullius-motor-1-vulcanus` | 2 iron wire + 1 iron plate + 2 silica + 1 iron rod | 1 motor 1 |
| Pipe 2 | `nullius-plastic-pipe` | `nullius-pipe-2` | 2 steel rod | 3 pipe 2 |
| Splitter 1 | `nullius-splitter-1` | `nullius-splitter-1-vulcanus` | 2 underground belt + 2 silicon insulation | 1 splitter |
| Insulated wire | `nullius-insulated-wire-1`, `nullius-insulated-wire-2` | `nullius-insulated-wire-vulcanus` | 3 aluminum wire + 2 silicon insulation | 4 insulated wire |
| One-way valve | `nullius-one-way-valve-2` | `nullius-one-way-valve` | 1 pipe + 1 iron sheet | 1 one-way valve |
| Pump 2 | `nullius-pump-2` | `nullius-pump-2-vulcanus` | 1 pump 1 + 1 motor 2 + 2 pipe 2 + 2 silicon insulation | 1 pump 2 |
| Display panel | `nullius-display-panel` | `nullius-display-panel-vulcanus` | 1 logic circuit + 1 glass + 1 silicon insulation + 1 aluminum wire | 1 display panel |
| Identification card | `nullius-align-identification-card` | `nullius-align-identification-card-vulcanus` | 1 steel sheet + 1 aluminum sheet | 1 identification card; optional multiplayer Alignment 1 only |
| Armor plate | `nullius-armor-plate` | `nullius-armor-plate-vulcanus` | 3 steel plate + 6 ceramic powder + 2 textile + 2 silicon insulation | 1 armor plate |
| Battery 1 | `nullius-battery-1` | `nullius-battery-1-vulcanus` | Original non-plastic inputs + 2 ceramic powder | 1 battery 1 |
| Insulation | `nullius-insulation` | `nullius-insulation-vulcanus` | 3 gypsum + 2 glass fiber + 2 refractory mix + 1 textile | 2 insulation |
| Repair pack | `nullius-repair-pack` | `nullius-repair-pack-vulcanus` | Original non-plastic inputs + 1 aluminum sheet | 1 repair pack |
| Levitation field 1 | `nullius-levitation-field-1` | `nullius-levitation-field-1-vulcanus` | Original non-plastic inputs + 4 silicon insulation | 1 levitation field 1 |
| Medium tank 2 | `nullius-medium-tank-2` | `nullius-medium-tank-2-vulcanus` | Original non-plastic inputs + 2 glass | 1 medium tank 2 |
| Optical cable | `nullius-optical-cable` | `nullius-optical-cable-vulcanus` | Original non-plastic inputs + 1 silicon insulation | 1 optical cable |
| Rail | `nullius-rail` | `nullius-rail-vulcanus` | 2 steel beam + 3 refractory brick + 1 steel rod + 5 gravel | 3 rail |
| Solar panel 1 | `nullius-solar-panel-1` | `nullius-solar-panel-1-vulcanus` | Original non-plastic inputs + 10 epoxy | 1 solar panel 1 |
| Transformer | `nullius-transformer` | `nullius-transformer-vulcanus` | Original non-plastic inputs + 1 silicon insulation | 1 transformer |
| Small power pole | `nullius-power-pole-1` | `nullius-small-electric-pole-vulcanus` | 2 iron wire + 1 iron rod + 1 glass | 1 small power pole |
| Bulk inserter | `nullius-inserter-3` | `nullius-bulk-inserter-vulcanus` | Original non-rubber inputs + 2 silicon insulation | 1 bulk inserter |
| Fast belt | `nullius-conveyor-belt-2` | `nullius-fast-transport-belt-vulcanus` | Original non-rubber inputs + 4 silicon insulation | 8 fast belt |
| Iron chest | `nullius-small-chest-2` | `nullius-iron-chest-vulcanus` | 2 iron sheet + 4 steel sheet + 2 steel rod + 1 silicon insulation | 1 iron chest |
| Car 1 | `nullius-car-1`, `nullius-legacy-car-1` | `nullius-car-1-vulcanus` | Original non-rubber canonical inputs + 4 silicon insulation | 1 car 1 |
| Chassis 2 | `nullius-chassis-2` | `nullius-chassis-2-vulcanus` | Original non-rubber inputs + 8 silicon insulation | 1 chassis 2 |
| Gun | `nullius-gun` | `nullius-gun-vulcanus` | Original non-rubber inputs + 1 silicon insulation | 1 gun |
| Leg augmentation 3 | `nullius-leg-augmentation-3` | `nullius-leg-augmentation-3-vulcanus` | Original non-rubber inputs + 8 silicon insulation | 1 leg augmentation 3 |
| Refueler | `nullius-refueler` | `nullius-refueler-vulcanus` | Original non-rubber inputs + 3 silicon insulation | 1 refueler |
| Self-repair pack | `nullius-self-repair-pack` | `nullius-self-repair-pack-vulcanus` | Original non-rubber inputs + 2 silicon insulation | 10 self-repair packs |
| Truck 1 | `nullius-truck-1` | `nullius-truck-1-vulcanus` | Original non-rubber inputs + 8 silicon insulation | 1 truck 1 |
| Power switch | `nullius-power-switch` | `nullius-power-switch-vulcanus` | Original non-rubber inputs + 1 silicon insulation | 1 power switch |
| Programmable speaker | `nullius-antenna` | `nullius-programmable-speaker-vulcanus` | Original non-rubber inputs + 1 silicon insulation | 1 programmable speaker |

#### Direct consumers without a current Vulcanus replacement

| Material | Produced item | Consumer recipes |
|---|---|---|
| Rubber | Rocket fuel | `rocket-fuel`, `nullius-legacy-rocket-fuel`; `ammonia-rocket-fuel` requires solid fuel, whose non-recycling producers require oil unavailable on Vulcanus |

#### Import, biology, and disposal consumers

| Material | Purpose | Recipes |
|---|---|---|
| Plastic | Package or unpackage imported plastic | `nullius-box-plastic`, `nullius-unbox-plastic` |
| Rubber | Package or unpackage imported rubber | `nullius-box-rubber`, `nullius-unbox-rubber` |
| Plastic | Biology | `nullius-arthropod-progenitor`, `nullius-arthropod-progenitor-2` |
| Rubber | Biology | `nullius-coal`, `nullius-tree-progenitor`, `nullius-tree-progenitor-2` |
| Plastic | Disposal | `nullius-plastic-pyrolysis` |
| Rubber | Disposal | `nullius-rubber-pyrolysis` |

#### Boxed consumers already covered by polymer-free production

| Polymer-consuming recipes | Current replacement path |
|---|---|
| `nullius-boxed-barrel-1`, `nullius-legacy-boxed-barrel-2` | `nullius-boxed-barrel-vulcanus` |
| `nullius-boxed-capacitor`, `nullius-capacitor-2` | `nullius-boxed-capacitor-vulcanus` |
| `nullius-boxed-explosive`, `nullius-boxed-explosive-2` | `nullius-boxed-thermite-explosive` |
| `nullius-boxed-filter-1`, `nullius-boxed-pressure-filter-1` | `nullius-boxed-filter-1-vulcanus` |
| `nullius-boxed-logic-circuit`, `nullius-logic-circuit-2` | `nullius-boxed-logic-circuit-vulcanus` |
| `nullius-boxed-pipe-2` | `nullius-boxed-pipe-steel` |
| `nullius-boxed-splitter-1` | `nullius-boxed-splitter-1-vulcanus` |
| `nullius-boxed-insulated-wire-1`, `nullius-boxed-insulated-wire-2` | `nullius-boxed-insulated-wire-vulcanus` |
| `nullius-boxed-one-way-valve` | `nullius-boxed-one-way-valve-vulcanus` |
| `nullius-boxed-pump-2` | `nullius-boxed-pump-2-vulcanus` |
| `nullius-boxed-display-panel` | `nullius-boxed-display-panel-vulcanus` |
| `nullius-boxed-battery-1`, `nullius-boxed-battery-1-copper` | `nullius-boxed-battery-1-vulcanus` |
| `nullius-boxed-insulation` | `nullius-boxed-insulation-vulcanus` |
| `nullius-boxed-repair-pack`, `nullius-legacy-boxed-repair-pack` | `nullius-boxed-repair-pack-vulcanus` |
| `nullius-boxed-levitation-field-1` | `nullius-boxed-levitation-field-1-vulcanus` |
| `nullius-boxed-medium-tank-2` | `nullius-boxed-medium-tank-2-vulcanus` |
| `nullius-boxed-optical-cable` | `nullius-boxed-optical-cable-vulcanus` |
| `nullius-boxed-rail` | `nullius-boxed-rail-vulcanus` |
| `nullius-boxed-solar-panel-1` | `nullius-boxed-solar-panel-1-vulcanus` |
| `nullius-boxed-transformer` | `nullius-boxed-transformer-vulcanus` |
| `nullius-boxed-antenna` | `nullius-boxed-antenna-vulcanus` |
| `nullius-boxed-belt-2` | `nullius-boxed-belt-2-vulcanus` |
| `nullius-boxed-inserter-3` | `nullius-boxed-inserter-3-vulcanus` |
| `nullius-boxed-power-switch` | `nullius-boxed-power-switch-vulcanus` |
| Boxed Motor 1 dependency | Existing `nullius-boxed-motor-1` + polymer-free boxed insulated wire |

Boxed variants require `nullius-mass-production-5` and ambient temperature
>= 100, except boxed belt 2, which preserves its `nullius-mass-production-6`
gate.

All other boxed-plastic and boxed-rubber consumers inherit the status of their
unboxed product. Packaging and unboxing remain valid for imported polymers;
polymer sinks remain valid disposal recipes.

#### Boxed consumers without a current Vulcanus replacement

| Material | Consumer recipes |
|---|---|
| Boxed plastic | `cargo-landing-pad`, `nullius-zoology-pack` |
| Boxed rubber | `cargo-landing-pad`, `nullius-boxed-coal`, `nullius-boxed-rocket-fuel`, `nullius-legacy-boxed-rocket-fuel` |
| Boxed plastic; disposal | `nullius-carbon-sink`, `nullius-chlorine-sink`, `nullius-boxed-plastic-pyrolysis` |
| Boxed rubber; disposal | `nullius-carbon-sink` |
| Imported material | `nullius-unbox-plastic`, `nullius-unbox-rubber` |

#### Plastic and rubber checkpoints

| Technology | Contract | Prerequisite of `nullius-probe-vulcanus` |
|---|---:|---:|
| `nullius-checkpoint-plastic` | Produce 5 plastic | Yes |
| `nullius-checkpoint-plastic-2` | Consume 250 plastic | Yes |
| `nullius-checkpoint-rubber` | Produce 20 rubber | Yes |

`nullius-pneumatic-technology` depends directly on `nullius-probe-vulcanus`;
no plastic or rubber checkpoint remains after Vulcanus access.

### 10.4 High-Temperature Resin

```yaml
shared_product:
  prototype: nullius-epoxy
  gameplay_identity: uncured-thermoset-resin
  downstream_recipes: unchanged

ordinary_epoxy:
  chemistry: BPA-epichlorohydrin
  surface_condition: {nullius-ambient-temperature: "<=50"}
  inputs: [nullius-bpa, nullius-ech, nullius-solvent]

vulcanus_high_temperature_resin:
  chemistry: phthalonitrile-inspired
  surface_condition: {nullius-ambient-temperature: ">=200"}
  category: basic-chemistry
  inputs:
    consumed:
      - nullius-benzene
      - nullius-acrylonitrile-barrel
      - nullius-ammonia-barrel
      - nullius-oxygen
      - nullius-solvent
    catalyst:
      input: nullius-alumina
      output: nullius-alumina
  outputs:
    primary: nullius-epoxy
    byproducts: [nullius-wastewater, barrel]
  new_item_or_fluid_prototypes: 0
  productivity: true
```

```text
propene + oxygen + ammonia
  -> acrylonitrile

methanol + carbon monoxide + oxygen
  -> solvent

benzene + barreled acrylonitrile + barreled ammonia + oxygen + solvent
  --alumina catalyst-> high-temperature resin + wastewater + returned barrels
```

The Vulcanus recipe abstracts aromatic oxidation, ammoxidation, and resin
functionalization. The fluid remains `nullius-epoxy`; its localized recipe name
is `High-temperature resin`. Existing fiberglass, composites, optical cable,
processor, and building recipes remain unchanged.

| Ordinary route | Vulcanus route |
|---|---|
| BPA branch | Benzene branch |
| Epichlorohydrin branch | Acrylonitrile/ammonia branch |
| Solvent branch | Solvent branch |
| Epoxy synthesis | High-temperature-resin synthesis |

BPA melts at approximately 156-159 C and approaches its decomposition range at
the 200 C Vulcanus ambient boundary. It is excluded from the local route rather
than transported as a boxed solid. The phthalonitrile-inspired resin uses the
ambient temperature as its initial processing and curing range; higher thermal
stability is developed during final curing in the consuming recipe.

### 10.5 Complete Bootstrap Chain (Vulcanus-Local Only)

```
Lava
  |--> Iron bloom ----> [hot casting] --> plate, rod
  |       +-----------> (cool) --> Iron ingot --> plate, rod, wire, gear
  |--> Aluminum bloom -> [hot casting] --> sheet, rod
  |       +-----------> (cool) --> Alumina --> [dry smelt + graphite] --> Aluminum ingot --> sheet, wire, rod
  |--> Calcite --> lime, calcium
  |--> Silica --> glass, silicon ingot, ceramic substrate
  |--> SO2 --> [rutile-catalyzed decomposition] --> Sulfur + O2
  |--> Compressed volcanic gas (fuel)
  +--> Stone and mineral intermediates

HCl geyser --> thermal cracking --> hydrogen + chlorine
Atmosphere --> CO2 + N2 + SO2
CO2 + hydrogen --> carbon monoxide --> graphite + water
Alumina + silica + mineral dust --> refractory mix --> refractory brick
Gravel --> sand; sand + sulfuric acid --> rutile + sludge + mineral dust
Rutile + graphite + chlorine --> TiCl4
TiCl4 + aluminum --> titanium ingot + aluminum chloride
Silicon ingot + HCl --> Polycrystalline silicon
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

The validated local slice closes over lava, atmosphere, HCl geysers, volcanic
rocks, and the wreck inventory. It needs no cargo imports through chemical
science. The alternative recipes are deliberately less efficient than their
Nauvis counterparts.

### 10.6 Generic Science Pack Alt Recipes (Vulcanus-Local)

Each generic pack needs a Vulcanus-specific alt recipe using only local materials. These are intentionally worse than Nauvis versions (slower, more ingredients) -- the player builds a janky minimum-viable-science-line, not a proper setup.

**Geology Pack (Nauvis: 4 bauxite + 4 sandstone + 4 iron ore)**

Problem: Vulcanus has no ore patches -- metals come from lava as ingots, not raw ore. No bauxite/sandstone/iron ore items.

| Vulcanus Alt Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Vulcanus geology pack (IMPLEMENTED) | 2 mineral dust + 2 silica + 1 crushed limestone + 1 sulfur | 1 geology pack | 40s | All from local mineral processing. |

**Climatology Pack (Nauvis: 5000 air + 4000 seawater OR 200 N2 + 100 wastewater + 5 volcanic gas)**

Problem: No seawater. Recipe 2 needs nitrogen (trace from atmosphere) + wastewater (tiny amounts from chemistry) + volcanic gas (abundant).

| Vulcanus Alt Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| Vulcanus climatology pack (IMPLEMENTED) | 400 CO2 + 30 N2 + 10 SO2 | 1 climatology pack | 50s | All from Vulcanus atmosphere separation. Heavy on CO2 (abundant), light on N2 (trace). Atmospheric composition analysis. Kept to 3 fluid inputs so it fits chemical plant fluid boxes. |

**Mechanical Pack (Nauvis: 1 motor-1 + 3 iron gear)**

No alt recipe needed IF the Vulcanus motor alt recipe (ceramic bushing) is available. Motor and gears use only iron, which is local.

| Vulcanus Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| (Same as Nauvis) | 1 motor-1 (Vulcanus alt) + 3 iron gear | 1 mechanical pack | 15s | Uses Vulcanus alt motor. No additional alt needed. |

**Electrical Pack (Nauvis: 1 decider-combinator + 1 lamp + 2 copper-cable + 1 capacitor)**

All ingredients need Vulcanus ceramic/silicon alt recipes (section 10.3). Once those alt components exist, the electrical pack recipe itself can stay the same.

| Vulcanus Recipe | Input | Output | Time | Notes |
|---|---|---|---|---|
| (Same as Nauvis) | 1 decider-combinator + 1 small-lamp + 2 copper-cable + 1 capacitor | 1 electrical pack | 12s | The named component recipes close through Vulcanus alternatives. |

**Summary: 2 alt recipes implemented** (geology + climatology packs). Mechanical and electrical packs work with existing component-level alt recipes.

**Chemical Pack**

| Recipe | Input | Output | Time | Executor |
|---|---|---|---|---|
| Chemical pack | 3 glass + 5 concrete + 1 ammonia barrel + 2 sodium hydroxide + 20 sulfuric acid + 4 lubricant | 1 chemical pack | 15s | Pneumatic chemical plant |

The full resolved contract includes local sulfuric acid, volcanic saline and
causticization, glass, graphite lubricant, cement/concrete, inorganic barrels,
and ammonia. Thermal Engineering 2 consumes 40 chemical packs; Thermal
Engineering 3 consumes 320.

### 10.7 What Still Requires Import (Post-Cargo)

| Item | Why | Import From |
|---|---|---|
| Plastic/rubber | No ambient-stable commodity production on Vulcanus | Fulgora or Nauvis |
| Bulk water | Local synthesis is deliberately expensive | Nauvis |
| Advanced electronics (processor 2+) | May need copper or complex organics | Nauvis or Fulgora |
| Bio-feed for demolishers | Biological organisms | Gleba |

---

## 11. Open Questions

- Should the metallurgic pack recipe require cooled ingots specifically, or accept molten blooms too? (Requiring cooled ingots means the cooldown bottleneck affects science production.)
- How many deep deposits per map? How large? How fast do demolishers expose them?
- Should demolisher bio-feed be a continuous stream or periodic batches?
- Sulfur output ratio: SO2 catalytic decomposition currently produces solid sulfur as a useful byproduct. Tune sulfur yield versus metallurgic science consumption and direct lava dumping load.

---

*Per-planet documents for Fulgora, Gleba, and Aquilo will follow.*
