#!/usr/bin/env python3
"""Audit native research gates, checkpoint actions and science costs.

Gate witnesses establish that a recipe or action is unlocked in the ancestor
closure. They do not prove recursive ingredients, executor construction,
planet access, energy, throughput or checkpoint quantities. Release progression
contracts and planet checkpoint audits cover those separate boundaries.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import shutil

import analyze_factorio_prereqs as prereqs
from plan_factorio_factory import place_item


def costs(data, runtime, names):
    """Return paid science costs; checkpoints have automatic completion and no lab bill."""
    packs = defaultdict(int)
    seconds = 0
    formulas = []
    triggers = []
    for name in sorted(names):
        tech = data['technology'][name]
        if name.startswith('nullius-checkpoint-'):
            continue
        unit = tech.get('unit')
        if not unit:
            triggers.append(name)
            continue
        count = runtime[name]['count']
        if unit.get('count_formula'):
            formulas.append(dict(technology=name, level=runtime[name]['level'], count=count,
                                 formula=unit['count_formula'], maximum=tech.get('max_level', 1)))
        for pack, amount in unit['ingredients']:
            if pack == 'nullius-checkpoint' or pack.startswith('nullius-requirement-'):
                continue
            packs[pack] += count * amount
        seconds += count * unit['time']
    return dict(packs=dict(sorted(packs.items())), lab_hours_at_speed_one=seconds/3600,
                formula_levels=formulas, triggered=triggers)


def recipe_cases(data, config):
    """Check selected recipes at their declared planet and research boundaries."""
    results = []
    for case in config.get('recipe_cases', []):
        recipe = data['recipe'][case['recipe']]
        product = recipe.get('main_product') or prereqs.recipe_results(recipe)[0]['name']
        args = prereqs.parse_arguments(['@' + case['boundary'], '--technology', case['technology'],
                                       '--recipe', product + '=' + case['recipe']])
        args.targets = [product]
        report = prereqs.analyze(data, args)
        results.append(dict(**case, target=product,
                            **{key: report[key] for key in ('required_technologies', 'unresolved', 'invalid_raw')}))
    return results


def audit(data, runtime, config):
    technologies = data['technology']
    active = {n for n, t in runtime['research'].items() if t['enabled'] and n in technologies}
    enabled = set(runtime['enabled_recipes'])
    recipes = data['recipe']
    owners = defaultdict(set)
    producers = defaultdict(set)
    consumers = defaultdict(set)
    extracted = set()
    entities = {}
    for kind, prototypes in data.items():
        if not isinstance(prototypes, dict):
            continue
        for name, prototype in prototypes.items():
            if not isinstance(prototype, dict):
                continue
            if kind in ('resource', 'simple-entity', 'tree', 'fish'):
                extracted.update(p['name'] for p in prereqs.minable_results(prototype))
            if prototype.get('minable') or prototype.get('placeable_by') or kind == 'character':
                entities[name] = prototype
    placements = {p['place_result']: n for entries in data.values() if isinstance(entries, dict)
                  for n, p in entries.items() if isinstance(p, dict) and p.get('place_result')}
    for name, technology in technologies.items():
        for effect in technology.get('effects', []):
            if effect['type'] == 'unlock-recipe':
                owners[effect['recipe']].add(name)
    for name, recipe in recipes.items():
        if recipe.get('hidden'):
            continue
        for product in prereqs.recipe_results(recipe):
            if product.get('amount', product.get('amount_max', 0)) > 0 and product.get('probability', 1) > 0:
                producers[product['name']].add(name)
        for ingredient in recipe.get('ingredients', []):
            consumers[ingredient['name']].add(name)
    burned = defaultdict(set)
    launchable = set()
    ammunition = set(data.get('ammo', {}))
    for prototypes in data.values():
        if not isinstance(prototypes, dict):
            continue
        for name, prototype in prototypes.items():
            if not isinstance(prototype, dict):
                continue
            if prototype.get('burnt_result'):
                burned[prototype['burnt_result']].add(name)
            if prototype.get('send_to_orbit_mode') == 'automated':
                launchable.add(name)
    closures = {}
    missing = []
    cycles = []
    def closure(name, visiting=()):
        if name in visiting:
            cycles.append(list(visiting) + [name])
            return set()
        if name not in technologies:
            missing.append(name)
            return set()
        if name not in closures:
            result = {name}
            for parent in technologies[name].get('prerequisites', []):
                result |= closure(parent, visiting + (name,))
            closures[name] = result
        return closures[name]
    for name in sorted(active):
        closure(name)
    def available(recipe, before):
        return recipe in enabled or bool(owners[recipe] & before)
    def material(name, before):
        if name in extracted:
            return ['natural source (planet availability unchecked)']
        witnesses = sorted(r for r in producers[name] if available(r, before))
        for fuel in burned[name]:
            if any(available(r, before) for r in producers[fuel]):
                witnesses.append('burn:' + fuel)
        return witnesses
    science_gaps = []
    input_gaps = []
    checkpoints = []
    for name in sorted(active):
        tech = technologies[name]
        before = closures[name] - {name}
        if not name.startswith('nullius-checkpoint-'):
            for pack, _ in tech.get('unit', {}).get('ingredients', []):
                if pack == 'nullius-checkpoint' or pack.startswith('nullius-requirement-'):
                    continue
                if not material(pack, before):
                    science_gaps.append(dict(technology=name, pack=pack,
                                             producer_unlocks=sorted(set().union(*(owners[r] for r in producers[pack])))))
        else:
            suffix = name.removeprefix('nullius-checkpoint-')
            definition = runtime['definitions'].get(suffix)
            if definition is None:
                checkpoints.append(dict(technology=name, status='missing_definition'))
                continue
            for kind, mode, amount, alternatives in definition:
                row = dict(technology=name, kind=kind, mode=mode, amount=amount, alternatives=alternatives, witnesses=[])
                checkpoints.append(row)
                if kind in (4, 5):
                    row['status'] = 'native_action_required'
                    continue
                for entry in alternatives:
                    product = entry[0]
                    produced = product
                    if kind == 3:
                        entity = entities.get(product)
                        if product in placements:
                            produced = placements[product]
                        elif entity:
                            produced = place_item(data, entity)
                        else:
                            continue
                    route = material(produced, before)
                    if not route:
                        continue
                    if kind == 3 or mode == 1:
                        row['witnesses'].append(dict(product=product, routes=route))
                    elif mode == 2:
                        sinks = sorted(r for r in consumers[product] if available(r, before) and not recipes[r].get('hide_from_stats'))
                        if product in launchable:
                            sinks.append('rocket launch (silo access unchecked)')
                        if product in ammunition:
                            sinks.append('ammunition (weapon access unchecked)')
                        if any(product in fuels for fuels in burned.values()):
                            sinks.append('burner fuel (burner access unchecked)')
                        if sinks:
                            row['witnesses'].append(dict(product=product, routes=route, sinks=sinks))
                row['status'] = 'gate_open' if row['witnesses'] else 'missing_action_gate'
        for effect in tech.get('effects', []):
            if effect['type'] != 'unlock-recipe':
                continue
            recipe = recipes[effect['recipe']]
            for ingredient in recipe.get('ingredients', []):
                product = ingredient['name']
                if not material(product, closures[name]):
                    input_gaps.append(dict(technology=name, recipe=recipe['name'], product=product,
                                           producer_unlocks=sorted(set().union(*(owners[r] for r in producers[product])))))
    milestone_rows = {}
    for name in config['milestones']:
        if name not in active:
            raise ValueError('Unknown or disabled milestone: ' + name)
        required = closures[name]
        bill = costs(data, runtime['research'], required)
        bill.update(technologies=len(required), checkpoints=sum(n.startswith('nullius-checkpoint-') for n in required),
                    supply_hours={str(rate): max(bill['packs'].values(), default=0)/rate/60
                                  for rate in config['supply_rates_per_minute']})
        milestone_rows[name] = bill
    for label, roots in config.get('groups', {}).items():
        required = set().union(*(closures[name] for name in roots))
        bill = costs(data, runtime['research'], required)
        bill.update(technologies=len(required), checkpoints=sum(n.startswith('nullius-checkpoint-') for n in required),
                    supply_hours={str(rate): max(bill['packs'].values(), default=0)/rate/60
                                  for rate in config['supply_rates_per_minute']})
        milestone_rows[label] = bill
    intervals = []
    for start, end in config.get('cost_intervals', []):
        intervals.append(dict(start=start, end=end, **costs(data, runtime['research'], closures[end] - closures[start])))
    direct = []
    for name in sorted(active):
        if name.startswith('nullius-checkpoint-'):
            continue
        bill = costs(data, runtime['research'], {name})
        direct.append(dict(technology=name, **bill))
    direct.sort(key=lambda row: max(row['packs'].values(), default=0), reverse=True)
    statuses = defaultdict(int)
    for row in checkpoints:
        statuses[row['status']] += 1
    return dict(schema=1, factorio_version=runtime['factorio_version'],
                scope=__doc__, cost_scope='Default map multiplier. One native current level per technology; unbounded repeat research excluded. Checkpoint display packs are not charged. Supply hours assume all pack lines already run at the stated equal rate; not player completion time.',
                counts=dict(enabled_technologies=len(active), checkpoint_technologies=sum(n.startswith('nullius-checkpoint-') for n in active),
                            checkpoint_requirements=dict(statuses)),
                missing_prerequisites=sorted(set(missing)), cycles=cycles,
                science_gate_gaps=science_gaps, recipe_input_gate_gaps=input_gaps,
                checkpoint_gaps=[row for row in checkpoints if row['status'].startswith('missing')],
                checkpoints=checkpoints, milestones=milestone_rows, cost_intervals=intervals, recipe_cases=recipe_cases(data, config), largest_direct_costs=direct[:config['largest_costs']])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=Path('tests/progression/final-research-audit.json'))
    parser.add_argument('--runtime', type=Path)
    parser.add_argument('--output', type=Path, help='Report written when auditing a runtime export')
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--section', choices=['summary','checkpoints','checkpoint_gaps','science_gate_gaps','recipe_input_gate_gaps','milestones','cost_intervals','recipe_cases','largest_direct_costs'], default='summary')
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        if not args.runtime or not args.output:
            parser.error('--runtime and --output are required unless --read-report is given')
        suite = json.loads(args.runtime.read_text())
        runtime = next(row for row in suite['results'] if row['case'] == 'checkpoint-contracts')
        if runtime['status'] != 'pass':
            raise ValueError('Native contract export failed')
        data, temporary = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            report = audit(data, runtime, json.loads(args.config.read_text()))
        finally:
            if temporary:
                shutil.rmtree(temporary)
        args.output.write_text(json.dumps(report, indent=2) + '\n')
    if args.section == 'summary':
        print(json.dumps({k:report[k] for k in ('counts','cycles','missing_prerequisites','science_gate_gaps','checkpoint_gaps')}, indent=2))
        print('Recipe input gate candidates:', len(report['recipe_input_gate_gaps']))
        for name, bill in report['milestones'].items():
            print(name, json.dumps({k:bill[k] for k in ('technologies','checkpoints','packs','supply_hours','lab_hours_at_speed_one')}))
    else:
        print(json.dumps(report[args.section], indent=2))


if __name__ == '__main__':
    main()
