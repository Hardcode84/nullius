#!/usr/bin/env python3
"""Audit prototype UI locale through Factorio's resolved data and locale dumps."""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Iterable

from run_factorio_tests import (
    BUILTIN_MODS,
    DEPENDENCY_MODS,
    TestFailure,
    default_dependency_mods,
    default_factorio,
    find_archive,
    prepare_config,
    run_factorio,
    tail,
)


REPOSITORY = Path(__file__).resolve().parents[1]
DEFAULT_MOD = REPOSITORY / "nullius-star"
LOCALE_KEY = re.compile(r"^[a-z0-9][a-z0-9_-]*\.[^\s.][^\s]*$")

# Factorio's --dump-prototype-locale file stem and the corresponding locale
# catalogue sections. Sections used only by scripted GUIs are deliberately not
# included: the resolved prototype graph cannot prove those keys unused.
LOCALE_DOMAINS: dict[str, tuple[str, str | None]] = {
    "achievement": ("achievement-name", "achievement-description"),
    "airborne-pollutant": ("airborne-pollutant-name", None),
    "ammo-category": ("ammo-category-name", None),
    "asteroid-chunk": ("asteroid-chunk-name", "asteroid-chunk-description"),
    "autoplace-control": ("autoplace-control-names", None),
    "damage-type": ("damage-type-name", None),
    "decorative": ("decorative-name", "decorative-description"),
    "entity": ("entity-name", "entity-description"),
    "equipment": ("equipment-name", "equipment-description"),
    "fluid": ("fluid-name", "fluid-description"),
    "fuel-category": ("fuel-category-name", None),
    "item-group": ("item-group-name", None),
    "item": ("item-name", "item-description"),
    "mod-setting": ("mod-setting-name", "mod-setting-description"),
    "noise-expression": ("noise-expression-name", "noise-expression-description"),
    "quality": ("quality-name", "quality-description"),
    "recipe": ("recipe-name", "recipe-description"),
    "shortcut": ("shortcut-name", None),
    "space-connection": ("space-connection-name", "space-connection-description"),
    "space-location": ("space-location-name", "space-location-description"),
    "surface": ("surface-name", "surface-description"),
    "surface-property": ("surface-property-name", None),
    "technology": ("technology-name", "technology-description"),
    "tile": ("tile-name", "tile-description"),
    "virtual-signal": ("virtual-signal-name", None),
}
PROTOTYPE_SECTIONS = {
    section
    for sections in LOCALE_DOMAINS.values()
    for section in sections
    if section is not None
}
PROTOTYPE_DOMAIN_ROOTS = {
    "AchievementPrototype": "achievement",
    "DecorativePrototype": "decorative",
    "EntityPrototype": "entity",
    "EquipmentPrototype": "equipment",
    "ItemPrototype": "item",
    "SpaceLocationPrototype": "space-location",
}
SETTING_TYPES = {
    "bool-setting",
    "double-setting",
    "int-setting",
    "string-setting",
}


@dataclass(frozen=True)
class LocaleEntry:
    key: str
    path: Path
    line: int


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Use Factorio's resolved prototype and locale dumps to report missing "
            "and unused English prototype UI locale entries."
        )
    )
    parser.add_argument("--mod", type=Path, default=DEFAULT_MOD)
    parser.add_argument("--prototype-prefix", default="nullius-")
    parser.add_argument("--factorio", type=Path, default=default_factorio())
    parser.add_argument(
        "--dependency-mod-directory",
        type=Path,
        default=default_dependency_mods(),
    )
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--max-results", type=int, default=100)
    parser.add_argument("--json", action="store_true", dest="json_output")
    return parser.parse_args()


def read_mod_name(mod_directory: Path) -> str:
    info_path = mod_directory / "info.json"
    try:
        info = json.loads(info_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise TestFailure(f"cannot read mod metadata {info_path}: {error}") from error
    name = info.get("name")
    if not isinstance(name, str) or not name:
        raise TestFailure(f"mod metadata has no valid name: {info_path}")
    return name


def prepare_mods(
    run_mods: Path, dependency_mods: Path, mod_directory: Path
) -> None:
    run_mods.mkdir(parents=True)
    enabled = list(BUILTIN_MODS)
    for dependency in DEPENDENCY_MODS:
        archive = find_archive(dependency_mods, dependency)
        (run_mods / archive.name).symlink_to(archive)
        enabled.append(dependency)

    mod_name = read_mod_name(mod_directory)
    (run_mods / mod_name).symlink_to(
        mod_directory.resolve(), target_is_directory=True
    )
    enabled.append(mod_name)
    (run_mods / "mod-list.json").write_text(
        json.dumps(
            {"mods": [{"name": name, "enabled": True} for name in enabled]},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def run_dumps(
    factorio: Path,
    dependency_mods: Path,
    mod_directory: Path,
    timeout_seconds: int,
) -> tuple[dict[str, Any], dict[str, dict[str, dict[str, str]]], str]:
    run_directory = Path(tempfile.mkdtemp(prefix="factorio-locale-audit-"))
    try:
        for directory in ("script-output", "temp"):
            (run_directory / directory).mkdir()
        config = prepare_config(run_directory, factorio)
        mods = run_directory / "mods"
        prepare_mods(mods, dependency_mods, mod_directory)
        common = [
            str(factorio),
            "--config",
            str(config),
            "--mod-directory",
            str(mods),
            "--disable-audio",
        ]
        for option, label in (
            ("--dump-data", "resolved prototype"),
            ("--dump-prototype-locale", "prototype locale"),
        ):
            log = run_directory / f"{option[2:]}.log"
            completed = run_factorio([*common, option], log, timeout_seconds)
            if completed.returncode != 0:
                raise TestFailure(
                    f"Factorio {label} dump exited {completed.returncode}\n{tail(log)}"
                )

        output = run_directory / "script-output"
        raw_path = output / "data-raw-dump.json"
        if not raw_path.is_file():
            raise TestFailure(f"Factorio did not create {raw_path.name}")
        data_raw = json.loads(raw_path.read_text(encoding="utf-8"))
        locale_dumps: dict[str, dict[str, dict[str, str]]] = {}
        for domain in LOCALE_DOMAINS:
            path = output / f"{domain}-locale.json"
            if not path.is_file():
                raise TestFailure(f"Factorio did not create {path.name}")
            value = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(value, dict) or not isinstance(value.get("names"), dict):
                raise TestFailure(f"invalid Factorio locale dump: {path}")
            descriptions = value.get("descriptions", {})
            if not isinstance(descriptions, dict):
                raise TestFailure(f"invalid descriptions in Factorio locale dump: {path}")
            locale_dumps[domain] = {
                "names": value["names"],
                "descriptions": descriptions,
            }

        log_text = (run_directory / "dump-prototype-locale.log").read_text(
            encoding="utf-8"
        )
        version_match = re.search(r"Factorio ([0-9.]+) ", log_text)
        if version_match is None:
            raise TestFailure("Factorio locale dump log has no version")
        version = version_match.group(1)
        return data_raw, locale_dumps, version
    finally:
        shutil.rmtree(run_directory, ignore_errors=True)


def parse_locale_catalog(locale_directory: Path) -> dict[str, LocaleEntry]:
    if not locale_directory.is_dir():
        raise TestFailure(f"locale directory not found: {locale_directory}")
    entries: dict[str, LocaleEntry] = {}
    for path in sorted(locale_directory.glob("*.cfg")):
        section: str | None = None
        for line_number, raw_line in enumerate(
            path.read_text(encoding="utf-8-sig").splitlines(), start=1
        ):
            line = raw_line.strip()
            if not line or line.startswith(("#", ";")):
                continue
            if line.startswith("[") and line.endswith("]"):
                section = line[1:-1].strip()
                if not section:
                    raise TestFailure(f"empty locale section: {path}:{line_number}")
                continue
            if "=" not in raw_line:
                raise TestFailure(f"invalid locale entry: {path}:{line_number}")
            name = raw_line.split("=", 1)[0].strip()
            if not name:
                raise TestFailure(f"empty locale key: {path}:{line_number}")
            key = f"{section}.{name}" if section is not None else name
            if key in entries:
                previous = entries[key]
                raise TestFailure(
                    f"duplicate locale key {key}: {previous.path}:{previous.line} "
                    f"and {path}:{line_number}"
                )
            entries[key] = LocaleEntry(key, path, line_number)
    return entries


def resolved_prototype_tables(data_raw: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result = {}
    for prototype_type, table in data_raw.items():
        if not isinstance(table, dict):
            continue
        prototypes = {
            name: prototype
            for name, prototype in table.items()
            if isinstance(name, str)
            and isinstance(prototype, dict)
            and prototype.get("type") == prototype_type
            and prototype.get("name") == name
        }
        if prototypes:
            result[prototype_type] = prototypes
    return result


def prototype_type_domains(prototype_api: dict[str, Any]) -> dict[str, str]:
    prototypes = prototype_api.get("prototypes")
    if not isinstance(prototypes, list):
        raise TestFailure("Factorio prototype API has no prototype list")
    by_name = {
        prototype.get("name"): prototype
        for prototype in prototypes
        if isinstance(prototype, dict) and isinstance(prototype.get("name"), str)
    }

    def domain_for(prototype: dict[str, Any]) -> str | None:
        current = prototype
        visited = set()
        while current is not None:
            name = current["name"]
            if name in visited:
                raise TestFailure(f"cycle in Factorio prototype API at {name}")
            visited.add(name)
            if name in PROTOTYPE_DOMAIN_ROOTS:
                return PROTOTYPE_DOMAIN_ROOTS[name]
            typename = current.get("typename")
            if typename in LOCALE_DOMAINS:
                return typename
            parent = current.get("parent")
            current = by_name.get(parent) if isinstance(parent, str) else None
        return None

    result = {}
    for prototype in prototypes:
        if not isinstance(prototype, dict):
            continue
        typename = prototype.get("typename")
        if not isinstance(typename, str):
            continue
        domain = domain_for(prototype)
        if domain is not None:
            result[typename] = domain
    for prototype_type in SETTING_TYPES:
        result[prototype_type] = "mod-setting"
    return result


def read_prototype_type_domains(factorio: Path) -> dict[str, str]:
    api_path = factorio.resolve().parents[2] / "doc-html" / "prototype-api.json"
    if not api_path.is_file():
        raise TestFailure(f"Factorio prototype API not found: {api_path}")
    try:
        prototype_api = json.loads(api_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise TestFailure(f"cannot read Factorio prototype API {api_path}: {error}") from error
    return prototype_type_domains(prototype_api)


def visible_in_ui(prototype: dict[str, Any], prototype_type: str = "") -> bool:
    if prototype.get("hidden", False) or prototype.get(
        "hidden_in_factoriopedia", False
    ):
        return False
    return not (
        prototype_type == "technology" and prototype.get("enabled") is False
    )


def requires_resolved_name(prototype: dict[str, Any], domain: str) -> bool:
    # A recipe with no explicit name is displayed using its main product. The
    # prototype-locale dump intentionally omits that derived recipe name.
    return domain != "recipe" or "localised_name" in prototype


def applicable_type_domains(
    prototype_tables: dict[str, dict[str, Any]],
    type_domains: dict[str, str],
) -> dict[str, str]:
    return {
        prototype_type: type_domains[prototype_type]
        for prototype_type in sorted(prototype_tables)
        if prototype_type in type_domains
    }


def collect_locale_references(value: Any, path: str = "") -> dict[str, list[str]]:
    references: dict[str, list[str]] = defaultdict(list)

    def visit(node: Any, current_path: str) -> None:
        if isinstance(node, dict):
            for key, child in node.items():
                visit(child, f"{current_path}.{key}" if current_path else str(key))
        elif isinstance(node, list):
            if node and isinstance(node[0], str) and LOCALE_KEY.fullmatch(node[0]):
                references[node[0]].append(current_path)
            for index, child in enumerate(node):
                visit(child, f"{current_path}[{index}]")

    visit(value, path)
    return dict(references)


def merge_references(
    destination: dict[str, list[str]], source: dict[str, list[str]]
) -> None:
    for key, paths in source.items():
        destination[key].extend(paths)


def audit_locale(
    data_raw: dict[str, Any],
    locale_dumps: dict[str, dict[str, dict[str, str]]],
    catalog: dict[str, LocaleEntry],
    prototype_prefix: str,
    type_domains: dict[str, str],
) -> dict[str, Any]:
    prototype_tables = resolved_prototype_tables(data_raw)
    applicable_domains = applicable_type_domains(prototype_tables, type_domains)
    explicit_references: dict[str, list[str]] = defaultdict(list)
    visible_explicit_references: dict[str, list[str]] = defaultdict(list)
    for prototype_type, prototypes in prototype_tables.items():
        for name, prototype in prototypes.items():
            paths = collect_locale_references(
                prototype, f"{prototype_type}.{name}"
            )
            merge_references(explicit_references, paths)
            if visible_in_ui(prototype, prototype_type):
                merge_references(visible_explicit_references, paths)
    used_references: dict[str, list[str]] = defaultdict(list)
    merge_references(used_references, explicit_references)

    missing_prototypes = []
    for prototype_type, domain in sorted(applicable_domains.items()):
        resolved = locale_dumps[domain]
        name_section, description_section = LOCALE_DOMAINS[domain]
        for name, prototype in sorted(prototype_tables[prototype_type].items()):
            if (
                name.startswith(prototype_prefix)
                and visible_in_ui(prototype, prototype_type)
                and requires_resolved_name(prototype, domain)
                and name not in resolved["names"]
            ):
                missing_prototypes.append(
                    {"prototype_type": prototype_type, "name": name, "domain": domain}
                )
            if "localised_name" not in prototype and name in resolved["names"]:
                used_references[f"{name_section}.{name}"].append(
                    f"{prototype_type}.{name}.<default-name>"
                )
            if (
                description_section is not None
                and "localised_description" not in prototype
                and name in resolved["descriptions"]
            ):
                used_references[f"{description_section}.{name}"].append(
                    f"{prototype_type}.{name}.<default-description>"
                )

    def owned_reference(key: str) -> bool:
        section, _, name = key.partition(".")
        owner_section = prototype_prefix.rstrip("-")
        return name.startswith(prototype_prefix) or section == owner_section

    missing_keys = [
        {"key": key, "references": sorted(paths)}
        for key, paths in sorted(visible_explicit_references.items())
        if owned_reference(key) and key not in catalog
    ]
    used_keys = set(used_references)
    unused = [
        {
            "key": key,
            "path": str(entry.path),
            "line": entry.line,
        }
        for key, entry in sorted(catalog.items())
        if key.partition(".")[0] in PROTOTYPE_SECTIONS and key not in used_keys
    ]
    return {
        "schema": 1,
        "prototype_count": sum(len(table) for table in prototype_tables.values()),
        "mapped_prototype_types": len(type_domains),
        "catalog_entry_count": len(catalog),
        "referenced_key_count": len(used_references),
        "missing_prototypes": missing_prototypes,
        "missing_keys": missing_keys,
        "unused_keys": unused,
        "prototype_type_domains": dict(sorted(applicable_domains.items())),
    }


def limited(values: list[dict[str, Any]], maximum: int) -> Iterable[dict[str, Any]]:
    return values if maximum == 0 else values[:maximum]


def render_human(report: dict[str, Any], maximum: int) -> None:
    print(
        f"Factorio {report['factorio_version']}: "
        f"{report['prototype_count']} resolved prototypes, "
        f"{report['catalog_entry_count']} locale entries, "
        f"{report['referenced_key_count']} referenced keys"
    )
    groups = (
        ("Missing prototype names", "missing_prototypes"),
        ("Missing referenced keys", "missing_keys"),
        ("Unused prototype UI keys", "unused_keys"),
    )
    for title, field in groups:
        values = report[field]
        print(f"\n{title}: {len(values)}")
        for value in limited(values, maximum):
            if field == "missing_prototypes":
                print(
                    f"  {value['prototype_type']}.{value['name']} "
                    f"(Factorio locale domain: {value['domain']})"
                )
            elif field == "missing_keys":
                print(f"  {value['key']} <- {value['references'][0]}")
            else:
                path = Path(value["path"])
                try:
                    rendered_path = path.relative_to(REPOSITORY)
                except ValueError:
                    rendered_path = path
                print(f"  {rendered_path}:{value['line']}: {value['key']}")
        omitted = len(values) - len(list(limited(values, maximum)))
        if omitted:
            print(f"  ... {omitted} more; use --max-results 0 or --json")


def main() -> int:
    args = parse_arguments()
    try:
        if args.max_results < 0:
            raise TestFailure("--max-results must be non-negative")
        factorio = args.factorio.expanduser().resolve()
        dependency_mods = args.dependency_mod_directory.expanduser().resolve()
        mod_directory = args.mod.expanduser().resolve()
        if not factorio.is_file():
            raise TestFailure(f"Factorio executable not found: {factorio}")
        if not dependency_mods.is_dir():
            raise TestFailure(f"dependency mod directory not found: {dependency_mods}")
        if not (mod_directory / "info.json").is_file():
            raise TestFailure(f"mod directory not found: {mod_directory}")

        catalog = parse_locale_catalog(mod_directory / "locale" / "en")
        type_domains = read_prototype_type_domains(factorio)
        data_raw, locale_dumps, factorio_version = run_dumps(
            factorio,
            dependency_mods,
            mod_directory,
            args.timeout_seconds,
        )
        report = audit_locale(
            data_raw,
            locale_dumps,
            catalog,
            args.prototype_prefix,
            type_domains,
        )
        report["factorio_version"] = factorio_version
        report["mod"] = str(mod_directory)
        report["locale"] = "en"
        if args.json_output:
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            render_human(report, args.max_results)
        finding_count = sum(
            len(report[field])
            for field in ("missing_prototypes", "missing_keys", "unused_keys")
        )
        return 1 if finding_count else 0
    except (
        TestFailure,
        OSError,
        json.JSONDecodeError,
        subprocess.TimeoutExpired,
    ) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
