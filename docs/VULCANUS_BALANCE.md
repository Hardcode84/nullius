# Vulcanus balance audit

The [generated factory plan](VULCANUS_FACTORY_PLAN.md) supersedes the rate and
capacity estimates below. Use the [factory planner skill](../.agents/skills/factorio-factory-planner/SKILL.md)
for new estimates. The historical batch audit below does not size an industrial factory.

## Result

The local path to first physics science has an argon research cycle.
A factory without imported argon or previously completed physics research
cannot complete this path. The current physics contract does not detect this
cycle because it supplies post-physics research.

The research budget is also large. After pneumatic technology, the prerequisite
closure for physics, volcanic titanium, and volcanic alkali needs 58,864 geology
packs. At 5 packs per minute for each science type, pack supply alone needs at
least 196.2 hours. This is a conditional budget, not a completion time for the
blocked path.

No gameplay values were changed for this audit.

## Boundary and evidence

| Input | Contract |
|---|---|
| Game | Factorio 2.0.77, build 84539 |
| Prototype snapshot | Fresh resolved dump; hash and source revision in `data/vulcanus-balance.json` |
| Entrance | Pneumatic technology and its prerequisites are complete |
| Surface | Ambient-temperature property 200; seawater pumping excluded |
| Local raw inputs | Each stage declares rock materials and HCl; no imported intermediates |
| Startup fuel | 24 compressed volcanic gas unless the stage declares other stock |
| Research model | Base pack costs; no lab productivity bonus; shared prerequisites counted once |
| Capacity model | Repeat each declared batch at 1 or 5 target items per minute; no productivity bonus |
| Runtime | Nine independent scenarios passed |

Research belongs to the force. Research completed on Nauvis reduces the remaining
budget. These costs do not apply unchanged to an established force that has
already reached chemical or physics science elsewhere. The command-based start
also grants an entrance boundary; it is not a new-campaign timing witness.

The analytical contracts supply installed machines. Their construction is not
included unless the machine is also an explicit target. Several runtime cases
supply intermediate materials and heat. Neither the contracts nor the nine cases
form a continuous wreck-to-physics campaign.

## Blocking chain

```text
first physics packs
  -> lab 2, batteries, Stirling engine 2
  -> processors, carbon fiber, compressed argon
  -> argon
  -> residual gas
  -> air separation 4
  -> 2,700 physics packs
```

`data-final-fixes.lua` restricts ordinary air separation and pressure air
separation to ambient temperature at most 50. The Vulcanus replacement consumes
150 air and produces 120 CO2, 15 nitrogen, and 10 SO2. It produces no residual
gas. The unrestricted `nullius-residual-gas` recipe unlocks at
`nullius-air-separation-4`, after physics science.

The audit removes all recipes that require physics-consuming technologies or
their descendants. Physics remains unreachable even when advanced machines are
supplied. The missing final ingredients are lab 2, Stirling engine 2, substation
2, and boxed missile 1. Their blocked branches converge on argon. The report
retains each blocked recipe and ingredient.

A correct repair must provide residual gas or argon on Vulcanus before these
technologies. It must preserve the planet's air composition and the ban on
ordinary oxygen separation. A separate trace-gas recipe must fit the selected
machine's output fluid boxes. Validation must run that recipe, carbon fiber,
processors, batteries, and a physics batch with no physics-consuming research
and no imported argon. Adding more assumed technologies to the physics contract
cannot repair the progression cycle.

## Research cost and time

These totals include shared prerequisites once. Do not add stage rows together.
Checkpoint tokens are script requirements, not additional manufactured science.

| Science | Packs through physics and local titanium/alkali |
|---|---:|
| Geology | 58,864 |
| Climatology | 57,154 |
| Mechanical | 56,602 |
| Electrical | 50,998 |
| Chemical | 47,241 |
| Metallurgic | 1,310 |

| Continuous supply per science type | Minimum pack-supply time |
|---|---:|
| 1 pack/min | 981.1 h |
| 5 packs/min | 196.2 h |

Formula: `max(pack totals) / packs_per_minute / 60`.
The model permits each pack line to operate from the start. Real unlock order,
construction, stock shortages, travel, and checkpoints add time. Production and
research can overlap; do not add their complete durations.

Research requires 532.94 lab-hours at speed 1 before bonuses. For comparison,
ten speed-2 labs provide 20 units of research speed, or 26.65 hours of aggregate
lab capacity for that workload. Those labs are not available from the start.
The lab-2 checkpoint requires ten placed lab-2 entities. Other checkpoints
require material consumption and placed infrastructure, not just science packs.
The required closure includes consumption checkpoints for 300,000 propene,
40,000 crushed iron ore, and 40,000 aluminum carbide. It also includes net-build
checkpoints for 20 Stirling engine 2 entities, four large tank 2 entities, and
four substation 2 entities. These force-wide requirements are excluded from the
pack-supply time and chemistry station counts.

The early efficient-metallurgy unlock is much smaller: 10 metallurgy, 10 geology,
5 mechanical, and 5 electrical packs, plus 150 lab-seconds at speed 1. It can
follow basic science. Chemical-science completion is not a prerequisite.

The current broad physics contract assumes research that consumes another
59,506 physics packs. Its 267 selected recipes and 17 machine types describe a
late factory boundary. They do not establish the cost of first physics.

## Runtime measurements

Game time is measured at 60 ticks per second. Test-runner wall time is separate.
The nine cases completed in 2 min 21 s of runner wall time.

| Scenario output | Game time | Important supplied boundary |
|---|---:|---|
| 10 bootstrap metallurgy packs | 35.285 min | 43 placed process machines, 27 heat pipes, prepared heat network, raw graphite and catalyst |
| Construction-cell targets | 49.315 min | Wreck fixture plus parallel machines; scripted material transfer |
| 10 each of four basic sciences | 64.001 min | 58 placed process machines, 25 heat pipes; also builds a gas reserve |
| 10 chemical packs | 15.03 s | All intermediates supplied; 10 chemical plants |
| Titanium pilot: 3 plates | 36.17 s | Acid, chlorine, sand, aluminum, graphite and fuel supplied; heat set by script |
| Foundry 2 and hydro plant 2 | 31.07 s | Construction materials and fuel supplied |
| 5 efficient metallurgy packs | 15.37 s | Hot blooms, barrel fluids and fuel supplied |
| Thermal nanofabricators | 38.33 s | Recipe inputs and heat interfaces supplied |
| Self-powered gas | 5.08 s from scenario start | Two gas cycles; not a long-duration capacity test |

The manifest runner moves materials through a script ledger. It does not use a
complete belt and pipe layout. The first three measurements prove bounded
production under their fixtures; the short chemical and titanium measurements
prove final process operation. Do not sum these times to estimate a campaign.

## Infrastructure and throughput

The chemical-science contract can be quantified from its declared local raw
inputs. Ten packs require 50 selected recipes and 1.539 aggregate executor-hours
in the zero-productivity reference model. This includes 226.5 seconds of hand
crafting. The contract supplies 13 process-machine types.

| Chemical-chain capacity | 1 pack/min | 5 packs/min |
|---|---:|---:|
| Dedicated process stations | 38 | 68 |
| Hydro plants | 7 | 19 |
| Foundries | 6 | 13 |
| Chemical plants | 9 | 12 |
| High-temperature radiators | 1 | 4 |
| Low-temperature radiators | 2 | 4 |
| HCl input per minute | 1,708 | 8,540 |
| Compressed gas consumed per minute | 3,223.81 | 16,119.05 |
| Player hand-crafting utilization | 37.75% | 188.75% |

Station counts round each recipe's workload up separately. A pooled machine
count is smaller, but requires recipe changes and inventory transfer. These
counts exclude hand-crafting stations, station construction, belts, inserters,
pipes, storage, labs, heat sources, heat loss, and warmup. The 5-pack/min route
cannot be sustained by one player while its hand-crafting steps remain manual.

Thermal foundries, furnaces, and crushers have native productivity. The reference
model omits that bonus; its material and workload totals are not exact in-game
consumption. It also uses early machines and selected routes, not an optimized
late factory. Rutile is a retained catalyst in this chemical route. The initial
one-unit charge must not be treated as recurring rutile consumption. The report
separates gross batch inputs from net raw consumption.

The wreck has four hydro plants. Even the chemical-only 5-pack/min reference
needs about 15.42 fully occupied hydro-plant equivalents, or 19 dedicated recipe
stations. Basic science, metallurgy, construction, and physics add demand.
Thus 5 packs/min needs substantial expansion beyond the landing inventory.

No complete physics-factory station count is established. The research cycle
blocks first physics, and the broad late-game manifest also fails its execution
schedule on the selected air/residual-gas chain. Reachability alone cannot
supply a valid total machine count or floor area.

## Balance assessment

| Finding | Effect | Required decision or correction |
|---|---|---|
| Argon requires physics research | Local first physics cannot finish | Add and validate a pre-physics trace-gas path |
| About 59,000 packs on the largest prerequisite line | 1–5 packs/min implies hundreds of hours | Set an explicit research-time budget before changing costs |
| Bootstrap metallurgy takes 60 recipe-seconds per pack; efficient metallurgy takes 3 | 20-fold assembly-time reduction | Treat ten bootstrap packs as the initial target; unlock efficient production early |
| Efficient metallurgy returns a barrel with probability 0.9 | Exact finite-batch manifest fails | Use runtime evidence or explicit best/worst return bounds; do not use an average as an exact contract |
| Chemistry requires HCl, gas, and 450 C cracking | Hydro capacity and heat delivery dominate early expansion | Validate continuous HCl supply and heat delivery at the chosen science rate |
| Synthetic rutile consumes 50 sand and 150 sulfuric acid per rutile | Titanium shifts load into acid and solids handling | Include the acid line when sizing titanium production |
| Physics recipe outputs 25 boxes, or 125 packs, per 900-second base cycle | First output is a large batch | Use 125 packs as the first-batch witness; 25 requested packs do not reduce the recipe batch |

A 40-hour pack-supply budget requires at least 24.53 packs/min on the largest
line before construction and unlock delays. A 20-hour budget requires at least
49.05 packs/min. These are required rates, not proof that such factories fit
within those durations. Keep the current research costs only if this scale and
duration are intended. The current evidence does not support a short,
self-contained Vulcanus stage at 1–5 packs/min.

## Reproduction

```bash
mkdir -p build/audits
python tools/run_factorio_tests.py \
  vulcanus-metallurgic-pack-10 vulcanus-basic-science-10 \
  vulcanus-chemical-pack-10 vulcanus-construction-closure \
  vulcanus-titanium-pilot vulcanus-titanium-construction \
  thermal-nanofabricators vulcanus-efficient-metallurgic-science \
  vulcanus-gas-self-power -n auto --result-json build/audits/vulcanus-runtime.json
python tools/audit_vulcanus_progression.py \
  --runtime-results build/audits/vulcanus-runtime.json \
  --output build/audits/vulcanus-audit.json \
  --export-summary docs/data/vulcanus-balance.json
python tools/audit_vulcanus_progression.py \
  --read-report build/audits/vulcanus-audit.json \
  --stage pre-physics-recipes --field blocked_recipes
python -m unittest discover -s tests -p 'test_audit_vulcanus_progression.py'
python -m unittest discover -s tests -p 'test_analyze_factorio_prereqs.py'
```
