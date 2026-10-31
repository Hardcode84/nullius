#!/usr/bin/env python3
"""Trace substituted components through item recipes to metal recovery outputs."""
import argparse
import json
from pathlib import Path
import shutil
import analyze_factorio_prereqs as prereqs


def audit(data, config):
    protected = set(config['protected'])
    feed = protected | set(config.get('mineral_feed', []))
    reachable = {name: [] for name in config['components']}
    findings = {}
    recipes = data['recipe']
    changed = True
    while changed:
        changed = False
        for name, recipe in sorted(recipes.items()):
            parents = [i['name'] for i in recipe.get('ingredients', [])
                       if i.get('type', 'item') == 'item' and i['name'] in reachable]
            if not parents:
                continue
            path = min((reachable[n] for n in parents), key=len) + [name]
            for product in prereqs.recipe_results(recipe):
                if product.get('type', 'item') != 'item':
                    continue
                if product.get('probability', product.get('independent_probability', 1)) == 0:
                    continue
                target = product['name']
                if target in protected:
                    # Material conversion consumes mineral feed; equipment recovery does not.
                    mineral_feed = any(i['name'] in feed for i in recipe.get('ingredients', []))
                    if not mineral_feed:
                        findings.setdefault((name, target), path)
                elif target not in reachable:
                    reachable[target] = path
                    changed = True
    return {'reachable_items': len(reachable), 'metal_recovery': [
        {'recipe': recipe, 'product': product, 'path': path}
        for (recipe, product), path in sorted(findings.items())]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--recipes-only', action='store_true')
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--recipe')
    args = parser.parse_args()
    if args.read_report:
        result = json.loads(args.read_report.read_text())
    else:
        data, work = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            result = audit(data, json.loads(args.config.read_text()))
        finally:
            if work: shutil.rmtree(work)
    if args.recipe:
        result['metal_recovery'] = [r for r in result['metal_recovery'] if r['recipe'] == args.recipe]
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(sorted({r["recipe"] for r in result["metal_recovery"]}) if args.recipes_only else result, indent=2))
    if args.check and result['metal_recovery']: raise SystemExit(1)


if __name__ == '__main__': main()
