# Gleba validation

## Cultivation from the probe wreck

The `gleba-cultivation` scenario uses one hand isolation, the wreck equipment and the two landing patches. The android mines 15 mat samples and three rocks. Machines supply all subsequent fuel and materials. On Factorio 2.1.24 the first biochemistry pack reached Lab 1 at tick 3,840. Wild Strain Cultivation finished at tick 14,085. The new biology lab accepted a local microbiology pack at tick 15,510. The scenario deadline is 15,600.

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

A spoiled item that stays in a one-slot fuel inventory blocks the burner, as the
antimatter-trap migration found. Before goop is designed around it, an
engine-witness scenario records whether inserters remove spoiled items from fuel
inventories and whether digestate in the burnt-result slot is removed.

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
| Spoiled fuel | Engine witness: spoiled goop and digestate leave fuel and burnt-result slots of placed nutrient machines |
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

The current lab costs 3 Lab 2s, a Sensor Node 2, a Nanofabricator 1, 2 Logistic
Bot 2s and 10 boxes of insulation. Current Biochemistry 1 costs 1,000 units
after Physics and Organic Chemistry 6. The early lab and the two culture
recipes replace these construction and research gates together.
