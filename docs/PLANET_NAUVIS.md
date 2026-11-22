# Nauvis design

## 1. Role

Nauvis is the starting planet and the primary terraforming target. Its industrial path runs through Tier 4. Probe research opens parallel branches before chemical science. Terraforming, paving, excavation, biological seeding and carbon sequestration drones operate on Nauvis. The oxygen mission counts gas production and use on Nauvis.

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

### 2.2 Interplanetary Signal Acquisition

**Probe reactivation tech**: "Interplanetary Signal Acquisition"

| Field | Value |
|---|---|
| **Order** | nullius-df (between sensors-1 and broadcasting-1) |
| **Prerequisites** | nullius-sensors-1, nullius-signal-processing, nullius-computation |
| **Cost** | count=50, time=25 |
| **Packs** | geology x1, climatology x1, mechanical x1, electrical x1 |
| **Essential** | true |
| **Unlocks** | Probe reactivation sub-techs (one per planet) |

Why this window:

| Player state | Consequence |
|---|---|
| Four packs: geology, climatology, mechanical, electrical | Enough industry to support a second planet |
| Sensors, signal processing and computation researched | The android can detect, decode and process the probe signals |
| No chemical pack yet | Planets give the player something to build during the cost spike before Experimental Chemistry |
| No beacons, robotics or advanced logistics | Each planet bootstrap is a real challenge |
| Moderate cost | Noticeable without becoming a major gate; planets feel part of the core game, not an endgame addition |

### 2.3 Per-Planet Reactivation

Each probe requires Interplanetary Signal Acquisition. A research unit uses one each of geology, climatology, mechanical and electrical science. Aquilo also needs one chemical pack.

| Destination | Signal recovery | Additional prerequisite | Units | Seconds per unit |
|---|---|---|---:|---:|
| [Vulcanus](PLANET_VULCANUS.md) | Volcanic | Metallurgy 2 | 30 | 20 |
| [Fulgora](PLANET_FULGORA.md) | Electromagnetic | Insulation 1 | 30 | 20 |
| [Gleba](PLANET_GLEBA.md) | Biological | Organic Chemistry 1 | 40 | 20 |
| Aquilo | Cryogenic | Experimental Chemistry and the thermal-tank checkpoint | 80 | 30 |
| Rogue | Unidentified | None | 15 | 10 |

**Rogue signal**

- Appears alongside the other planet reactivation techs. Cheap to research (15 count -- why not try it?).
- On completion: "Signal transmitted. No response received. Probe status: INDETERMINATE. Recommend: deprioritize and revisit."
- No surface created. No tech branch revealed. No consciousness transfer. Just a log entry.
- The android files it as a low-priority anomaly and moves on.
- **30+ hours later**: scouts appear. The player (maybe) remembers the probe that didn't respond.
- **After Rogue awakening**: the tech description retroactively updates to "Signal transmitted. Response received [HOSTILE]. See: Anomaly Countermeasures."

This plants the seed early without spoiling anything. Players who pay attention to flavor text get a "holy shit" moment when the connection clicks. Players who skip flavor text never notice until the scouts arrive.

### 2.4 Probe body access

Volcanic, electromagnetic and biological signal recovery each activate a probe.

1. The force gains access to the destination.
2. The surface is created if absent. Each force receives one wreck and one idle android.
3. The player can transfer to the idle android after research.
4. Any player in that force can transfer to the idle android. An occupied body cannot be taken.
5. The `/nullius-vulcanus` command transfers its caller if the probe body is idle. A later caller receives an occupied-body message.
6. Late joins receive access to the same body. Repeated activation and reconnects do not create more supplies.

In Alignment mode, quick-start waits for the faction landing.

## 3. Nauvis research

### 3.1 Industrial tiers

| Tier | Order Range | Content | SA Impact |
|---|---|---|---|
| 1-2 | b*, c* | Basic industry through mechanical pack | None |
| 3 early | d* (da-de) | Electrical engineering, sensors, computation | Probe reactivation inserted here |
| 3 late | d* (df-dl) | Broadcasting, empiricism-2 | None |
| 3-4 gate | e* (ea-eb) | Experimental chemistry (chemical pack) | Aquilo reactivation gated here |
| 4 | e* | Chemical pack era, nanotechnology | None |

### 3.2 Tier 5

| Industry | Progression |
|---|---|
| Nuclear power 1-4 (all on Nauvis) | Shared reactor; fusion on Nauvis, advanced by Aquilo; fission from Gleba uranium. See [Nuclear branches](SPACE_AGE_BRAINSTORM.md#nuclear-branches) |
| Asteroid mining (abstract, Nauvis) | Removed with Nauvis ore renewal; Vulcanus and Fulgora supply infinite ores. See [Asteroid mining removal](SPACE_AGE_BRAINSTORM.md#asteroid-mining-removal) |
| Copper from asteroids | Import copper from Fulgora, its sole primary source; see [Fulgora design](PLANET_FULGORA.md#late-game-copper) |
| Rocket science (Nauvis) | Rocket science moves to the start of the physics tier and enables orbital lift; space platforms carry cross-planet cargo. See [Launch vehicle](SPACE_AGE_BRAINSTORM.md#46-launch-vehicle) |
| Physics pack (complex machines) | Nauvis keeps its ordinary recipe. Gleba makes physics packs locally at Physics. |

### 3.3 New Tier 6+ Content (SA additions)

| Tier | Content | Packs Required |
|---|---|---|
| 5 | Planet-specific research (heavy planet pack, light generic) | 1 planet pack + generic |
| 6 | Cross-planet chains (sequential Theory/Application) | 1 planet pack per technology, local generic packs |
| 7 | Combined research (one lab, needs cargo) | 2+ planet packs + Nauvis packs |
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

## 4. Cargo

### Exports

Once cargo is available, Nauvis exports:

| Export | Destination | Purpose |
|---|---|---|
| Water | Vulcanus, Fulgora | Both lack water. Critical import. |
| Basic science packs | All planets | Supplement local generic pack production |
| Manufactured goods | All planets | Electronics, motors, pipes -- Nauvis has the most diverse industry |
| Antimatter (late game) | The Solution | Produced from monopole-catalyzed proton decay research |
| Construction kits | New planet outposts | Pre-packaged building sets for rapid deployment |

### Imports

| Import | Source | Purpose |
|---|---|---|
| Rutile or titanium ingots | Vulcanus | Replaces punitive synthetic rutile for scalable advanced alloys and heat-resistant equipment |
| Advanced polymers | Fulgora | Organic electronics, advanced chemistry |
| Exotic biochemicals | Gleba | Advanced biology packs, organism progenitors |
| Tritium, lithium, fusion cells | Aquilo | Solves nuclear bottleneck |
| Monopoles | Aquilo (if exportable) | Antimatter research, The Solution |
| Rogue-tech fragments | Shattered planet | Final tech tier (post-Solution) |

---

## 5. Target progression time

| Hours (approx) | Phase | SA Content |
|---|---|---|
| 0-10 | Bootstrap | No SA content. Standard Nullius. |
| 10-20 | Tier 2-3 | Probe reactivation becomes available (~hour 15-20). |
| 15-25 | First planet access | Vulcanus or Fulgora reactivated. Painful bootstrap begins. |
| 20-30 | Second planet | Both Vulcanus and Fulgora active. Gleba accessible. |
| 25-40 | Chemical pack era | Aquilo accessible (requires chemical pack). Planet-specific research flowing. |
| 30-50 | Multi-planet industry | All 4 planets bootstrapped. Planet-specific research accelerating. |
| 40-60 | Rockets and space platforms | Interplanetary logistics. Cross-planet trade begins. Combined research. |
| 50-80 | Scouts appear | Foreshadowing. Weapons research unlocked. Defense preparation. |
| 60-100 | Rogue awakening | Raids begin. Countermeasure research. Multi-planet defense. |
| 80-150 | The Solution | All-planet combined effort. Vacuum decay device construction. |
| 150+ | Post-Rogue | Shattered planet debris. Rogue-tech research. Infinite research. |

## 6. Unresolved design decisions

| Decision | Options |
|---|---|
| Rogue scouts | How scout visits fit the minimal-combat design of Nauvis |
| Probe hardware | Whether probe reactivation needs a placed transmitter building or stays a research unlock |
| Simultaneous probes | Whether every planet probe can be active at once, or reactivation is sequential or on a cooldown |
