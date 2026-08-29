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
| **Copper** | Asteroid-only (endgame) | Available as basic resource everywhere | A) Keep asteroid-only, remap SA copper recipes. B) Copper available on specific planets only (e.g., Vulcanus). |
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
  - **Fulgora probe**: Electromagnetic storms fried most equipment. Scrap plus a few non-metallic survivors (capacitor banks, polymer pipes, one distillation column). Must salvage and rebuild.
  - **Gleba probe**: Biological contamination. Organisms overran the probe. Must study and control native life.
  - **Aquilo probe**: Froze solid. Cryogenically preserved but needs heating infrastructure to thaw and restart.
- **Defers bulk logistics**: Physical cargo rockets come much later (rocket science tier). Early multi-planet play is about bootstrapping each probe independently using only local resources. Bulk material transfer is a late-game unlock that transforms the economy.

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

LATE GAME (Nauvis Tier 5+):
  Research: Interplanetary Cargo (rocket science tier)
  Effect: Launch cargo rockets between planets
  Transform: Planets shift from independent outposts to integrated supply chain

ENDGAME:
  Full cross-planet logistics. Planetary specialization.
  Each planet feeds unique resources/research to Nauvis terraforming.
```

### 2.4 Independent Bootstrap Design

Each planet needs enough local resources to get started without imports. The broken equipment from the dormant probe provides initial infrastructure, but the player must figure out how to sustain and expand using only what the planet offers.

**Bootstrap requirements per planet:**

| Planet | Local Power | Local Materials | Local Chemistry | Missing (import later) |
|---|---|---|---|---|
| **Vulcanus** | Compressed volcanic gas from lava (self-fueling). Fully pneumatic, no electrical grid. | Iron, aluminum, calcite from lava (need cooldown!), titanium (deep, needs demolishers) | CO2 atmosphere + HCl geysers. Thermal cracking. Ceramic/silica alt recipes. No organics. | Organics, bulk water, biology |
| **Fulgora** | Lightning (massive peaks, zero baseload) | Trace metals filtered from hydrocarbons (random, slow). Abundant organic feedstock. | Organic chemistry only (cracking, polymerization). No combustion (no O2). | Bulk metals, oxygen, water, combustion-based anything |
| **Gleba** | Biofilm galvanic cells (tiny, constant replacement) | Bacterial loops: sulfur-metabolizing bacteria from H2S atmosphere. Net negative without breeding (mineral carbon depletion). | H2S-based biochemistry. Sulfur abundant, carbon scarce (from rocks only). No CO2, no O2. | Water (low), carbon (the scarce resource!), conventional ores, predictability, metals, stable power |
| **Aquilo** | Nuclear fusion (local fuel, but most output goes to heating) | Lithium, ammonia ice, heavy water ice, deuterium ice | Cryogenic chemistry (TBD mechanic) | Heat (defining scarcity), water, metals, biology |

**Key design constraint**: Each planet must be playable (if painful) with zero imports. The fun comes from solving "how do I make X with only what's here?" Then later, cargo rockets remove the pain and enable specialization.

**Broken equipment per planet** (initial probe salvage):

| Planet | Surviving Equipment | Why It Survived |
|---|---|---|
| **Vulcanus** | Furnaces, heat pipes, lava intake (toggles to free-gas vent), gas-powered inserters, pre-filled gas tank, gas pipes | Heat-resistant components survived. Electronics melted. No Stirling, no circuits. See PLANET_VULCANUS.md section 7. |
| **Fulgora** | Capacitor banks, polymer pipes, a distillation column, basic inserters | Probe landed near a fountain. Non-metallic components survived; electronics fried by lightning. |
| **Gleba** | Basic lab, containment walls, bacterial harvester, water recycler | Probe landed in bacterial mat zone. Sterile equipment survived; biological seal held. Minimal power. |
| **Aquilo** | Everything, but frozen -- must thaw | Cryogenic preservation kept equipment intact but inert |

---

## 3. Planet-by-Planet Design Ideas

### 3.1 Vulcanus (Pneumatic Hell)

> **Detailed design**: See [PLANET_VULCANUS.md](PLANET_VULCANUS.md) for full production chains, recipes, component analysis, and numbers.

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

**Concept**: No prior civilization, no ruins. A primordial world with a vast **deep abiogenic hydrocarbon ocean** beneath a thick, oxygen-free atmosphere. Lightning storms are the only power source. You are sitting on an ocean of fuel you cannot burn.

#### Core Constraints
- **No oxygen** -- cannot combust anything. The hydrocarbon ocean is feedstock, not fuel.
- **No combustion** -- eliminates the entire hydrogen storage loop. Lightning is your only power and it is violently intermittent.
- **Metal-poor** -- trace metals exist dissolved in hydrocarbons, but no ore deposits. Must filter from hydrocarbon soup.
- **Organic-rich** -- abundant hydrocarbons enable advanced organic chemistry without the industrial bootstrap Nauvis requires. Direct access to ethylene, propene, benzene, etc. from cracking.

#### Magnetosphere: Conductive Hydrocarbon Dynamo

Fulgora's magnetic field and lightning are not weather -- they are planetary-scale electromagnetic phenomena driven by a **conductive subsurface hydrocarbon ocean**. The deep ocean is a mixture of polyaromatic hydrocarbons (heavy crude) saturated with dissolved metal salts (iron, copper, rare earths). Conjugated pi-electron systems in the hydrocarbons, doped by the dissolved metals, make the ocean electrically conductive (same principle as doped polyacetylene -- 2000 Nobel Prize chemistry).

Convection currents in the hot, conductive ocean generate a magnetospheric dynamo -- same mechanism as Earth's liquid iron core, but organic instead of metallic. The intense magnetic field drives constant surface lightning as magnetospheric discharge.

**This explains everything:**
- **Constant powerful lightning** -- planetary dynamo, not weather patterns
- **Dissolved metals in hydrocarbons** -- they are the dopants that make the ocean conductive. Filtering them out is both resource extraction AND (eventually) weakening the dynamo
- **No surface metal deposits** -- metals are dissolved in the ocean, not deposited as ores
- **Conductive polymer wire** (see Organic-Rich Industry below) -- the player is literally synthesizing the same chemistry that powers the planet. Doped conjugated polymers from Fulgora hydrocarbons + Vulcanus FeCl3 as dopant = organic wiring

**Industrial feedback loop**: Extracting hydrocarbons, processing them, and dumping waste heat and byproducts back into the ocean *increases* convection and introduces more conductive contaminants. Storms get **worse** the bigger your factory gets. The player's own success destabilizes the dynamo.

This creates an ongoing tension:
- Build too fast, extract too aggressively --> storms escalate beyond grid capacity --> overloads
- Must scale surge protection proportionally (costs resources diverted from production)
- Or throttle extraction rate (intentionally slow down to keep storms manageable)
- Or research late-game storm mitigation tech (expensive, buys headroom)

Mechanically: `nullius-storm-intensity` surface property scales with total industrial activity (extraction rate, machine count, or cumulative hydrocarbon processed). Same `set_property()` call, driven by factory metrics instead of a fixed sine wave. The sine cycle still exists for short-term variation, but the *baseline* ramps with industrialization.

#### Hydrocarbon Fountains & Filtration

The deep hydrocarbon ocean is unreachable initially. A few natural **fountains** (geological seeps/geysers) provide free hydrocarbon fluid at the surface.

```
Hydrocarbon Fountain (natural, finite count on map)
    |
    v
Raw Hydrocarbon Fluid (complex mixture)
    |
    v
[Filtration/Distillation] --> Primary: ethylene, propene, methane, benzene, etc.
                          --> Trace: iron dust, aluminum dust, silicon, sulfur, rare elements
                          --> Waste: heavy tars, unusable fractions
```

**Random trace extraction**: Filtering raw hydrocarbons yields random trace resources in small amounts. Like Nauvis's ore flotation but with probabilistic outputs. Player must:
- Build enough filtration capacity to get useful quantities of rare traces
- **Dispose of unwanted resources** -- the inverse of Nauvis's chlorine problem. Instead of "can't void chlorine," it's "drowning in unwanted trace elements, need to dump them"
- Design factory to handle variable input ratios

**Waste disposal mechanic**: Unlike Nauvis where certain fluids can't be voided, Fulgora's challenge is the *volume* of unwanted byproducts. Possible mechanics:
- Dump back into hydrocarbon ocean (liquid void equivalent, but limited throughput)
- Compress and store (fills up fast)
- Find creative uses for unwanted traces (cross-planet export?)

#### Power: Lightning Without Combustion

Lightning storms provide **massive but extremely spiky** power. Nullius's surge/priority system is perfect here, but the key difference from Nauvis wind: **there is no hydrogen combustion backup** because there is no oxygen.

#### Power Poles as Lightning Collectors (No Dedicated Collectors)

**Key design**: No separate lightning rod buildings. **Power poles themselves are the lightning attractors.** Lightning hits your poles, energy enters your grid. This is elegant -- you already need poles for power distribution, so lightning collection is automatic.

**Engine approach**: `LightningAttractorPrototype` and `ElectricPolePrototype` share the same parent (`EntityWithOwnerPrototype`) but are separate types. Options:
- **Option A**: Create custom pole entities that are compound (pole + attractor behavior). May need scripting to link the two.
- **Option B**: Use `LightningProperties.priority_rules` to make lightning prefer electric poles over other entities. Poles take the hit but don't inherently collect energy -- use `strike_effect` trigger to inject energy via script.
- **Option C**: Place invisible lightning attractors on top of every pole via script (on_built_entity). Attractor has `energy_source` linked to the pole's network. Ugly but works.

**Needs engine verification**: Can a single entity be both an ElectricPole and a LightningAttractor? If not, Option C (invisible attractor overlay) is the fallback.

#### Dynamic Storm Cycles (Engine-Confirmed)

Lightning intensity can be **changed at runtime** with zero UPS cost for the lightning simulation itself.

**Mechanism**: `LightningProperties.multiplier_surface_property` ties lightning frequency to a custom surface property. `LuaSurface.set_property()` changes that property at runtime. The engine scales lightning frequency automatically.

**Setup:**
1. Define `SurfacePropertyPrototype`: `nullius-storm-intensity` (default_value = 1.0)
2. Set on Fulgora planet: `lightning_properties.multiplier_surface_property = "nullius-storm-intensity"`
3. Script modulates the property over time:

```lua
-- Storm cycle: calm periods, building intensity, peak, dying off
on_nth_tick(300, function()  -- every 5 seconds
    local tick = game.tick
    local cycle = math.sin(tick * 0.0001745)  -- ~1 hour full cycle
    local intensity = math.max(0.05, (cycle + 1) / 2)  -- 0.05 to 1.0
    fulgora_surface.set_property("nullius-storm-intensity", intensity)
end)
```

**Design possibilities:**
- **Sinusoidal calm/storm cycles**: Predictable rhythm the player can learn and plan around. Build during calm, brace during storms.
- **Random storm spikes**: Occasional extreme intensity events ("superstorms") that test the player's overload protection.
- **Escalating intensity**: Storms get worse over game time, forcing continuous infrastructure upgrades.
- **Multi-layered cycles**: Short-period local fluctuations + long-period "seasons." Sometimes a calm period coincides with a season peak and you get moderate storms; sometimes a storm peak hits during peak season and everything goes white.

**Built-in day/night modifier**: `lightning_multiplier_at_day = 0` and `lightning_multiplier_at_night = 1` already exist on LightningProperties. Storms can be night-only or night-heavier, giving the player predictable safe windows.

**Cost**: One `set_property()` call every few seconds. The engine handles all lightning spawning, targeting, and energy delivery natively. Essentially free.

#### The Overload Problem

Lightning dumps massive energy spikes into the grid. The core challenge is not capture but **survival**:

**Power overload mechanic**: If instantaneous production exceeds consumption + accumulator charge rate, the grid **overloads**. Excess energy has nowhere to go. The EMP effect triggers.

```
Lightning strike --> Energy spike into grid
  |
  If (production > consumption + accumulator_headroom):
    OVERLOAD --> EMP effect on affected network
    All accumulators in network discharge to 0
    All machines on network temporarily disabled
  |
  If (production <= consumption + accumulator_headroom):
    Normal operation -- accumulators absorb excess
```

**This inverts the normal Factorio power problem.** On every other planet, the challenge is "not enough power." On Fulgora, the challenge is "too much power at once, and it breaks everything."

#### Power Sinks (Surge Absorbers)

To prevent overload, players must build **dedicated power sinks** -- buildings that continuously consume large amounts of power, acting as safety valves:

```
Power Sink (high constant draw)
  |
  Type: ElectricEnergyInterface with high energy_usage
  Priority: tertiary (same as Nullius surge electrolyzers)
  Purpose: Burn excess power as heat/waste when lightning spikes
  |
  Spacing requirement: Like wind turbines, must be spread out
  (Prevents cramming all sinks in one spot -- forces grid design)
```

**The surge/priority pattern from Nauvis transfers perfectly:**
- **Surge sinks** (tertiary priority): Only draw power when excess is available. Burn it as waste heat.
- **Priority sinks** (secondary): Constant moderate draw, keeps headroom available.
- Accumulators: Buffer between spikes, charge rate is the critical stat.

**The power balance puzzle:**
```
TOO FEW SINKS:    Lightning overloads grid --> EMP --> everything dies
TOO MANY SINKS:   Sinks consume power you need for production --> brownouts between storms
JUST RIGHT:       Sinks absorb spikes, accumulators smooth gaps, production runs steady
```

Players must balance: enough sink capacity to survive the biggest lightning spike, but not so much that sinks drain the grid dry between storms.

#### Engine Feasibility for Overload Detection

**How to detect overload (needs verification):**

`LuaEntity.electric_network_statistics` provides `LuaFlowStatistics` with:
- `get_flow_count()` -- production/consumption per tick
- `input_counts` / `output_counts` -- per-prototype flow data

**Possible approach:**
```lua
on_nth_tick(10):  -- check every 10 ticks
  for each electric_network on Fulgora surface:
    local stats = pole.electric_network_statistics
    local production = stats:get_flow_count{input=true, precision_index=...}
    local consumption = stats:get_flow_count{input=false, precision_index=...}
    local accumulator_headroom = get_total_accumulator_capacity(network)
    if production > consumption + accumulator_headroom then
      trigger_overload(network)
    end
```

**Concerns:**
- `electric_network_statistics` flow precision may not be granular enough for per-tick spike detection
- May need to track lightning energy injection via `strike_effect` trigger and compare against known network capacity
- Accumulator headroom calculation requires iterating accumulators or maintaining a cached sum
- **Biggest unknown**: Can we reliably detect "energy spike exceeds absorption capacity" within the engine? Or do we need to simulate it entirely in script?

**Alternative (simpler, less accurate):**
- Track lightning strikes via `strike_effect` trigger (we know exactly how much energy each strike adds)
- Track total accumulator empty capacity (cached, updated on build/remove)
- If strike energy > empty accumulator capacity, trigger overload
- Simpler than reading flow statistics, and deterministic (we control the numbers)

**Recommended approach**: The simpler alternative. We define the lightning energy, we know the accumulator capacity, we can calculate overload directly without reading engine flow statistics. Much more reliable.

```lua
-- On lightning strike (via strike_effect trigger):
local strike_energy = lightning_prototype.energy
local network_headroom = cached_accumulator_headroom[network_id]
if strike_energy > network_headroom then
  trigger_overload(network_id)
else
  -- Energy absorbed normally by accumulators
  -- (engine handles this natively via attractor energy_source)
end
```

#### Softlock Prevention (Revised)

With the overload mechanic, softlock prevention is built-in:
- Lightning with `damage = 0` (no entity destruction)
- Overload disables machines temporarily via `entity.active = false`
- Overload drains accumulators via `entity.energy = 0`
- Machines re-enable after N ticks (scripted timer)
- Player's factory stops, but nothing is destroyed. They just need more sinks/accumulators.
- **Cannot softlock**: even with zero sinks, the grid recovers after the disable timer. Production is interrupted, not destroyed.
- **Cascade guard needed**: an overload drains accumulators AND disables machines, so the grid recovers with zero stored headroom -- perfectly set up to chain-overload on the very next strike. Needs a post-EMP grace window (storm intensity temporarily suppressed, or a minimum recovery interval before the next strike can trigger another EMP) and ideally a storm-forecast signal so the player can brace instead of being ambushed.

#### Energy Storage Hierarchy (No Combustion)

Since there's no oxygen and no combustion, the hydrogen storage loop from Nauvis doesn't work. Fulgora gets a **three-tier storage hierarchy** with different trade-offs:

| Storage | Charge Rate | Capacity | Leak Rate | Role |
|---|---|---|---|---|
| **Super-capacitors** | Enormous | Very low | High (constant drain) | Absorb lightning spikes instantly. Prevent overload. Leak energy fast -- must be used or lost. |
| **Accumulators** | Moderate | Medium | Low | Standard buffer. Charge from super-caps or directly. Provide steady power between storms. |
| **Thermal storage** (sinks + tanks + Stirling) | Slow | High | Very low | Long-term storage. Excess power --> heat --> thermal tanks --> Stirling engines later. Lossy conversion but retains energy for extended calm periods. |

**The energy flow:**
```
Lightning strike
    |
    v
[Super-capacitors] -- absorb spike instantly (prevents overload)
    |                  but leak fast -- energy drains in minutes
    v
[Accumulators] -- charge from super-cap overflow at moderate rate
    |              hold energy for hours
    v
[Thermal storage] -- slow charge from excess accumulator energy
                     holds energy indefinitely (low leak)
                     Stirling engines convert back when needed
```

**Super-capacitor design:**
- Produced from Fulgora's organic materials (polymer dielectric, carbon electrodes -- fits organic-first industry)
- **Huge charge rate**: Can absorb an entire lightning strike's energy in one tick. This is what prevents overload.
- **Very low capacity**: Maybe 5-10 MJ each (vs. accumulator's 15-100 MJ). They fill up fast.
- **High leak**: Constant energy drain even when full. Energy dissipates over minutes if not transferred to accumulators. Cannot be stockpiled -- use it or lose it.
- Implemented as AccumulatorPrototype with high `input_flow_limit`, low `buffer_capacity`, and high `drain` on the energy source.

**The design puzzle:**
```
NOT ENOUGH SUPER-CAPS:  Can't absorb spike --> overload EMP
TOO MANY SUPER-CAPS:    Leak burns all your energy before accumulators can charge
NOT ENOUGH ACCUMULATORS: Super-caps fill, overflow, leak. No medium-term storage.
NOT ENOUGH THERMAL:      Long calm periods between storms drain accumulators dry.
BALANCED:                Spikes absorbed by super-caps --> trickle into accumulators
                         --> slow-charge thermal tanks --> Stirling baseload during calm
```

Each tier feeds the next. Players must balance all three -- there's no single "best" storage type. Super-caps are essential for survival but useless for long-term. Thermal is essential for calm periods but useless for spikes. Accumulators bridge the two.

**The leak on super-capacitors is the key constraint**: Without it, players would just build a million super-caps and never worry about overload. The leak forces the energy to flow *through* the hierarchy, not just sit in the first tier.

#### Organic-Rich Industry

With abundant hydrocarbons and no metals, Fulgora develops an **organic-first industrial base**:

| Nauvis (metal-first) | Fulgora (organic-first) |
|---|---|
| Iron beams, steel structures | Polymer composites, carbon fiber |
| Metal pipes | Plastic/polymer tubing |
| Copper/aluminum wire | Conductive polymers, carbon nanotube wire? |
| Metal gears | Plastic gears, rubber belts |
| Glass (silica) | Organic glass (acrylic, polycarbonate) |

This means Fulgora can produce items Nauvis struggles with (advanced plastics, organic chemicals, carbon materials) while being unable to produce basic metal infrastructure. Natural trade partner with Vulcanus.

#### Late Game: Nuclear Geoengineering

Deep hydrocarbon ocean is inaccessible from surface. Late-game solution: **nuclear weapons crack open the surface**, exposing large areas of liquid hydrocarbon ocean at once.

**Progression:**
1. **Early**: Limited to natural fountain output. Scarce, fixed locations, low throughput.
2. **Mid**: Improve filtration efficiency, build infrastructure around existing fountains.
3. **Late**: Research nuclear geoengineering (requires Aquilo fusion tech? Or Nauvis nuclear tech imported).
4. **Detonation**: Nuclear charges fracture surface geology, creating new hydrocarbon access points -- **massive** areas of exposed ocean.
5. **Bulk surface filtering**: Build large filtering facilities on exposed ocean surface for high-throughput extraction.

**Nuclear weapon as tool, not weapon**: The android uses nuclear devices purely as geological tools. No enemies to fight -- just cracking rock to reach resources. Reframes nuclear weapons in the Nullius narrative as engineering instruments.

**Territory transformation**: Post-detonation areas become "fractured zones" with different terrain properties -- fluid-rich but structurally unstable. Must build specialized platforms/foundations.

#### Fulgora-Vulcanus Complementarity

These two planets are **perfect inverses**:

| Resource | Vulcanus | Fulgora |
|---|---|---|
| Metals | Abundant (lava) | Trace only (filtered from hydrocarbons) |
| Organics | None (too hot) | Abundant (hydrocarbon ocean) |
| Power | Geothermal (constant) | Lightning (spiky, no combustion backup) |
| Water | None | None (hydrocarbons instead) |
| Insulation | Silicon-based | Polymer-based |
| Late-game unlock | Demolishers (synthetic bio) | Nuclear geoengineering (physics) |

Trade relationship: Vulcanus exports metals, Fulgora exports organics/polymers. Neither has water -- both depend on Nauvis or Aquilo for it.

#### Fulgora Summary

```
POWER:     Lightning (massive peaks, zero baseload, no combustion backup)
MATERIALS: Hydrocarbons from fountains --> organic chemistry + trace metal filtering
MISSING:   Oxygen, metals (bulk), water, combustion capability
UNIQUE:    Random trace filtering, organic-first industry, nuclear geoengineering
EXPORTS:   Advanced organics, polymers, carbon materials, trace rare elements
IMPORTS:   Metals (from Vulcanus), water, nuclear devices (for geoengineering)
```

### 3.3 Gleba (Microbiology/Breeding)

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
- Fulgora: **random trace filtering** (hydrocarbons yield probabilistic resources)
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

**This makes Aquilo the "strategy" planet**: while other planets reward throughput optimization (Vulcanus), probability management (Fulgora/Gleba), or ecosystem balance (Gleba), Aquilo rewards **resource allocation and spatial planning** with a hard-capped finite resource.

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

Aquilo solves Nauvis's nuclear endgame bottleneck. Once cargo rockets connect, bulk tritium import transforms fusion from "tritium-starved supplement" to "reliable baseload power."

#### Power Question

Every planet has a different power challenge:
- Nauvis: wind (intermittent, H2 storage loop)
- Vulcanus: geothermal (abundant, constant)
- Fulgora: lightning (spiky, no combustion, capacitor storage)
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
| **"Defensive Orbital Repositioning"** | Redirect asteroid mining platforms to intercept incoming raid ships | Reduces raid frequency by ~20% | Point-defense space platform |
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

**Phase 1: Independent Outposts (mid game)**
- Consciousness transfer only -- no physical cargo
- Each planet bootstraps from broken probe equipment + local resources
- Players switch between planets like switching android bodies
- Painful but possible -- forces creative problem-solving with limited resources
- **Research is the cross-planet contribution** (see 4.2 below)

**Phase 2: Integrated Supply Chain (late game)**
- Cargo rockets unlock bulk material transfer
- Planets specialize: each exports what it's rich in, imports what it lacks
- Boxing system becomes critical for efficient interplanetary shipping (compressed cargo)
- Rocket cargo capacity creates natural throughput limits -- cannot just belt everything between planets

### 4.2 Pre-Cargo Research: How Isolated Planets Contribute

Factorio research is **global per force**. Any lab on any surface contributes to the same tech tree. Science packs are physical items that stay on-planet. This means:

**Each planet produces local science packs from local resources, researches in local labs, and the unlocks apply everywhere.**

#### Planet-Specific Science Packs

Each planet can produce one or more science packs from purely local materials:

| Planet | Local Pack | Produced From | Notes |
|---|---|---|---|
| **Nauvis** | Geology, Climatology, Mechanical, Electrical, Chemical, Physics | (existing Nullius packs) | The core 6 packs, same as current Nullius |
| **Vulcanus** | **Metallurgic Pack** | Lava metals, volcanic compounds, titanium intermediates | Requires cooled (spoiled) metal products |
| **Fulgora** | **Petrochemical Pack** | Hydrocarbon distillates, polymer compounds, trace metals | Requires filtering infrastructure |
| **Gleba** | **Biological Pack** | Bred bacterial strains, exotic enzymes, cultured organisms | Requires active breeding loop (probabilistic) |
| **Aquilo** | **Cryogenic Pack** | Monopole-processed deuterium, lithium compounds, ammonia derivatives | Requires monopole allocation to lab processes |

#### Technology Gating by Pack Availability

```
TIER 1-3 (Nauvis only, pre-planets):
  Requires: Nauvis packs only (geology through chemical)
  [Current Nullius progression unchanged]

TIER 4 (Probe reactivation, first planet access):
  Requires: Nauvis physics pack
  Unlocks: Probe reactivation tech

TIER 5 (Single-planet research, no cargo needed):
  Some techs require: Nauvis packs + ONE off-world pack
  Example: "Volcanic Metallurgy" needs physics + metallurgic pack
           --> Research physics portion in Nauvis lab
           --> Research metallurgic portion in Vulcanus lab
           --> Both contribute to same tech progress

  Each planet unlocks globally-useful technologies:
    Vulcanus metallurgic --> advanced alloys, heat-resistant equipment
    Fulgora petrochemical --> advanced polymers, organic electronics
    Gleba biological --> advanced organisms, bio-catalysts
    Aquilo cryogenic --> fusion improvements, exotic physics

TIER 6 (Multi-planet research, some cargo helps):
  Some techs require packs from 2-3 planets
  CAN be done without cargo (just slow -- switch consciousness,
    produce packs locally, research locally)
  Cargo rockets make it faster by shipping packs to centralized lab

TIER 7+ (Endgame, cargo required):
  Techs require packs from 4+ planets simultaneously
  A single lab needs packs from multiple planets in its input slots
  Cannot be researched without interplanetary logistics
  Forces cargo rocket infrastructure before endgame research
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

The 500 metallurgic packs are the real cost, and they're trivial to produce on Vulcanus. The 10 geology + 5 mechanical packs are a stretch goal -- you need to bootstrap minimal generic science production from whatever the planet offers. Painful, but you only need a trickle.

**This solves several problems:**
- **No full science infrastructure needed**: You're not replicating Nauvis's 6-pack production chain on Vulcanus. You need a tiny, ugly, inefficient line that drips out a few generic packs.
- **Planet-specific packs carry the cost**: 95% of the research cost is the local pack. The generic packs are a gate, not a grind.
- **Bootstrap incentive**: Even a crude 1-per-minute geology pack line on Vulcanus is enough. The player focuses on the fun planet-specific production, not on rebuilding Nauvis.
- **Scales naturally to cargo era**: Once cargo rockets connect, generic packs flow freely. Pre-cargo, you scrape by with local production.

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
- Tech requires large amounts of 4+ pack types simultaneously in one lab
- Cannot be satisfied by local trickle production
- Forces interplanetary cargo logistics
- This IS the gating mechanism for endgame research

#### Generic Pack Production on Hostile Planets

Each planet needs to produce small amounts of generic Nauvis packs from local resources. This is intentionally painful but possible:

| Pack | Vulcanus (metals, no water) | Fulgora (organics, no O2) | Gleba (bio, no ores) | Aquilo (cryo, limited everything) |
|---|---|---|---|---|
| **Geology** | Volcanic rock + mineral dust (easy) | Trace minerals from filtering (slow) | Bacterial mineral extraction (unreliable) | Ice-bound minerals (thaw first) |
| **Mechanical** | Abundant metal gears (easy) | Polymer gears (alt recipe) | Bio-composite gears (alt recipe) | Frozen salvage from probe |
| **Electrical** | Silicon-based circuits (no copper!) | Conductive polymer circuits (alt recipe) | Bio-electric cells (bred strain) | Superconductor circuits (monopole-enabled) |

Each planet gets **alternative recipes** for generic packs using local materials. These recipes are deliberately worse than Nauvis versions (slower, fewer per craft, more ingredients) but they work. The player builds a janky minimum-viable-science-line and moves on.

#### What Each Planet Unlocks Globally (Pre-Cargo)

| Planet Research | Globally Useful Unlocks |
|---|---|
| **Vulcanus metallurgic** | Advanced alloys for all planets, heat-resistant buildings, improved furnace tiers, titanium recipes |
| **Fulgora petrochemical** | Advanced polymers, organic electronics, improved chemical recipes, lightning-resistant equipment |
| **Gleba biological** | Improved organism designs for Nauvis seeding, bio-catalysts that improve recipes everywhere, advanced biology packs |
| **Aquilo cryogenic** | Fusion reactor improvements (global), improved tritium production, superconductor components, monopole applications |

**The motivation to visit each planet isn't just resources -- it's KNOWLEDGE.** Even without cargo, each planet contributes research that makes ALL planets easier. This gives the player a reason to bootstrap painful outposts: the research payoff is immediate and global, even if physical resources can't flow yet.

### 4.3 What Flows Between Planets (Phase 2)

```
NAUVIS (home, terraforming target):
  Imports: Copper (asteroid mining), rare electronics, tritium, advanced bio-research
  Exports: Basic chemicals, manufactured goods, construction kits

VULCANUS (heavy industry):
  Imports: Water, chemicals, electronics
  Exports: Titanium, calcite, bulk metals, volcanic compounds, artillery shells

FULGORA (hydrocarbon/organics):
  Imports: Bulk metals (from Vulcanus), nuclear devices (for geoengineering), water
  Exports: Advanced organics, polymers, carbon materials, trace rare elements

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

Space platforms in Nullius context could be:
- **Orbital assembly stations** for asteroid mining (replaces current abstract asteroid mechanic)
- **Transit hubs** with hydrogen/oxygen life support (Nullius already has these fluids)
- **Solar power collection** above atmosphere (no wind, but constant solar at higher output)
- **Zero-gravity manufacturing** for specific recipes (nanotechnology in microgravity?)

---

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

### Current Nullius Packs --> Potential Planet Assignment

| Nullius Pack | Current Source | SA Planet Analog |
|---|---|---|
| Geology | Nauvis ores | Nauvis (stays) |
| Climatology | Nauvis air/water | Nauvis (stays) |
| Mechanical | Nauvis industry | Nauvis (stays) |
| Electrical | Nauvis electronics | Fulgora (advanced electronics) |
| Chemical | Nauvis chemistry | Nauvis (stays) or Vulcanus |
| Physics | Nauvis (complex machines) | Could split: Nauvis + Vulcanus |
| Astronomy | Nauvis (space program) | Space platform production |
| Biology packs (7) | Nauvis farming | Gleba (primary) + Nauvis (deployment) |

### New Packs for SA Planets?

| Potential Pack | Planet | Ingredients |
|---|---|---|
| Metallurgic | Vulcanus | Titanium intermediates + calcite + volcanic alloys |
| Petrochemical | Fulgora | Hydrocarbon distillates + polymers + super-capacitor cells |
| Cryogenic | Aquilo | Lithium + tritium + ammonia compounds |

---

## 7. Migration/Compatibility Strategy

### 7.1 Phased Approach
1. **Phase 1**: Core SA support (space platforms, rocket logistics, basic planet access)
2. **Phase 2**: Vulcanus + Fulgora integration (industrial planets, less narrative conflict)
3. **Phase 3**: Gleba integration (biology rework, spoilage mechanics)
4. **Phase 4**: Aquilo integration (nuclear rework, endgame)
5. Quality compatibility -- **implemented as loaded but gameplay-neutralized**

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
- Should there be a "care package" mechanic -- small one-time data/blueprint transfer before cargo rockets?

### Resources & Production
- Should copper remain asteroid-exclusive, or should Fulgora's trace filtration yield small amounts of copper dust as a rare byproduct?
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

### 9.2 Lightning System -- FEASIBLE (Space Age DLC)

**Requires Space Age.** Lightning is configured per-planet via `PlanetPrototype.lightning_properties`.

**LightningPrototype fields:**

| Field | Type | Default | Notes |
|---|---|---|---|
| `damage` | double | 100 | Damage to non-attractor entities. **Can be set to 0 for non-destructive lightning.** |
| `energy` | Energy | Max double | Energy transferred to attractors on hit. |
| `strike_effect` | Trigger | nil | Effect triggered on non-attractor strike. Fires BEFORE damage. |
| `attractor_hit_effect` | Trigger | nil | Effect triggered when hitting an attractor. |
| `time_to_damage` | uint16 | 0 | Delay before damage applies. |

**LightningProperties (per-planet):**

| Field | Notes |
|---|---|
| `lightnings_per_chunk_per_tick` | Frequency control |
| `lightning_multiplier_at_day` / `_at_night` | 0-1 range, controls day/night frequency |
| `exemption_rules` | Rules for entities exempt from lightning |
| `priority_rules` | Rules for lightning targeting priority |
| `search_radius` | How far lightning searches for targets |

**Non-destructive lightning approach:**
- **Option A**: Set `damage = 0` on the LightningPrototype. Lightning still fires visually but deals no damage. Use `strike_effect` trigger to script power drain instead.
- **Option B**: Use `exemption_rules` to exempt all player entities from lightning damage, while attractors still capture energy.
- **Option C**: Intercept via `on_entity_damaged` event, check damage type, heal entity back to full. Works but is reactive.

**Option A (damage=0 + strike_effect trigger) is the cleanest.** Lightning strikes, looks dramatic, feeds energy to attractors, and the strike_effect trigger can run a script that temporarily disables nearby power grid via `entity.active = false`.

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

**EMP implementation for Fulgora lightning:**
```
1. Lightning strikes (damage=0, no destruction)
2. strike_effect trigger fires script
3. Script identifies the affected electric network(s)
4. Drains all accumulators in the network: entity.energy = 0
5. Sets entity.active = false on consumers (machines), NOT poles --
   electric poles have no active state that gates power distribution,
   so toggling them does nothing
6. Registers on_nth_tick callback to re-enable machines after N ticks
7. Machines reactivate; the network resumes with empty accumulators
```

This is clean, reversible, and doesn't require destroying/recreating anything.

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
| Cargo rockets/platforms | **Yes** (Space Age) | Yes (cross-planet logistics) |

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
