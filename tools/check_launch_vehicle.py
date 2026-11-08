#!/usr/bin/env python3
"""Check launch research placement and rocket stage cost bounds."""
import argparse
import json
from pathlib import Path
import shutil
import analyze_factorio_prereqs as prereqs

ROOT = Path(__file__).resolve().parents[1]
CONTRACTS = ROOT / 'tests/progression'
BOUNDARY = CONTRACTS / 'nauvis-launch-boundary.args'
CHECKPOINT = 'nullius-checkpoint-rocket-fuel'
# Prerequisites of the launch research before it moved to the physics tier.
# Every other technology must keep the closure this tree gave it.
FORMER_PREREQUISITES = {
    'nullius-rocket-science-1': ['nullius-demolitions-2', 'nullius-freight-transportation-3',
                                 'nullius-high-pressure-chemistry-2'],
    'nullius-rocket-science-2': ['nullius-braking-8', 'nullius-personal-transportation-4'],
}
TITANIUM_STRUCTURES = 'nullius-titanium-rocket-structures'
PREREQUISITES = {
    'nullius-rocket-science-1': ['nullius-physics'],
    'nullius-rocket-science-2': [CHECKPOINT, 'nullius-composites-2'],
    TITANIUM_STRUCTURES: ['nullius-rocket-science-2', 'nullius-volcanic-titanium-metallurgy'],
}
# Each stage recipe is unlocked by exactly this technology.
STAGE_UNLOCKS = {
    'nullius-rocket-stage': 'nullius-rocket-science-2',
    'nullius-titanium-rocket-stage': TITANIUM_STRUCTURES,
}
MOVED = {*FORMER_PREREQUISITES, CHECKPOINT}
NEW_TECHNOLOGIES = {'nullius-aluminum-co2-propellant', 'nullius-rp1-fuel', TITANIUM_STRUCTURES, 'nullius-orbital-construction'}
IMPORTED_BOUND = 2 / 3
TIME_BOUND = 1 / 2


def research_violations(technologies):
    """Return launch research placement and closure violations."""
    violations = [f'{name} prerequisites: expected {expected}, found {technologies[name].get("prerequisites")}'
                  for name, expected in PREREQUISITES.items()
                  if sorted(technologies[name].get('prerequisites') or []) != sorted(expected)]
    former = {name: {**technology, 'prerequisites': FORMER_PREREQUISITES.get(name, technology.get('prerequisites'))}
              for name, technology in technologies.items()}
    for recipe, expected in STAGE_UNLOCKS.items():
        unlockers = sorted(name for name, technology in technologies.items()
                           for effect in technology.get('effects') or []
                           if effect.get('type') == 'unlock-recipe' and effect.get('recipe') == recipe)
        if unlockers != [expected]:
            violations.append(f'{recipe} unlocked by {unlockers}, expected {expected}')
    for name in sorted(technologies.keys() - MOVED - NEW_TECHNOLOGIES):
        current = prereqs.technology_closure(technologies, {name})
        expected = prereqs.technology_closure(former, {name})
        if current != expected:
            violations.append(f'{name} closure: lost {sorted(expected - current)}, gained {sorted(current - expected)}')
    return violations


def split_raw(raw_inputs, nauvis_raw, fluids):
    """Split a manifest's raw inputs into Nauvis ore, Nauvis gas, and imports."""
    result = {'ore': 0.0, 'gas': 0.0, 'imports': {}}
    for name, amount in raw_inputs.items():
        if name not in nauvis_raw:
            result['imports'][name] = amount
        elif name in fluids:
            result['gas'] += amount
        else:
            result['ore'] += amount
    return result


def material_cost(data, arguments, nauvis_raw, *, mineral_boundary=False):
    args = prereqs.parse_arguments(['@' + str(arguments)])
    quantities = dict(args.targets)
    args.targets = list(quantities)
    if args.fuel and args.fuel not in args.targets:
        args.targets.append(args.fuel)
    report = prereqs.analyze(data, args)
    if report['unresolved'] or report['required_technologies']:
        raise prereqs.TestFailure(f'Unclosed launch cost boundary: {arguments}')
    manifest = prereqs.build_production_manifest(data, report, quantities, args.fuel, dict(args.stock), True)
    available = manifest['available_inputs']
    minerals = {'nullius-crushed-iron-ore', 'nullius-crushed-bauxite', 'nullius-sand',
                'nullius-crushed-limestone', 'stone', 'nullius-gypsum'}
    if available and (not mineral_boundary or set(available) - minerals):
        raise prereqs.TestFailure(f'Unpriced launch inputs: {available}')
    inputs = dict(manifest['raw_inputs'])
    for name, amount in available.items():
        inputs[name] = inputs.get(name, 0) + amount
    return dict(raw_inputs=manifest['raw_inputs'], mineral_inputs=available,
                energy_joules=manifest['energy_joules'], fuel_consumption=manifest['fuel_consumption'],
                **split_raw(inputs, nauvis_raw | set(available), data.get('fluid', {})))


def ratios(variant, default):
    return {kind: variant[kind] / default[kind] for kind in ('ore', 'gas')}


CO2_TECH = 'nullius-aluminum-co2-propellant'


def co2_research_violations(technologies):
    """Require Vulcanus science, probe ownership, and both fuel unlocks."""
    technology = technologies[CO2_TECH]
    failed = []
    expected = {'nullius-rocket-science-1', 'nullius-pneumatic-technology'}
    if set(technology.get('prerequisites', [])) != expected:
        failed.append('Aluminum CO2 propellant prerequisites differ from the launch design')
    ingredients = technology['unit']['ingredients']
    if not any((part[0] if isinstance(part, list) else part['name']) == 'nullius-metallurgic-pack'
               for part in ingredients):
        failed.append('Aluminum CO2 propellant requires metallurgic science')
    if 'nullius-probe-vulcanus' not in prereqs.technology_closure(technologies, {CO2_TECH}):
        failed.append('Aluminum CO2 propellant requires the Vulcanus probe')
    for recipe in ('nullius-aluminum-co2-rocket-fuel', 'nullius-boxed-aluminum-co2-rocket-fuel'):
        owners = [name for name, tech in technologies.items() for effect in tech.get('effects', [])
                  if effect.get('type') == 'unlock-recipe' and effect.get('recipe') == recipe]
        if owners != [CO2_TECH]:
            failed.append(f'{recipe} must be unlocked only by {CO2_TECH}: {owners}')
    return failed


def fuel_cost_violations(costs, fuel_value, quantity):
    """Check the energy floor and the off-Vulcanus material penalty."""
    failed = []
    for planet, routes in costs.items():
        for route, cost in routes.items():
            energy = sum(cost['energy_joules'].values()) / quantity
            if energy <= fuel_value:
                failed.append(f'{planet} {route} machine energy {energy:g} J/fuel <= {fuel_value:g}')
        if planet == 'vulcanus':
            continue
        co2, default, rp1 = (routes[name] for name in ('co2', 'default', 'rp1'))
        bauxite = 'nullius-bauxite' if planet == 'nauvis' else 'nullius-crushed-bauxite'
        field = 'raw_inputs' if planet == 'nauvis' else 'mineral_inputs'
        if co2[field].get(bauxite, 0) < 2 * default[field][bauxite]:
            failed.append(f'{planet} CO2 fuel requires less than twice the default bauxite')
        for kind in ('ore', 'gas'):
            if co2[kind] <= rp1[kind]:
                failed.append(f'{planet} CO2 {kind} cost must exceed RP-1')
    return failed


def fuel_costs(data):
    costs = {}
    for planet in ('nauvis', 'fulgora', 'vulcanus'):
        boundary = 'vulcanus-co2-fuel-common.args' if planet == 'vulcanus' else f'{planet}-launch-boundary.args'
        raw = set(prereqs.parse_arguments(['@' + str(CONTRACTS / boundary)]).raw)
        routes = ('co2',) if planet == 'vulcanus' else ('default', 'rp1', 'co2')
        costs[planet] = {route: material_cost(data, CONTRACTS / f'fuel-cost-{planet}-{route}.args', raw,
                                             mineral_boundary=planet == 'fulgora') for route in routes}
    return costs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--data-raw', type=Path)
    parser.add_argument('--fuel-only', action='store_true', help='check fuel costs and research without pricing stages or platform components')
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        violations = research_violations(data['technology']) + co2_research_violations(data['technology'])
        if violations:
            raise prereqs.TestFailure('Launch research violations:\n' + '\n'.join(violations))
        if args.fuel_only:
            costs = fuel_costs(data)
            fuel_value = prereqs.parse_energy(data['item']['rocket-fuel']['fuel_value'], 'J')
            args.output.write_text(json.dumps(costs, indent=2) + '\n')
            print(json.dumps(costs, indent=2))
            failed = fuel_cost_violations(costs, fuel_value, 300)
            if failed:
                raise prereqs.TestFailure('Fuel bounds failed: ' + ', '.join(failed))
            return
        nauvis_raw = set(prereqs.parse_arguments(['@' + str(BOUNDARY)]).raw)
        results = {'unchanged_research_closures': len(data['technology'].keys() - MOVED - NEW_TECHNOLOGIES)}
        failed = []
        for fuel in ('composite', 'rp1'):
            costs = {}
            for variant in ('default', 'synthetic', 'imported'):
                prefix = 'launch-cost-' if fuel == 'composite' else 'launch-cost-rp1-'
                costs[variant] = material_cost(data, CONTRACTS / f'{prefix}{variant}.args', nauvis_raw)
            for variant in ('synthetic', 'imported'):
                costs[variant + '_ratio'] = ratios(costs[variant], costs['default'])
            failed.extend(f'{fuel} imported {kind} ratio {value:.3f}'
                          for kind, value in costs['imported_ratio'].items() if value > IMPORTED_BOUND)
            results[fuel] = costs
        results['orbital_components'] = {}
        for component in ('space-platform-foundation', 'space-platform-starter-pack', 'cargo-bay', 'thruster'):
            cost = material_cost(data, CONTRACTS / f'orbital-cost-{component}.args', nauvis_raw)
            results['orbital_components'][component] = dict(cost, ratio_to_launch=ratios(cost, results['composite']['default']))
        results['fuel_costs'] = fuel_costs(data)
        fuel_value = prereqs.parse_energy(data['item']['rocket-fuel']['fuel_value'], 'J')
        failed.extend(fuel_cost_violations(results['fuel_costs'], fuel_value, 300))
        vulcanus_raw = set(prereqs.parse_arguments(['@' + str(CONTRACTS / 'vulcanus-launch-boundary.args')]).raw)
        results['vulcanus_stages'] = {
            variant: material_cost(data, CONTRACTS / f'launch-cost-vulcanus-{variant}.args', vulcanus_raw)
            for variant in ('default', 'titanium')}
        recipes = data['recipe']
        results['time_ratio'] = (recipes['nullius-titanium-rocket-stage']['energy_required']
                                 / recipes['nullius-rocket-stage']['energy_required'])
        args.output.write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(results, indent=2))
        if results['time_ratio'] > TIME_BOUND:
            failed.append(f'time ratio {results["time_ratio"]:.3f}')
        if failed:
            raise prereqs.TestFailure('Rocket stage bounds failed: ' + ', '.join(failed))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
