---
name: factorio-factory-planner
description: Plan Nullius* factory capacity and research supply time from resolved Factorio prototypes. Use for science-rate comparisons, alternative recipes, co-products, machine counts, fuel, heat, and factory balance. Use scenario tests for actual throughput and layout timing.
---

# Factorio Factory Planner

Run commands from the repository root. Use the maintained planner in
`tools/plan_factorio_factory.py`; do not copy it into this skill or calculate
balance estimates by hand.

```bash
python tools/plan_factorio_factory.py \
  --config tests/progression/planner/vulcanus.json \
  --output /tmp/vulcanus-factory-plan.json --overview
```

This command creates a fresh Factorio prototype dump. Use `--data-raw PATH`
only when the Factorio version, mod sources, and startup settings match that
dump. Install the tested dependencies with
`python -m pip install -r tools/requirements-planner.txt`. The planner records the dump hash and source
revision in the report.

Read [the configuration and query guide](references/configuration.md) when
changing a boundary, inspecting a result, or exporting a runtime fixture.
Keep repeatable boundaries in checked-in configuration files. The Vulcanus
configuration compares 30, 60, and 120 packs/min. These are comparison points;
use the user's requested rates when supplied.

Before reporting a result:

- Check each flow status and each construction status. A feasible science flow
  does not prove that its machines can be built.
- Check excluded recipes, unreachable targets, and blocked inputs. Trace a
  failure to its surface conditions, research unlocks, and compatible machines.
  Compare upstream source before attributing a fork failure to upstream.
- Report the declared raw inputs, seed stock, waste removal, technologies,
  machine catalog, and surface. Seed reachability does not prove that the
  finite seed quantity can start the complete factory.
- Report machine counts with fuel, heat, surplus, and research supply time.
  Counts cover process machines, extractors, and reserved labs. Transport,
  storage, and heat delivery need a declared layout and production-cell targets.
- Separate continuous flow from finite construction. The solver minimizes
  active machine time, then rounds each recipe's station count. It does not
  optimize integer station counts or schedule construction.
- State that research lines and labs are available at time zero in the research
  schedule. Checkpoints and research triggers are assumed satisfied when
  reached. Do not label this value as total player completion time.
- State that the heat model assumes continuous duty and ideal heat delivery.
  Verify geometry, warmup, sampled controller behavior, and actual throughput
  in a Factorio scenario before claiming a working factory rate.

For material reachability or an exact integer batch, use the adjacent
[factorio-prerequisites skill](../factorio-prerequisites/SKILL.md). Include
machines and logistics in production-cell targets. Inspect both ordinary and
boxed recipes when a recipe path changes.

Validate planner changes with:

```bash
python -m unittest discover -s tests -p 'test_plan_factorio_factory.py'
```

Also run a representative fresh-dump plan. If recipe/executor selection changes,
regenerate and run the executor scenario described in the query guide. This
scenario checks selected recipe execution; it does not prove a connected factory.
