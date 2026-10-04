#!/usr/bin/env python3
"""Find a material, executor, and research order from a declared landing kit.

Reports existential reachability, not quantities, elapsed time, checkpoint actions,
energy sufficiency, or a finite-inventory campaign.
"""
import argparse
import json
import hashlib
from pathlib import Path
import shutil
import subprocess

import analyze_factorio_prereqs as prereqs
from plan_factorio_factory import fluid_ports_fit, place_item


def audit(data, config, targets, research_roots):
    surface = config['surface']
    technologies = data['technology']
    permitted = prereqs.technology_closure(technologies, set(research_roots))
    known_products = {n for entries in data.values() if isinstance(entries, dict)
                      for n, value in entries.items() if isinstance(value, dict)}
    unknown = set(targets) - known_products
    if unknown:
        raise prereqs.TestFailure('Unknown targets: ' + ', '.join(sorted(unknown)))
    researched = prereqs.technology_closure(technologies, set(config['entrance_technologies']))
    permitted |= researched
    products = {name: {'source': 'local extraction', 'round': 0} for name in config['raw']}
    supplied = set(config['starter_items'])
    for product, extraction in config['raw'].items():
        resource = data['resource'][extraction['resource']]
        drill = data['mining-drill'][extraction['machine']]
        if product not in {p['name'] for p in prereqs.minable_results(resource)}:
            raise prereqs.TestFailure('Resource does not supply ' + product)
        if resource.get('minable', {}).get('required_fluid'):
            raise prereqs.TestFailure('Extraction startup fluid is not modeled: ' + product)
        if (place_item(data, drill) not in supplied or not prereqs.allowed_on_surface(drill, surface)
                or resource.get('category', 'basic-solid') not in drill.get('resource_categories', [])):
            raise prereqs.TestFailure('No supplied compatible extractor for ' + product)
    craftable = {}
    machines = {}
    labs = {}
    for kind in ('assembling-machine', 'furnace', 'lab'):
        for name, machine in data.get(kind, {}).items():
            if not prereqs.allowed_on_surface(machine, surface):
                continue
            if not name.startswith('nullius-'):
                continue
            if not machine.get('minable') and not machine.get('placeable_by') and not any(
                    p.get('place_result') == name for entries in data.values()
                    if isinstance(entries, dict) for p in entries.values() if isinstance(p, dict)):
                continue
            item = place_item(data, machine)
            (labs if kind == 'lab' else machines)[name] = (item, machine)
    hand = data['character'][config['character']].get('crafting_categories', [])
    forbidden = set(config['forbid_categories']) | prereqs.IGNORED_RECIPE_CATEGORIES
    recipes = {n: r for n, r in data['recipe'].items()
               if not r.get('hidden') and prereqs.allowed_on_surface(r, surface)
               and set(prereqs.recipe_categories(r)) - forbidden}
    unlocks = {}
    for tech in permitted:
        for effect in technologies[tech].get('effects', []):
            if effect['type'] == 'unlock-recipe':
                unlocks.setdefault(effect['recipe'], set()).add(tech)
    eligible = {n: r for n, r in recipes.items() if r.get('enabled', True) or n in unlocks}
    checkpoints = config['checkpoint_products']
    for tech in permitted - researched:
        if tech.startswith('nullius-checkpoint-') and tech not in checkpoints:
            raise prereqs.TestFailure('Missing checkpoint material contract: ' + tech)
        if technologies[tech].get('research_trigger'):
            raise prereqs.TestFailure('Unsupported research trigger: ' + tech)
    burners = []
    for kind, entries in data.items():
        if not isinstance(entries, dict):
            continue
        for name, entity in entries.items():
            if not isinstance(entity, dict) or not prereqs.allowed_on_surface(entity, surface):
                continue
            source = entity.get('burner') or entity.get('energy_source', {})
            if source.get('type') != 'burner' and not entity.get('burner'):
                continue
            if not entity.get('minable'):
                continue
            burners.append((name, place_item(data, entity), set(source.get('fuel_categories', []))))
    fuels = {n: p for entries in data.values() if isinstance(entries, dict)
             for n, p in entries.items() if isinstance(p, dict) and p.get('burnt_result')}
    rounds = []
    executed = set()
    while True:
        step = len(rounds) + 1
        active = {n: m for n, (item, m) in machines.items() if item in supplied or item in products}
        added = []
        for name, recipe in eligible.items():
            if name in executed or not (recipe.get('enabled', True) or unlocks.get(name, set()) & researched):
                continue
            ingredients = recipe.get('ingredients', [])
            if not all(i['name'] in products for i in ingredients):
                continue
            if any(any(k in i for k in ('temperature', 'minimum_temperature', 'maximum_temperature')) for i in ingredients):
                continue
            categories = set(prereqs.recipe_categories(recipe)) - forbidden
            executor = None
            if categories.intersection(hand) and all(i.get('type', 'item') == 'item' for i in ingredients + prereqs.recipe_results(recipe)):
                executor = config['character']
            else:
                executor = next((n for n, m in active.items()
                                 if categories.intersection(m.get('crafting_categories', []))
                                 and m.get('energy_source', {}).get('type') in ('electric', 'void')
                                 and fluid_ports_fit(recipe, m)), None)
            if executor is None:
                continue
            outputs = prereqs.recipe_results(recipe)
            uncertain = any(not prereqs.deterministic_product(p) for p in outputs)
            if uncertain and name not in config['probabilistic_recipes']:
                continue
            executed.add(name)
            for product in outputs:
                if product.get('probability', 1) <= 0 or product.get('amount', product.get('amount_max', 0)) <= 0:
                    continue
                witness = {'source': name, 'executor': executor, 'round': step,
                           'research': sorted(unlocks.get(name, set()) & researched),
                           'ingredients': [i['name'] for i in ingredients],
                           'probabilistic': uncertain}
                if product['name'] not in products:
                    products[product['name']] = witness
                    added.append(product['name'])
                craftable.setdefault(product['name'], witness)
        for fuel, prototype in fuels.items():
            result = prototype['burnt_result']
            if fuel not in products or result in products:
                continue
            burner = next((n for n, item, cats in burners if (item in products or item in supplied)
                           and cats.intersection(prototype.get('fuel_categories', []))), None)
            if burner:
                witness = {'source': 'burn:' + fuel, 'executor': burner, 'round': step,
                           'ingredients': [fuel], 'research': [], 'probabilistic': False}
                products[result] = witness
                craftable[result] = witness
                added.append(result)
        new_techs = []
        for name in sorted(permitted - researched):
            tech = technologies[name]
            if not set(tech.get('prerequisites', [])) <= researched:
                continue
            requirements = [i[0] for i in tech.get('unit', {}).get('ingredients', [])
                            if i[0] != 'nullius-checkpoint' and not i[0].startswith('nullius-requirement-')]
            if not set(requirements) <= products.keys():
                continue
            if not any((item in supplied or item in products) and set(requirements) <= set(lab.get('inputs', []))
                       for item, lab in labs.values()):
                continue
            if not all(any(p in products for p in alternatives) for alternatives in checkpoints.get(name, [])):
                continue
            new_techs.append(name)
        if not added and not new_techs:
            break
        researched.update(new_techs)
        rounds.append({'round': step, 'products': sorted(added), 'technologies': new_techs})
    result = {}
    for target in sorted(set(targets)):
        if target in config['raw']:
            result[target] = {'status': 'extracted', **products[target]}
        elif target in craftable:
            result[target] = {'status': 'craftable', **craftable[target]}
        else:
            producers = {}
            for name, recipe in eligible.items():
                if target not in {p['name'] for p in prereqs.recipe_results(recipe)}:
                    continue
                producers[name] = {'missing_inputs': sorted({i['name'] for i in recipe.get('ingredients', [])} - products.keys()),
                                   'unresearched_unlocks': sorted(unlocks.get(name, set()) - researched),
                                   'categories': prereqs.recipe_categories(recipe)}
            result[target] = {'status': 'blocked', 'supplied': target in supplied, 'producers': producers}
    research_blockers = {name: {
        'prerequisites': sorted(set(technologies[name].get('prerequisites', [])) - researched),
        'checkpoint_products': [group for group in checkpoints.get(name, []) if not any(p in products for p in group)],
        'science': [i[0] for i in technologies[name].get('unit', {}).get('ingredients', [])
                    if i[0] not in products and i[0] != 'nullius-checkpoint' and not i[0].startswith('nullius-requirement-')]
    } for name in sorted(permitted - researched)}
    placeable = {name for entries in data.values() if isinstance(entries, dict)
                 for name, item in entries.items() if isinstance(item, dict) and item.get('place_result')}
    return {'building_targets': sorted(set(targets) & placeable), 'targets': result, 'rounds': rounds, 'unreached_research': sorted(permitted - researched),
            'blocked_targets': [n for n, row in result.items() if row['status'] == 'blocked'],
            'products': products, 'research_blockers': research_blockers,
            'boundaries': config,
            'interpretation': 'Existential material/research order. Only declared probabilistic recipes permitted; no output averaging or quantity claim. External electricity and manual surplus disposal. Checkpoint materials checked, actions and quantities not executed. Temperature-dependent recipes excluded.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--plan', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--target')
    parser.add_argument('--product')
    parser.add_argument('--technology')
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        if not args.plan:
            parser.error('--plan is required without --read-report')
        config = json.loads(args.config.read_text())
        plan = json.loads(args.plan.read_text())
        # Query the maintained planner schema; include every operating and construction executor.
        stage = next(s for s in plan['stages'] if s['name'] == config['stage'])
        targets = set(config['extra_targets']) | set(config['starter_items'])
        targets.update(p for groups in config['checkpoint_products'].values() for group in groups for p in group)
        roots = set(config['research_roots'])
        for row in stage['plans']:
            roots.update(t['name'] for t in row['research']['technologies'])
            targets.update(row['construction']['items'])
        data, directory = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            digest = hashlib.sha256((directory / 'script-output/data-raw-dump.json').read_bytes()).hexdigest()
            if digest != plan['provenance']['dump_sha256']:
                raise prereqs.TestFailure('Factory plan prototype snapshot differs; regenerate the plan')
            report = audit(data, config, targets, roots)
            report['dump_sha256'] = digest
            report['revision'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
            args.output.write_text(json.dumps(report, indent=2) + '\n')
        finally:
            if directory:
                shutil.rmtree(directory)
    if args.target:
        print(json.dumps(report['targets'][args.target], indent=2))
    elif args.technology:
        print(json.dumps(report['research_blockers'].get(args.technology), indent=2))
    elif args.product:
        print(json.dumps(report['products'].get(args.product), indent=2))
    else:
        print(json.dumps({k: report[k] for k in ('blocked_targets', 'unreached_research')}, indent=2))
        print(f"Targets: {len(report['targets'])}; buildings: {len(report['building_targets'])}; reachability rounds: {len(report['rounds'])}")
    return bool(report['blocked_targets'] or report['unreached_research'])


if __name__ == '__main__':
    raise SystemExit(main())
