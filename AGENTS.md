# Repository rules

## Repository layout

| Content | Location |
|---|---|
| Distributable Nullius* mod | `nullius-star/` |
| Design and validation documents | `docs/` |
| Factorio scenario tests | `tests/scenarios/` |
| Prerequisite argument contracts | `tests/progression/` |
| Test-support mod | `tests/factorio-test-support/` |
| Python unit tests | `tests/test_*.py` |
| Development commands and analyzers | `tools/` |

- Keep documentation, scenarios, fixtures, test support, and unit tests out of
  `nullius-star/`; that directory is packaged as the released mod.
- Scenario code may import shared scenario modules through the
  `__nullius-star__/scenarios/` namespace. The external runner supplies that
  namespace only in its temporary test overlay.

## Communication

- Lead with concrete results.
- Minimize prose.
- Prefer YAML, JSON, tables, schemas, command lines, and exact assertions.
- Use semantic names; avoid numbered milestone names such as `V0` or `Phase 1`.
- Do not add introductions, aspirations, roadmaps, future-work sections, or
  restatements of the task.
- Name exact failures, mechanisms, inputs, outputs, ticks, counts, and paths.
- Do not use `known limitation`, `pre-existing`, `unrelated`, or equivalent
  language to dismiss a problem.

## Data access

- Use repository scripts, Factorio's Lua API, or resolved-prototype tools.
- Do not manually parse generated or resolved data files with `jq`, `rg`,
  one-off Python, shell pipelines, or similar ad hoc queries.
- Source-code search with `rg` is allowed.
- If a required data query has no script interface:
  1. stop the data investigation;
  2. specify the missing query, inputs, and output schema;
  3. propose a reusable script or an extension to an existing script;
  4. continue only after the script exists.
- Keep repeatable queries in checked-in argument/configuration files.
- Fail on unknown, ambiguous, probabilistic, or ranged values when an exact
  contract is required; do not guess or average.

## Factorio prerequisite analysis

- Use `.agents/skills/factorio-prerequisites/SKILL.md` for reachability,
  production closure, recipe selection, machine selection, and quantities.
- Run `tools/analyze_factorio_prereqs.py` against a fresh Factorio dump unless
  an explicitly matching cached dump is part of the test fixture.
- Declare all boundaries: technologies, raw resources, bootstrap stock,
  available machines, surface properties, recipes, executors, and fuel.
- Include machines and logistics in production-cell targets; a final product
  alone does not prove scalability.
- Model startup stock separately from steady-state net-positive production.

## Test model

```yaml
layers:
  feature:
    scope: one mechanic or recipe
    fixture: declared inputs and placements
    execution: Factorio ticks
    assertions: Lua API and result JSON
  campaign:
    scope: progression boundary
    map: fixed
    execution: real recipes, entities, fluids, heat, spoilage, logistics
    assertions: semantic state
independence:
  save_inheritance: false
  parallel: true
  prior_stage_output: copied-fixture-contract
```

- Use `given`, `place`, `connect`, `act`, `run`, and `expect` for scenario
  specifications.
- Declare every debug/infinity input; never inject an undeclared intermediate
  or target.
- Use production statistics to distinguish crafted equipment from bootstrap
  inventory.
- Test heat/fluid connections through placed entities, including geometry and
  delayed connection where relevant.
- Use semantic assertions, not state hashes.
- Avoid per-tick script work; schedule checks at required ticks or terminal
  events.
- Stage duration is a test contract, not shared orchestration machinery.
- Encode each default deadline in the scenario's `test.json`.
- Run independent scenarios in parallel with `-n auto` unless debugging one
  case.

## Completion

- Run focused tests and fresh resolved-prototype checks appropriate to the
  change.
- Update stale references in adjacent documentation.
- End with a clean worktree unless preserved user changes prevent it.
