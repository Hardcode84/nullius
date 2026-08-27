# Repository rules

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
- Local Factorio documentation: `/home/vano/factorio-mod-wiki/`.

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
- Run independent scenarios in parallel with `-n auto` unless debugging one
  case.

## Engineering

- Handle supported cases completely or fail loudly.
- Fix the contract that permits a bug before adding fallback branches.
- Prefer fewer states, branches, flags, adapters, and dependencies.
- Add no dependency until an existing repository or standard-library facility
  is insufficient.
- Tests must exercise production behavior; do not weaken production contracts
  for test convenience.
- A passing test is evidence only when its fixture and assertions exercise the
  named mechanism.
- Preserve user changes and unrelated dirty-worktree files.
- Use `apply_patch` for manual file edits.
- Before replacing a design document:
  1. write the complete replacement beside the original;
  2. compare both for required contracts;
  3. delete or replace the original only after the comparison.

## Completion

```bash
git diff --check
git status
git add <task-files>
git commit -m "..."
git status
```

- Run focused tests and fresh resolved-prototype checks appropriate to the
  change.
- Update stale references in adjacent documentation.
- End with a clean worktree unless preserved user changes prevent it.
