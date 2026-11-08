#!/usr/bin/env python3
"""Check launch material costs and unchanged research prerequisite closures."""
import argparse
import json
from pathlib import Path
import shutil
import analyze_factorio_prereqs as prereqs

ROOT = Path(__file__).resolve().parents[1]
MOVED = {'nullius-rocket-science-1', 'nullius-checkpoint-rocket-fuel', 'nullius-rocket-science-2'}


def research_snapshot(data):
    return {name: sorted(prereqs.technology_closure(data['technology'], {name}))
            for name in data['technology']}


def material_cost(data, arguments):
    args = prereqs.parse_arguments(['@' + str(arguments)])
    quantities = dict(args.targets)
    args.targets = list(quantities)
    report = prereqs.analyze(data, args)
    if report['unresolved'] or report['required_technologies']:
        raise prereqs.TestFailure(f"Unclosed launch cost boundary: {arguments}")
    manifest = prereqs.build_production_manifest(data, report, quantities, None, {}, True)
    if manifest['available_inputs']:
        raise prereqs.TestFailure(f"Unpriced launch inputs: {manifest['available_inputs']}")
    return dict(raw_inputs=manifest['raw_inputs'], total=sum(manifest['raw_inputs'].values()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-baseline', type=Path)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        current = research_snapshot(data)
        if args.write_baseline:
            args.write_baseline.write_text(json.dumps(current, indent=2) + '\n')
            args.output.write_text(json.dumps({'technologies': len(current)}) + '\n')
            return
        results = {}
        if args.baseline:
            baseline = json.loads(args.baseline.read_text())
            changed = [name for name in baseline if name not in MOVED and current.get(name) != baseline[name]]
            if changed:
                raise prereqs.TestFailure(f"Unintended prerequisite closure changes: {changed}")
            results['unchanged_research_closures'] = len(baseline) - len(MOVED)
        for variant in ('default', 'synthetic', 'imported'):
            results[variant] = material_cost(data, ROOT / 'tests/progression' / f'launch-cost-{variant}.args')
        base = results['default']['total']
        results['imported_ratio'] = results['imported']['total'] / base
        results['synthetic_ratio'] = results['synthetic']['total'] / base
        results['time_ratio'] = data['recipe']['nullius-titanium-rocket-stage']['energy_required'] / data['recipe']['nullius-rocket-stage']['energy_required']
        args.output.write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(results, indent=2))
        if results['imported_ratio'] > 2/3 or results['time_ratio'] > .5:
            raise prereqs.TestFailure('Rocket stage cost or time bound failed')
    finally:
        if temporary:
            shutil.rmtree(temporary)

if __name__ == '__main__':
    main()
