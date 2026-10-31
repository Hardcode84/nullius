#!/usr/bin/env python3
"""Audit checkpoint action routes before their research unlocks.

Uses a native checkpoint-contracts scenario export and fresh resolved prototypes.
Reports existential routes, not finite stock, power, or elapsed gameplay time.
"""
import argparse
import json
import math
import shutil
from pathlib import Path

import analyze_factorio_prereqs as prereqs
from audit_factorio_building_bootstrap import audit
from audit_vulcanus_progression import pre_physics_technologies
from plan_factorio_factory import place_item


def action_rows(data, surface, requirements, products, executed, supplied):
    rows = []
    entities = {n: p for entries in data.values() if isinstance(entries, dict)
                for n, p in entries.items() if isinstance(p, dict) and
                (p.get('minable') or p.get('placeable_by'))}
    for kind, mode, amount, alternatives in requirements:
        row = dict(kind=kind, mode=mode, amount=amount, alternatives=alternatives, witnesses=[])
        rows.append(row)
        if kind not in (1, 2, 3) or mode not in (1, 2, 3):
            row['unsupported'] = 'Mission or special action needs a native scenario'
            continue
        for entry in alternatives:
            name, ratio = entry[0], entry[1] if len(entry) > 1 else 1
            witness = None
            if kind == 3:
                entity = entities.get(name)
                if entity and prereqs.allowed_on_surface(entity, surface):
                    item = place_item(data, entity)
                    if item in products:
                        witness = dict(action='place', entity=name, item=item)
            elif mode == 1 and name in products:
                source = products[name]['source']
                if source == 'local extraction' or source.startswith('burn:'):
                    witness = dict(action='produce', **products[name])
                else:
                    for recipe_name in sorted(executed):
                        recipe = data['recipe'][recipe_name]
                        if recipe.get('hide_from_stats'):
                            continue
                        if any(p['name'] == name and p.get('amount', p.get('amount_max', 0)) > 0
                               and p.get('probability', 1) > 0 for p in prereqs.recipe_results(recipe)):
                            witness = dict(action='produce', recipe=recipe_name)
                            break
            elif mode == 2 and name in products:
                for recipe_name in sorted(executed):
                    recipe = data['recipe'][recipe_name]
                    if recipe.get('hide_from_stats'):
                        continue
                    if any(i['name'] == name for i in recipe.get('ingredients', [])):
                        witness = dict(action='consume', recipe=recipe_name)
                        break
                if witness is None:
                    for product in products.values():
                        if product['source'] == 'burn:' + name:
                            witness = dict(action='burn', executor=product['executor'])
                            break
                if witness is None and name in data.get('ammo', {}):
                    category = data['ammo'][name]['ammo_category']
                    for entity_name, turret in data.get('artillery-turret', {}).items():
                        gun = data['gun'][turret['gun']]['attack_parameters']
                        if (category in gun.get('ammo_categories', [])
                                and place_item(data, turret) in products
                                and prereqs.allowed_on_surface(turret, surface)):
                            witness = dict(action='fire', executor=entity_name)
                            break
            if witness:
                witness.update(material=name, count=math.ceil(amount / ratio))
                row['witnesses'].append(witness)
        if not row['witnesses']:
            row['blocked'] = 'No available action route before checkpoint unlock'
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--contracts', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--checkpoint')
    parser.add_argument('--list', action='store_true', help='Show every checkpoint and its first action witness')
    args = parser.parse_args()
    if args.read_report:
        report = json.loads(args.read_report.read_text())
    else:
        suite = json.loads(args.contracts.read_text())
        result = next(r for r in suite['results'] if r['case'] == 'checkpoint-contracts')
        if result['status'] != 'pass':
            raise prereqs.TestFailure('Checkpoint contract export failed')
        definitions = result['definitions']
        config = json.loads(args.config.read_text())
        data, directory = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            surface = prereqs.resolve_surface(data, config['surface'])
            roots = pre_physics_technologies(data['technology']) | set(config['research_roots'])
            permitted = prereqs.technology_closure(data['technology'], roots)
            entrance = prereqs.technology_closure(data['technology'], set(config['entrance_technologies']))
            required = prereqs.technology_closure(data['technology'], set(config['research_roots']))
            names = sorted(n for n in permitted if n.startswith('nullius-checkpoint-'))
            # Runtime action definitions replace the weaker hand-maintained product gates.
            config['checkpoint_products'] = {n: [] for n in names}
            checks = {}
            def check(name, products, executed, supplied, step):
                rows = action_rows(data, surface, definitions[name.removeprefix('nullius-checkpoint-')],
                                   products, executed, supplied)
                passed = all(r['witnesses'] for r in rows)
                checks[name] = dict(status='reachable' if passed else 'blocked', round=step,
                                    required_for_roots=name in required, requirements=rows)
                return passed
            reachability = audit(data, config, [], roots, checkpoint_check=check)
            for name in names:
                if name in entrance:
                    checks[name] = dict(status='researched_before_landing', required_for_roots=name in required)
                elif name not in checks:
                    checks[name] = dict(status='blocked_prerequisites', required_for_roots=name in required,
                                        blockers=reachability['research_blockers'][name])
            report = dict(checkpoints=checks, research_blockers=reachability['research_blockers'],
                          required_unreached_research=sorted(required & set(reachability['unreached_research'])),
                          boundaries=config, interpretation=__doc__)
            args.output.write_text(json.dumps(report, indent=2) + '\n')
        finally:
            shutil.rmtree(directory)
    if args.checkpoint:
        print(json.dumps(report['checkpoints'][args.checkpoint], indent=2))
    else:
        counts = {}
        for name, row in report['checkpoints'].items():
            counts[row['status']] = counts.get(row['status'], 0) + 1
            if args.list:
                actions = [r['witnesses'][0] for r in row.get('requirements', []) if r['witnesses']]
                print(name, row['status'], json.dumps(actions))
            if row['status'].startswith('blocked'):
                print(name, json.dumps(row))
        print(json.dumps(counts, indent=2))
        print('Required research blocked:', report['required_unreached_research'])
    return bool(report['required_unreached_research']) or any(
        r['status'].startswith('blocked') for r in report['checkpoints'].values())


if __name__ == '__main__':
    raise SystemExit(main())
