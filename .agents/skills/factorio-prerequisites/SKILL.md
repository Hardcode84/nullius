---
name: factorio-prerequisites
description: Analyze Factorio item or production-cell reachability from resolved prototypes, including recursive intermediates, recipe research, crafting providers, explicit raw resources, and bootstrap machines. Use for prerequisite, buildability, progression-closure, or scalable-factory questions; use scenario tests instead for tick behavior, throughput, or layout validation.
---

# Factorio Prerequisites

Run the repository checker from the repository root:

```bash
python3 tools/analyze_factorio_prereqs.py [BOUNDARIES] ITEM[=COUNT] [ITEM[=COUNT] ...]
```

Omit `--data-raw` when checking the current checkout so the tool loads the
actual mod set in Factorio and creates a fresh resolved prototype dump. Reuse a
dump with `--data-raw PATH` only for repeated queries against the same Factorio
version, mod versions, and startup settings.

Use repeatable `--describe-product ITEM` to inspect every resolved producer,
including byproduct recipes, exact inputs and outputs, categories, surface
conditions, and unlock technologies. Use `--describe-recipe RECIPE` when the
exact recipe prototype is already known. Use `--describe-technology TECHNOLOGY`
for its prerequisite, research cost or trigger, and effects contract.
Use repeatable `--describe-consumers ITEM` to inspect every resolved recipe
that consumes an item or fluid, including the amount returned by the same
recipe, its net consumption per cycle, compatible executor entities, and
whether every compatible executor requires electricity.

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
- `--recipe PRODUCT=RECIPE` selects the intended route when several recipes
  produce the same product.
- `--find-dependency ITEM` reports recursive ingredient paths from every target
  to that item at the declared technology and surface boundary. Repeat it for a
  material family. Implicit routes follow only a recipe's primary product; use
  `--recipe PRODUCT=RECIPE` to select an intentional byproduct route.
- `--executor CATEGORY=ENTITY` selects the exact runtime entity whose crafting
  speed and energy source define the manifest.
- `--machine-category CATEGORY` forbids hand crafting for that category.
- `--surface-property NAME=VALUE` excludes recipes incompatible with a declared
  surface property.
- `--forbid-category CATEGORY` excludes an operation unavailable at the
  campaign boundary even when a shared machine item can execute it elsewhere.
  For example, forbid `seawater-pumping` on a surface without seawater while
  retaining the same intake item's lava-pumping mode.
- `--require-no-additional-technologies` makes undeclared research a failing
  contract. Without it, the report lists the additional research closure.

Use `--manifest` with counted targets and `--fuel FLUID` to calculate integer
recipe batches, exact deterministic inputs and outputs, byproducts, executor
ticks, fluid-fuel demand, heat requirements, and the aggregate raw/available
boundaries. The fuel recipe is part of the graph and is sized by net output
after powering itself. The checker fails instead of averaging probabilistic or
ranged results. Put a repeatable contract in an argument file and invoke it as
`@path/to/file.args`.

Declare finite bootstrap material with `--stock ITEM=COUNT`. Unlike
`--available`, stock is consumed and the checker expands production after it is
exhausted. A self-powered fuel recipe must name the first-cycle prime this way;
net-positive steady state does not prove startup from an empty pipe.

Use `--prototype-overlay PATH` only to quantify a deliberately specified
prototype that has not been implemented. An overlay may add prototypes but
cannot replace resolved ones, so implementation forces the contract to be
reconciled rather than silently masking production data.

Use `--json` when another script or test consumes the report. A successful
query proves an acyclic material route and an executor for every selected
recipe. In manifest mode it also proves the reported arithmetic for that exact
route and executor selection. Unknown raw declarations and unresolved products
fail with a nonzero exit status. Do not replace those failures with guessed
recipes or injected items.

Treat the default result as a reachability witness and the manifest as a static
production contract. A manifest's single-executor tick totals do not model
parallel machine scheduling, fluid transfer, heat propagation, placement, or
runtime control behavior; prove those in Factorio scenario tests. For a
production cell, pass every machine and logistics item that the cell must
reproduce as a target, rather than querying only its final product.

When changing the checker, run:

```bash
python3 -m unittest tests/test_analyze_factorio_prereqs.py
```

Also run at least one fresh-dump query representative of the changed behavior.
