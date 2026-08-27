---
name: factorio-prerequisites
description: Analyze Factorio item or production-cell reachability from resolved prototypes, including recursive intermediates, recipe research, crafting providers, explicit raw resources, and bootstrap machines. Use for prerequisite, buildability, progression-closure, or scalable-factory questions; use scenario tests instead for tick behavior, throughput, or layout validation.
---

# Factorio Prerequisites

Run the repository checker from the repository root:

```bash
python3 tools/analyze_factorio_prereqs.py [BOUNDARIES] ITEM [ITEM ...]
```

Omit `--data-raw` when checking the current checkout so the tool loads the
actual mod set in Factorio and creates a fresh resolved prototype dump. Reuse a
dump with `--data-raw PATH` only for repeated queries against the same Factorio
version, mod versions, and startup settings.

Declare the starting contract explicitly:

- `--technology TECH` assumes that technology and its prerequisite closure are
  researched. Repeat it for independent starting technologies.
- `--raw ITEM` permits extraction only when the resolved prototypes contain a
  natural minable source. Do not infer planet availability from the existence
  of a prototype; choose raw boundaries from the scenario or campaign contract.
- `--available ITEM` is an existing consumable/item boundary and stops tracing
  that item.
- `--available-machine ITEM` permits that bootstrap machine to execute recipes
  without treating the machine item as a consumable input. Use this for wreck
  or starting equipment.
- `--surface-property NAME=VALUE` excludes recipes incompatible with a declared
  surface property.
- `--require-no-additional-technologies` makes undeclared research a failing
  contract. Without it, the report lists the additional research closure.

Use `--json` when another script or test consumes the report. A successful
query proves an acyclic material route and an executor for every selected
recipe. Unknown raw declarations and unresolved products fail with a nonzero
exit status. Do not replace those failures with guessed recipes or injected
items.

Treat the result as a reachability witness. It does not establish recipe
amounts, throughput, fuel or heat sufficiency, machine counts, placement, or
tick behavior; derive quantities separately and prove runtime behavior with a
Factorio scenario test. For a production cell, pass every machine and logistics
item that the cell must reproduce as a target, rather than querying only its
final product.

When changing the checker, run:

```bash
python3 -m unittest tools/test_analyze_factorio_prereqs.py
```

Also run at least one fresh-dump query representative of the changed behavior.
