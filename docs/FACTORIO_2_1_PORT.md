# Factorio 2.1 port assessment

Assessed 2026-09-21: Nullius* `8ca5de2`, Factorio 2.0.77 → 2.1.19.
Scope: dependency inventory, isolated loading probes, source/API audit, and
planner schema witness. Full gameplay has not been ported.

## Required changes

| Area | Evidence | Required work |
|---|---|---|
| Recipe categories | 1,419 category-definition lines across 20 item/planet files; 2.1 removes `category` | Use `categories`; preserve machine and character eligibility. Update recipe definitions and mutation; prototype filters, runtime filters, and tool category handling pass |
| Recipe presentation | 1,193 lines across 18 files reference removed recipe fields | Remove obsolete display fields; move freshness settings to products where used |
| Product amounts | Initial audit: 75 probability-related lines across 13 files | Port remaining products to `independent_probability`; preserve yields and recycling calculations. Rock loot is ported; other loot needs its own schema check |
| Industrial metallurgic science | The second barrel return uses the engine-specific 90% probability field | Both engines retain five science packs, one guaranteed barrel, and one 90% barrel return. Native tests verify that productivity doubles science but does not duplicate barrels |
| Wreck-repair recipe categories | Ten repairs select the native category schema; solar-panel repair retains `hand-casting` | Both engines and full Nullius 2.0 run ten repairs and check inputs, outputs, times, and rejection by the other category |
| Turbine recipe categories | All 26 fuel conversions and 12 ordinary/boxed assembly recipes select the native category schema | Both engines run all 38 recipes and check exact inputs, outputs, times, categories, and turbine icons; full Nullius 2.0 also passes |
| Disposal recipe categories | All 42 recipes select the native category schema; names and icons match category sets | Tests load the complete production file, check exact categories and decoration, and run 210 disposal crafts on each engine |
| Void recipe products | All 42 liquid, gas, and energy disposal recipes use the engine-specific zero-probability field | Native tests run 210 disposal crafts on each engine and in full Nullius 2.0. All input fluid is consumed; output inventories stay empty. Input amounts and craft times are unchanged |
| Fluid resource products | Fumarole, optional offshore vent, and Vulcanus geyser omit redundant `probability = 1` | Both engines use guaranteed output. Native extraction checks retain 10 units, 200°C volcanic gas, and the default HCl temperature; full Nullius 2.0 checks cover the fumarole and geyser |
| Asteroid-miner returns | Both return tables select the engine's probability field | All twelve products retain their amounts and probabilities. Resolved checks pass: 62 assertions on 2.0, 74 on 2.1, and 62 in full Nullius 2.0; 2.1 checks confirm independent rolls |
| Rock drops | Both engines use their native loot and mining probability fields | Checks cover all 38 mineable rock types: base, Alien Biomes, crystal, Vulcanus, and Fulgora. Mining yields stay unchanged. Generated destruction bounds round down to integers on both engines; some destruction yields decrease. Vulcanus has no destruction loot. Rock rewrites exclude shells |
| Assembler pipe pictures | Four calls use `prototypes/entity/assembler-pipe-pictures.lua` | Both engines load the fixture geometry; directional sprite data matches each engine and copies are independent |
| Turbine generator pictures | One helper selects the engine picture schema for all 18 variants | Both engines retain sprites, tints, frame counts, and two-direction behavior. Native tests check 36 isolated grids, tier power caps, priorities, and fuel conversion; full Nullius 2.0 also passes |
| Vehicle forces | Three cars and two trucks use numeric `braking_force` and `friction_force` on both engines | Braking force is the former power in watts divided by 60; friction is unchanged. Native tests check resolved values, coasting, and braking. The 2.0 reference uses the original fields |
| Logistic chest doors | All 15 logistic chests select the engine's door schema and inherited sound/duration | Both engines load all 17 chests. Checks cover animation layers/frames, capacities, trash slots, upgrade links, modes, circuit counts, and robot delivery. Isolated tests use Bob's graphics only; full Nullius 2.0 also passes |
| Miner circuit connectors | Six electric miners keep draw orders 14/30/30/30 on both engines | Checks cover four directions, sprite and wire geometry, base connector isolation, and optional reskin tables. The 2.1 settings use private connector sprites |
| Extractor foundations | Both tiers use directional working visualisations on 2.1 | Checks preserve the foundation scale, placement, and layer; shadow frames use the 2.1 dimensions and origin. Eight native extraction cases retain tier rates. The gas-vent drill remains invisible |
| Water-well shadows | Both tiers and their legacy copies select the engine shadow frames and origin | Checks cover all 16 directional shadows and native water output. Scales, animation timing, and well speeds stay unchanged |
| Lab-wreck salvage research | The mining trigger selects `entity` on 2.0 and `entities` on 2.1 | Native character mining checks reject another entity, retain all salvage items, complete salvage research, and permit geology research |
| Pump wagon connectors | Five full-size pumps select the engine connector graphics field | Checks cover all five definitions and 16 native loading/unloading cases across both normal tiers and four directions |
| Nuclear-reactor neighbours | The 2.1 connection points use a private Nullius category | 32 layouts check bonuses, heat output, rotation, gaps, mixed prototypes, and neighbour removal. Different reactor prototypes give no bonus, as on 2.0 |
| Solar-collector neighbours | Each tier has four 2.1 connection points around its 5×4 footprint and a separate category | 144 layouts check same-tier bonuses, mixed-tier exclusion, gaps, offsets, neighbour removal, and native plus scripted heat in daylight and darkness |
| Entity prototypes | Other mining-drill graphics and crafting symmetry changed | Port each entity family; check graphics and fluid port geometry |
| Runtime fluid preservation | Version-specific fluid access; snapshots retain their slot count | 61 assertions pass on each engine: replacement, empty slots, fluid identity, amount, temperature, and rejection of missing occupied slots |
| Runtime mining flags | Four helper creation paths use `minable_flag` on both engines | 45 assertions per engine verify protection and cleanup; full Nullius heat and gas-vent scenarios pass 160 assertions |
| Mining drone refresh | Uses `update_connections()` without activation writes | 18 assertions pass per engine and in full Nullius 2.0: ore pickup, disabled-state preservation, and mining after explicit re-enable |
| Prototype recipe filtering | Both `hidden.lua` passes use `prototypes/recipe-visibility.lua` | Category sets preserve testing-tool exemptions; full-mod filter and checkpoint scenarios pass 223 assertions |
| Runtime recipe filtering | Startup uses the dual-version `scripts/recipe_filter.lua` | 174 assertions per engine cover prototype visibility, product visibility, exemptions, locked recipes, broken counts, and repeated filtering; full-mod force creation also passes |
| Test code | 121 fluidbox-reference lines across 20 files; 52 candidate active/minable-write lines across 19 files | Port fluid reads/writes, capacities, filters, and connection queries. Preserve actual fluid and heat assertions |
| Recipe productivity families | Matcher accepts both category schemas | Verified on 2.0.77 and 2.1.19: three sorted effects, no duplicates, zero-cap exclusion, and +1% research bonuses |
| Analysis and release tools | Dual-schema planners, UI audit, test overlays, and release metadata checks | Supported on 2.0 and 2.1; see tool checks below |

Counts are lexical source matches, not resolved prototype counts or an edit
budget. Comments and non-entity fields can match. In particular, a logistic
section's `active` field must not receive the entity API conversion.

## Tool checks

| Check | Result |
|---|---|
| Python tool tests | 98 pass |
| Fresh Nullius 2.0 Vulcanus plan | Completes; regenerated executor fixture is unchanged |
| Nullius 2.0 chemical executors | 1,927 assertions pass |
| Nullius 2.0 manifest executors | Three scenarios; 1,705 assertions pass |
| Nullius 2.0 productivity fixtures | Two scenarios; 51 assertions pass |
| Isolated 2.0.77 and 2.1.19 tool fixtures | Both pass: fresh dump, category selection, exact/guaranteed yields, native item/fluid crafting, and recipe UI audit |

Use `--factorio`, `--mod-under-test`, and `--dependency-mod-directory`
with the planner or prerequisite analyzer to select a matching installation
and mod set. Test-support manifests follow the subject mod version. Release
metadata checks accept 2.0 and 2.1.

The planners treat categories as alternatives. A forbidden category removes
that executor path. Exact amounts reject independent and shared probability.
Guaranteed amounts omit uncertain products. The fluid matcher reserves
additional ports; shared executor helpers use each engine's native fluid API.

These checks use isolated fixtures on 2.1. Full Nullius 2.1 plans require the
prototype and dependency repairs listed above.

```bash
python tools/test_factorio_tool_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_factorio_tool_compatibility.py --factorio /path/to/factorio-2.1
python tools/probe_factorio_loot_fractions.py --factorio /path/to/factorio-2.0
```

## Published dependencies

The Mod Portal reports 2.1 releases for all eight installed dependencies.

| Dependency | Installed | 2.1 release |
|---|---|---|
| alien-biomes | 0.7.4 | 0.8.0 |
| alien-biomes-graphics | 0.7.1 | 0.8.0 |
| angelspetrochemgraphics | 2.0.1 | 2.1.0 |
| angelsrefininggraphics | 2.0.0 | 2.1.0 |
| angelssmeltinggraphics | 2.0.0 | 2.1.0 |
| boblibrary | 2.0.3 | 3.0.0 |
| boblogistics | 2.0.6 | 3.0.1 |
| configurable-valves | 0.3.3 | 2.0.2 |

Upgrade dependencies before porting Nullius prototypes. Check the configurable
valves registration contract in `data.lua` and `scripts/turbine.lua` against its
new release. A published release does not prove integration compatibility.

## Executed witnesses

| Probe | Result |
|---|---|
| Retarget only installed manifests to 2.1 | Bob's Logistics 2.0.6 fails at `entity/inserter.lua:97`: removed global `assembler3pipepictures` |
| Use Bob library 3.0.0 and logistics 3.0.1 source | Nullius fails at `entity/assembler.lua:111`: removed global `assembler2pipepictures` |
| Replace four assembler picture calls in the staged copy | Lua data stages complete; prototype validation rejects `nullius-asteroid-miner-1.rocket_launch_products[0].probability` |
| Feed a declared 2.1 recipe to the planner | Preserves `categories=["chemistry"]`; rejects the 50% product as an exact amount |

Portal archive download returned HTTP 403 with the installed credentials. The
Bob probe uses public tag `v3.0-patch1`, commit
`41ecd658bc63ab69c96315c260276d4d82134198`. The other six dependencies remain
manifest-retargeted installed versions in that probe. Full 2.1 prototype,
runtime, and campaign validation has not passed; the probe stops at the concrete
product-schema error above. The planner schema witness now passes.

Bob's 3.0.1 also reports two missing `bob-tungsten-processing` prerequisites.
Its robot and repair-pack updates detect Space Age's `tungsten-carbide` item,
then assume Bob's tungsten technology exists. Guard this integration by the
technology/mod that supplies the prerequisite, not by the shared item name.

## Behavior and validation

- Fluid ingredient/product buffer multipliers now default to 3. Recheck
  pneumatic startup, starvation, fluid capacity, and throughput contracts.
- Recycling is a separate built-in mod in 2.1. Check that Nullius still disables
  generated recycling and unwanted quality behavior.
- Science packs can remain tools: 2.1 still uses tool durability for labs.
  Converting every pack into an item is not required.
- Body ownership and personal autocrafting have no demonstrated need for a
  redesign. Run their scenarios; 2.1 changed remote-view teleport behavior, while
  body switching already sets the controller explicitly.
- Acceptance requires fresh resolved prototypes, recipe/locale audits, planner
  contracts, and the 85-scenario suite. Preserve ingredients, yields, machine
  eligibility, and the Nauvis/Vulcanus research supply comparison.

The [electrical API experiment](PLANET_FULGORA.md#factorio-21-api-experiment)
already passes 81 assertions on isolated Space Age fixtures. It establishes the
Fulgora API benefit, not full-mod compatibility.

## Reproduce

```bash
python tools/assess_factorio_port.py --factorio-version 2.1 --portal-only
python tools/assess_factorio_port.py --factorio-version 2.1 --source-audit tests/compatibility/factorio-2.1-source-audit.json --report ../nullius-source-audit.json
python tools/assess_factorio_port.py --factorio-version 2.1 --planner-schema-witness tests/compatibility/factorio-2.1-planner-witness.json
python tools/assess_factorio_port.py --factorio-version 2.1 --destination ../nullius-port-assessment
```

Run the staged checkout's scenario runner with the candidate `--factorio` and
staged `--dependency-mod-directory`. `--apply-probe-edits` accepts
`tests/compatibility/factorio-2.1-probe-edits.json` for the bounded assembler
repair. `--baseline-api` and `--candidate-api` compare shipped runtime API files;
the result lists lexical references for manual receiver-type review.

Authorities: shipped 2.1.19 changelog and API docs,
[Mod Portal API](https://wiki.factorio.com/Mod_portal_API),
[Bob's source tag](https://github.com/modded-factorio/bobsmods/tree/v3.0-patch1),
[2.1 item science capacity](https://lua-api.factorio.com/latest/prototypes/ItemPrototype.html#science_capacity).
