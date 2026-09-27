#!/usr/bin/env python3
"""Fixed-fleet batch work bounds from the factory planner's resolved catalog.

Cold analysis path. Fractional cycles and pooled machine time give lower bounds,
not a schedule: startup, recipe changes, travel and electrical outages are absent.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

import numpy as np
from scipy.optimize import linprog

import plan_factorio_factory as planner


def expected_catalog(catalog, names, output_amount=None):
    """Opt in to expected independent returns for named recipes only."""
    if output_amount is not None and (isinstance(output_amount, bool) or not isinstance(output_amount, int) or output_amount < 1):
        raise planner.TestFailure("expected-output amount must be a positive integer")
    found = set()
    result = deepcopy(catalog)
    for row in result:
        if row['recipe'] not in names:
            continue
        found.add(row['recipe'])
        if row['native_productivity']:
            raise planner.TestFailure('expected-output recipes must have zero productivity')
        for product in row['uncertain_outputs']:
            if 'amount' not in product or product.get('shared_probability', {'min': 0, 'max': 1}) != {'min': 0, 'max': 1}:
                raise planner.TestFailure('expected output needs fixed amounts and independent probability')
            probability = product.get('independent_probability', product.get('probability', 1))
            # Guaranteed mode contributed zero for uncertain products.
            row['flows'][product['name']] += (product['amount'] if output_amount is None else output_amount) * probability
    if set(names) != found:
        raise planner.TestFailure('expected recipes absent from the available catalog: ' + str(set(names) - found))
    return result


def character_catalog(data, boundary, name):
    """One real android's solid-only hand crafting, sharing one work budget."""
    character = data['character'][name]
    executor = '<character:' + name + '>'
    view = dict(data)
    view['recipe'] = {n: r for n, r in data['recipe'].items()
                      if not r.get('hide_from_player_crafting', False)
                      and not any(p.get('type') == 'fluid' for p in
                                  list(r.get('ingredients', [])) + planner.prereqs.recipe_results(r))}
    view['assembling-machine'] = {executor: dict(character, name=executor,
        type='assembling-machine', crafting_speed=character.get('crafting_speed', 1),
        energy_source={'type': 'void'}, energy_usage='0W',
        minable={'result': executor})}
    rows, _, _ = planner.recipe_catalog(view, dict(boundary, machines=[executor], extractors={}))
    return executor, rows


def batch_bound(catalog, demands, raw, fleet, buffers, stored_solids, duty=1):
    """Minimize shared fleet work duration while conserving all products."""
    if not 0 < duty <= 1 or any(n <= 0 for n in fleet.values()):
        raise planner.TestFailure('positive fleet counts and duty in (0,1] required')
    catalog = [r for r in catalog if r['machine'] in fleet]
    products = sorted(set(demands) | {p for r in catalog for p in r['flows']})
    index = {p: i for i, p in enumerate(products)}
    columns = [('recipe', r) for r in catalog] + [('raw', p) for p in raw]
    columns += [('store', p) for p in products if p in stored_solids or p in buffers or p.startswith('@heat:')]
    columns += [('seconds', None)]
    material = np.zeros((len(products), len(columns)))
    work = np.zeros((len(fleet), len(columns)))
    machines = sorted(fleet)
    machine_index = {m: i for i, m in enumerate(machines)}
    bounds = []
    for j, (kind, entry) in enumerate(columns):
        bounds.append((0, buffers.get(entry) if kind == 'store' else None))
        if kind == 'recipe':
            for p, v in entry['flows'].items():
                material[index[p], j] = v
            work[machine_index[entry['machine']], j] = entry['seconds']
        elif kind in ('raw', 'store'):
            if entry in index:
                material[index[entry], j] = 1 if kind == 'raw' else -1
        else:
            for m, i in machine_index.items():
                work[i, j] = -fleet[m] * (1 if m.startswith('<character:') else duty)
    cost = np.zeros(len(columns)); cost[-1] = 1
    rhs = np.array([demands.get(p, 0) for p in products])
    # The 4x recovery/no-storage balance makes the default simplex solver
    # return an unknown status. Interior point resolves that case explicitly.
    result = linprog(cost, A_eq=material, b_eq=rhs, A_ub=work,
                     b_ub=np.zeros(len(fleet)), bounds=bounds, method='highs-ipm')
    if result.status == 2:
        return {'status': 'infeasible'}
    if not result.success:
        raise planner.TestFailure('duration solve: ' + result.message)
    # At the optimal duration minimize work and surplus to avoid arbitrary cycles.
    bounds[-1] = (result.fun, result.fun + 1e-6)
    cost = np.array([entry['seconds'] + 1e-6 if kind == 'recipe' else 1e-7
                     for kind, entry in columns])
    result = linprog(cost, A_eq=material, b_eq=rhs, A_ub=work,
                     b_ub=np.zeros(len(fleet)), bounds=bounds, method='highs-ipm')
    if not result.success:
        raise planner.TestFailure('work solve: ' + result.message)
    error = float(np.max(np.abs(material @ result.x - rhs), initial=0))
    if error > 1e-5 or np.max(work @ result.x, initial=0) > 1e-5:
        raise planner.TestFailure('batch conservation or capacity residual exceeded tolerance')
    seconds = float(result.x[-1])
    usage, stored, recipes = defaultdict(float), {}, []
    energy = 0
    for (kind, entry), n in zip(columns, result.x):
        if n < 1e-7:
            continue
        if kind == 'recipe':
            usage[entry['machine']] += n * entry['seconds']
            energy += n * entry['joules']
            recipes.append({'recipe': entry['recipe'], 'machine': entry['machine'], 'cycles': float(n),
                            'machine_seconds': n * entry['seconds']})
        elif kind == 'store':
            stored[entry] = float(n)
    return {'status': 'optimal', 'production_minutes_lower_bound': seconds / 60,
            'active_energy_mj': energy / 1e6, 'conservation_max_error': error,
            'machine_utilization': {m: t / (seconds * fleet[m] * (1 if m.startswith('<character:') else duty)) for m, t in sorted(usage.items())},
            'stored_surplus': stored, 'recipes': recipes,
            'machine_work': {m: sorted([r for r in recipes if r['machine'] == m],
                key=lambda r: -r['machine_seconds']) for m in usage}}


def analyze(data, config):
    if config['uncertain_outputs'] != 'guaranteed':
        raise planner.TestFailure('bootstrap catalog requires guaranteed outputs before explicit mean-yield opt-in')
    if any(p not in data['fluid'] for p in config['buffer_allocation']):
        raise planner.TestFailure('buffer allocation names unknown fluids')
    placements = {item: data['item'][item]['place_result'] for item in config['fleet']}
    base_fleet = {placements[item]: n for item, n in config['fleet'].items()}
    stage = dict(config['boundary'], machines=list(base_fleet))
    boundary = planner.boundary_from_config(data, config, stage)
    catalog, excluded, technologies = planner.recipe_catalog(data, boundary)
    android, hand_rows = character_catalog(data, boundary, config['character'])
    base_fleet[android] = 1
    catalog += hand_rows
    guaranteed_catalog = catalog
    catalog = expected_catalog(guaranteed_catalog, config['expected_recipes'])
    raw = ['@resource:' + s['resource'] for s in config['extractors'].values()]
    reachable = planner.startup_reachability(catalog, {}, raw)
    catalog = [r for r in catalog if set(r['inputs']) <= reachable]
    tank = data['storage-tank'][config['buffer_tank']]['fluid_box']['volume']
    buffers = {p: n * tank for p, n in config['buffer_allocation'].items()}
    solids = set(data.get('item', {})) | set(data.get('tool', {}))
    results = []
    for target in config['targets']:
        demand = dict(target.get('items', {}))
        research = planner.research_cost(data, target.get('research_roots', []), config['entrance_technologies'])
        if research['unquantified']:
            raise planner.TestFailure('unquantified research cost')
        for p, n in research['packs'].items():
            demand[p] = demand.get(p, 0) + n
        lab_minutes = research['lab_hours_at_speed_one'] * 60 / (
            data['lab'][config['lab']]['researching_speed'] * config['labs'])
        row = {'name': target['name'], 'demands': demand, 'research': research,
               'blocked_inputs': planner.blocked_inputs(catalog, demand, reachable),
               'lab_minutes_lower_bound': lab_minutes, 'cases': []}
        for case in config['cases']:
            fleet = dict(base_fleet)
            for m, multiplier in case.get('fleet_multipliers', {}).items():
                fleet[placements[m]] *= multiplier
            storage = {p: n * case.get('buffer_multiplier', 1) for p, n in buffers.items()} if case.get('store_fluids', True) else {}
            for p in case.get('unbounded_buffers', []):
                storage[p] = None
            if case.get('unbounded_fluid_storage'):
                storage = {p: None for p in data['fluid']}
            case_catalog = expected_catalog(guaranteed_catalog, config['expected_recipes'],
                                            case.get('expected_output_amount'))
            case_catalog = [r for r in case_catalog if set(r['inputs']) <= reachable]
            for recipe in case_catalog:
                if recipe['recipe'].startswith('<mine:'):
                    for p in recipe['flows']:
                        if not p.startswith('@') and recipe['flows'][p] > 0:
                            recipe['flows'][p] *= case.get('vent_yield_multiplier', 1)
            try:
                result = batch_bound(case_catalog, demand, raw, fleet, storage, solids,
                                     case.get('duty', 1))
            except planner.TestFailure as error:
                raise planner.TestFailure(f"{target['name']} / {case['name']}: {error}") from error
            result['name'] = case['name']
            result['expected_output_amount'] = case.get('expected_output_amount')
            result['hypothetical'] = result['expected_output_amount'] is not None and any(
                p['amount'] != result['expected_output_amount'] for r in guaranteed_catalog
                if r['recipe'] in config['expected_recipes'] for p in r['uncertain_outputs'])
            if result['status'] == 'optimal':
                result['production_and_lab_minutes_lower_bound'] = max(
                    result['production_minutes_lower_bound'], lab_minutes / case.get('duty', 1))
            row['cases'].append(result)
        for case in row['cases']:
            if case['status'] == 'optimal':
                case['solid_storage_slots'] = sum(int(np.ceil(n / (data.get('item', {}).get(p) or data.get('tool', {}).get(p))['stack_size'] - 1e-9))
                    for p, n in case['stored_surplus'].items() if p in solids)
                case['bottlenecks'] = [m for m, u in case['machine_utilization'].items() if u > .9999]
        results.append(row)
    return {'assumptions': config['assumptions'], 'buffer_capacities': buffers,
            'allowed_technologies': sorted(technologies), 'excluded': excluded, 'targets': results}


def timing_table(report):
    lines = ['| Target | 100% vent yield | Survey high yield | Survey low yield |',
             '|---|---:|---:|---:|']
    labels = {'first-metals': '20 iron plates + 20 aluminum plates',
              'first-expansion': 'Expansion kit', 'first-science': '10 of each early science pack',
              'expansion-and-first-science': 'Expansion kit + first science'}
    for target in report['targets']:
        if target['name'] not in labels:
            continue
        cases = {r['name']: r for r in target['cases']}
        values = []
        for case in ('starter', 'survey-high-yield', 'survey-low-yield'):
            r = cases[case]
            values.append(f"{r['production_minutes_lower_bound']:.1f} min" if r['status'] == 'optimal' else r['status'])
        lines.append('| ' + labels[target['name']] + ' | ' + ' | '.join(values) + ' |')
    return '\n'.join(lines)


def comparison_table(report, cases):
    lines = ['| Target | ' + ' | '.join(cases) + ' |',
             '|---|' + '---:|' * len(cases)]
    for target in report['targets']:
        selected = {r['name']: r for r in target['cases']}
        values = []
        for name in cases:
            case = selected[name]
            values.append(f"{case['production_minutes_lower_bound']:.1f} min"
                          if case['status'] == 'optimal' else case['status'])
        lines.append('| ' + target['name'] + ' | ' + ' | '.join(values) + ' |')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--factorio', type=Path, default=planner.prereqs.default_factorio())
    parser.add_argument('--dependency-mod-directory', type=Path, default=planner.prereqs.default_dependency_mods())
    parser.add_argument('--mod-under-test', type=Path, default=planner.ROOT / 'nullius-star')
    parser.add_argument('--read-plan', type=Path)
    parser.add_argument('--target')
    parser.add_argument('--case')
    parser.add_argument('--field')
    parser.add_argument('--update-fulgora-doc', type=Path)
    parser.add_argument('--table', action='store_true')
    parser.add_argument('--compare-cases', nargs='+')
    args = parser.parse_args()
    if args.read_plan:
        report = json.loads(args.read_plan.read_text())
    else:
        config = json.loads(args.config.read_text())
        dump_args = planner.prereqs.parse_arguments([])
        dump_args.factorio = args.factorio
        dump_args.dependency_mod_directory = args.dependency_mod_directory
        dump_args.mod_under_test = args.mod_under_test
        data, directory = planner.prereqs.dump_resolved_data(dump_args)
        try:
            report = analyze(data, config)
            report['provenance'] = {'config_sha256': hashlib.sha256(args.config.read_bytes()).hexdigest(),
                'planner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                'catalog_planner_sha256': hashlib.sha256(Path(planner.__file__).read_bytes()).hexdigest(),
                'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=planner.ROOT, text=True).strip(),
                'dump_sha256': hashlib.sha256((directory / 'script-output/data-raw-dump.json').read_bytes()).hexdigest()}
            args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
        finally:
            shutil.rmtree(directory)
    if args.compare_cases:
        print(comparison_table(report, args.compare_cases))
        return
    if args.update_fulgora_doc:
        planner.update_markdown_section(args.update_fulgora_doc, 'bootstrap-timing', timing_table(report))
    if args.table:
        print(timing_table(report))
        return
    if args.target:
        report = next(r for r in report['targets'] if r['name'] == args.target)
    if args.case:
        report = next(r for r in report['cases'] if r['name'] == args.case)
    if args.field:
        for key in args.field.split('.'):
            report = report[key]
    elif not args.target:
        report = [{'name': t['name'], 'demands': t['demands'], 'lab_minutes': t['lab_minutes_lower_bound'],
                   'cases': [{k: v for k, v in c.items() if k not in ('recipes', 'stored_surplus', 'machine_utilization', 'machine_work')} for c in t['cases']]}
                  for t in report['targets']]
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (planner.TestFailure, OSError, ValueError, KeyError, StopIteration) as error:
        raise SystemExit(f'ERROR: {error}')
