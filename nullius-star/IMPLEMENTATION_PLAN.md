# Nullius Space Age -- Implementation Plan

> **Started**: 2026-03-23
> **Status**: Planning
> **Prerequisite reading**: DESIGN_DOC.md (current Nullius), SPACE_AGE_BRAINSTORM.md (SA design)
> **Dependency**: Requires Space Age DLC as mod dependency

---

## 0. Scope and Phasing

The implementation is split into phases that can each be developed, tested, and released incrementally. Each phase builds on the previous one. Later phases can be cut or deferred without breaking earlier ones.

| Phase | Content | Dependency |
|---|---|---|
| **Phase 0** | Infrastructure: multi-surface support, SA dependency, tech tree restructuring | None |
| **Phase 1** | Vulcanus: lava processing, spoilage cooldown, silicon insulation | Phase 0 |
| **Phase 2** | Fulgora: hydrocarbon ocean, lightning power, organic industry | Phase 0 |
| **Phase 3** | Gleba: bacterial loops, probabilistic breeding, bio-power | Phase 0 |
| **Phase 4** | Aquilo: monopoles, cryo chemistry, belt circulation | Phase 0 |
| **Phase 5** | Cross-planet: cargo rockets, combined research, interplanetary logistics | Phases 1-4 |
| **Phase 6** | Rogue: scouts, awakening, raids, countermeasures, The Solution | Phase 5 |
| **Phase 7** | Polish: balance, playtesting, maintenance mechanic, UPS optimization | All |

Phases 1-4 are independent of each other and can be developed in parallel or any order.

---

## Phase 0: Infrastructure

**Goal**: Get Nullius running with Space Age dependency, multiple surfaces, and the restructured tech tree. No new content yet -- just the skeleton.

### 0.1 SA Dependency and Compatibility

- [ ] Add `space-age` as required dependency in info.json
- [ ] Keep `quality` as incompatible
- [ ] Audit all existing Nullius prototypes for SA conflicts (new vanilla prototypes, renamed fields, etc.)
- [ ] Run existing Nullius on Factorio 2.0 + SA and catalog all errors/warnings
- [ ] Resolve prototype conflicts (SA adds new items, recipes, entities that may collide with Nullius names)

**Files affected**: `info.json`, `data.lua`, `data-updates.lua`, `data-final-fixes.lua`

**Risk**: SA may add prototypes that shadow or conflict with Nullius definitions. Need a full audit.

### 0.2 Planet Definitions

- [ ] Define PlanetPrototype for each planet (Vulcanus, Fulgora, Gleba, Aquilo, Rogue)
- [ ] Define SpaceConnectionPrototype between planets
- [ ] Define SurfacePropertyPrototype for custom properties (e.g., `nullius-maintenance-rate`, `nullius-lightning-intensity`)
- [ ] Define map generation settings per planet (resources, terrain, tiles)
- [ ] Disable/override SA's default planet definitions (we replace them entirely)

**Files to create**: `prototypes/planet/vulcanus.lua`, `prototypes/planet/fulgora.lua`, etc.

**Key decisions needed**:
- Planet distances and travel times
- Asteroid definitions for space connections
- Map gen settings (resource density, terrain types, starting area)

### 0.3 Tech Tree Restructuring

- [ ] Reorganize existing Nullius tech tree into Tier 1-4 (Nauvis-only, unchanged)
- [ ] Add probe reactivation techs (one per planet, Tier 4-5)
- [ ] Create placeholder tech branches per planet (hidden by default)
- [ ] Implement tech visibility system:
  - Script: on probe reactivation research complete, enable planet tech branch
  - Use `technology.enabled` + `technology.visible_when_disabled` runtime API
- [ ] Create planet-specific science pack item prototypes (metallurgic, petrochemical, biological, cryogenic)
- [ ] Create lab recipes accepting new pack types

**Files affected**: `prototypes/item/technology.lua` (major restructure), new `scripts/planets.lua`

### 0.4 Probe Reactivation System

- [ ] Define probe reactivation tech per planet (moderate Tier 4 cost)
- [ ] Script: on reactivation research, create starting entities on target planet surface
- [ ] Define broken equipment sets per planet (from BRAINSTORM.md tables)
- [ ] Extend existing broken equipment mechanic to work per-surface
- [ ] Implement consciousness transfer between surfaces (extend existing body.lua)

**Files affected**: `scripts/body.lua` (extend), `scripts/startup.lua`, new `scripts/probe.lua`

### 0.5 Generic Pack Alt Recipes

- [ ] Define alternative recipes for geology/mechanical/electrical packs per planet
- [ ] Use `surface_conditions` to restrict alt recipes to appropriate planets
- [ ] Set asymmetric pack multipliers on cross-planet techs (high planet-specific, low generic)

**Files to create**: `prototypes/item/planet_recipes.lua`

---

## Phase 1: Vulcanus

### 1.1 Resources and Terrain

- [ ] Define Vulcanus tile set (volcanic rock, lava, obsidian, fumarole terrain)
- [ ] Define lava fluid prototype (or reuse SA's if compatible)
- [ ] Define Vulcanus-specific resource patches (iron-in-lava, aluminum-in-lava, calcite deposits)
- [ ] Define map generation: abundant lava pools, fumarole clusters, no water

### 1.2 Lava Processing + Spoilage Cooldown

- [ ] Define "molten" item variants for each metal (molten-iron-bloom, molten-aluminum-bloom, etc.)
  - `spoil_ticks` = cooling time (tunable, maybe 1800-3600 ticks = 30-60 seconds)
  - `spoil_result` = solid ingot equivalent
- [ ] Define lava extractor entity (mines lava fluid)
- [ ] Define lava processing recipes: lava --> molten metal blooms
- [ ] Define water quenching recipes (later tech): molten + water --> instant solid
  - Requires imported water -- expensive via cargo
- [ ] Test spoilage chain: lava extraction --> molten items on belt --> cool into ingots

### 1.3 Silicon Insulation

- [ ] Define silicon-based insulation recipes (replace organic insulation on Vulcanus)
- [ ] Define silica extraction from volcanic rock
- [ ] Gate organic insulation recipes off Vulcanus via `surface_conditions`

### 1.4 Titanium Production Chain

- [ ] Design the Kroll process chain: TiO2 --> TiCl4 --> Ti reduction
- [ ] Define intermediate items (rutile, titanium tetrachloride, titanium sponge)
- [ ] Define recipes with appropriate crafting categories
- [ ] Gate behind Vulcanus metallurgic research + deep deposit access

### 1.5 Geothermal Power (Vulcanus variant)

- [ ] Reuse/extend existing Nullius geothermal entities for Vulcanus
- [ ] Abundant fumaroles in map gen -- power is not the challenge here
- [ ] Ensure geothermal works without water (volcanic gas direct conversion?)

### 1.6 Metallurgic Science Pack

- [x] Define pack recipe from Vulcanus-local materials (lava metals, volcanic compounds, cooled ingots)
- [ ] Define Vulcanus-specific research techs consuming metallurgic packs
- [ ] Set asymmetric multipliers (heavy metallurgic, light generic)

### 1.7 Demolishers (Late Vulcanus)

- [ ] Define custom SegmentedUnitPrototype for synthetic demolishers
- [ ] Define segment chain (head + body segments + tail) with custom graphics
- [ ] Script: player-initiated territory creation + demolisher spawning
- [ ] Script: patrol path control via `territory.set_patrol_path()`
- [ ] Define demolisher deployment item + recipe (requires Gleba bio-research)
- [ ] Define feeding mechanic (scripted periodic check, damage if not fed)
- [ ] Define deep rare-metal deposits that only demolishers can expose
- [ ] Territory management UI? (Or just map visualization)

**Dependency**: Demolisher deployment recipe requires Gleba bio-research. Can stub this initially.

---

## Phase 2: Fulgora

### 2.1 Resources and Terrain

- [ ] Define Fulgora tile set (hydrocarbon crust, fountain vents, fractured zones)
- [ ] Define raw hydrocarbon fluid prototype
- [ ] Define fountain entities (fixed map positions, produce raw hydrocarbon fluid)
- [ ] Define map generation: scattered fountains, no ore deposits, no water

### 2.2 Hydrocarbon Filtering

- [ ] Define filtration/distillation recipes: raw hydrocarbon --> ethylene, propene, methane, benzene, etc.
- [ ] Define trace metal extraction recipes with probabilistic outputs:
  - Use `probability` field on ItemProductPrototype
  - Iron dust, aluminum dust, silicon, sulfur, rare elements as low-probability outputs
- [ ] Define waste disposal recipes (dump unwanted traces back to ocean)
- [ ] Define filtration building entity (reuse/reskin chemistry plant?)

### 2.3 Lightning Power System

- [ ] Define Fulgora LightningPrototype with `damage = 0`
- [ ] Define `strike_effect` trigger that injects energy + runs overload check script
- [ ] Configure PlanetPrototype.lightning_properties for Fulgora
- [ ] Implement power pole as lightning attractor:
  - Option A: Test if compound entity works
  - Option B: Invisible attractor overlay spawned via script on pole placement
  - Option C: Use `priority_rules` to target poles
- [ ] Define super-capacitor entity (AccumulatorPrototype: high input_flow, low capacity, high drain)
- [ ] Define power sink entity (ElectricEnergyInterface: high constant consumption, tertiary priority)
- [ ] Implement overload detection script:
  - Track lightning energy injection via strike_effect
  - Compare against cached accumulator headroom
  - Trigger EMP on overload (entity.active = false on network, drain accumulators, timer to re-enable)
- [ ] Implement power sink spacing requirement (like wind turbine placement)

### 2.4 Organic Industry

- [ ] Define polymer/organic alternative recipes for standard items:
  - Polymer pipes, plastic gears, conductive polymer wire, organic glass
  - Use `surface_conditions` to restrict to Fulgora (or make available everywhere as alt recipes?)
- [ ] Define Fulgora-specific crafting machines (organic assembler? polymer furnace?)

### 2.5 Nuclear Geoengineering (Late Fulgora)

- [ ] Define nuclear charge item (requires cross-planet nuclear tech)
- [ ] Define detonation mechanic: place charge --> script transforms terrain in radius
  - Convert hydrocarbon crust tiles to fractured zone tiles
  - Spawn new hydrocarbon fluid sources in fractured zones
- [ ] Define surface filtering facility (large building, works on fractured zones, bulk filtration)

### 2.6 Petrochemical Science Pack

- [ ] Define pack recipe from Fulgora-local materials (hydrocarbon distillates, polymers, trace metals)
- [ ] Define Fulgora-specific research techs
- [ ] Set asymmetric multipliers

---

## Phase 3: Gleba

### 3.1 Resources and Terrain

- [ ] Define Gleba tile set (bacterial mats, fungal ground, sterile zones)
- [ ] Define harvestable bacterial mat resource (renewable, regrows)
- [ ] Define map generation: bacterial mat clusters, sparse minerals, low water, exotic atmosphere

### 3.2 Bacterial Resource Loop

- [ ] Define bacterial processing recipes: biomass --> trace iron/sulfur/silica
- [ ] Define closed-loop recipes that are net-negative (output slightly less than input)
- [ ] Define spoilage on bacterial products (failed/degraded cultures)
- [ ] Test: loop runs continuously but slowly depletes without breeding input

### 3.3 Probabilistic Breeding

- [ ] Define breeding chamber entity
- [ ] Define breeding recipes with probabilistic outputs:
  - Viable strain (probability ~0.60)
  - Failed strain (probability ~0.25, spoils into waste)
  - Variant strain (probability ~0.10)
  - Contamination event (probability ~0.05, triggers script effect?)
- [ ] Viable strains feed back into deterministic production loops
- [ ] Contamination handling: script that disrupts nearby production when contamination item produced?
- [ ] Define strain maintenance: bred strains spoil over long timescale, must be re-bred periodically

### 3.4 Bio-Power Progression

- [ ] Define biofilm galvanic cell item (crude battery, low capacity, spoils fast)
- [ ] Define microbial fuel cell entity (low power, decays via breeding maintenance)
- [ ] Define thermogenic bacteria strain + Stirling engine integration
- [ ] Ensure power generation is itself subject to breeding loop pressure

### 3.5 Complex Organisms (Late Gleba)

- [ ] Define incubation recipes for complex organisms
- [ ] Define premature hatch mechanic: low-probability output spawns entity via `spoil_to_trigger_result`?
- [ ] Define escaped organism entity (hostile, roams, consumes resources)
- [ ] Define containment infrastructure (walls, traps)
- [ ] Define successful organism types (living bio-factories, organism progenitors for Nauvis)

### 3.6 Biological Science Pack

- [ ] Define pack recipe from Gleba-local materials (bred strains, exotic enzymes)
- [ ] Define Gleba-specific research techs
- [ ] Set asymmetric multipliers

---

## Phase 4: Aquilo

### 4.1 Resources and Terrain

- [ ] Define Aquilo tile set (ammonia ice, frozen ground, crevasses)
- [ ] Define ammonia ocean fluid
- [ ] Define ice deposit resources (heavy water ice, deuterium ice, lithium deposits)
- [ ] Define map generation: ammonia ocean, ice fields, sparse surface features
- [ ] Enable `entities_require_heating` on Aquilo surface properties

### 4.2 Magnetic Monopoles

- [ ] Define monopole-north and monopole-south item prototypes
  - `spoil_result` = opposite polarity (north --> south, south --> north)
  - `spoil_ticks` = asymmetric! (north phase longer than south phase)
  - `fuel_category` = "nullius-monopole"
  - `burnt_result` = self (self-returning fuel cell)
  - `fuel_value` = heat output per reactor pass
- [ ] Define dredging entity (extracts monopoles from ammonia ocean)
- [ ] Implement diminishing returns on dredging:
  - Script: track monopole count per surface
  - Modify dredging recipe probability based on count (or swap recipe via script)
- [ ] Define induction heater entity (reactor-type, burns monopoles, produces heat, provides heated zone)
- [ ] Test belt circulation: monopole in --> reactor burn --> monopole out --> belt --> next reactor

### 4.3 Polarity Mechanics

- [ ] Verify spoilage oscillation works on belts (item type changes while in transit)
- [ ] Define north-only and south-only recipe/machine variants
- [ ] Test: polarity-filtered inserters route north vs south correctly
- [ ] Test: asymmetric spoil_ticks create unequal duty cycle
- [ ] Define fusion reactor variant that requires south-polarity monopoles for confinement

### 4.4 Cryogenic Chemistry

- [ ] Define ammonia processing recipes (local ammonia ocean --> useful chemicals)
- [ ] Define heavy water ice extraction --> deuterium + tritium chain
- [ ] Define lithium surface mining
- [ ] Define fusion fuel cell recipe (local deuterium + tritium, monopole-catalyzed)
- [ ] Define exotic cryogenic products (Aquilo-exclusive exports)

### 4.5 Cryogenic Science Pack

- [ ] Define pack recipe from Aquilo-local materials
- [ ] Define Aquilo-specific research techs
- [ ] Set asymmetric multipliers

---

## Phase 5: Cross-Planet Integration

### 5.1 Cargo Rockets

- [ ] Define/configure rocket silo for interplanetary launches
- [ ] Define cargo landing pads per planet
- [ ] Configure SpaceConnectionPrototype travel times and asteroid hazards
- [ ] Define space platform starter pack for Nullius
- [ ] Integrate boxing system with rocket cargo (boxed items for efficient shipping)

### 5.2 Combined Research

- [ ] Define Tier 7+ techs requiring packs from multiple planets
- [ ] Verify labs can accept all pack types simultaneously
- [ ] Balance: ensure combined-pack techs are genuinely gated behind cargo logistics
- [ ] Define sequential prerequisite techs for pre-cargo cross-planet research (Theory/Application split)

### 5.3 Cross-Planet Dependencies

- [ ] Vulcanus demolisher deployment needs Gleba bio-research (wire up prerequisite)
- [ ] Fulgora nuclear geoengineering needs Nauvis/Aquilo nuclear tech
- [ ] Gleba organism designs export to Nauvis for seeding missions
- [ ] Aquilo monopole exports to Nauvis for antimatter research
- [ ] Balance cross-planet trade flows (what ships where, in what volume)

---

## Phase 6: Rogue

### 6.1 Rogue Planet Definition

- [ ] Define Rogue as SpaceLocationPrototype (no surface, no landing)
- [ ] Script: destroy any space platform that arrives at Rogue (pre-Solution)
- [ ] Define space connection to Rogue (accessible but fatal)

### 6.2 Scout System

- [ ] Define scout entity prototype (small, fast, non-hostile, self-destructs)
- [ ] Script: periodic scout spawning on player surfaces after trigger milestone
  - Escalating frequency over time
  - Scouts roam near base perimeter
  - Self-destruct after timer, drop debris item
- [ ] Define scout debris item
- [ ] Define "Anomaly Debris Analysis" tech chain (3 tiers)
- [ ] Implement: analysis tier gates weapons research visibility

### 6.3 Weapons Tech (gated by planets + debris analysis)

- [ ] Define Nauvis weapons: gun turrets, ammo ("high-velocity material redistribution")
- [ ] Define Vulcanus weapons: artillery ("long-range overpressure vessel application")
- [ ] Define Fulgora weapons: laser turrets ("directed energy transfer devices")
- [ ] Define Gleba weapons: homing missiles ("autonomous navigating sample collectors")
- [ ] Gate each behind appropriate planet research + debris analysis tier
- [ ] Define weapon recipes using planet-specific materials

### 6.4 Rogue Awakening

- [ ] Define awakening trigger conditions (scout timer + milestone combination)
- [ ] Script: awakening event
  - Alert player across all surfaces
  - Enable countermeasure tech branch
  - Tease The Solution tech (visible_when_disabled = true)
  - Begin raid system

### 6.5 Raid System

- [ ] Define raid unit prototypes (adapted for each planet's environment)
- [ ] Script: periodic raid event generator
  - Escalating strength over time
  - Target selection (player infrastructure, especially labs/science)
  - Multi-planet simultaneous raids
- [ ] Define raid arrival mechanic (drop pods from orbit? scripted entity spawning?)
- [ ] Define countermeasure techs ("Offensive Use of Geoengineering Tools", etc.)
  - Each reduces raid severity but doesn't eliminate raids
- [ ] Balance: raid pressure should motivate The Solution research, not overwhelm the player

### 6.6 The Solution

- [ ] Define vacuum decay device recipe (components from all 5 planets)
- [ ] Define The Solution tech (enormous cost, requires all planet packs)
- [ ] Script: on vacuum decay device use/launch
  - Destroy Rogue planet
  - Convert to shattered asteroid field SpaceLocationPrototype
  - Cease all raids
  - Victory event / achievement
- [ ] Define post-shattering: asteroid field with exotic debris collection
- [ ] Define Rogue-tech fragments (researchable for final tech tier)

---

## Phase 7: Polish and Balance

### 7.1 Building Maintenance System

- [ ] Implement event-driven building registry
- [ ] Implement proportional maintenance damage (excess above threshold * rate)
- [ ] Tune per-building-type rules (active-only, always-on, etc.)
- [ ] Tune per-tier rates (tier 1 high, tier 3 low)
- [ ] Add configurable setting (off/low/standard/hardcore)
- [ ] Add per-planet maintenance modifiers
- [ ] UPS profiling at megabase scale

### 7.2 Balance Pass

- [ ] Playtest each planet independently (bootstrap to self-sufficiency)
- [ ] Playtest cross-planet progression (Tier 5 through endgame)
- [ ] Tune science pack costs and asymmetric multipliers
- [ ] Tune monopole diminishing returns curve
- [ ] Tune Gleba breeding probabilities and decay rates
- [ ] Tune Fulgora lightning frequency and overload thresholds
- [ ] Tune Vulcanus spoilage cooldown times
- [ ] Tune Rogue raid escalation curve
- [ ] Tune The Solution cost (should feel like a monumental achievement)

### 7.3 UPS Optimization

- [ ] Profile all scripted systems under megabase load:
  - Wind simulation (existing)
  - Lightning overload detection
  - Gleba breeding/decay
  - Monopole tracking
  - Maintenance system
  - Rogue raid spawning
- [ ] Optimize hot paths (amortize, cache, reduce entity iteration)
- [ ] Target: <1ms total script overhead per tick at 5000+ entities per surface

### 7.4 UI and Polish

- [ ] Informatron pages per planet (in-game guide)
- [ ] Planet-specific tips and tutorials
- [ ] Achievement definitions
- [ ] Locale strings for all new content (EN first, then translations)
- [ ] Graphics: placeholder --> final for all new entities/items
- [ ] Sound design for planet-specific ambience

### 7.5 Mod Compatibility

- [ ] Audit existing 40+ optional mod integrations for SA compatibility
- [ ] Update mods.lua conditional blocks for new planet content
- [ ] Test with common companion mods (Factorissimo2, jetpack, miniloader, etc.)

---

## Technical Risks and Open Questions

### High Risk
- [ ] **Can a single entity be both ElectricPole and LightningAttractor?** If not, need invisible overlay approach for Fulgora. Test early.
- [ ] **Spoilage oscillation on belts**: Does item type change propagate correctly when items are on belts/in inserter hands? Could cause sorting/filtering issues. Test early.
- [ ] **Scripted territory creation for player-spawned demolishers**: Does `regenerate_segmented_units()` work on script-created territories? Verify.
- [ ] **Performance of overload detection script**: How often can we check electric network state without UPS impact?

### Medium Risk
- [ ] **SA prototype conflicts**: How many Nullius prototypes collide with SA additions? Could be trivial or massive.
- [ ] **Existing Nullius scripts vs multiple surfaces**: Do wind.lua, geothermal.lua, solar.lua etc. work correctly when multiple surfaces exist? Probably need per-surface data tables.
- [ ] **Monopole belt circulation timing**: Does spoilage timer pause/reset in any context (inserter hand, machine input slot, chest) that would break the polarity oscillation?
- [ ] **Raid spawning on multiple surfaces**: Can we reliably create enemy entities on player surfaces without desync in multiplayer?

### Low Risk
- [ ] **Tech visibility toggling**: Well-supported API, Nullius already uses similar patterns.
- [ ] **Probabilistic recipes**: Base 2.0 feature, well-tested.
- [ ] **Planet definitions**: Well-documented, major modding use case.

---

## Estimated Effort

| Phase | Scope | Rough Estimate |
|---|---|---|
| Phase 0 | Infrastructure | Large (tech tree restructure is the bulk) |
| Phase 1 | Vulcanus | Medium (spoilage is simple, titanium chain is complex) |
| Phase 2 | Fulgora | Large (lightning scripting, overload detection, organic alt recipes) |
| Phase 3 | Gleba | Large (breeding system is novel, lots of scripting) |
| Phase 4 | Aquilo | Medium-Large (monopole mechanics need careful testing) |
| Phase 5 | Cross-planet | Medium (mostly wiring up existing systems) |
| Phase 6 | Rogue | Large (raid system is entirely new, The Solution is complex) |
| Phase 7 | Polish | Ongoing (balance is iterative) |

**Total**: This is a very large project. Phases 1-4 can be developed independently and released incrementally.

---

*This plan will be updated as implementation progresses and technical risks are resolved.*
