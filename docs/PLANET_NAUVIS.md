# Nullius SA: Nauvis -- Planet Design Document

> **Status**: Mixed: Vulcanus access and optional thermal branches implemented; other planet and endgame sections are design only
> **Role**: Home planet. Primary terraforming target. Industrial foundation.

---

## 1. Nauvis Role in SA

Nauvis remains the starting planet and primary terraforming objective. The
existing critical path remains available while optional Space Age branches
begin in mid Tier 3, after the player has established core industry but before
the chemical pack.

**What stays the same**: Existing Nullius production and research remain the
Nauvis critical path through Tier 4.

**What changes now**: Signal acquisition and Vulcanus probe recovery add a
parallel branch. Vulcanus research unlocks optional heat-powered versions of
corresponding Nauvis crushers, furnaces, and foundries.

**Design only**: Other planet branches, cargo logistics, biology or nuclear
redistribution, and Rogue content.

---

## 2. Probe Reactivation: When and How

### 2.1 Insertion Point in the Tech Tree

The tech tree progression (with order codes from technology.lua):

```
TIER 1-2 (order nullius-b*, nullius-c*):
  Geology, climatology, mechanical packs
  Basic industry, wind power, water processing
  [NO CHANGES]

TIER 3 EARLY (order nullius-d*):
  nullius-electrical-engineering (order db) -- unlocks electrical pack
  nullius-empiricism-1 (order dc) -- unlocks lab-1 (count=5, 4 packs, time=10)
  nullius-signal-processing (order dd) -- red wire, antenna (count=12, 2 packs)
  nullius-sensors-1 (order de) -- sensor-1 (count=30, 4 packs, time=20)
  nullius-computation (order de) -- circuit network, combinators

  >>> PROBE REACTIVATION WINDOW <<<

  nullius-empiricism-2 (order dl) -- lab speed +20% (count=180, 4 packs, time=30)
  nullius-broadcasting-1 (order dh) -- beacons (count=100, 2 packs)

TIER 3 LATE (order nullius-e*):
  nullius-experimental-chemistry (order eb) -- chemical pack (count=250, 4 packs)
  [Major cost spike, gates Tier 4]
```

### 2.2 Recommended: After sensors-1, before empiricism-2

**Probe reactivation tech**: "Interplanetary Signal Acquisition"

| Field | Value |
|---|---|
| **Order** | nullius-df (between sensors-1 and broadcasting-1) |
| **Prerequisites** | nullius-sensors-1, nullius-signal-processing, nullius-computation |
| **Cost** | count=50, time=25 |
| **Packs** | geology x1, climatology x1, mechanical x1, electrical x1 |
| **Essential** | true |
| **Unlocks** | Probe reactivation sub-techs (one per planet) |

**Rationale for this position:**
- Player has **4 science packs** (geology, climatology, mechanical, electrical) -- enough infrastructure to be established
- Player has **sensors** (can detect signals) and **signal processing** (can decode them) and **computation** (can process the data) -- narratively justified
- Player does NOT yet have chemical pack (250-count spike ahead) -- planets provide something to do during that grind
- Player does NOT yet have beacons, robotics, or advanced logistics -- planets feel like a genuine challenge to bootstrap
- Cost is moderate (50 count with 4 packs) -- noticeable but not a major gate
- **Early enough** that planets feel like part of the core game, not endgame bolted on

### 2.3 Per-Planet Reactivation

After the umbrella "Interplanetary Signal Acquisition" tech, each planet has its own reactivation tech:

| Planet | Tech Name | Prerequisites | Cost | Status |
|---|---|---|---|---|
| **Vulcanus** | Volcanic Probe Signal Recovery | Interplanetary Signal Acquisition, metallurgy 2 | count=30; geology, climatology, mechanical, electrical x1; time=20 | Implemented |
| **Fulgora** | Electromagnetic Probe Signal Recovery | Interplanetary Signal Acquisition, insulation 1 | count=30, 4 packs | Design only |
| **Gleba** | Biological Probe Signal Recovery | Interplanetary Signal Acquisition, organic chemistry 1 | count=40, 4 packs | Design only |
| **Aquilo** | Cryogenic Probe Signal Recovery | Interplanetary Signal Acquisition, experimental chemistry, thermal-tank checkpoint | count=80, 5 packs | Design only |
| **Rogue** | Unidentified Probe Signal Recovery | Interplanetary Signal Acquisition | count=15, 4 packs | Design only |

**Proposed Rogue reactivation -- the dead end:**
- Appears alongside the other planet reactivation techs. Cheap to research (15 count -- why not try it?).
- On completion: "Signal transmitted. No response received. Probe status: INDETERMINATE. Recommend: deprioritize and revisit."
- No surface created. No tech branch revealed. No consciousness transfer. Just a log entry.
- The android files it as a low-priority anomaly and moves on.
- **30+ hours later**: scouts appear. The player (maybe) remembers the probe that didn't respond.
- **After Rogue awakening**: the tech description retroactively updates to "Signal transmitted. Response received [HOSTILE]. See: Anomaly Countermeasures."

This plants the seed early without spoiling anything. Players who pay attention to flavor text get a "holy shit" moment when the connection clicks. Players who skip flavor text never notice until the scouts arrive.

**Proposed unlock order after Vulcanus**:
- Vulcanus and Fulgora: Available immediately after signal acquisition. Can be researched with 4 packs.
- Rogue: Available immediately. Cheap. Dead end (for now).
- Gleba: Slightly later (needs organic-chemistry-1 which is Tier 3).
- Aquilo: Requires chemical pack (Tier 4 gate). Player should have experience on other planets first.

### 2.4 Implemented Vulcanus Reactivation

When Vulcanus probe recovery is researched:

1. Vulcanus is unlocked for the force.
2. The surface and landing wreck are created if absent.
3. A new android body receives the probe equipment.
4. Player control transfers to that body.

---

## 3. Proposed Nauvis Tech Tree Modifications After the Current Slice

### 3.1 Existing Tiers (Unchanged)

| Tier | Order Range | Content | SA Impact |
|---|---|---|---|
| 1-2 | b*, c* | Basic industry through mechanical pack | None |
| 3 early | d* (da-de) | Electrical engineering, sensors, computation | Probe reactivation inserted here |
| 3 late | d* (df-dl) | Broadcasting, empiricism-2 | None |
| 3-4 gate | e* (ea-eb) | Experimental chemistry (chemical pack) | Aquilo reactivation gated here |
| 4 | e* | Chemical pack era, nanotechnology | None |

### 3.2 New Tier 5 Split (Modified)

Currently, Tier 5 is physics pack + nuclear + rocket + asteroid mining. With SA:

| Current Tier 5 | SA Tier 5 |
|---|---|
| Nuclear power 1-4 (all on Nauvis) | Nuclear power 1-2 on Nauvis, 3-4 benefit from Aquilo |
| Asteroid mining (abstract, Nauvis) | Asteroid mining moved to space platform / Rogue aftermath |
| Rocket science (Nauvis) | Rocket science enables cargo rockets (cross-planet logistics) |
| Physics pack (complex machines) | Physics pack stays on Nauvis |

### 3.3 New Tier 6+ Content (SA additions)

| Tier | Content | Packs Required |
|---|---|---|
| 5 | Planet-specific research (heavy planet pack, light generic) | 1 planet pack + generic |
| 6 | Cross-planet techs (sequential Theory/Application) | 2 planet packs (researched separately per planet) |
| 7 | Combined research (simultaneous multi-pack, needs cargo) | 3-4 planet packs + Nauvis packs |
| 8 | Rogue countermeasures and The Solution | All packs |

### 3.4 Weapons Tech Branch (Hidden Until Scouts)

| Tech | Prerequisites | Packs | Planet Gate |
|---|---|---|---|
| Anomaly Debris Analysis 1 | Scout debris item produced | 4 Nauvis packs | Nauvis |
| High-Velocity Material Redistribution | Analysis 1 | 4 Nauvis packs + mechanical | Nauvis |
| Anomaly Debris Analysis 2 | Analysis 1 + time/more debris | 4 Nauvis packs | Nauvis |
| Long-Range Overpressure Vessels | Analysis 2 | Metallurgic + mechanical | Vulcanus |
| Directed Energy Transfer Devices | Analysis 2 | Petrochemical + electrical | Fulgora |
| Anomaly Debris Analysis 3 | Analysis 2 + time/more debris | 5 packs | Nauvis |
| Autonomous Navigating Sample Collectors | Analysis 3 | Biological + chemical | Gleba |

---

## 4. Nauvis-Specific Numbers

### 4.1 Implemented Research

| Technology | Count | Packs per unit | Time | Status |
|---|---:|---|---:|---|
| Interplanetary Signal Acquisition | 50 | geology 1, climatology 1, mechanical 1, electrical 1 | 25s | Implemented |
| Volcanic Probe Signal Recovery | 30 | geology 1, climatology 1, mechanical 1, electrical 1 | 20s | Implemented |

### 4.2 Proposed Probe Reactivation Costs

| Tech | Count | Packs | Time | Total Science (approx) |
|---|---|---|---|---|
| Electromagnetic Probe Signal Recovery | 30 | geo+clim+mech+elec x1 each | 20s | 120 packs total |
| Biological Probe Signal Recovery | 40 | geo+clim+mech+elec x1 each | 20s | 160 packs total |
| Cryogenic Probe Signal Recovery | 80 | geo+clim+mech+elec+chem x1 each | 30s | 400 packs total |
| Unidentified Probe Signal Recovery | 15 | geo+clim+mech+elec x1 each | 10s | 60 packs total |

### 4.3 Proposed Nauvis Exports (Post-Cargo)

Once cargo rockets are available, Nauvis exports:

| Export | Destination | Purpose |
|---|---|---|
| Water | Vulcanus, Fulgora | Both lack water. Critical import. |
| Basic science packs | All planets | Supplement local generic pack production |
| Manufactured goods | All planets | Electronics, motors, pipes -- Nauvis has the most diverse industry |
| Antimatter (late game) | The Solution | Produced from monopole-catalyzed proton decay research |
| Construction kits | New planet outposts | Pre-packaged building sets for rapid deployment |

### 4.4 Proposed Nauvis Imports (Post-Cargo)

| Import | Source | Purpose |
|---|---|---|
| Rutile or titanium ingots | Vulcanus | Replaces punitive synthetic rutile for scalable advanced alloys and heat-resistant equipment |
| Advanced polymers | Fulgora | Organic electronics, advanced chemistry |
| Exotic biochemicals | Gleba | Advanced biology packs, organism progenitors |
| Tritium, lithium, fusion cells | Aquilo | Solves nuclear bottleneck |
| Monopoles | Aquilo (if exportable) | Antimatter research, The Solution |
| Rogue-tech fragments | Shattered planet | Final tech tier (post-Solution) |

---

## 5. Proposed Nauvis Timeline with SA

| Hours (approx) | Phase | SA Content |
|---|---|---|
| 0-10 | Bootstrap | No SA content. Standard Nullius. |
| 10-20 | Tier 2-3 | Probe reactivation becomes available (~hour 15-20). |
| 15-25 | First planet access | Vulcanus or Fulgora reactivated. Painful bootstrap begins. |
| 20-30 | Second planet | Both Vulcanus and Fulgora active. Gleba accessible. |
| 25-40 | Chemical pack era | Aquilo accessible (requires chemical pack). Planet-specific research flowing. |
| 30-50 | Multi-planet industry | All 4 planets bootstrapped. Planet-specific research accelerating. |
| 40-60 | Cargo rockets | Interplanetary logistics. Cross-planet trade begins. Combined research. |
| 50-80 | Scouts appear | Foreshadowing. Weapons research unlocked. Defense preparation. |
| 60-100 | Rogue awakening | Raids begin. Countermeasure research. Multi-planet defense. |
| 80-150 | The Solution | All-planet combined effort. Vacuum decay device construction. |
| 150+ | Post-Rogue | Shattered planet debris. Rogue-tech research. Infinite research. |

---

## 6. Open Questions (Nauvis-specific)

- Should existing Nullius biology packs remain fully producible on Nauvis, or should advanced bio-packs (dendrology, zoology, evolution) require Gleba inputs?
- Should Nauvis asteroid mining be removed/relocated to space platforms, or kept as a parallel path?
- Should the oxygen mission remain Nauvis-only, or extend to terraforming other planets?
- How does the Rogue scout spawning interact with Nauvis's existing minimal-combat design?
- Should probe reactivation require a physical item (transmitter building) or just be a tech unlock?
- Should the player be able to reactivate all planet probes simultaneously, or is there a cooldown/sequential constraint?

---
