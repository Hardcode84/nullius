#!/usr/bin/env python3
"""Check radio astronomy research, planetary production, and correlation yields."""
import argparse
import itertools
import json
import shutil
from pathlib import Path
import analyze_factorio_prereqs as prereqs
from check_launch_vehicle import material_cost

ROOT = Path(__file__).resolve().parents[1]
PLANETS = ('fulgora', 'nauvis', 'vulcanus')


def ladder_violations(data):
    """Return errors in the resolved distinct-planet correlation ladder."""
    errors = []
    expected_names = set()
    previous = 0
    for size in range(1, len(PLANETS) + 1):
        for planets in itertools.combinations(PLANETS, size):
            name = 'nullius-correlate-' + '-'.join(planets)
            expected_names.add(name)
            recipe = data['recipe'].get(name)
            if not recipe:
                errors.append('Missing ' + name)
                continue
            count = 20 if size == 1 else 10
            inputs = {f'nullius-{p}-interferometric-recording': count for p in planets}
            products = {'nullius-blank-recording-module': count * size,
                        'nullius-astronomy-pack': 1 if size == 1 else 10 * size * (size - 1) // 2}
            if {i['name']: i['amount'] for i in recipe['ingredients']} != inputs:
                errors.append(name + ': unequal or repeated source planets')
            if {p['name']: p['amount'] for p in recipe['results']} != products:
                errors.append(name + ': incorrect science yield or blank return')
            if recipe.get('maximum_productivity') != 0:
                errors.append(name + ': productivity permitted')
            ratio = products['nullius-astronomy-pack'] / (count * size)
            if ratio <= previous:
                errors.append(name + ': no benefit from larger array')
        previous = 0.05 if size == 1 else (size - 1) / 2
    actual = {name for name in data['recipe'] if name.startswith('nullius-correlate-')}
    if actual != expected_names:
        errors.append('Unexpected correlation recipes: ' + str(actual - expected_names))
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data, temporary = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
    try:
        errors = ladder_violations(data)
        technologies = data['technology']
        for planet in ('fulgora', 'vulcanus'):
            name = f'nullius-{planet}-radio-astronomy'
            entry = 'nullius-primitive-filtration' if planet == 'fulgora' else 'nullius-pneumatic-technology'
            if set(technologies[name]['prerequisites']) != {'nullius-astronomy', entry}:
                errors.append(name + ': incorrect research boundary')
        expected_unlocks = {'nullius-radio-dish': 'nullius-astronomy',
                            'nullius-correlator': 'nullius-astronomy',
                            'nullius-blank-recording-module': 'nullius-astronomy',
                            'nullius-boxed-blank-recording-module': 'nullius-astronomy',
                            'nullius-radio-dish-pneumatic': 'nullius-vulcanus-radio-astronomy'}
        for planet in PLANETS:
            expected_unlocks[f'nullius-{planet}-interferometric-recording'] = (
                'nullius-astronomy' if planet == 'nauvis' else f'nullius-{planet}-radio-astronomy')
        for recipe in data['recipe']:
            if recipe.startswith('nullius-correlate-'):
                expected_unlocks[recipe] = 'nullius-astronomy'
        for recipe, expected in expected_unlocks.items():
            actual = [name for name, tech in technologies.items() for effect in tech.get('effects', [])
                      if effect.get('type') == 'unlock-recipe' and effect.get('recipe') == recipe]
            if actual != [expected]:
                errors.append(recipe + ': unexpected unlocks ' + str(actual))
        for name, weight in {'nullius-blank-recording-module': 1000,
                             'nullius-box-blank-recording-module': 5000,
                             **{f'nullius-{p}-interferometric-recording': 1000 for p in PLANETS}}.items():
            if data['item'][name]['weight'] != weight:
                errors.append(name + ': cargo weight breaks the return comparison')
        ordinary = data['recipe']['nullius-blank-recording-module']
        bulk = data['recipe']['nullius-boxed-blank-recording-module']
        bulk_inputs = {}
        for item in bulk['ingredients']:
            unbox = data['recipe'][item['name'].replace('nullius-box-', 'nullius-unbox-', 1)]
            product = unbox['results'][0]
            bulk_inputs[product['name']] = item['amount'] * product['amount']
        if bulk_inputs != {i['name']: i['amount'] * 5 for i in ordinary['ingredients']}:
            errors.append('Boxed media ingredients do not match ordinary media')
        results = {}
        for contract in sorted((ROOT / 'tests/progression').glob('*astronomy-closure.args')):
            parsed = prereqs.parse_arguments(['@' + str(contract)])
            parsed.targets = [name for name, _ in parsed.targets]
            report = prereqs.analyze(data, parsed)
            results[contract.stem] = {key: report[key] for key in
                ('unresolved', 'required_technologies', 'invalid_raw', 'blocked_recipes')}
            if report['unresolved'] or report['required_technologies'] or report['invalid_raw']:
                errors.append(contract.stem + ': production does not close')
        results['media_cost'] = {}
        for planet in PLANETS:
            raw = set(prereqs.parse_arguments(['@' + str(ROOT / f'tests/progression/{planet}-astronomy-boundary.args')]).raw)
            costs = {kind: material_cost(data, ROOT / f'tests/progression/astronomy-cost-{planet}-{kind}.args', raw,
                                        mineral_boundary=planet == 'fulgora') for kind in ('media', 'return')}
            ratios = {kind: costs['media'][kind] / costs['return'][kind]
                      for kind in ('ore', 'gas') if costs['return'][kind] > 0}
            if any(ratio <= 1 for ratio in ratios.values()):
                errors.append(planet + ': new media is cheaper than its rocket return')
            results['media_cost'][planet] = dict(costs=costs, new_media_to_return_ratio=ratios)
        results['violations'] = errors
        args.output.write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(results, indent=2))
        if errors:
            raise prereqs.TestFailure('; '.join(errors))
    finally:
        if temporary:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
