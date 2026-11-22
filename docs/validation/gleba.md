# Gleba validation

## Cultivation from the probe wreck

The `gleba-cultivation` scenario uses one hand isolation, the wreck equipment and the two landing patches. The android keeps mining mat samples by hand; a nutrient miner and nutrient inserter feed ferric rock into the nutrient crusher. Each machine runs when its inputs are ready, and machines supply all later fuel and materials. Leach residue roasts into `nullius-silica`, which casts standard `nullius-glass` in the nutrient foundry. The android handcrafts `Small Assembler 1` from a wreck inserter and local materials, switches it to nutrient mode, and reproduces a silica-insulated motor and four replacement inserters. On Factorio 2.1.24 the first biochemistry pack reached Lab 1 at tick 6,075. Wild Strain Cultivation finished at tick 19,980. The new biology lab accepted a local microbiology pack at tick 27,315. The run fixed goop from rock in 17 batches, recycled digestate in 5 batches and ended with less than one recycling batch of digestate. The scenario deadline is 30,000.

## Biology tree before the Gleba redesign

The counts below refer to the tree before Gleba cultivation. The release check compares
the new graph with the resolved tree from the parent release.

| Direction | Count | Technologies |
|---|---:|---|
| Biology technologies with main-tree prerequisites | 34 | Biochemistry 1-5, 7, 8; Biology 1-2; Botany 1-2; Ecology 1-6; Evolution 1-7; Zoology 1-3; Carbon Sequestration 4; Locomotion 5; Nitrogen Chemistry 3; Personal Transportation 5; Weaving 3; Wildlife Management 2; Woodworking |
| Main-tree technologies requiring biology | 8 | Artificial Intelligence 2, Battery Storage 5, Cybernetics 7, Genetic Archive 1 and 2, Rocket Science 3, Solar Power 4, Uranium Processing |

36 technologies cost biology packs, and every one costs only biology packs.
Biochemistry 1 costs ordinary packs and unlocks the biochemistry pack and the
biology lab.

## Research checks

Compare the implemented graph with the parent release using fresh resolved
prototypes. List the direct crossings above and their inherited prerequisites.
For every moved technology, record each retained ingredient or machine gate
and each removed edge. Reject undeclared changes to dependent research.
Check each pack, its usable lab, and each new recipe at its owning research
with `--require-no-additional-technologies`. Check bulk recipes along with
loose recipes. Run deployment and seawater applications on their named surfaces.

Extend the research-pacing comparison to the probe, Wild Strain Cultivation,
Biochemistry 1, both fork tips, Zoology 3 and Orbital Construction. Compare
total packs by type and lab time. In the campaign, measure time from transfer
to the first microbiology research, then time to chemical science and the first
cargo delivery. On the early-biology test route, complete Biochemistry 1 before Experimental
Chemistry with the wreck equipment and ongoing local production.

## Deterministic recipe checks

The prerequisite analyzer currently credits every listed result to a closure, including probabilistic ones, and quantity manifests reject them. It must not credit a result with probability below 1 unless the contract declares it `--available`. Gleba contracts consume this rule.

## Fuel inventory checks

`gleba-fuel-spoilage`, Factorio 2.1.24:

| Case | Result |
|---|---|
| Goop spoils in the fuel slot of an idle nutrient lab | The digestate moves to the burnt-result slot; the fuel slot accepts fresh goop |
| Goop spoils while the burnt-result slot is full | The digestate stays in the fuel slot, which then refuses goop |
| A nutrient inserter picks up from the blocked lab without electricity | It removes the fuel-slot digestate first, then continues with the burnt-result slot; the fuel slot accepts goop again |
| Wild culture spoils | It becomes culture sludge; sludge digestion and digestate recycling return it to goop |

## Surface conditions and nutrient modes

`gleba-surface-and-modes`, Factorio 2.1.24 (140 assertions, tick 900):

| Check | Result |
|---|---|
| Forbidden Gleba entities | Solar panels, wind turbines, grid batteries, supercapacitors, Stirling engines, steam turbines, seawater intakes, water wells, and normal logistic robots fail `nullius-hydrogen-sulfide <= 0`; they and pneumatic machines, which require `nullius-ambient-temperature >= 100`, fail placement on `nullius-gleba` |
| Forbidden Gleba voids | `nullius-void-oxygen`, `nullius-void-compressed-oxygen`, and `nullius-void-sulfur-dioxide` fail on `nullius-gleba` and pass on `nauvis`. A nutrient chimney on Gleba vents nitrogen and leaves the same amount of oxygen untouched |
| Gleba air | A nutrient air filter runs `nullius-air-separation-gleba`, makes nitrogen and no `nullius-air`; nutrient air filters cannot be placed on Nauvis |
| Hand crafts | A character on Gleba finishes `nullius-isolate-wild-culture` and `nullius-gleba-small-assembler-1`; a character on Nauvis with the same ingredients makes neither |
| Ordinary biology | `nullius-biochemistry-pack` and `nullius-algae` keep no surface conditions |
| Locked blueprint downgrade | Placing a `-nutrient` ghost on Gleba before `Nutrient Technology` reverts to the ordinary entity |
| Mode transitions | The `Ctrl+R` transition, called through the test-support hook, switches inserters, assemblers, hydro plants, pumps, boxers, labs, and biology labs into and out of `-nutrient` mode while preserving health, never creating electric energy, and spilling fuel on leave |
| Upgrade chains | `variant_upgrades.apply("-nutrient")` keeps `next_upgrade` in nutrient mode across inserters, assemblers, crushers, chemical plants, furnaces, foundries, labs, and pumps |

`tests/progression/gleba-construction.args` closes local zero-electricity production of `nullius-motor-1`, `inserter`, `transport-belt`, `wooden-chest`, `pipe`, `nullius-small-assembler-1`, `nullius-small-miner-1`, `nullius-small-furnace-1`, `nullius-foundry-1`, `nullius-crusher-1`, `nullius-pump-1`, and `nullius-biology-lab` at `Wild Strain Cultivation` with `--require-no-additional-technologies` and `--require-no-electricity`.

Factorio 2.1.24 ignores recipe surface conditions for a machine's fixed recipe: a nutrient air filter fixed to `nullius-air` finished 3 cycles on Gleba with the recipe limited to `nullius-hydrogen-sulfide <= 0`. Gleba air is therefore selected by the nutrient filter's fixed recipe.

## Acceptance contracts

| Contract | Check |
|---|---|
| Surface | `surface-mapgen-contract` covers planet terrain. `gleba-activation` checks both resource patches and the absence of natural enemies |
| Surface conditions | Oxygen void, sulfur dioxide void, and electricity generators fail on Gleba; mat culture fails elsewhere; no biology recipe has a surface condition |
| Electricity | Every ground production closure on Gleba rejects electricity-required executors, as `vulcanus-launch-closure.args` |
| Seeds | On the Nauvis boundary without imports, no living product closes; with declared wild culture, the ordinary biology chain closes at its research |
| Biology branch | The proposed `tools/check_biology_branch.py` checks the pack owners, shared research gates, and changes to dependent research in the release build. |
| Contained culture | Every biology pack closes on the Gleba boundary at the research that unlocks it |
| Randomness | Every Gleba closure passes with probabilistic results uncredited |
| Spoiled fuel | `gleba-fuel-spoilage` checks spoiled goop in free and full burnt-result slots, inserter removal and the dead-culture route back to goop |
| Goop energy | A release check fails if a Nauvis or Fulgora goop recipe yields more fuel value than its organic inputs |
| Carbon | No Gleba recipe cycle, including the goop-digestate loop, returns more carbon than it consumes |
| Machine modes | Transitions between ordinary, nutrient, and bioreactor modes keep recipes and contents and never create energy or health |
| Bootstrap | Check that the starting inventory contains only the listed equipment. Harvest mat samples by hand and use the manual recipe to produce the first wild culture and nutrient goop. Use that batch and the wreck equipment to reproduce basic machines and logistics without imports. |
| Early research | From the equipment-only wreck, complete Wild Strain Cultivation in Lab 1. Build the biology lab from local materials and complete Biochemistry 1 there before chemical science. Record handcrafts and elapsed ticks. |
| Science | Supply all six normal packs, all seven biology packs and single-planet astronomy at their named research boundaries. Check the machines, fuel and ingredients with `--require-no-additional-technologies`. |
| Bioreactor closure | Goop on Nauvis and Fulgora closes on each boundary at the research that unlocks bioreactor tier 1 |
| Transit | `astronomy-transit` measures the Gleba-Nauvis leg and the reference transit stays at its current value |
| Space logistics | From the probe boundary, finish Orbital Construction with locally earned checkpoints and packs. Launch a locally built platform, fill a cargo request, deliver to Nauvis and return using only Gleba supplies. |
| Spoiling exports | Every spoiling Gleba export outlasts the recording spoil time |

## Earlier biology requirements

Before Gleba cultivation the biology lab cost 3 Lab 2s, a Sensor Node 2, a
Nanofabricator 1, 2 Logistic Bot 2s and 10 boxes of insulation, and Biochemistry
1 cost 1,000 units after Physics and Organic Chemistry 6. The early lab now
replaces that construction gate on every surface. Biochemistry 1 has not moved
yet, so on Nauvis the cheaper lab arrives at the old research gate.
