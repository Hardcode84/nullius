#!/usr/bin/env python3
"""Report Fulgora burst power from fresh prototypes and optional native samples."""
import argparse
import json
import hashlib
import subprocess
import math
from pathlib import Path

if __package__:
    from .analyze_factorio_prereqs import dump_resolved_data, parse_energy
    from .run_factorio_tests import MOD_UNDER_TEST, default_factorio, default_dependency_mods
else:
    from analyze_factorio_prereqs import dump_resolved_data, parse_energy
    from run_factorio_tests import MOD_UNDER_TEST, default_factorio, default_dependency_mods


def minimum_demand(offered, ratio, floor):
    """Return the demand that prevents a trip at either strict threshold."""
    return max(0, min(offered / ratio, offered - floor))


def report(data, config):
    collector = data['lightning-attractor']['nullius-pole-lightning-collector']
    bolt = data['lightning']['nullius-fulgora-lightning']
    battery = data['accumulator']['nullius-grid-battery-1']['energy_source']
    source = collector['energy_source']
    energy = parse_energy(bolt['energy'], 'J') * collector['efficiency']
    capacity = parse_energy(source['buffer_capacity'], 'J')
    output = parse_energy(source['output_flow_limit'], 'W')
    charge = parse_energy(battery['input_flow_limit'], 'W')
    storage = parse_energy(battery['buffer_capacity'], 'J')
    fleet_config = json.loads(Path(config['fleet_config']).read_text())
    fleet = dict(fleet_config['fleet'])
    fleet[fleet_config['lab']] = fleet_config['labs']
    machines = []
    for name, count in fleet.items():
        entity_name = data['item'][name]['place_result']
        matches = [table[entity_name] for table in data.values()
                   if isinstance(table, dict) and entity_name in table
                   and isinstance(table[entity_name], dict)
                   and 'energy_source' in table[entity_name]]
        if len(matches) != 1:
            raise ValueError(f'Ambiguous energy consumer: {name}: {len(matches)}')
        entity = matches[0]
        supply = entity['energy_source']
        if supply['type'] != 'electric':
            continue
        use = entity.get('energy_usage', entity.get('energy_consumption'))
        if use is None:
            raise ValueError(f'Missing electric usage: {name}')
        machines.append({'name': name, 'count': count,
                         'active_MW': count * parse_energy(use, 'W') / 1e6,
                         'drain_MW': count * parse_energy(supply.get('drain', '0W'), 'W') / 1e6})
    candidates = []
    for cap in [output / 1e6, *config['candidate_output_MW']]:
        for active in config['charged_poles']:
            offered = cap * active * 1e6
            demand = minimum_demand(offered, config['ratio'], config['excess_floor_MW'] * 1e6)
            for load in config['load_MW']:
                candidates.append({'output_per_pole_MW': cap, 'charged_poles': active,
                    'load_MW': load, 'minimum_total_demand_MW': demand / 1e6,
                    'minimum_empty_batteries': max(0, math.ceil((demand - load * 1e6) / charge)),
                    'full_storage_trips': load * 1e6 < demand})
    sensitivity = []
    for factor in config['strike_energy_factors']:
        captured = min(capacity, energy * factor)
        sensitivity.append({'strike_energy_factor': factor, 'captured_MJ': captured / 1e6,
                            'full_rate_seconds': captured / output,
                            'minimum_batteries_for_energy': math.ceil(captured / storage)})
    return {'collector': {'captured_MJ_per_strike': energy / 1e6,
            'buffer_MJ': capacity / 1e6, 'output_MW': output / 1e6,
            'full_rate_seconds_per_strike': min(energy, capacity) / output},
        'battery': {'count': config['batteries'], 'total_MJ': storage * config['batteries'] / 1e6,
                    'total_charge_MW': charge * config['batteries'] / 1e6,
                    'total_discharge_MW': parse_energy(battery['output_flow_limit'], 'W') * config['batteries'] / 1e6,
                    'seconds_to_charge_empty': storage / charge},
        'storms': data['planet']['nullius-fulgora']['lightning_properties'],
        'machines': machines, 'fleet_active_MW': sum(m['active_MW'] + m['drain_MW'] for m in machines),
        'fleet_idle_MW': sum(m['drain_MW'] for m in machines),
        'candidates': candidates, 'strike_energy_sensitivity': sensitivity,
        'buffer_sensitivity': [{'buffer_MJ': cap, 'full_output_seconds': cap * 1e6 / output,
                                'bank_MJ': cap * max(config['charged_poles']),
                                'maximum_capture_fraction': min(1, cap * 1e6 / energy)}
                               for cap in config['candidate_buffer_MJ']]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=Path('tests/progression/planner/fulgora-power.json'))
    parser.add_argument('--factorio', type=Path, default=default_factorio())
    parser.add_argument('--dependency-mod-directory', type=Path, default=default_dependency_mods())
    parser.add_argument('--mod-under-test', type=Path, default=MOD_UNDER_TEST)
    parser.add_argument('--data-raw', type=Path)
    parser.add_argument('--timeout-seconds', type=int, default=300)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--native-results', type=Path)
    parser.add_argument('--drain-results', type=Path)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--profile', action='append', help='Print only native samples for named profiles')
    args = parser.parse_args()
    if args.read_report:
        result = json.loads(args.read_report.read_text())
    else:
        data, work = dump_resolved_data(args)
        result = report(data, json.loads(args.config.read_text()))
        result['dump_directory'] = str(work) if work else None
        result['resolved_sha256'] = hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()
        result['source_revision'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
        result['config_sha256'] = hashlib.sha256(args.config.read_bytes()).hexdigest()
    if args.native_results:
        native = json.loads(args.native_results.read_text())
        if native['status'] != 'pass':
            raise ValueError('Native scenario run did not pass')
        matches = [r for r in native['results'] if r['case'] == 'fulgora-power-budget']
        if len(matches) != 1:
            raise ValueError('Expected exactly one native power scenario')
        case = matches[0]
        summaries = []
        for row in case['observations']:
            for phase in ('direct', 'day', 'night'):
                sample = row[phase]
                n = sample['samples']
                summaries.append({'name': row['name'], 'phase': phase,
                    'captures_per_minute': sample['captures'] / (n / 120),
                    'potential_capture_MW': sample['captures'] * result['collector']['captured_MJ_per_strike'] / (n / 2),
                    'trip_percent': sample['trip_samples'] / n * 100,
                    'powered_percent': sample['powered_samples'] / n * 100,
                    'mean_offered_MW': sample['sum_offered_MW'] / n,
                    'mean_demand_MW': sample['sum_demand_MW'] / n,
                    'mean_charged_poles': sample['sum_charged_poles'] / n,
                    'max_charged_poles': sample['max_charged_poles'],
                    'end_collector_MJ': sample['end_collector_MJ'],
                    'end_battery_MJ': sample['end_battery_MJ']})
        result['native'] = summaries
        result['native_factorio_version'] = case['factorio_version']
        result['native_first_flows'] = [{k: v for k, v in r.items() if k in ('name', 'first_trip', 'first_flow')}
                                       for r in case['observations']]
    if args.drain_results:
        run = json.loads(args.drain_results.read_text())
        if run['status'] != 'pass':
            raise ValueError('Native drain scenario run did not pass')
        cases = [r for r in run['results'] if r['case'] == 'fulgora-collector-drain']
        if len(cases) != 1:
            raise ValueError('Expected one collector drain result')
        samples = cases[0]['observations']['samples']
        first, second = samples[:2]
        result['drain'] = {
            'observed_discharge_MW': (first['networks'][0]['energy_MJ'] - second['networks'][0]['energy_MJ']) / (second['seconds'] - first['seconds']),
            'last_nonempty_seconds': max(s['seconds'] for s in samples if s['networks'][0]['energy_MJ'] > 0),
            'first_empty_seconds': min(s['seconds'] for s in samples if s['networks'][0]['energy_MJ'] == 0),
            'end_idle_MJ': samples[-1]['networks'][1]['energy_MJ'],
            'end_loaded_MJ': samples[-1]['networks'][0]['energy_MJ'],
            'end_loaded_offered_MW': samples[-1]['networks'][0]['offered_MW'],
        }
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    if 'drain' in result:
        print('drain', json.dumps(result['drain']))
    if args.profile:
        unknown = set(args.profile) - {row['name'] for row in result.get('native', [])}
        if unknown:
            raise ValueError(f'Unknown native profiles: {sorted(unknown)}')
        for row in result['native']:
            if row['name'] in args.profile:
                print(json.dumps(row))
        return
    for field in ('collector', 'battery', 'fleet_active_MW', 'fleet_idle_MW', 'machines', 'strike_energy_sensitivity', 'buffer_sensitivity'):
        print(field, json.dumps(result[field]))
    if 'native' in result:
        print('native_first_flows', json.dumps(result['native_first_flows']))
        for row in result['native']:
            print('native', json.dumps(row))
    print('output_MW charged_poles load_MW minimum_empty_batteries full_storage_trips')
    for row in result['candidates']:
        print(*(row[k] for k in ('output_per_pole_MW', 'charged_poles', 'load_MW', 'minimum_empty_batteries', 'full_storage_trips')))


if __name__ == '__main__':
    main()
