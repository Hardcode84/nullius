# Vulcanus test specification: activation to metallurgic pack

Every case in this file is independently runnable. A case creates its own fixed
surface and fixture; it never loads another case's save. Counts are exact unless
an assertion explicitly uses `at least`. All production actions use normal
recipes and entity simulation. Infinity pipes/chests may supply a component
test's declared inputs or consume its declared outputs, but may not supply an
undeclared intermediate or target.

`nullius-pneumatic-technology` and its prerequisites are researched before each
Vulcanus production case. The fixed surface has
`nullius-ambient-temperature=200`. Graphite, rutile, and limestone come from
placed minable volcanic rocks, not direct item insertion, in V10 and V12.

The static contracts are executable from the repository root:

```bash
python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-pack.args
python3 tools/analyze_factorio_prereqs.py @nullius-star/progression/vulcanus-construction.args
```

The pack command uses
`progression/vulcanus-planned-prototypes.json` because the pack prototype is not
implemented. The overlay refuses to replace a resolved prototype; once the
prototype exists, the command fails until the overlay is removed and the real
prototype satisfies the same contract.

## V00 — pack prototype

Input: the resolved mod prototypes plus the planned prototype overlay.

Action: run the pack manifest command.

Expected output:

- item `nullius-metallurgic-pack`, stack size 200, durability 1;
- enabled `small-crafting` recipe, 900 base ticks;
- input: 3 `nullius-iron-ingot`, 2 `nullius-aluminum-ingot`, 1
  `nullius-crushed-limestone`, 1 `nullius-silica`, 1 `sulfur`;
- output: 1 `nullius-metallurgic-pack`;
- surface condition: `nullius-ambient-temperature >= 100`;
- no research beyond `nullius-pneumatic-technology` and its prerequisite
  closure.

## V01 — activation

Input: a force on Nauvis with `nullius-probe-vulcanus` completed and
`nullius-pneumatic-technology` researched.

Action: deliver the probe-research completion event once.

Expected output:

- one surface attached to planet `nullius-vulcanus`;
- one valid `character` at the landing site, associated with every player in
  the force and registered for body switching;
- the force has `nullius-vulcanus` unlocked and the square from `(-64,-64)` to
  `(64,64)` charted;
- one `nullius-landing-main` containing exactly:

| Item | Count |
|---|---:|
| `nullius-seawater-intake-1` | 2 |
| `nullius-hydro-plant-1` | 4 |
| `nullius-small-furnace-1` | 4 |
| `pipe` | 50 |
| `nullius-heat-pipe-1` | 30 |
| `pipe-to-ground` | 10 |
| `nullius-extractor-1` | 2 |
| `nullius-air-filter-1` | 2 |
| `nullius-distillery-1` | 2 |
| `nullius-chemical-plant-1` | 2 |
| `nullius-foundry-1` | 4 |
| `nullius-small-assembler-1` | 4 |
| `inserter` | 12 |
| `iron-chest` | 4 |
| `nullius-lab-1` | 1 |
| `transport-belt` | 50 |
| `splitter` | 4 |
| `cliff-explosives` | 30 |

Without `Companion_Drones`, the android additionally has one
`nullius-chassis-1`, its code-defined charger/hangar/solar/battery equipment,
and 6 `nullius-construction-bot-1`.

## V02 — free-vent prime

Input: 1 `nullius-seawater-intake-1`, connected pipe with at least 24 units of
free capacity, and no compressed volcanic gas.

Action: place the intake through the production placement event, toggle it to
gas-vent mode, and simulate 120 ticks.

Expected output: at least 24 `nullius-compressed-volcanic-gas` in the connected
network. Destroying the visible vent removes its hidden drill and resource.

## V03 — self-powered gas

Input: 1 pneumatic `nullius-hydro-plant-1`, 100 lava, 24
`nullius-compressed-volcanic-gas`, output capacity for gas and stone, and no
connected vent after tick 0.

Action: select `nullius-lava-gas-extraction` and simulate 240 ticks.

Expected output after the first 120 ticks: 60 gas and 3 stone produced, 24 gas
consumed, and the gas inventory is 60. Expected output after 240 ticks: 120 gas
and 6 stone produced, 48 gas consumed, and the gas inventory is 96. The second
cycle therefore completes using only the first cycle's net output.

## V04 — lava separations

This is a parameterized case. Each row starts with one pneumatic
`nullius-hydro-plant-1`, the listed lava and gas, empty output storage, and the
named recipe.

| Recipe | Ticks | Exact input | Exact recipe output | Gas remaining |
|---|---:|---|---|---:|
| `nullius-lava-iron-separation` | 300 | 100 lava, 60 gas | 4 `nullius-molten-iron-bloom`, 30 gas, 10 stone | 30 |
| `nullius-lava-aluminum-separation` | 300 | 100 lava, 60 gas | 3 `nullius-molten-aluminum-bloom`, 25 gas, 8 stone | 25 |
| `nullius-lava-calcite-separation` | 240 | 80 lava, 48 gas | 6 `nullius-crushed-limestone`, 20 gas | 20 |
| `nullius-lava-silica-extraction` | 180 | 60 lava, 36 gas | 8 `nullius-silica`, 5 stone, 15 gas, 10 `nullius-sulfur-dioxide` | 15 |

The assertion is made on production statistics and storage contents immediately
after the listed tick count. No output may appear before a recipe completes.

## V05 — bloom cooldown

This is a two-row parameterized case using real item spoilage.

| Input at tick 0 | Run | Expected output |
|---|---:|---|
| 4 `nullius-molten-iron-bloom` | 1,800 ticks | 4 `nullius-iron-ingot`, 0 iron bloom |
| 3 `nullius-molten-aluminum-bloom` | 2,400 ticks | 3 `nullius-alumina`, 0 aluminum bloom |

## V06 — aluminum reduction

Input: 1 pneumatic `nullius-small-furnace-1` connected to a heat network at or
above 100 C with at least 2.76 MJ available, 9 `nullius-alumina`, and 5
`nullius-graphite`.

Action: select `nullius-aluminum-ingot` and simulate 2,400 ticks.

Expected output: 3 `nullius-aluminum-ingot`, 4
`nullius-aluminum-carbide`, no alumina, and no graphite.

## V07 — sulfur catalysis

Input: 1 `nullius-vulcanus-radiator-1` connected to a heat network at or above
200 C with at least 4 MJ available, 40 `nullius-sulfur-dioxide`, and 1
`nullius-rutile`.

Action: select `nullius-so2-catalytic-decomposition` and simulate 240 ticks.

Expected output: 40 `nullius-oxygen`, 1 `sulfur`, and the same 1
`nullius-rutile`. The initial catalyst must be present before the first cycle;
the returned catalyst cannot satisfy that initial input.

## V08 — endogenous heat

Input: 4 pneumatic `nullius-hydro-plant-1` connected to infinity lava input and
unbounded product sinks, 96 gas to prime one simultaneous extraction cycle, 30
`nullius-heat-pipe-1`, 1 pneumatic `nullius-small-furnace-1` containing 9
alumina and 5 graphite, and 1 radiator containing 40 sulfur dioxide and 1
rutile. All heat entities start at their engine default temperature.

Action: run `nullius-lava-gas-extraction` continuously in all four hydro plants;
connect both heat consumers through the 30 heat pipes; simulate at most 30,000
ticks.

Expected output before the deadline:

- the furnace reaches at least 100 C and produces 3 aluminum ingots plus 4
  aluminum carbide;
- the radiator reaches at least 200 C and produces 40 oxygen plus 1 sulfur,
  returning 1 rutile;
- every degree of heat comes from hidden interfaces owned by the four working
  pneumatic plants; no preheated entity or debug heat source exists; and
- disconnecting the pipes prevents another thermal cycle after residual heat
  falls below the recipe threshold.

## V09 — one pack

Input: 1 pneumatic `nullius-small-assembler-1`, 3 iron ingots, 2 aluminum
ingots, 1 crushed limestone, 1 silica, 1 sulfur, and 88.5 compressed volcanic
gas.

Action: select `nullius-metallurgic-pack` and simulate 1,800 ticks.

Expected output: exactly 1 metallurgic pack, all five item inputs consumed, and
no gas remaining.

## V10 — replacement construction set

Input:

- the V01 wreck machines as recipe executors, without counting them as output;
- 24 compressed volcanic gas as the finite V02 prime;
- enough volcanic rocks to mine 128 graphite, 100 limestone, and 1 rutile; the
  production fixture accepts exactly those counts and leaves additional mined
  material outside the cell;
- free lava through `nullius-lava-pumping`;
- empty output storage and no injected intermediate.

Action: execute every batch printed by
`@nullius-star/progression/vulcanus-construction.args`. Recipes may run in
parallel and may reuse byproducts. Continue until these target counts have been
produced after activation:

| Target | Count |
|---|---:|
| `nullius-seawater-intake-1` | 1 |
| `nullius-hydro-plant-1` | 5 |
| `nullius-air-filter-1` | 1 |
| `nullius-chemical-plant-1` | 1 |
| `nullius-distillery-1` | 1 |
| `nullius-small-furnace-1` | 1 |
| `nullius-foundry-1` | 1 |
| `nullius-small-assembler-1` | 1 |
| `nullius-medium-assembler-1` | 1 |
| `nullius-vulcanus-radiator-1` | 1 |
| `transport-belt` | 50 |
| `inserter` | 12 |
| `pipe` | 50 |
| `pipe-to-ground` | 10 |
| `storage-tank` | 2 |
| `wooden-chest` | 4 |
| `nullius-heat-pipe-1` | 30 |

Expected static totals: 50 selected production steps, 24,233.4 gas consumed,
and no research beyond the assumed pneumatic closure. Expected terminal gas is
30.6. The other exact terminal surplus is 2 inserters, 100 lava, 88 aluminum
carbide, 2 aluminum ingots, 70 carbon dioxide, 25 crushed limestone, 43 gravel,
1 hydro plant, 1 iron gear, 4 iron rods, 4 iron sheets, the returned rutile, 308
silica, 1 steel beam, 1 steel ingot, 3 pipes, 1 underground pipe, 2,635 stone,
15 sulfur, and 6 belts. Production statistics for every target must be at least
its table count; items already present in the wreck do not satisfy the
assertion. All rocks are mined by the character or an extractor, and all
non-rock ingredients are accounted for by the manifest's recipe outputs.

## V11 — ten-pack material line

Input: the five wreck executor types named by
`@nullius-star/progression/vulcanus-pack.args`, 24 gas as the finite V02 prime,
enough rocks to mine 35 graphite and 1 rutile, free lava, and no injected
intermediate. The fixture accepts exactly those mined counts.

Action: execute the manifest's exact batches:

| Product | Recipe cycles | Single-executor ticks |
|---|---:|---:|
| metallurgic pack | 10 | 18,000 |
| aluminum ingot | 7 | 16,800 |
| sulfur | 10 | 2,400 |
| iron bloom | 8 | 2,400 |
| aluminum bloom | 21 | 6,300 |
| crushed limestone | 2 | 480 |
| silica and sulfur dioxide | 40 | 7,200 |
| dedicated gas | 76 | 9,120 |
| lava pumping | 75 | 4,500 |

The 30 iron blooms spoil for 1,800 ticks and the 63 aluminum blooms spoil for
2,400 ticks before their consumers can use them.

Expected output: exactly 10 metallurgic packs, 5,985 gas consumed, 4 gas
remaining, and terminal surplus of 115 lava, 28 aluminum carbide, 1 aluminum
ingot, 2 crushed limestone, 2 iron blooms, 400 oxygen, the returned rutile, 310
silica, and 676 stone. The pack recipe consumes 30 iron ingots, 20 aluminum
ingots, 10 crushed limestone, 10 silica, and 10 sulfur. No recipe or executor
may differ from the checked-in manifest.

## V12 — complete slice

Input: only the V01 activation result and a fixed map containing a lava shore
and enough volcanic rocks to meet the V10 and V11 raw boundaries. No item,
fluid, heat, recipe output, or equipment is inserted after activation.

Action:

1. recover the wreck and switch to the Vulcanus body;
2. obtain the 24-gas prime through V02 and disconnect the vent;
3. keep V03 dedicated gas production operational;
4. manufacture the complete V10 replacement set;
5. place one additional production cell using only items counted by
   post-activation production statistics;
6. produce 10 metallurgic packs in that cell and insert them into the wreck lab.

Expected output:

- every V10 target count was produced, not merely recovered from the wreck;
- the additional cell's placed entities are matched item-for-entity by those
  post-activation production counts;
- 10 metallurgic packs were produced by that cell and accepted by the wreck
  lab;
- graphite, limestone, and rutile were obtained only by mining the placed
  rocks; lava came only from the intake recipe; and
- the gas network is nonempty and completes another dedicated gas cycle with
  the vent disconnected.
