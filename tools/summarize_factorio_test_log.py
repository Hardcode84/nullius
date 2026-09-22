#!/usr/bin/env python3
"""Summarize a scenario runner log and group native API failures."""
import argparse
import collections
import json
from pathlib import Path
import re


def prototype_warnings(source):
    if "Finished checking unused prototype data" not in source or "Factorio initialised" not in source:
        raise ValueError("Prototype audit did not finish checking and initializing")
    groups = collections.defaultdict(set)
    count = 0
    for kind, name, field in re.findall(r"Value ROOT\.([^.]+)\.([^.]+)\.(.*?) was not used\.", source):
        if not name.startswith("nullius-"):
            continue
        count += 1
        groups[kind + "." + field.split(".")[0]].add(name)
    return {"nullius_warnings": count, "groups": {
        key: {"prototypes": len(names), "examples": sorted(names)[:3]}
        for key, names in sorted(groups.items())}}


def summarize(source, allow_incomplete=False):
    records = []
    pattern = re.compile(r"^\[(\d+)/(\d+)\] (PASS|FAIL) (\S+) - (.*)$", re.MULTILINE)
    matches = list(pattern.finditer(source))
    for index, match in enumerate(matches):
        block = source[match.end():matches[index + 1].start() if index + 1 < len(matches) else len(source)]
        record = {"case": match[4], "status": match[3].lower()}
        if record["status"] == "fail":
            error = re.search(r"(Lua\w+(?:::| doesn't contain)[^\n]+)", block)
            if not error:
                error = re.search(r"Error while running event[^\n]+\n\s*([^\n]+)", block)
            record["error"] = error[1] if error else next((line.strip() for line in block.splitlines() if line.strip()), "missing diagnostic")
            record["locations"] = list(dict.fromkeys(re.findall(r"(?:__level__|__nullius-star__|\.\.\.)[^\n]*\.lua:\d+[^\n]*", block)))
            artifact = re.search(r"artifacts: (\S+)", block)
            if artifact: record["artifacts"] = artifact[1]
        records.append(record)
    final = re.search(r"^Result: (\d+) passed, (\d+) failed in (.+)$", source, re.MULTILINE)
    if not final and not allow_incomplete:
        raise ValueError("Suite log has no final result; wait for completion")
    counts = collections.Counter(record["status"] for record in records)
    if final and (counts["pass"] != int(final[1]) or counts["fail"] != int(final[2])):
        raise ValueError("Case records do not match the final suite counts")
    failures = [record for record in records if record["status"] == "fail"]
    groups = collections.defaultdict(list)
    for failure in failures: groups[failure["error"]].append(failure["case"])
    return {"complete": final is not None, "passed": counts["pass"], "failed": counts["fail"],
            "duration": final[3] if final else None,
            "failure_counts": {error: len(cases) for error, cases in groups.items()},
            "failure_groups": dict(groups), "failures": failures}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--groups-only", action="store_true")
    parser.add_argument("--allow-incomplete", action="store_true")
    parser.add_argument("--unused-prototypes", action="store_true")
    args = parser.parse_args()
    report = prototype_warnings(args.log.read_text()) if args.unused_prototypes else summarize(args.log.read_text(), args.allow_incomplete)
    if args.output: args.output.write_text(json.dumps(report, indent=2) + "\n")
    if args.groups_only and not args.unused_prototypes: report.pop("failures")
    print(json.dumps(report, indent=2))
