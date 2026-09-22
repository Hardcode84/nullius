# Factorio 2.1 port assessment

Checked 2026-09-22: Nullius* `8faa697`, Factorio 2.0.77 and 2.1.19.
The staged 2.1 mod loads, renders, and passes multiplayer checks. Full
compatibility is not established. The original audit found 38 failing
scenarios. Subsequent scenario API corrections are listed below.

## Scenario API corrections

All 27 scenario input-inventory accesses now use `inventory-api.lua`.
The seven inventory-blocked scenarios pass on 2.1. The nanofabricator test
also uses `fluid-api.lua`; its 98 assertions pass on both engines.

All 41 entity `active` assignments now use the inverse `disabled_by_script`
value. Both engines support this field. The 2.0 `active` setter changes only
this flag, so no version branch is required. Test timing and production
assertions are unchanged.

Scenario fluid access now uses `fluid-api.lua`, including pipe connections.
Both engines pass 600 mirrored pipe target and transfer checks. The full 2.0
suite passes all 127 scenarios; the last full 2.1 run passed 116 and failed 11.
The two category failures now pass focused reruns on both engines: 175 thermal
technology assertions and 108 hot-casting assertions. Nine failures remain.

| Remaining 2.1 failure | Scenarios | Required correction |
|---|---:|---|
| Old fluid removal signature | 1 | Use the native argument list |
| Missing hot-rock contracts | 1 | Add mining and destruction checks |
| Immediate build statistics | 1 | Read after the native tick flush |
| Configurable Valves linked connection | 1 | Port dependency `builder.lua` to entity fluid methods; retain the revival event |
| Lava intake timing | 5 | Resolve slower input-buffer filling with the same finite stock and pipe layout |

At tick 60, the iron separation input holds 71.631107 lava on 2.1 versus
86.197913 on 2.0. Fuel is equal. At tick 440, 2.1 has no completed cycle and
0.82 progress. A separate test with buffer multiplier 2 does not restore
2.0 timing. The scenario reports buffer contents; deadlines remain unchanged.

## Original full audit

| Check | Result |
|---|---|
| Full 2.0 scenario suite | 126 pass, 0 fail |
| Full 2.1 scenario suite | 88 pass, 38 fail |
| 2.1 isolated compatibility suite | Pass, including native recipe execution, fluid preservation, mining, power, and recipe UI checks |
| Fresh full-mod plans | Vulcanus progression through physics, plus Nauvis and Vulcanus tier-2 science plans complete |
| Locale, both engines | No missing prototype names, missing keys, or unused UI keys |
| Strict 2.1 prototype check | 2,131 ignored fields on Nullius prototypes; see below |
| Release metadata | The shipping manifest still selects 2.0 |
| Published 2.1 dependencies | Download retry returns HTTP 403; the full published set is not tested |

The full suites use the same source and 126 scenario contracts. The 2.1 set
uses Bob library 3.0.0 and logistics 3.0.1, plus six installed dependencies
with changed manifests. The locale check must use a real source copy:
its source scanner skips staged directory links and otherwise reports 74
false unused keys.

| First 2.1 failure | Scenarios | Required correction |
|---|---:|---|
| Writes to read-only `LuaEntity.active` | 18 | Use the native script-disable flag; retain timing and throughput assertions |
| Removed `LuaEntity.fluidbox` | 8 | Use the shared version-specific fluid API |
| Removed assembler inventory indices | 7 | Select `crafter_input` on 2.1 |
| Removed recipe `category` | 2 | Check the native category list |
| Old `remove_fluid` call signature | 1 | Port the pneumatic-roboport experiment call |
| Missing hot-rock contracts | 1 | Add `big-volcanic-rock-hot` and `huge-volcanic-rock-hot` and test mining and destruction |
| Immediate build-statistics assertions | 1 | Read after the next tick; retain both surface attribution checks |

The separate `flow-statistics-timing` witness passes on both engines. After
`on_flow(+1)` and `on_flow(-1)`, 2.1 reads 0/0 in the same tick and 1/1 in
the next tick. The 2.0 values are 1/1 in both ticks. This confirms a test
timing error, not lost build counts. Other failures can hide later assertions;
the full suite must run again after the test APIs are ported.

The strict check reports `always_show_products` on 1,071 recipes,
`show_amount_in_title` on 1,047 recipes, `base_render_layer` on three
geothermal build drills, and `fluid_wagon_connector_frame_count` on ten pumps.
These fields are ignored on 2.1. Recipe categories already use the native
schema; their display flags still need cleanup.

## Required changes

| Area | Evidence | Required work |
|---|---|---|
| Multiplayer support overlay | The overlay extends the private staged directory and keeps its generated manifest | Unit tests cover both version manifests, settings, deadlines, and conflicts. All three scenarios pass on both engines, including shared-body save/reload. The 2.1 run passes 287 assertions |
| Assembler sprite layouts | All eight definitions use native 2.1 layers with the Nullius scale, offsets, and cycle duration | Both clients render and craft: 16 assertions each. Checks include status lights, frozen overlays, and inherited variants. The full 2.0 prototype dump is unchanged |
| Distillery sprite layouts | All three tiers and their pneumatic variants use complete native 2.1 refinery graphics with their tier colours | Both clients render and craft in all four directions: 48 assertions each. Native layers, smoke, lights, and frozen overlays match. The full 2.0 prototype dump is unchanged |
| Pumpjack sprite layouts | Wells and extractors use native 2.1 arm shadows; custom coloured arms stay unchanged | Shadow scale and timing match each arm. Both clients render all eight definitions in four directions and produce water: 64 assertions each. The full 2.0 prototype dump is unchanged |
| Chemical-plant sprite layouts | All three tiers and their pneumatic variants use native 2.1 body layers with Nullius scale, offsets, and colours | Both clients render and craft in all four directions: 48 assertions each. Checks preserve animation timing and recipe effects and include frozen overlays. The full 2.0 prototype dump is unchanged |
| Configurable Valves key bindings | The old keypad defaults map to `KP_MINUS` and `KP_PLUS` on 2.1 | Fresh full dumps show exactly two changed defaults on 2.1 and no changes on 2.0. Native multiplayer clients accept the bindings |
| Hidden upgrade targets | Cleanup checks build items across all item types and the first explicit `placeable_by` entry | Ten native cases pass on each engine. Full-mod 2.0 data is unchanged. Removing nine invalid rolling-stock links lets the staged 2.1 prototype dump pass |
| Rocket-silo crafting graphics | The silo copies the base graphics set with its working sound | Both engines and full Nullius 2.0 pass 30 assertions: rocket construction, launch, and 100 astronomy boxes at tick 26,700. Mission startup accepts zero players and uses the cargo pod force |
| Logistic network connections | Robotics 1 and Primitive robotics grant `unlock-logistic-network` on 2.1 | Native checks pass on both engines: independent forces, recipe unlocks, personal requests, and effect reset |
| Recipe categories | Full staged 2.1 data loads and native recipe execution checks pass | Two scenario category reads still use the removed runtime field |
| Recipe presentation | Strict checking finds 2,118 ignored display fields | Remove obsolete flags on 2.1 and check the intended recipe UI |
| Product amounts | Full staged 2.1 validation and native recipe checks pass | Add the two new hot-rock contracts to complete the full-mod rock test |
| Industrial metallurgic science | The second barrel return uses the engine-specific 90% probability field | Both engines retain five science packs, one guaranteed barrel, and one 90% barrel return. Native tests verify that productivity doubles science but does not duplicate barrels |
| Pump wagon reach | Five pump definitions use the native arm reach on 2.1; alignment tolerances and the Mini Trains override apply only on 2.0 | Headless tests cover 64 aligned, offset, and out-of-reach placements per engine. Tests check inherited pneumatic settings and the Mini Trains override branch. Actual Mini Trains wagon tests require its archive; authenticated downloads returned HTTP 403 |
| Hidden fluid connections | A shared helper retains the box-level flag on 2.0 and sets it on each connection on 2.1 | Full-mod 2.0 resolved data matches the baseline exactly. Native fixtures check 60 fluid boxes and 121 connections on both engines, including linked ports and inherited variants |
| Crafting-machine mirroring | All 15 declarations retain `forced_symmetry` on 2.0 and use `use_mirroring` on 2.1 | Isolated native assemblers use 29 resolved recipe-port layouts, including thermal and pneumatic variants. Both engines pass 116 mirrored orientations and 600 pipe-flow checks. 2.1 also checks both native flip axes and fluid preservation; fixtures use base graphics and void power |
| Optional mod recipe definitions | `prototypes/mods.lua` uses native categories and removes obsolete display fields on 2.1 | Native fixtures craft 174 recipes on both engines and compare recipes and technologies with the original 2.0 source across 12 configurations. Legacy Crafting Combinator item names contain `:` and fail native validation on both engines; their external port must supply valid names before the integration can load |
| Optional mod overrides | All remaining recipe categories in `override_mod.lua` use the native schema; removed display fields are version-gated, cargo drone friction uses `friction_force`, and obsolete depot-fluid fields are removed | Both engines craft 18 Text Plates recipes and 25 transport recipes with declared external prototypes. Tests check exact costs, yields, categories, depot volumes, and optional guards; full Nullius 2.0 passes the absent-mod cases |
| Induction Charging recipe category | The override replaces inherited categories with the native small-crafting field | Both engines pass 93 assertions for crafting, inherited output/unlock, five research definitions, item properties, and the absent-mod guard. External prototypes are declared fixtures; full Nullius 2.0 passes the absent-mod case |
| GCKI car-key recipe category | The optional recipe selects the native schema | Both engines pass 28 assertions with declared external prototypes: crafting, broadcasting unlock, exact costs and time, category rejection, and both guards. Full Nullius 2.0 passes the GCKI-absent guard; the external GCKI mod is not included in this test |
| Generated barrel recipe categories | Fill and empty overrides select the native schema and replace the generated category | Both engines and full Nullius 2.0 pass 141 assertions for water, fuel, steam, and cold gas. Native fill/empty cycles preserve quantities, temperatures, barrel returns, enabled states, and exclusive machine categories |
| Vulcanus processing recipes | The complete file selects native recipe categories and removes obsolete presentation fields on 2.1 | Both engines match 136 recipe contracts and six items from a fresh full-mod 2.0 capture, and craft all 108 generated recipes. Tests include boxed variants, fluid temperatures, catalysts, and both alignment settings |
| Vulcanus entity recipe categories | All five recipes select the native schema; entity and resource definitions stay unchanged | Both engines and full Nullius 2.0 pass 117 assertions for costs, yields, times, categories, and enabled states. Circuit selection rejects radiator recipes at temperature 99 and accepts them at 100; thermal-machine and gas-vent scenarios pass |
| Primitive robotics recipe categories | The generator selects the native schema for all five recipes; item definitions and crafting categories stay unchanged | Both engines and full Nullius 2.0 craft all five with exact costs, times, and outputs. The full-mod primitive robotics scenario also passes |
| Intermediate recipe categories | All 293 ordinary, boxed, and alternative recipes select the native schema; items and recipe quantities stay unchanged | Both engines and full Nullius 2.0 craft all 293 with exact inputs, outputs, times, temperatures, catalyst balances, and category rejection |
| Fluid recipe categories | All 223 recipes select the native schema; fluid definitions and optional AAI fuel handling stay unchanged | Both engines and full Nullius 2.0 check native crafting, exact yields, temperatures, canister returns, and explicit fluid ports. Ingredient-free recipes check output backpressure on each engine |
| Biology recipe categories | All 152 unique recipes select the native schema; the redundant oil-incineration declaration is removed with the effective recipe unchanged | Both engines and full Nullius 2.0 craft every recipe with exact ingredients, products, times, and category rejection. Tests check finite fluid feeds, returned catalysts, and multiple fluid outputs |
| Equipment recipe categories | All 157 ordinary, boxed, and legacy recipes select the native schema in both registration lists; armor, items, and optional reskins stay unchanged | Both engines and full Nullius 2.0 craft all 157 with exact inputs, outputs, times, and category rejection, including battery recharging, chlorine by-products, and generator reprioritization |
| Building recipe categories | All 137 ordinary, boxed, and legacy recipes select the native schema; item and optional reskin definitions stay unchanged | Both engines and full Nullius 2.0 craft all 137 with exact materials, yields, times, and category rejection. Tests connect finite lubricant, epoxy, and argon feeds |
| Plumbing recipe categories | All 113 ordinary, boxed, and legacy recipes select the native schema; items and optional reskins stay unchanged | Both engines and full Nullius 2.0 craft all 113 with exact inputs, outputs, times, and category rejection. Tests connect finite epoxy, water, gas, and lubricant feeds |
| General recipe categories | All 66 construction, logistics, and barrel recipes select the native schema; legacy recipes and the conditional Bob inserter item stay unchanged | Both engines and full Nullius 2.0 craft all 66 with exact inputs, outputs, times, and category rejection. Full Nullius also checks 25 recipe renames |
| Landfill recipe categories | All 30 ordinary, boxed, composting, sink, and dumping recipes select the native schema; tiles stay unchanged | Both engines and full Nullius 2.0 craft all 30 with exact inputs, fluid by-products, yields, times, and category rejection |
| Weapon recipe categories | All 17 recipes select the native schema; gun and ammunition categories stay unchanged | Both engines and full Nullius 2.0 craft ordinary and boxed recipes, with three separate fluid feeds, exact wastewater/sludge outputs, and category rejection |
| Drone recipe categories | All 50 recipes select the native schema; ammunition types, legacy visibility, and returns stay unchanged | Both engines craft all 50 with exact inputs, outputs, times, and category rejection. Terrain checks retain bulk quantities and color mappings; full Nullius 2.0 checks terrain unlocks and the android recipe rename |
| Alignment recipe categories | Nine recipes select the native schema; seven research unlock sets and the startup toggle stay unchanged | Both engines and full Nullius 2.0 craft all nine recipes. Isolated checks verify research costs and exclusion when alignment is disabled |
| Module recipe categories | All 46 ordinary, boxed, and coprocessor recipes select the native schema; 18 module categories and effects stay unchanged | Both engines and full Nullius 2.0 run every recipe and check exact materials, outputs, times, and category rejection |
| Boxing recipe categories | The generator selects the native category schema for box and unbox recipes; item-type selection is unchanged | Both engines test 16 stack/type cases. Full Nullius 2.0 runs all 258 standard pairs before and after the change: 1,290 crafts and 7,999 assertions |
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
| Entity prototypes | All enabled sprites load; strict checking finds 13 ignored drill/pump fields | Remove or port those fields and retain layer and connector behavior |
| Runtime fluid preservation | Version-specific fluid access; snapshots retain their slot count | 61 assertions pass on each engine: replacement, empty slots, fluid identity, amount, temperature, and rejection of missing occupied slots |
| Runtime mining flags | Four helper creation paths use `minable_flag` on both engines | 45 assertions per engine verify protection and cleanup; full Nullius heat and gas-vent scenarios pass 160 assertions |
| Mining drone refresh | Uses `update_connections()` without activation writes | 18 assertions pass per engine and in full Nullius 2.0: ore pickup, disabled-state preservation, and mining after explicit re-enable |
| Prototype recipe filtering | Both `hidden.lua` passes use `prototypes/recipe-visibility.lua` | Category sets preserve testing-tool exemptions; full-mod filter and checkpoint scenarios pass 223 assertions |
| Runtime recipe filtering | Startup uses the dual-version `scripts/recipe_filter.lua` | 174 assertions per engine cover prototype visibility, product visibility, exemptions, locked recipes, broken counts, and repeated filtering; full-mod force creation also passes |
| Test code | The full 2.1 suite fails 38 scenarios; the full 2.0 suite passes | Port the API calls, add hot-rock contracts, and defer statistics assertions by one tick. Preserve fluid, heat, and throughput checks |
| Recipe productivity families | Matcher accepts both category schemas | Verified on 2.0.77 and 2.1.19: three sorted effects, no duplicates, zero-cap exclusion, and +1% research bonuses |
| Analysis and release tools | Dual-schema planners, UI audit, test overlays, and release metadata checks | Supported on 2.0 and 2.1; see tool checks below |

Counts are lexical source matches, not resolved prototype counts or an edit
budget. Comments and non-entity fields can match. In particular, a logistic
section's `active` field must not receive the entity API conversion.

## Tool checks

| Check | Result |
|---|---|
| Python tool tests | 105 pass, plus 10 subtests |
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

The fresh full-mod 2.1 plans also complete with the staged dependencies.
These solver results do not prove a connected factory or the failing scenario
contracts.

```bash
python tools/test_factorio_tool_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_factorio_tool_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_vulcanus_recipe_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_vulcanus_recipe_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_vulcanus_processing_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1
python tools/test_barrel_recipe_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_barrel_recipe_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_car_key_recipe_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_car_key_recipe_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_induction_recipe_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_induction_recipe_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_textplate_recipe_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_textplate_recipe_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_optional_override_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_optional_override_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_logistic_unlock_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_logistic_unlock_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_silo_compatibility.py --factorio /path/to/factorio-2.0
python tools/test_silo_compatibility.py --factorio /path/to/factorio-2.1
python tools/test_hidden_upgrade_compatibility.py --factorio /path/to/factorio-2.0 --compare-full-mod
python tools/test_hidden_upgrade_compatibility.py --factorio /path/to/factorio-2.1 --staged-full-mod --dependency-mod-directory /path/to/staged/mods
python tools/test_assembler_graphics_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1 --staged-dependency-mod-directory /path/to/staged/mods
python tools/test_distillery_graphics_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1 --staged-dependency-mod-directory /path/to/staged/mods
python tools/test_pumpjack_graphics_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1 --staged-dependency-mod-directory /path/to/staged/mods
python tools/test_chemical_plant_graphics_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1 --staged-dependency-mod-directory /path/to/staged/mods
python tools/test_valve_input_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1 --staged-dependency-mod-directory /path/to/staged/mods
python tools/test_mod_recipe_compatibility.py --factorio-2-0 /path/to/factorio-2.0 --factorio-2-1 /path/to/factorio-2.1
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
| Current source with the staged Bob 3.0 dependency set | Full 2.1 prototype dump passes after the hidden upgrade-target fix; no temporary prototype edits are needed |

Portal archive download returned HTTP 403 with the installed credentials. The
Bob probe uses public tag `v3.0-patch1`, commit
`41ecd658bc63ab69c96315c260276d4d82134198`. The other six dependencies remain
manifest-retargeted installed versions in that probe. The current source passes
the full 2.1 prototype dump with this staged set. The full suite passes 116 of
127 scenarios. All three multiplayer scenarios pass. Fresh full-mod plans
and the isolated compatibility suite pass.

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
- Body ownership, personal autocrafting, and probe alignment pass their real
  multiplayer scenarios, including shared-body save/reload.
- Acceptance requires fresh resolved prototypes, recipe/locale audits, planner
  contracts, and every discovered scenario. Preserve ingredients, yields, machine
  eligibility, and the Nauvis/Vulcanus research supply comparison.

The [electrical API experiment](PLANET_FULGORA.md#factorio-21-api-experiment)
already passes 81 assertions on isolated Space Age fixtures. It establishes the
Fulgora API benefit, not full-mod compatibility.

## Reproduce

```bash
python tools/run_factorio_tests.py --factorio "$FACTORIO_2_1" --mod-under-test "$STAGED_MOD" --dependency-mod-directory "$STAGED_DEPS" --keep-run-directory --result-json "$AUDIT_DIR/scenarios.json" -n auto > "$AUDIT_DIR/scenarios.log" 2>&1
python tools/run_factorio_tests.py flow-statistics-timing --factorio "$FACTORIO_2_1" --mod-under-test "$STAGED_MOD" --dependency-mod-directory "$STAGED_DEPS" --json
python tools/summarize_factorio_test_log.py "$AUDIT_DIR/scenarios.log" --groups-only
"$FACTORIO_2_1" --config "$STAGED_CONFIG" --mod-directory "$STAGED_MODS" --dump-data --check-unused-prototype-data > "$AUDIT_DIR/unused.log" 2>&1
python tools/summarize_factorio_test_log.py "$AUDIT_DIR/unused.log" --unused-prototypes
python tools/test_hidden_connections_compatibility.py --factorio-2-0 "$FACTORIO_2_0" --factorio-2-1 "$FACTORIO_2_1"
python tools/test_machine_mirroring_compatibility.py --factorio-2-0 "$FACTORIO_2_0" --factorio-2-1 "$FACTORIO_2_1"
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
