# Automated testing for Factorio mods

## Authorities

| Fact | Authority |
|---|---|
| Test architecture | This document |
| Mod progression | Mod-specific progression document |
| Prototype behavior and values | Factorio resolved prototypes |
| Runtime fixture, actions, assertions | Scenario source |
| Tick limit | Scenario `test.json` |
| Reachability boundary | Checked-in prerequisite arguments |
| Test inventory and result | Test runner discovery and output |

## Engine interface

| Requirement | Production interface |
|---|---|
| Fixed simulation | Scenario and compiled save |
| Bounded execution | `--load-game` with `--until-tick` |
| Repeated execution | `--benchmark` |
| State inspection | Runtime Lua API |
| Machine-readable result | JSON written to `script-output` |

The production executable does not expose Wube's internal C++ test framework.

## Feature tests

```yaml
scope: one runtime or prototype contract
fixture:
  surface: explicit
  force: explicit
  research: explicit
  entities: explicit
  inventories: explicit
action: production event or API path
execution: Factorio simulation
assertions: observable Lua API state
result: one final JSON object
```

- Fixture construction may inject state.
- The operation under test must use its production path.
- Prefer engine events, one-shot callbacks, or coarse `on_nth_tick` checks.
- Lua errors, failed assertions, missing results, tick overruns, and wall-clock
  overruns fail the test.
- Use semantic state assertions; do not use state hashes.

### Prototype load

Load the complete mod set with `--check-unused-prototype-data`. Warnings that
name an owned prototype fail unless their exact text is explicitly accepted.

## Campaign stages

```yaml
boundary: research, production, construction, or sustained-operation goal
map: fixed
execution: independent
save_inheritance: false
parallel: true
fixture: subset of prior attainable state plus declared external boundaries
simulation: real recipes, entities, fluids, heat, spoilage, and logistics
result: achieved boundary and completion tick
```

- Each stage reconstructs its entrance state and runs independently.
- Every injected item, fluid, technology, utility, or debug entity is declared.
- Injected inputs are not counted as stage output.
- Equipment used after construction closure must be reachable from the declared
  boundary.
- Stage duration belongs to its scenario; no shared stage-budget mechanism is
  required.
- Alternative paths use equivalent entrance boundaries and separate scenarios.

## Multiplayer-sensitive behavior

Run the relevant feature or campaign scenario on a dedicated server with the
required clients. Multiplayer validation does not require replaying the entire
campaign.

## External runner

```yaml
discovery: scenario metadata
execution: parallel Factorio processes
success:
  process_exit: 0
  result_status: pass
  within_tick_limit: true
  within_wall_limit: true
report:
  - test name
  - status
  - simulation ticks
  - test duration
  - suite wall time
  - Factorio version
  - loaded mod versions
```

## Factorio version update

```yaml
candidate_check:
  - diff runtime API
  - diff prototype API
  - diff resolved prototypes
  - run feature tests
  - run campaign stages in parallel
  - compare milestone completion and pacing evidence
acceptance:
  all_tests_pass: true
  every_observed_change_explained: true
```

## References

- [Wube integration tests](https://factorio.com/blog/post/fff-60)
- [Factorio command-line parameters](https://wiki.factorio.com/Command_line_parameters)
- [Factorio scenario system](https://wiki.factorio.com/Scenario_system)
