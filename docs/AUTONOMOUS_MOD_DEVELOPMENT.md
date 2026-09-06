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

Declare startup-setting changes in the scenario `settings-updates.lua`.
The runner applies that file only in the temporary support mod for that case.

Set `multiplayer: true` in the scenario `test.json`. The runner starts a
loopback server and the first real client. The scenario requests a second
client, disconnect, reconnect, or server save/load through numbered actions.
The runner preserves each connection log. A client error, desync, server
error, missing result, or deadline breach fails the test.

Clients use the full Factorio executable. The runner creates a private Xvfb
display for each scenario and uses Mesa llvmpipe software rendering. No desktop
session, configured display, or GPU is required. Install `Xvfb`, `xauth`, and the
Mesa software OpenGL driver. On Debian or Ubuntu, install the `xvfb`, `xauth`,
`libgl1-mesa-dri`, and `libglx-mesa0` packages.

The runner ignores desktop display variables and hardware-driver selections.
It disables X TCP listening, uses a private authorization cookie, and removes
the display process and cookie on success or failure. `xvfb.log` and all client
logs remain in retained test artifacts. Each client log must confirm llvmpipe
rendering and a clean multiplayer join. Fresh profiles contain no account
credentials.

This runs real clients in a headless environment. It still uses Factorio's
graphics code. The dedicated headless executable in Factorio 2.0.77 rejects
`--mp-connect`, so it cannot replace these clients.

```bash
env -u DISPLAY -u WAYLAND_DISPLAY -u XAUTHORITY -u FACTORIO_CLIENT_DISPLAY python tools/run_factorio_tests.py vulcanus-shared-body --keep-run-directory
python tools/run_factorio_tests.py -n auto
```

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
