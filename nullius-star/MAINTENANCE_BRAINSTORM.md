# Building Maintenance / Degradation -- Brainstorm

> **Status**: Tentative. May be implemented as a separate companion mod.
> **Extracted from**: SPACE_AGE_BRAINSTORM.md (was section 10)

## Anti-Scaling: Building Maintenance / Degradation

**Problem**: Nullius provides multiple tiers of buildings, but nothing mechanically prevents players from just spamming 500 tier-1 wind turbines instead of upgrading to tier-3. Infinite horizontal scaling with low-tier buildings is boring, UPS-hostile, and bypasses the intended progression.

### 10.1 Core Mechanic: Periodic Maintenance Damage

Every N ticks, a script scans buildings of certain types and applies damage to a percentage of them. Buildings that aren't repaired eventually break. This forces either:
- **Upgrade to fewer, higher-tier buildings** (less total maintenance)
- **Invest in repair infrastructure** (construction bots, repair packs)
- **Actively maintain** (personal bots for medium bases, can't AFK indefinitely)

### 10.2 Rules

**Threshold protection (bootstrap safety):**
- If total count of a building type on a surface is below a threshold, NO maintenance damage is applied
- Example: first 20 wind turbines are maintenance-free. Turbine #21+ starts taking damage.
- Prevents early-game pain when the player has 3 turbines and no repair bots
- Threshold scales per tier: tier-3 turbines have a higher free threshold than tier-1

**Per-building-type rules:**

| Building Type | When Damaged | Rationale |
|---|---|---|
| **Assemblers** | Only while actively crafting | Idle machines don't wear out |
| **Wind turbines** | Always (when generating) | Moving parts wear constantly |
| **Solar panels** | Daytime only | Thermal cycling from sun exposure |
| **Accumulators** | Always | Charge/discharge degradation |
| **Furnaces** | Only while smelting | Thermal stress |
| **Miners** | Only while mining | Mechanical wear |
| **Labs** | Only while researching | Precision instrument degradation |
| **Inserters** | Only while moving items | Mechanical wear |
| **Pipes/belts** | Never (or very slow) | Static infrastructure, no moving parts to speak of |
| **Beacons** | Always when active | High-energy field stress |

**Tier scaling:**

| Tier | Maintenance Rate | Design Intent |
|---|---|---|
| Tier 1 | High (fast degradation) | Discourages mass deployment |
| Tier 2 | Medium | Standard maintenance burden |
| Tier 3 | Low | Reward for upgrading |
| Tier 4+ | Very low / none | Endgame buildings are robust |

This creates a soft cap: 100 tier-1 turbines need constant bot repair, while 10 tier-3 turbines with equivalent output barely degrade. The "optimal" play is to upgrade, not to scale.

### 10.3 Implementation Strategy

**Reference: Space Exploration's robot attrition**

SE's approach is instructive -- it does NOT degrade buildings at all. Instead it probabilistically destroys robots per action (event-driven, stateless, O(1) per event). Key lessons:
- **Event-driven >> tick-driven.** No `on_tick` iteration. Piggyback on existing game events.
- **Stateless probability checks.** No per-entity tracking, no registry, no surface scans.
- **Per-surface rates.** Different attrition on different planets via cached zone data.
- **Players accepted it** because it created meaningful logistics pressure without feeling arbitrary.

**Applying SE's lessons to building maintenance:**

The problem: buildings don't fire per-action events the way robots do. An assembler that runs continuously doesn't trigger "I just finished a craft" in a way that's easy to hook. We need a different approach.

**Recommended: Event-driven registry + proportional tick processing**
```lua
-- Registry populated via events (O(1) per build/remove):
on_built_entity: add to registry[entity.name][surface.index]
on_entity_died:  remove from registry

-- Proportional maintenance (scales with building count):
on_nth_tick(60):  -- every second
  for each building_type in maintenance_types:
    local count = #registry[building_type]
    if count > threshold[building_type] then
      local excess = count - threshold[building_type]
      local damage_events = math.ceil(excess * rate_per_tick[building_type])
      for i = 1, damage_events do
        local target = registry[building_type][math.random(count)]
        if should_damage(target) then  -- active check
          target.health = target.health - damage_for_tier(target)
        end
      end
    end
```

**Scaling behavior:**
- 20 turbines (at threshold=20): 0 damage events per cycle. Free.
- 50 turbines (30 excess): ~1-2 damage events per cycle. Manageable.
- 200 turbines (180 excess): ~5-10 damage events per cycle. Need repair bots.
- 1000 turbines (980 excess): ~30-50 damage events per cycle. Serious bot infrastructure or upgrade to tier 3.

The `rate_per_tick` is a small fraction (e.g., 0.02-0.05 for tier-1), so damage events scale linearly with excess count above threshold. Double your buildings beyond threshold = double your maintenance burden.

**Cost**: O(damage_events) per second, which is O(excess_buildings * rate). At 1000 excess tier-1 buildings with rate 0.03, that's ~30 health writes per second -- still negligible UPS. At 5000 excess, ~150/sec -- starting to matter but still manageable. The player should have upgraded to tier-3 long before hitting 5000 tier-1 of anything.

**The scaling creates the right pressure curve:**
```
Buildings:   |---threshold---|--------linear scaling-------->
Maintenance: [    zero      ] [proportional to excess count ]
Feel:        [ comfortable  ] [ upgrade or invest in repair ]
```

**Alternative: Quadratic scaling for aggressive anti-spam**
```lua
local damage_events = math.ceil(excess * excess * tiny_rate)
```
Quadratic makes the first few excess buildings nearly free but 10x buildings = 100x maintenance. Extremely punishing for mass tier-1 spam. Possibly too aggressive -- linear is probably sufficient and more predictable for players.

### 10.4 Repair Burden at Different Base Sizes

| Base Size | Building Count | Maintenance Events/min | Repair Solution |
|---|---|---|---|
| **Bootstrap** (<threshold) | <20 per type | 0 | None needed |
| **Small** (20-50) | 50-200 total | ~5-10 | Occasional manual repair |
| **Medium** (50-200) | 200-1000 total | ~20-50 | Personal roboport + repair packs |
| **Large** (200-1000) | 1000-5000 total | ~100-250 | Roboport network + bot army |
| **Megabase** (1000+) | 5000+ total | ~500+ | Massive bot infrastructure OR upgrade to high-tier buildings |

**The intended pressure**: At megabase scale with tier-1 buildings, maintenance becomes a serious logistics challenge. Upgrading to tier-3 reduces building count by ~3-5x AND reduces per-building maintenance rate, compounding the benefit.

### 10.5 Interaction with Other Planet Mechanics

Maintenance could scale differently per planet:

| Planet | Maintenance Modifier | Rationale |
|---|---|---|
| **Nauvis** | Standard (1x) | Baseline |
| **Vulcanus** | Higher for non-heat-resistant buildings | Thermal stress from volcanic heat |
| **Fulgora** | Higher after lightning strikes (EMP damage) | Already covered by EMP mechanic? Or additive. |
| **Gleba** | Biological corrosion from atmosphere | Organic acid damage to metal infrastructure |
| **Aquilo** | Higher without heating | Cold-stress cracking on unheated buildings |

Could use `surface_conditions` or custom surface properties to modify maintenance rates per planet.

### 10.6 Open Questions

- Should maintenance be a flat HP drain or percentage-based? Flat favors high-HP buildings; percentage is tier-neutral.
- Should destroyed-by-maintenance buildings drop loot (recoverable) or just vanish?
- How does maintenance interact with the boxing system? Are boxers subject to maintenance?
- Should repair packs be consumed faster on hostile planets?
- Can maintenance be a configurable setting (off/low/standard/hardcore) for player preference?
- Does this mechanic make the game feel tedious rather than challenging? Needs playtesting.
- **Engine cost verification needed**: Profile the event-driven registry approach at 5000+ buildings to confirm UPS impact is acceptable.
- Should buildings warn the player (flashing icon, alert) before dying from maintenance, or just quietly degrade?
- How does this interact with the broken equipment start mechanic? Broken buildings shouldn't additionally take maintenance damage.

**Status**: Tentative. Core idea is sound (force tier upgrades, prevent infinite scaling), but risk of feeling like busywork. Needs prototyping and playtesting to find the fun-to-tedium ratio.

