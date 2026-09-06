# Iron water quenching

| Recipe | Inputs | Output | Time | Unlock |
|---|---|---|---|---|
| Dry hot casting | 4 hot iron blooms | 3 iron plates | 3 s | Hot metalworking |
| Water quenching | 4 hot iron blooms, 2 water | 4 iron plates | 3 s | Water quenching |
| Bulk water quenching | 20 hot iron blooms, 10 water | 4 boxes, each with 5 plates | 15 s | Mass production 4 |

All three recipes use the foundry. Quenching keeps the dry recipe's bloom
consumption rate and productivity eligibility. Water is consumed. There is no
steam output or recovery loop. The ordinary quenching research follows hot
metalworking and experimental chemistry. Its ten units each cost ten metallurgic,
one mechanical, and one chemical pack, with a unit time of 30 seconds.

The [generated comparison](VULCANUS_QUENCHING_PLAN.md) includes local water
production, gas supply, heat, and waste treatment. It compares dry casting,
quenching, and unrestricted recipe selection at the same output rates. The
unrestricted solver selects quenching with the two-water dose. The recipe uses
less bloom and fuel but needs more process stations and heat. Small factories
must build several low-duty chemistry stations to obtain this benefit.

Retain the iron recipe as the tested production slice. The report does not
establish a water dose or a yield for iron rods or aluminum products.

The runtime test supplies water through a connected pipe. At tick 2,100, the
water outage has let four blooms cool. A pneumatic output inserter moves all four iron
ingots to a chest. New blooms enter through a second inserter after water returns.
The foundry then makes four plates. No script removes or replaces inventory.
The line must have an output path for both iron plates and cooled iron ingots.

The prerequisite manifest checks the ordinary and boxed routes with declared
bloom and water supplies. The planner separately checks the complete supply
network and the construction flow for one foundry, one water pipe, one heat pipe,
two inserters, and two chests. The runtime fixture supplies its heat interface
and initial fuel. These checks do not measure a complete connected factory.

```bash
python tools/plan_factorio_factory.py --config tests/progression/planner/vulcanus-quenching.json --output /tmp/vulcanus-quenching.json --comparison-output docs/VULCANUS_QUENCHING_PLAN.md --overview
python tools/analyze_factorio_prereqs.py @tests/progression/vulcanus-water-quenching.args
python tools/run_factorio_tests.py vulcanus-water-quenching vulcanus-hot-casting planner-chemical-executors planner-physics-executors -n auto
```
