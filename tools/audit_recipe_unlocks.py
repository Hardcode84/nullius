#!/usr/bin/env python3
"""Report research gates and ordinary-to-bulk prerequisite gaps for named recipes."""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import shutil

import analyze_factorio_prereqs as prereqs


def audit(data, config):
    technologies, recipes = data['technology'], data['recipe']
    owners = defaultdict(list)
    for name, technology in technologies.items():
        for effect in technology.get('effects', []):
            if effect['type'] == 'unlock-recipe':
                owners[effect['recipe']].append(name)
    closures = {}

    def closure(name):
        if name not in closures:
            closures[name] = prereqs.technology_closure(technologies, {name})
        return closures[name]

    rows, findings = [], []
    seen = set()
    for spec in config['recipes']:
        name = spec['name']
        if name in seen:
            raise ValueError('Duplicate audited recipe: ' + name)
        seen.add(name)
        recipe = recipes[name]
        for required in spec.get('requires', []):
            if required not in technologies:
                raise ValueError('Unknown required technology: ' + required)
        unlocks = sorted(owners[name])
        row = dict(recipe=name, classification=spec['classification'], enabled=recipe.get('enabled', True),
                   unlocks=unlocks, requirements=spec.get('requires', []), gates=[])
        rows.append(row)
        if row['enabled']:
            findings.append(dict(recipe=name, kind='enabled_without_research'))
        if not unlocks:
            findings.append(dict(recipe=name, kind='missing_unlock'))
        ordinary = spec.get('ordinary')
        if ordinary and ordinary not in recipes:
            raise ValueError('Unknown ordinary recipe: ' + ordinary)
        for owner in unlocks:
            available = closure(owner)
            missing = sorted(set(spec.get('requires', [])) - available)
            packs = sorted({ingredient[0] if isinstance(ingredient, list) else ingredient['name']
                            for technology in available
                            for ingredient in technologies[technology].get('unit', {}).get('ingredients', [])})
            row['gates'].append(dict(technology=owner, missing_required=missing, science=packs))
            if missing:
                findings.append(dict(recipe=name, kind='missing_research_gate', technology=owner, missing=missing))
            if ordinary and not recipes[ordinary].get('enabled', True):
                if not owners[ordinary]:
                    raise ValueError('Ordinary recipe has no unlock: ' + ordinary)
                if not any(unlock in available for unlock in owners[ordinary]):
                    findings.append(dict(recipe=name, kind='bulk_bypasses_ordinary', technology=owner,
                                         ordinary=ordinary, ordinary_unlocks=sorted(owners[ordinary])))
    for name in config.get('absent', []):
        if name in recipes:
            findings.append(dict(recipe=name, kind='unexpected_recipe'))
    return dict(schema=1, scope=config['scope'], recipes=rows, findings=findings)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--read-report', type=Path)
    parser.add_argument('--data-raw', type=Path)
    parser.add_argument('--show-all', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.read_report:
        result = json.loads(args.read_report.read_text())
    elif args.data_raw:
        result = audit(json.loads(args.data_raw.read_text()), json.loads(args.config.read_text()))
    else:
        data, work = prereqs.dump_resolved_data(prereqs.parse_arguments([]))
        try:
            result = audit(data, json.loads(args.config.read_text()))
        finally:
            if work:
                shutil.rmtree(work)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(f"Audited {len(result['recipes'])} recipes; {len(result['findings'])} findings")
    if args.show_all:
        for row in result['recipes']:
            print(row['recipe'] + ': ' + ', '.join(row['unlocks']))
    for finding in result['findings']:
        print(json.dumps(finding, sort_keys=True))
    if args.check and result['findings']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
