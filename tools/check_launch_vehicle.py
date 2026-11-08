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
CO2_PROPELLANT = 'nullius-aluminum-co2-propellant'
PREREQUISITES = {
    'nullius-rocket-science-1': ['nullius-physics'],
    'nullius-rocket-science-2': [CHECKPOINT, 'nullius-composites-2'],
    TITANIUM_STRUCTURES: ['nullius-rocket-science-2', 'nullius-volcanic-titanium-metallurgy'],
    CO2_PROPELLANT: ['nullius-rocket-science-1', 'nullius-pneumatic-technology'],
}
# Each launch recipe is unlocked by exactly this technology.
RECIPE_UNLOCKS = {
    'nullius-rocket-stage': 'nullius-rocket-science-2',
    'nullius-titanium-rocket-stage': TITANIUM_STRUCTURES,
    'nullius-aluminum-co2-rocket-fuel': CO2_PROPELLANT,
    'nullius-boxed-aluminum-co2-rocket-fuel': CO2_PROPELLANT,
}
# Vulcanus research: metallurgic science and the Vulcanus probe in its closure.
VULCANUS_TECHNOLOGIES = (TITANIUM_STRUCTURES, CO2_PROPELLANT)
MOVED = {*FORMER_PREREQUISITES, CHECKPOINT}
NEW_TECHNOLOGIES = {CO2_PROPELLANT, 'nullius-rp1-fuel', TITANIUM_STRUCTURES, 'nullius-orbital-construction'}
# Fulgora's boundary supplies these minerals without a priced local route.
FULGORA_MINERALS = {'nullius-crushed-iron-ore', 'nullius-crushed-bauxite', 'nullius-sand',
                    'nullius-crushed-limestone', 'stone', 'nullius-gypsum'}
IMPORTED_BOUND = 2 / 3
TIME_BOUND = 1 / 2


def research_violations(technologies):
    """Return launch research placement and closure violations."""
    violations = [f'{name} prerequisites: expected {expected}, found {technologies[name].get("prerequisites")}'
                  for name, expected in PREREQUISITES.items()
                  if sorted(technologies[name].get('prerequisites') or []) != sorted(expected)]
    former = {name: {**technology, 'prerequisites': FORMER_PREREQUISITES.get(name, technology.get('prerequisites'))}
              for name, technology in technologies.items()}
    for recipe, expected in RECIPE_UNLOCKS.items():
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
    for name in VULCANUS_TECHNOLOGIES:
        if 'nullius-metallurgic-pack' not in (pack for pack, _ in technologies[name]['unit']['ingredients']):
            violations.append(f'{name} does not require metallurgic science')
        if 'nullius-probe-vulcanus' not in prereqs.technology_closure(technologies, {name}):
            violations.append(f'{name} does not require the Vulcanus probe')
    return violations


def split_raw(raw_inputs, local_raw, fluids):
    """Split a manifest's raw inputs into local ore, local gas, and imports."""
    result = {'ore': 0.0, 'gas': 0.0, 'imports': {}}
    for name, amount in raw_inputs.items():
        if name not in local_raw:
            result['imports'][name] = amount
        elif name in fluids:
            result['gas'] += amount
        else:
            result['ore'] += amount
    return result


def material_cost(data, arguments, local_raw, *, mineral_boundary=False):
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
    if available and (not mineral_boundary or set(available) - FULGORA_MINERALS):
        raise prereqs.TestFailure(f'Unpriced launch inputs: {available}')
    inputs = dict(manifest['raw_inputs'])
    for name, amount in available.items():
        inputs[name] = inputs.get(name, 0) + amount
    return dict(raw_inputs=manifest['raw_inputs'], mineral_inputs=available,
                fuel_consumption=manifest['fuel_consumption'],
                **split_raw(inputs, local_raw | set(available), data.get('fluid', {})))


def ratios(variant, default):
    return {kind: variant[kind] / default[kind] for kind in ('ore', 'gas')}


def fuel_cost_violations(costs):
    """Require aluminum-CO2 fuel to cost more than the local fuels off Vulcanus."""
    failed = []
    for planet, routes in costs.items():
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
    """Price each fuel route on the planets other than Vulcanus."""
    costs = {}
    for planet in ('nauvis', 'fulgora'):
        raw = set(prereqs.parse_arguments(['@' + str(CONTRACTS / f'{planet}-launch-boundary.args')]).raw)
        costs[planet] = {route: material_cost(data, CONTRACTS / f'fuel-cost-{planet}-{route}.args', raw,
                                             mineral_boundary=planet == 'fulgora')
                         for route in ('default', 'rp1', 'co2')}
    return costs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--data-raw', type=Path)
    args = parser.parse_args()
    dump_args = prereqs.parse_arguments([])
    dump_args.data_raw = args.data_raw
    data, temporary = prereqs.dump_resolved_data(dump_args)
    try:
        violations = research_violations(data['technology'])
        if violations:
            raise prereqs.TestFailure('Launch research violations:\n' + '\n'.join(violations))
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
        failed.extend(fuel_cost_violations(results['fuel_costs']))
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
