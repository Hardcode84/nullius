# Factorio 2.1 port assessment

Assessed 2026-09-21: Nullius* `8ca5de2`, Factorio 2.0.77 → 2.1.19.
Scope: dependency inventory, isolated loading probes, source/API audit, and
planner schema witness. No gameplay port is applied.

## Required changes

| Area | Evidence | Required work |
|---|---|---|
| Recipe categories | 1,419 category-definition lines across 20 item/planet files; 2.1 removes `category` | Use `categories`; preserve machine and character eligibility. Update recipe mutation and startup filtering; tool category handling passes |
| Recipe presentation | 1,193 lines across 18 files reference removed recipe fields | Remove obsolete display fields; move freshness settings to products where used |
| Product amounts | 75 probability-related lines across 13 files | Port products to `independent_probability`; preserve yields, rocket returns, and recycling calculations. Loot has a separate schema change |
| Entity prototypes | Generator pictures, chest robot doors, mining-drill graphics, vehicle braking/friction, and crafting symmetry changed | Port each entity family; check graphics, fluid port geometry, and vehicle behavior |
| Runtime fluid preservation | Six `fluidbox` references in `scripts/mirror.lua` | Use per-box `LuaEntity` fluid methods. This helper serves turbine modes, entity transitions, and Vulcanus intake replacement |
| Runtime flags | Six writes across five script files | Replace entity `active` writes with `disabled_by_script`; replace entity `minable` writes with `minable_flag`. Affects drones, beacons, geothermal plants, Vulcanus heat, and gas vents |
| Runtime initialization | `scripts/startup.lua:131` reads removed `recipe.category` | Filter the category set; otherwise initialization fails after prototype loading is fixed |
| Test code | 121 fluidbox-reference lines across 20 files; 52 candidate active/minable-write lines across 19 files | Port fluid reads/writes, capacities, filters, and connection queries. Preserve actual fluid and heat assertions |
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
