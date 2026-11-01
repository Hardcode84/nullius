#!/usr/bin/env python3
"""Compare machine counts and energy from matched resolved factory plans."""
import argparse
import json
from pathlib import Path


def compare(config, directory):
    reports = {name: json.loads((directory / filename).read_text())
               for name, filename in config['plans'].items()}
    if len({report['provenance']['dump_sha256'] for report in reports.values()}) != 1:
        raise ValueError('Plans must use the same resolved prototypes')
    rows = []
    for name, report in reports.items():
        stage = next(stage for stage in report['stages'] if stage['name'] == config['stage'])
        for rate in config['rates']:
            plan = next(plan for plan in stage['plans'] if plan['rate_per_minute'] == rate)
            if plan['flow']['status'] != 'optimal' or plan['construction']['flow']['status'] != 'optimal':
                raise ValueError(f'{name} at {rate}: production or construction is infeasible')
            factory = plan['factory']
            machines = sorted(factory['machines'].items(), key=lambda row: (-row[1]['count'], row[0]))
            rows.append(dict(planet=name, rate=rate, demands=plan['demands_per_minute'],
                             machines=factory['process_machines'],
                             active_equivalents=sum(machine['active_equivalents'] for machine in factory['machines'].values()),
                             electric_mw=factory['electric_grid_mw'],
                             heat_mw=sum(factory['heat_demand_mw_by_minimum_temperature'].values()),
                             fuel_per_minute=factory['fuel_per_minute'],
                             research_hours=plan['research_schedule'].get('hours'),
                             labs=plan['research_schedule'].get('lab_count'),
                             construction_machine_hours=plan['construction']['flow']['objective_machine_seconds_per_minute']/3600,
                             raw=plan['flow']['raw_per_minute'],
                             waste={name: amount for name, amount in plan['flow']['discard_per_minute'].items()
                                    if not name.startswith('@')},
                             top_machines=[dict(name=machine, **values) for machine, values in machines[:8]]))
    for row in rows:
        reference = next(r for r in rows if r['planet'] == config['reference'] and r['rate'] == row['rate'])
        row['machines_vs_reference'] = row['machines']/reference['machines']
        row['electric_vs_reference'] = row['electric_mw']/reference['electric_mw'] if reference['electric_mw'] else None
    return dict(stage=config['stage'], reference=config['reference'], rows=rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--plan-directory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    config = json.loads(args.config.read_text())
    report = compare(config, args.plan_directory)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print('Planet | packs/min each | machines (includes labs) | relative count | electric MW | heat MW | compressed fuel/min')
    for row in report['rows']:
        print(f"{row['planet']} | {row['rate']} | {row['machines']} | {row['machines_vs_reference']:.3f} | "
              f"{row['electric_mw']:.1f} | {row['heat_mw']:.1f} | {row['fuel_per_minute']:.0f}")
    for row in report['rows']:
        if row['rate'] != config['rates'][0]:
            continue
        print('\n'+row['planet']+' output: '+', '.join(row['demands']))
        print('Largest machine groups: '+', '.join(f"{m['name']}={m['count']}" for m in row['top_machines']))
        print(f"Active machine equivalents: {row['active_equivalents']:.1f}; construction machine-hours: {row['construction_machine_hours']:.1f}")
        print('Raw input/min: '+json.dumps(row['raw'], sort_keys=True))
        print('Solid discard/min: '+json.dumps(row['waste'], sort_keys=True))


if __name__ == '__main__':
    main()
