#!/usr/bin/env python3
"""Summarize a factory plan and size ideal lightning and storage requirements."""
import argparse
import json
import hashlib
import math
from pathlib import Path
import shutil

import analyze_factorio_prereqs as prereqs
import plan_factorio_factory as planner


def power_requirement(load_mw, capacity_mj, discharge_mw, captured_mj, seconds):
    """Size full storage for a constant load with no generation during the gap."""
    if min(capacity_mj, discharge_mw, captured_mj, seconds) <= 0 or load_mw < 0:
        raise ValueError('positive storage, capture and gap values required')
    return {'minimum_full_batteries': math.ceil(max(load_mw / discharge_mw,
                load_mw * seconds / capacity_mj) - 1e-9),
            'ideal_captured_strikes_per_minute': load_mw * 60 / captured_mj}


def summarize(data, plan, config):
    bolt = data['lightning'][config['lightning']]
    collector = data['lightning-attractor'][config['collector']]
    captured = min(prereqs.parse_energy(bolt['energy'], 'J') * collector['efficiency'],
                  prereqs.parse_energy(collector['energy_source']['buffer_capacity'], 'J')) / 1e6
    battery = data['accumulator'][config['battery']]['energy_source']
    capacity = prereqs.parse_energy(battery['buffer_capacity'], 'J') / 1e6
    discharge = prereqs.parse_energy(battery['output_flow_limit'], 'W') / 1e6
    rows = []
    for stage in plan['stages']:
        for p in stage['plans']:
            row = {'stage': stage['name'], 'rate': p['rate_per_minute'],
                   'flow': p['flow']['status'], 'unreachable_targets': stage['unreachable_targets']}
            rows.append(row)
            if row['flow'] != 'optimal':
                continue
            factory = p['factory']
            priorities = factory['electric_mw_by_priority']
            if set(priorities) - {'primary-input', 'secondary-input', 'tertiary'}:
                raise ValueError('unsupported electric consumer priority')
            battery_load = sum(priorities.get(name, 0) for name in ('primary-input', 'secondary-input'))
            row['science_lines'] = [r for r in plan.get('science_analysis', {}).get('production_lines', []) if r['stage'] == stage['name'] and r['rate'] == p['rate_per_minute']]
            row.update(stations=factory['process_machines'], electric_mw=factory['electric_grid_mw'],
                installed_mw=factory['electric_installed_mw'],
                priority_mw=priorities, battery_supported_mw=battery_load,
                ideal_captured_strikes_per_minute=factory['electric_grid_mw'] * 60 / captured,
                construction=p['construction']['flow']['status'],
                construction_raw=p['construction']['flow'].get('raw_per_minute'),
                research_packs=p['research']['packs'],
                supply_hours=p['base_research_supply_hours'],
                scheduled_hours=p['research_schedule'].get('hours'), labs=p['research_schedule'].get('lab_count'),
                raw_per_minute=p['flow']['raw_per_minute'],
                materials={name: planner.material_consumption(p, name) for name in config['materials']},
                expected_recipes=factory['expected_output_recipes'],
                machines=sorted([dict(name=name, **{k:v for k,v in m.items() if k != 'recipes'}) for name, m in factory['machines'].items()],
                                key=lambda m: (-m['count'], m['name'])),
                power_drivers=sorted([{'name': name, 'mw': m['electric_mw']} for name, m in factory['machines'].items()],
                                    key=lambda m: (-m['mw'], m['name'])),
                storage={str(seconds): power_requirement(battery_load, capacity, discharge, captured, seconds)
                         for seconds in config['calm_seconds']})
    return {'plan_provenance': plan['provenance'], 'power_boundary': config,
            'battery_capacity_mj': capacity, 'battery_discharge_mw': discharge,
            'capture_mj_per_full_strike': captured,
            'interpretation': 'Storage starts full. Ideal capture excludes clipping, losses, grounding consumption and charging congestion. Batteries only cover primary and secondary inputs; tertiary machines stop without generation. No storm frequency or calm duration is asserted. Process demand excludes logistics and power infrastructure.',
            'rows': rows, 'science_analysis': plan.get('science_analysis')}


def markdown(report):
    lines = ['| Case | Packs/min each | Stations incl. labs | Labs | Demand MW | Installed MW | Supply hours |',
             '|---|---:|---:|---:|---:|---:|---:|']
    for r in report['rows']:
        if r['flow'] != 'optimal':
            lines.append(f"| {r['stage']} | {r['rate']} | Blocked | — | — | — | — |")
        else:
            lines.append(f"| {r['stage']} | {r['rate']} | {r['stations']} | {r['labs']} | {r['electric_mw']:.1f} | {r['installed_mw']:.1f} | {r['supply_hours']:.2f} |")
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan', type=Path)
    parser.add_argument('--config', type=Path, default=Path('tests/progression/planner/fulgora-industry-power.json'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--field')
    parser.add_argument('--stage')
    parser.add_argument('--rate', type=float)
    parser.add_argument('--table', action='store_true')
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        if not args.plan:
            parser.error('--plan is required')
        dump_args = prereqs.parse_arguments([])
        data, work = prereqs.dump_resolved_data(dump_args)
        try:
            plan = json.loads(args.plan.read_text())
            digest = hashlib.sha256((work / 'script-output/data-raw-dump.json').read_bytes()).hexdigest()
            if digest != plan['provenance']['dump_sha256']:
                raise ValueError('factory plan differs from fresh power prototypes; rerun the factory planner')
            report = summarize(data, plan, json.loads(args.config.read_text()))
            report['power_dump_sha256'] = digest
        finally:
            if work:
                shutil.rmtree(work)
        args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
    value = report
    if args.stage:
        value = [r for r in report['rows'] if r['stage'] == args.stage]
        if args.rate is not None:
            value = next(r for r in value if r['rate'] == args.rate)
    if args.field:
        for name in args.field.split('.'):
            value = value[name]
    print(markdown(report) if args.table else json.dumps(value, indent=2, sort_keys=True))


if __name__ == '__main__':
    main()
