# Iron and aluminum water quenching

Each ordinary recipe consumes four hot blooms and two water. Each bulk recipe
consumes twenty hot blooms and ten water. Each box contains five products.

| Product | Dry yield | Quenched yield | Ordinary time | Bulk output | Bulk time |
|---|---:|---:|---:|---:|---:|
| Iron plate | 3 | 4 | 3 s | 4 boxes | 15 s |
| Iron rod | 5 | 7 | 4 s | 7 boxes | 20 s |
| Aluminum plate | 3 | 4 | 4 s | 4 boxes | 20 s |
| Aluminum rod | 5 | 7 | 4 s | 7 boxes | 20 s |

All recipes use the foundry. Quenching keeps each dry recipe's bloom consumption
rate and productivity eligibility. Water is consumed. There is no steam output
or recovery loop. Water quenching unlocks all four ordinary recipes after hot
metalworking and experimental chemistry. Its ten units each cost ten metallurgic,
one mechanical, and one chemical pack, with a unit time of 30 seconds.
Mass production 4 unlocks all four bulk recipes.

The [generated comparison](VULCANUS_QUENCHING_PLAN.md) includes local water
production, gas supply, heat, and waste treatment. It compares dry casting,
quenching, and unrestricted recipe selection for each product at the same output
rates. The unrestricted solver selects quenching for all four products at both
rates. Each route uses less fuel but needs more heat. Most comparisons need more
process stations. Small factories must build several low-duty chemistry stations.

Four separate runtime scenarios supply water through connected pipes. At tick
2,700, each water outage has let four blooms cool. A pneumatic output inserter
moves all four cooled items to a chest: iron ingots for iron blooms, or alumina
for aluminum blooms. New blooms enter through a second inserter after water
returns. The foundry then makes four plates or seven rods. No script removes or
replaces inventory. Each line needs an output path for its product and cooled items.

The prerequisite manifest checks all eight ordinary and boxed routes with declared
bloom and water supplies. The planner separately checks the complete supply
network and the construction flow for one foundry, one water pipe, one heat pipe,
two inserters, and two chests. The runtime fixture supplies its heat interface
and initial fuel. These checks do not measure a complete connected factory.

```bash
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-quenching.json --output /tmp/vulcanus-quenching.json --comparison-output docs/VULCANUS_QUENCHING_PLAN.md --overview
python tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-water-quenching.args
python tools/run_factorio_tests.py vulcanus-water-quenching vulcanus-water-quenching-iron-rod vulcanus-water-quenching-aluminum-plate vulcanus-water-quenching-aluminum-rod -n auto
```
