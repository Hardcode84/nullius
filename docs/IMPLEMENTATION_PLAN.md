# Nullius* implementation status

> **Status**: Active vertical slice
> **Updated**: 2026-09-04

## Authority

| Scope | Authority |
|---|---|
| Current Vulcanus progression | Exact stage contracts |
| Implemented mechanics | Resolved prototypes and runtime scenario results |
| Proposed mechanics | Planet design documents |
| Other planets and endgame | Space Age brainstorming document |

## Implemented vertical slice

| Area | Implemented contract | Evidence |
|---|---|---|
| Space Age load | Space Age is required; Quality loads transitively and its gameplay effects, modules, and recycling are disabled | Strict prototype load |
| Planet access | Vulcanus probe research unlocks the planet, creates the surface and wreck, and transfers control to a new android body | Activation scenario |
| Bootstrap | Free lava intake and diminishing-return gas vent prime a net-positive lava-gas loop | Vent-prime and gas-self-power scenarios |
| Pneumatic factory | Eligible non-heavy-industry machines switch on Vulcanus through the common transition system; working machines expose correctly sized process-heat interfaces | Pneumatic lifecycle scenarios |
| Local materials | Lava separation, bloom cooling, aluminum reduction, sulfur catalysis, inorganic barrels, renewable graphite, alkali, lubricant, glass, concrete, sulfuric acid, boric acid, and metallic sodium are reachable without seawater, organic chemistry, or electricity | Production scenarios and prerequisite manifests |
| Local science | Geology, climatology, mechanical, electrical, chemical, bootstrap metallurgic, and efficient metallurgic packs are producible | Science-production scenarios |
| Thermite explosives | Inorganic chlorine, sulfur dioxide, aluminum powder, circuitry, and a disposable miner produce stable cliff explosives without electricity or organic chemistry | Thermite scenario and prerequisite manifest |
| Hot casting | Hot Metalworking unlocks direct pneumatic casting of iron and aluminum blooms before spoilage | Hot-casting scenario and prerequisite manifest |
| Refractory production | Local mineral byproducts become refractory mix and bricks for organic-free tier-2 heat pipes and improved high-temperature radiators | Refractory-production scenario and prerequisite manifest |
| Titanium pilot | Synthetic rutile and TiCl4 feed aluminothermic reduction; chloride recovery and three titanium plates close refractory hydro-plant-2 and foundry-2 construction | Titanium pilot and construction scenarios and manifests |
| Construction closure | The Vulcanus cell reproduces the buildings and logistics required to scale the implemented slice | Construction-closure scenario and manifest |
| Thermal industry | Pneumatic technology unlocks global tier-1 heat-powered crushers, furnace sizes, and foundries; metallurgic research unlocks tiers 2-3; eligible recipes receive innate and repeatable productivity | Thermal and productivity scenarios |
| Automated validation | Scenario runner supports selection, parallel workers, per-test timing, wall time, and tick ceilings; prerequisite checker consumes resolved prototypes | Full automated suite |
| Release lineage | Version `0.0.1` starts a new-game-only lineage; upstream Nullius saves are rejected before configuration mutation | Save-lineage scenario and packaged release gate |

## Release identity

| Field | Value |
|---|---|
| Initial version | `0.0.1` |
| Upstream Nullius saves | Unsupported; rejected on configuration change |
| Nullius* prior versions | None |
| Packaged migrations | None |

## Active hardening work

| Required result | Status |
|---|---|
| Vulcanus surface properties and map-generation fields are accepted and exercised by Factorio | Complete |
| Probe activation, bodies, and late join are correct for every player | Open |
| Pneumatic heat ownership cannot leave duplicate or orphan hidden interfaces | Complete |
| Current upstream Nullius development changes are integrated and revalidated | Open |
| Version, changelog, and save-migration policy are coherent | Complete |
| Required dependencies and supported optional mods have a tested matrix | Open |
| The complete validation flow reproduces from a clean checkout | Open |
| The runner orchestrates real multiplayer scenario tests | Open |
| The harness compares the supported Factorio build with a candidate build | Open |

## Planned content boundary

| Area | Status | Design source |
|---|---|---|
| Vulcanus beyond tier-3 thermal industry | Design only | Vulcanus design |
| Fulgora | Design only | Space Age brainstorm |
| Gleba | Design only | Space Age brainstorm |
| Aquilo | Design only | Space Age brainstorm |
| Cargo logistics and combined research | Design only | Space Age brainstorm |
| Rogue, raids, and final objective | Design only | Space Age brainstorm |
| Maintenance mechanic | Design only | Maintenance brainstorm |
