# Release checklist

## Release contract

| Field | Assertion |
|---|---|
| Mod identity | `info.json`, archive name, archive root, and portal entry agree |
| Version | Numeric `major.minor.patch` |
| Git tag | Annotated `v<version>` tag resolves to the commit recorded in the release manifest |
| Maturity | Alpha, beta, or stable status is declared |
| Playable endpoint | Last supported progression boundary is declared |
| Save lineage | Supported and unsupported upgrade paths are declared |
| Multiplayer | Support is declared only when server/client validation passes |
| Factorio version | Declared version is included in the tested version matrix |

## Automated candidate gate

```bash
python tools/build_release.py -n auto
```

| Gate | Assertion |
|---|---|
| Checkout | No tracked or untracked changes |
| Metadata | Name, Factorio version, dependencies, and numeric mod version are valid |
| Changelog | First `Version` equals `info.json` version |
| Unit tests | Every repository unit test passes |
| Payload | Every archive member is a tracked regular file under `<mod-name>/` |
| Payload safety | No executable, script, cache, secret, or parent-directory archive entry |
| Reproducibility | Stable file ordering, timestamp, permissions, and compression |
| Dependency isolation | Exactly one installed archive for each tested dependency |
| Prototype load | Exact release ZIP loads with `--check-unused-prototype-data` |
| Prototype strictness | No unused prototype-data warnings |
| New game | Exact release ZIP creates a fixed-seed map |
| Save/load | New map reloads and advances ticks |
| Progression | Every declared progression contract passes against packaged prototypes |
| Locale | Resolved prototype locale audit has zero findings |
| Scenarios | Every independent Factorio scenario passes against packaged payload |
| Output | ZIP and JSON manifest contain matching name, version, commit, size, and SHA-256 |

## Correctness gate

| Area | Assertion |
|---|---|
| Progression | Every reachable path through the declared endpoint is buildable |
| Endpoint | Unfinished paths are unreachable or explicitly terminate |
| Runtime state | Hidden entities and ownership mappings survive save/load, cloning, destruction, and configuration changes |
| Surfaces | Surface properties, map-generation settings, placement restrictions, and checkpoints behave on every supported surface |
| Multiplayer | Force, player, join, late-join, reconnect, and save/reload scenarios pass |
| Dependencies | Minimum and current required dependency combinations pass |
| Optional integrations | Every declared integration has an identified code path and passing test |
| Upstream delta | Relevant upstream crash, migration, API, and compatibility changes are audited |
| Performance | Declared tick, wall-time, and update-time limits pass |

## Portal metadata

| Field | Required content |
|---|---|
| Title | Mod name and release maturity |
| Summary | Current playable endpoint |
| Description | Scope, dependencies, incompatibilities, multiplayer status, and save policy |
| License | Declared license matching packaged license text |
| Attribution | Upstream authors and current contributors |
| Source URL | Public source revision matching release commit |
| Issue URL | Public bug-report location |
| Thumbnail | Included and verified in portal preview |

## Publish sequence

```text
run automated candidate gate
review manifest and portal metadata
upload exact ZIP
download portal ZIP
compare SHA-256
create, save, reload, and advance a fresh map with downloaded ZIP
create annotated v<version> tag on the commit recorded in the manifest
verify the tag resolves to the manifest commit
push the tag
publish endpoint and save/multiplayer policy
```

| Tag operation | Command |
|---|---|
| Create | `git tag --annotate "v<version>" "<manifest-commit>" --message "Release <version>"` |
| Verify target | `test "$(git rev-parse "v<version>^{commit}")" = "<manifest-commit>"` |
| Publish | `git push origin "v<version>"` |

## Upgrade gate

| Gate | Assertion |
|---|---|
| Upgrade fixtures | Saves from every supported prior version load |
| Migration result | Entities, recipes, technologies, forces, and hidden runtime state remain valid |
| Dependency candidates | Minimum and current supported dependency combinations pass |
| Factorio candidate | Current supported and proposed versions produce equivalent required behavior |
