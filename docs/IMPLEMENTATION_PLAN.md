# Nullius* implementation status

Release `0.0.7`, reviewed 2026-11-17.

## Authority

| Scope | Authority |
|---|---|
| Planet validation | [Vulcanus](validation/vulcanus.md), [Fulgora](validation/fulgora.md), [Gleba](validation/gleba.md) |
| Implemented mechanics | Resolved prototypes and runtime scenario results |
| Planet mechanics and progression | Planet design documents |
| Other planets and endgame | Space Age brainstorming document |
| Factorio 2.1 migration | [Port assessment](FACTORIO_2_1_PORT.md) |

## Implemented mechanics

| Area | Implemented contract | Evidence |
|---|---|---|
| Space Age load | Nullius* requires Factorio and Space Age 2.1.20 or later in the 2.1 series. Quality is incompatible. | Strict prototype load |
| Planet access | Probe research gives access to Vulcanus, Fulgora and Gleba. Each force gets one wreck and one shared android on each planet it unlocks. The quick-start command transfers its caller. | Activation and shared-body scenarios |
| Bootstrap | Free lava intake and diminishing-return gas vent prime a net-positive lava-gas loop | Vent-prime and gas-self-power scenarios |
| Pneumatic factory | Eligible non-heavy-industry machines switch on Vulcanus through the common transition system; working machines expose correctly sized process-heat interfaces | Pneumatic lifecycle scenarios |
| Local materials | Lava separation, bloom cooling, aluminum reduction, sulfur catalysis, inorganic barrels, renewable graphite, alkali, lubricant, glass, concrete, sulfuric acid, boric acid, and metallic sodium are reachable without seawater, organic chemistry, or electricity | Production scenarios and prerequisite manifests |
| Local science | Geology, climatology, mechanical, electrical, chemical, bootstrap metallurgic, and efficient metallurgic packs are producible | Science-production scenarios |
| Thermite explosives | Inorganic chlorine, sulfur dioxide, aluminum powder, circuitry, and a disposable miner produce stable cliff explosives without electricity or organic chemistry | Thermite scenario and prerequisite manifest |
| Hot casting | Hot metalworking unlocks thermal casting of iron and aluminum blooms before spoilage. Water quenching increases iron and aluminum plate and rod yields. | Hot-casting and water-quenching scenarios, prerequisite manifests, and planner comparison |
| Refractory production | Local mineral byproducts become refractory mix and bricks for organic-free tier-2 heat pipes and improved high-temperature radiators | Refractory-production scenario and prerequisite manifest |
| Titanium pilot | Synthetic rutile and TiCl4 feed aluminothermic reduction; chloride recovery and three titanium plates close refractory hydro-plant-2 and foundry-2 construction | Titanium pilot and construction scenarios and manifests |
| Construction closure | The Vulcanus cell reproduces the buildings and logistics required to scale the implemented slice | Construction-closure scenario and manifest |
| Thermal industry | Pneumatic technology unlocks global tier-1 heat-powered crushers, furnace sizes, and foundries; metallurgic research unlocks tiers 2-3; eligible recipes receive innate and repeatable productivity | Thermal and productivity scenarios |
| [Fulgora industry](PLANET_FULGORA.md) | Lightning supplies power. Overload affects the grid. Deep drilling supplies copper, and hydrocarbons supply helium. Local industry also produces polymers and climate science. | `fulgora-grid-overload`, `fulgora-deep-drilling`, `fulgora-helium`, Fulgora production contracts |
| Rocket launches and cargo | Silos fill platform requests. Vulcanus has a pneumatic silo. A platform can deliver cargo to Vulcanus and return empty canisters to Nauvis. | `launch-vehicle`, `silo-platform-request`, `vulcanus-silo-request`, `platform-first-flight` |
| Radio astronomy | Arrays on Nauvis, Vulcanus, and Fulgora record signals. Correlators combine the recordings for astronomy research. | `astronomy-array`, `astronomy-transit`, `astronomy-correlation` |
| Nuclear power and antimatter | Seawater supplies uranium for gas centrifuges. Traps collect antimatter in Fulgora orbit and require recharging before the contents spoil. | `seawater-uranium`, `uranium-enrichment`, `antiproton-capture` |
| [Gleba cultivation](PLANET_GLEBA.md) | Gleba blocks electricity generators, water intakes, normal logistic bots, ordinary air, and oxidant voids; nutrient air filters draw Gleba air, which distilleries separate into nitrogen. Nutrient-mode machines (including inserters, assemblers, pumps, and upgrade chains) burn nutrient goop fixed from ferric rock and recycled from digestate; dead culture digests back into the loop. Leach residue roasts into standard silica for glass casting and local tier-1 building/inserter reproduction; local assays make biochemistry and microbiology packs for Wild Strain Cultivation and the biology lab. | `gleba-cultivation`, `gleba-fuel-spoilage`, `gleba-surface-and-modes`, `gleba-nutrient-technology.args`, `gleba-cultivation.args`, `gleba-construction.args` |
| Automated validation | Scenario runner supports selection, parallel workers, per-test timing, wall time, and tick ceilings; prerequisite checker consumes resolved prototypes | Full automated suite |
| Release lineage | Version `0.0.1` starts a new-game-only lineage; upstream Nullius saves are rejected before configuration mutation | Save-lineage scenario and packaged release gate |

## Release identity

| Field | Value |
|---|---|
| Initial version | `0.0.1` |
| Tagged release | `0.0.7` |
| Local science coverage | Vulcanus and Fulgora production through physics science |
| Upstream Nullius saves | Unsupported; rejected on configuration change |
| Save upgrades | The release includes migrations for upstream progression, radio astronomy, uranium enrichment, reactors, and antimatter traps. The [changelog](../nullius-star/changelog.txt) lists the effects on players. |

## Active hardening work

| Required result | Status |
|---|---|
| Vulcanus surface properties and map-generation fields are accepted and exercised by Factorio | Complete |
| Shared probe access, late join, reconnect, exact-body respawn, and save/load pass with real clients | Complete |
| Pneumatic heat ownership cannot leave duplicate or orphan hidden interfaces | Complete |
| Selected upstream changes from the October 2026 review pass integration checks | Complete |
| Version, changelog, and save-migration policy are coherent | Complete |
| Required dependencies and supported optional mods have a tested matrix | Open |
| The release tool validates the package from a clean checkout | Complete |
| The runner orchestrates real multiplayer scenario tests | Complete |
| The harness compares the supported Factorio build with a candidate build | Open |
| Vulcanus campaign timing | Open. Measure the research unlocks and the first 125 physics packs on a fixed map. Start with finite wreck stock. The factory must build its expansion machines and supply its own materials and heat. |

## Planned content boundary

| Area | Status | Design source |
|---|---|---|
| Vulcanus beyond tier-3 thermal industry | Design only | Vulcanus design |
| Gleba | Implemented through Wild Strain Cultivation | [Gleba design](PLANET_GLEBA.md) |
| Aquilo | Design only | Space Age brainstorm |
| Rogue, raids, and final objective | Design only | Space Age brainstorm |
| Maintenance mechanic | Design only | Maintenance brainstorm |
